#!/usr/bin/env bash
# Java Dependency Auditor - Analysis Script
# Scans Maven/Gradle projects for vulnerabilities, outdated deps, unused deps, and license issues

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: Directory '$PROJECT_DIR' does not exist${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

echo "============================================="
echo "  Java Dependency Audit"
echo "============================================="
echo ""

# ─── Build Tool Detection ───
BUILD_TOOL="unknown"
if [ -f "pom.xml" ]; then
    BUILD_TOOL="maven"
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    BUILD_TOOL="gradle"
fi
echo -e "${BLUE}Build Tool:${NC} $BUILD_TOOL"

if [ "$BUILD_TOOL" = "unknown" ]; then
    echo -e "${RED}Error: No pom.xml or build.gradle found. Not a Maven/Gradle project.${NC}"
    exit 1
fi

# ─── Java Version Detection ───
JAVA_VERSION="unknown"
if [ "$BUILD_TOOL" = "maven" ]; then
    JAVA_VERSION=$(grep -oP '(?<=<java.version>)[^<]+' pom.xml 2>/dev/null || echo "")
    if [ -z "$JAVA_VERSION" ]; then
        JAVA_VERSION=$(grep -oP '(?<=<maven.compiler.source>)[^<]+' pom.xml 2>/dev/null || echo "")
    fi
elif [ "$BUILD_TOOL" = "gradle" ]; then
    GRADLE_FILE="build.gradle"
    [ -f "build.gradle.kts" ] && GRADLE_FILE="build.gradle.kts"
    JAVA_VERSION=$(grep -oP "sourceCompatibility\s*=\s*['\"]?\K[^'\"\\s]+" "$GRADLE_FILE" 2>/dev/null || echo "")
fi
if [ -z "$JAVA_VERSION" ]; then
    JAVA_VERSION=$(java -version 2>&1 | head -1 | grep -oP '"([0-9]+)' | tr -d '"' 2>/dev/null || echo "unknown")
fi
echo -e "${BLUE}Java Version:${NC} $JAVA_VERSION"

# ─── Spring Boot Version Detection ───
SPRING_BOOT_VERSION="not detected"
if [ "$BUILD_TOOL" = "maven" ]; then
    SPRING_BOOT_VERSION=$(grep -A5 'spring-boot-starter-parent' pom.xml 2>/dev/null | grep -oP '(?<=<version>)[^<]+' | head -1 || echo "")
    if [ -z "$SPRING_BOOT_VERSION" ]; then
        SPRING_BOOT_VERSION=$(grep -oP '(?<=<spring-boot.version>)[^<]+' pom.xml 2>/dev/null || echo "not detected")
    fi
elif [ "$BUILD_TOOL" = "gradle" ]; then
    GRADLE_FILE="build.gradle"
    [ -f "build.gradle.kts" ] && GRADLE_FILE="build.gradle.kts"
    SPRING_BOOT_VERSION=$(grep -oP "org.springframework.boot['\"]?\s*(version\s*)?['\"]?[0-9]+\.[0-9]+\.[0-9]+[^'\"]*" "$GRADLE_FILE" 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+.*' | head -1 || echo "not detected")
fi
echo -e "${BLUE}Spring Boot Version:${NC} $SPRING_BOOT_VERSION"

# ─── Dependency Count ───
echo ""
echo "---------------------------------------------"
echo "  Dependency Overview"
echo "---------------------------------------------"

if [ "$BUILD_TOOL" = "maven" ]; then
    DIRECT_DEPS=$(grep -c '<dependency>' pom.xml 2>/dev/null || echo "0")
    echo -e "Direct dependencies in pom.xml: ${CYAN}${DIRECT_DEPS}${NC}"

    # Count by scope
    COMPILE_DEPS=$(grep -B5 '</dependency>' pom.xml 2>/dev/null | grep -c '<scope>compile</scope>' || echo "0")
    TEST_DEPS=$(grep -B5 '</dependency>' pom.xml 2>/dev/null | grep -c '<scope>test</scope>' || echo "0")
    RUNTIME_DEPS=$(grep -B5 '</dependency>' pom.xml 2>/dev/null | grep -c '<scope>runtime</scope>' || echo "0")
    PROVIDED_DEPS=$(grep -B5 '</dependency>' pom.xml 2>/dev/null | grep -c '<scope>provided</scope>' || echo "0")
    NO_SCOPE=$((DIRECT_DEPS - COMPILE_DEPS - TEST_DEPS - RUNTIME_DEPS - PROVIDED_DEPS))

    echo "  compile/default: $((COMPILE_DEPS + NO_SCOPE))"
    echo "  test: $TEST_DEPS"
    echo "  runtime: $RUNTIME_DEPS"
    echo "  provided: $PROVIDED_DEPS"

elif [ "$BUILD_TOOL" = "gradle" ]; then
    GRADLE_FILE="build.gradle"
    [ -f "build.gradle.kts" ] && GRADLE_FILE="build.gradle.kts"
    IMPL_DEPS=$(grep -c "implementation\s" "$GRADLE_FILE" 2>/dev/null || echo "0")
    TEST_DEPS=$(grep -c "testImplementation\s" "$GRADLE_FILE" 2>/dev/null || echo "0")
    RUNTIME_DEPS=$(grep -c "runtimeOnly\s" "$GRADLE_FILE" 2>/dev/null || echo "0")
    COMPILE_ONLY=$(grep -c "compileOnly\s" "$GRADLE_FILE" 2>/dev/null || echo "0")
    TOTAL=$((IMPL_DEPS + TEST_DEPS + RUNTIME_DEPS + COMPILE_ONLY))

    echo -e "Dependencies in build file: ${CYAN}${TOTAL}${NC}"
    echo "  implementation: $IMPL_DEPS"
    echo "  testImplementation: $TEST_DEPS"
    echo "  runtimeOnly: $RUNTIME_DEPS"
    echo "  compileOnly: $COMPILE_ONLY"
fi

# ─── OWASP Dependency-Check Detection ───
echo ""
echo "---------------------------------------------"
echo "  Vulnerability Scanning Setup"
echo "---------------------------------------------"

OWASP_CONFIGURED="false"
if [ "$BUILD_TOOL" = "maven" ]; then
    if grep -q "dependency-check-maven" pom.xml 2>/dev/null; then
        OWASP_CONFIGURED="true"
        echo -e "${GREEN}OWASP Dependency-Check Maven plugin: CONFIGURED${NC}"
        OWASP_VERSION=$(grep -A3 "dependency-check-maven" pom.xml 2>/dev/null | grep -oP '(?<=<version>)[^<]+' | head -1 || echo "unknown")
        echo "  Version: $OWASP_VERSION"
    else
        echo -e "${YELLOW}OWASP Dependency-Check Maven plugin: NOT CONFIGURED${NC}"
    fi
elif [ "$BUILD_TOOL" = "gradle" ]; then
    GRADLE_FILE="build.gradle"
    [ -f "build.gradle.kts" ] && GRADLE_FILE="build.gradle.kts"
    if grep -q "org.owasp.dependencycheck" "$GRADLE_FILE" 2>/dev/null; then
        OWASP_CONFIGURED="true"
        echo -e "${GREEN}OWASP Dependency-Check Gradle plugin: CONFIGURED${NC}"
    else
        echo -e "${YELLOW}OWASP Dependency-Check Gradle plugin: NOT CONFIGURED${NC}"
    fi
fi

# Check for other security scanning tools
SNYK_CONFIGURED="false"
if [ -f ".snyk" ] || grep -rq "snyk" .github/ 2>/dev/null; then
    SNYK_CONFIGURED="true"
    echo -e "${GREEN}Snyk: CONFIGURED${NC}"
fi

TRIVY_CONFIGURED="false"
if grep -rq "trivy" .github/ 2>/dev/null || grep -rq "trivy" .gitlab-ci.yml 2>/dev/null; then
    TRIVY_CONFIGURED="true"
    echo -e "${GREEN}Trivy: CONFIGURED${NC}"
fi

if [ "$OWASP_CONFIGURED" = "false" ] && [ "$SNYK_CONFIGURED" = "false" ] && [ "$TRIVY_CONFIGURED" = "false" ]; then
    echo -e "${RED}No vulnerability scanning tool detected${NC}"
fi

# ─── Dependency Version Analysis ───
echo ""
echo "---------------------------------------------"
echo "  Version Pinning Analysis"
echo "---------------------------------------------"

if [ "$BUILD_TOOL" = "maven" ]; then
    # Check for SNAPSHOT dependencies
    SNAPSHOT_COUNT=$(grep -c "SNAPSHOT" pom.xml 2>/dev/null || echo "0")
    if [ "$SNAPSHOT_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}SNAPSHOT dependencies found: $SNAPSHOT_COUNT${NC}"
        grep "SNAPSHOT" pom.xml 2>/dev/null | grep -oP '(?<=<version>)[^<]*SNAPSHOT[^<]*' | head -5 | while read ver; do
            echo "  - $ver"
        done
    else
        echo -e "${GREEN}No SNAPSHOT dependencies${NC}"
    fi

    # Check for version ranges
    RANGE_COUNT=$(grep -cP '<version>\[|\(' pom.xml 2>/dev/null || echo "0")
    if [ "$RANGE_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}Version ranges found: $RANGE_COUNT (non-deterministic builds)${NC}"
    else
        echo -e "${GREEN}No version ranges (deterministic)${NC}"
    fi

    # Check for missing versions (managed by parent)
    MANAGED_COUNT=$(grep -c '<dependency>' pom.xml 2>/dev/null || echo "0")
    VERSIONED_COUNT=$(grep -B2 -A5 '<dependency>' pom.xml 2>/dev/null | grep -c '<version>' || echo "0")
    UNVERSIONED=$((MANAGED_COUNT - VERSIONED_COUNT))
    if [ "$UNVERSIONED" -gt 0 ]; then
        echo -e "${BLUE}Dependencies managed by parent/BOM: ~$UNVERSIONED${NC}"
    fi

elif [ "$BUILD_TOOL" = "gradle" ]; then
    GRADLE_FILE="build.gradle"
    [ -f "build.gradle.kts" ] && GRADLE_FILE="build.gradle.kts"
    SNAPSHOT_COUNT=$(grep -c "SNAPSHOT" "$GRADLE_FILE" 2>/dev/null || echo "0")
    if [ "$SNAPSHOT_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}SNAPSHOT dependencies found: $SNAPSHOT_COUNT${NC}"
    else
        echo -e "${GREEN}No SNAPSHOT dependencies${NC}"
    fi

    DYNAMIC_COUNT=$(grep -cP ":\+'" "$GRADLE_FILE" 2>/dev/null || echo "0")
    DYNAMIC_COUNT2=$(grep -cP 'latest\.release|latest\.integration' "$GRADLE_FILE" 2>/dev/null || echo "0")
    DYNAMIC_TOTAL=$((DYNAMIC_COUNT + DYNAMIC_COUNT2))
    if [ "$DYNAMIC_TOTAL" -gt 0 ]; then
        echo -e "${YELLOW}Dynamic versions found: $DYNAMIC_TOTAL (non-deterministic builds)${NC}"
    else
        echo -e "${GREEN}No dynamic versions (deterministic)${NC}"
    fi
fi

# ─── Known Outdated Libraries Check ───
echo ""
echo "---------------------------------------------"
echo "  Known Outdated / EOL Library Detection"
echo "---------------------------------------------"

OUTDATED_FOUND=0

check_outdated() {
    local pattern="$1"
    local description="$2"
    local recommendation="$3"
    local found="false"

    if [ "$BUILD_TOOL" = "maven" ]; then
        if grep -q "$pattern" pom.xml 2>/dev/null; then
            found="true"
        fi
    elif [ "$BUILD_TOOL" = "gradle" ]; then
        GRADLE_FILE="build.gradle"
        [ -f "build.gradle.kts" ] && GRADLE_FILE="build.gradle.kts"
        if grep -q "$pattern" "$GRADLE_FILE" 2>/dev/null; then
            found="true"
        fi
    fi

    if [ "$found" = "true" ]; then
        echo -e "  ${RED}[FOUND]${NC} $description"
        echo "         -> $recommendation"
        OUTDATED_FOUND=$((OUTDATED_FOUND + 1))
    fi
}

check_outdated "junit:junit" "JUnit 4" "Migrate to JUnit 5 (org.junit.jupiter)"
check_outdated "javax.servlet" "javax.servlet API" "Use jakarta.servlet (for Spring Boot 3.x)"
check_outdated "javax.persistence" "javax.persistence API" "Use jakarta.persistence (for Spring Boot 3.x)"
check_outdated "javax.validation" "javax.validation API" "Use jakarta.validation (for Spring Boot 3.x)"
check_outdated "log4j-core.*1\." "Log4j 1.x (EOL, CVE-prone)" "Upgrade to Log4j 2.x or use SLF4J+Logback"
check_outdated "commons-logging" "Commons Logging" "Use SLF4J (Spring Boot default)"
check_outdated "guava.*[0-2][0-9]\." "Guava (old version pattern)" "Check for latest Guava version (33+)"
check_outdated "httpclient.*4\." "Apache HttpClient 4.x" "Upgrade to HttpClient 5.x for Spring Boot 3.x"
check_outdated "swagger-annotations.*2\." "Swagger 2.x annotations" "Migrate to springdoc-openapi (OpenAPI 3)"
check_outdated "springfox" "Springfox (unmaintained)" "Migrate to springdoc-openapi"
check_outdated "jasypt" "Jasypt (low maintenance)" "Consider Spring Vault or environment-based secrets"
check_outdated "commons-lang:commons-lang" "Commons Lang 2.x" "Upgrade to commons-lang3"
check_outdated "commons-collections:commons-collections" "Commons Collections 3.x (CVE history)" "Upgrade to commons-collections4"
check_outdated "mysql-connector-java" "Old MySQL connector artifact" "Use com.mysql:mysql-connector-j"

if [ "$OUTDATED_FOUND" -eq 0 ]; then
    echo -e "  ${GREEN}No known outdated/EOL libraries detected${NC}"
fi

# ─── License File Detection ───
echo ""
echo "---------------------------------------------"
echo "  License Compliance"
echo "---------------------------------------------"

if [ -f "LICENSE" ] || [ -f "LICENSE.md" ] || [ -f "LICENSE.txt" ]; then
    LICENSE_FILE=$(ls LICENSE* 2>/dev/null | head -1)
    LICENSE_TYPE=$(head -5 "$LICENSE_FILE" 2>/dev/null | grep -oiP '(MIT|Apache|GPL|BSD|LGPL|MPL|AGPL|ISC|Unlicense)' | head -1 || echo "unknown")
    echo -e "Project license: ${GREEN}${LICENSE_TYPE:-detected}${NC} ($LICENSE_FILE)"
else
    echo -e "${YELLOW}No LICENSE file found in project root${NC}"
fi

LICENSE_PLUGIN="false"
if [ "$BUILD_TOOL" = "maven" ]; then
    if grep -q "license-maven-plugin" pom.xml 2>/dev/null; then
        LICENSE_PLUGIN="true"
    fi
elif [ "$BUILD_TOOL" = "gradle" ]; then
    GRADLE_FILE="build.gradle"
    [ -f "build.gradle.kts" ] && GRADLE_FILE="build.gradle.kts"
    if grep -q "license" "$GRADLE_FILE" 2>/dev/null; then
        LICENSE_PLUGIN="true"
    fi
fi
echo -e "License audit plugin: $([ "$LICENSE_PLUGIN" = "true" ] && echo -e "${GREEN}configured${NC}" || echo -e "${YELLOW}not configured${NC}")"

# ─── Dependency Management Check ───
echo ""
echo "---------------------------------------------"
echo "  Build Hygiene"
echo "---------------------------------------------"

if [ "$BUILD_TOOL" = "maven" ]; then
    # Check for BOM usage
    BOM_COUNT=$(grep -c '<type>pom</type>' pom.xml 2>/dev/null || echo "0")
    echo -e "BOMs imported: ${CYAN}$BOM_COUNT${NC}"

    # Check for dependency management section
    if grep -q '<dependencyManagement>' pom.xml 2>/dev/null; then
        echo -e "${GREEN}dependencyManagement section: present${NC}"
    else
        echo -e "${BLUE}dependencyManagement section: not present (may use parent)${NC}"
    fi

    # Check for enforcer plugin
    if grep -q "maven-enforcer-plugin" pom.xml 2>/dev/null; then
        echo -e "${GREEN}Maven Enforcer Plugin: configured${NC}"
    else
        echo -e "${YELLOW}Maven Enforcer Plugin: not configured (recommended for dependency convergence)${NC}"
    fi

    # Check for versions-maven-plugin
    if grep -q "versions-maven-plugin" pom.xml 2>/dev/null; then
        echo -e "${GREEN}Versions Maven Plugin: configured${NC}"
    else
        echo -e "${YELLOW}Versions Maven Plugin: not configured (useful for update checks)${NC}"
    fi

elif [ "$BUILD_TOOL" = "gradle" ]; then
    GRADLE_FILE="build.gradle"
    [ -f "build.gradle.kts" ] && GRADLE_FILE="build.gradle.kts"

    if grep -q "platform\|enforcedPlatform" "$GRADLE_FILE" 2>/dev/null; then
        echo -e "${GREEN}Gradle platform/BOM: configured${NC}"
    fi

    # Check for dependency locking
    if [ -d "gradle/dependency-locks" ] || grep -q "dependencyLocking" "$GRADLE_FILE" 2>/dev/null; then
        echo -e "${GREEN}Dependency locking: enabled${NC}"
    else
        echo -e "${YELLOW}Dependency locking: not enabled (recommended for reproducible builds)${NC}"
    fi

    # Check for version catalogs
    if [ -f "gradle/libs.versions.toml" ]; then
        echo -e "${GREEN}Version catalog (libs.versions.toml): present${NC}"
    else
        echo -e "${YELLOW}Version catalog: not present (recommended for centralized version management)${NC}"
    fi
fi

# ─── Duplicate Dependency Detection ───
echo ""
echo "---------------------------------------------"
echo "  Potential Duplicates"
echo "---------------------------------------------"

DUPLICATE_FOUND=0

check_duplicate() {
    local pattern1="$1"
    local pattern2="$2"
    local description="$3"
    local build_file="pom.xml"

    if [ "$BUILD_TOOL" = "gradle" ]; then
        build_file="build.gradle"
        [ -f "build.gradle.kts" ] && build_file="build.gradle.kts"
    fi

    if grep -q "$pattern1" "$build_file" 2>/dev/null && grep -q "$pattern2" "$build_file" 2>/dev/null; then
        echo -e "  ${YELLOW}[POSSIBLE]${NC} $description"
        DUPLICATE_FOUND=$((DUPLICATE_FOUND + 1))
    fi
}

check_duplicate "jackson-databind" "gson" "Both Jackson and Gson (pick one JSON library)"
check_duplicate "logback" "log4j-core" "Both Logback and Log4j2 (pick one logging impl)"
check_duplicate "commons-lang3" "guava.*Strings" "Commons Lang3 and Guava overlapping utils"
check_duplicate "hibernate-validator" "javax.validation\|jakarta.validation" "Explicit validation API alongside Hibernate Validator (may be transitively included)"
check_duplicate "junit-jupiter" "junit:junit" "Both JUnit 5 and JUnit 4 (migrate fully to JUnit 5)"
check_duplicate "mockito-core" "easymock\|powermock" "Multiple mocking frameworks (standardize on Mockito)"
check_duplicate "spring-boot-starter-web" "spring-boot-starter-webflux" "Both Servlet and Reactive starters (usually pick one)"
check_duplicate "httpclient" "okhttp" "Both Apache HttpClient and OkHttp (pick one HTTP client)"

if [ "$DUPLICATE_FOUND" -eq 0 ]; then
    echo -e "  ${GREEN}No obvious duplicate libraries detected${NC}"
fi

# ─── Summary ───
echo ""
echo "============================================="
echo "  Audit Summary"
echo "============================================="
echo ""
echo "| Category                   | Status                  |"
echo "|----------------------------|-------------------------|"
echo "| Build Tool                 | $BUILD_TOOL             |"
echo "| Java Version               | $JAVA_VERSION           |"
echo "| Spring Boot Version        | $SPRING_BOOT_VERSION    |"
echo "| Vulnerability Scanner      | $([ "$OWASP_CONFIGURED" = "true" ] || [ "$SNYK_CONFIGURED" = "true" ] || [ "$TRIVY_CONFIGURED" = "true" ] && echo "configured" || echo "MISSING") |"
echo "| SNAPSHOT Dependencies      | ${SNAPSHOT_COUNT:-0}    |"
echo "| Outdated/EOL Libraries     | $OUTDATED_FOUND         |"
echo "| Potential Duplicates       | $DUPLICATE_FOUND        |"
echo "| License Plugin             | $([ "$LICENSE_PLUGIN" = "true" ] && echo "configured" || echo "not configured") |"
echo ""
echo "Audit complete. Review findings above for detailed recommendations."
