#!/usr/bin/env bash
# Java 17 to 21 Migration Analysis Script
# Detects project state and identifies migration requirements

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: Directory '$PROJECT_DIR' does not exist${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

echo "============================================="
echo "  Java 17 to 21 Migration Analysis"
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

# ─── Java Version Detection ───
JAVA_VERSION="unknown"
if [ "$BUILD_TOOL" = "maven" ] && [ -f "pom.xml" ]; then
    JAVA_VERSION=$(grep -oP '(?<=<java.version>)[^<]+' pom.xml 2>/dev/null || echo "")
    if [ -z "$JAVA_VERSION" ]; then
        JAVA_VERSION=$(grep -oP '(?<=<maven.compiler.source>)[^<]+' pom.xml 2>/dev/null || echo "")
    fi
    if [ -z "$JAVA_VERSION" ]; then
        JAVA_VERSION=$(grep -oP '(?<=<maven.compiler.release>)[^<]+' pom.xml 2>/dev/null || echo "")
    fi
elif [ "$BUILD_TOOL" = "gradle" ]; then
    if [ -f "build.gradle" ]; then
        JAVA_VERSION=$(grep -oP "sourceCompatibility\s*=\s*['\"]?\K[^'\"\\s]+" build.gradle 2>/dev/null || echo "")
        if [ -z "$JAVA_VERSION" ]; then
            JAVA_VERSION=$(grep -oP "JavaVersion\.VERSION_\K[0-9]+" build.gradle 2>/dev/null || echo "")
        fi
    elif [ -f "build.gradle.kts" ]; then
        JAVA_VERSION=$(grep -oP 'sourceCompatibility\s*=\s*JavaVersion\.VERSION_\K[0-9]+' build.gradle.kts 2>/dev/null || echo "")
        if [ -z "$JAVA_VERSION" ]; then
            JAVA_VERSION=$(grep -oP "jvmTarget\s*=\s*['\"]?\K[^'\"\\s]+" build.gradle.kts 2>/dev/null || echo "")
        fi
    fi
fi
if [ -z "$JAVA_VERSION" ] || [ "$JAVA_VERSION" = "unknown" ]; then
    if command -v java &>/dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -1 | grep -oP '"([0-9]+)' | tr -d '"' || echo "unknown")
    fi
fi
echo -e "${BLUE}Java Version:${NC} $JAVA_VERSION"

# ─── Spring Boot Version Detection ───
SPRING_BOOT_VERSION="unknown"
SPRING_BOOT_MAJOR="unknown"
if [ "$BUILD_TOOL" = "maven" ] && [ -f "pom.xml" ]; then
    # Check parent version
    SPRING_BOOT_VERSION=$(grep -A5 'spring-boot-starter-parent' pom.xml 2>/dev/null | grep -oP '(?<=<version>)[^<]+' | head -1 || echo "")
    # Check spring-boot.version property
    if [ -z "$SPRING_BOOT_VERSION" ]; then
        SPRING_BOOT_VERSION=$(grep -oP '(?<=<spring-boot.version>)[^<]+' pom.xml 2>/dev/null || echo "")
    fi
elif [ "$BUILD_TOOL" = "gradle" ]; then
    GRADLE_FILE="build.gradle"
    [ -f "build.gradle.kts" ] && GRADLE_FILE="build.gradle.kts"
    SPRING_BOOT_VERSION=$(grep -oP "org.springframework.boot['\"]?\s*(version\s*)?['\"]?[0-9]+\.[0-9]+\.[0-9]+[^'\"]*" "$GRADLE_FILE" 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+.*' | head -1 || echo "")
    if [ -z "$SPRING_BOOT_VERSION" ]; then
        SPRING_BOOT_VERSION=$(grep -oP "springBootVersion\s*=\s*['\"]?\K[^'\"\\s]+" "$GRADLE_FILE" 2>/dev/null || echo "")
    fi
fi

if [ -n "$SPRING_BOOT_VERSION" ] && [ "$SPRING_BOOT_VERSION" != "unknown" ]; then
    SPRING_BOOT_MAJOR=$(echo "$SPRING_BOOT_VERSION" | grep -oP '^[0-9]+' || echo "unknown")
fi
echo -e "${BLUE}Spring Boot Version:${NC} $SPRING_BOOT_VERSION"

# ─── Web Model Detection ───
WEB_MODEL="unknown"
if [ "$BUILD_TOOL" = "maven" ] && [ -f "pom.xml" ]; then
    if grep -q 'spring-boot-starter-webflux' pom.xml 2>/dev/null; then
        WEB_MODEL="reactive"
    elif grep -q 'spring-boot-starter-web' pom.xml 2>/dev/null; then
        WEB_MODEL="servlet"
    fi
elif [ "$BUILD_TOOL" = "gradle" ]; then
    GRADLE_FILE="build.gradle"
    [ -f "build.gradle.kts" ] && GRADLE_FILE="build.gradle.kts"
    if grep -q 'spring-boot-starter-webflux' "$GRADLE_FILE" 2>/dev/null; then
        WEB_MODEL="reactive"
    elif grep -q 'spring-boot-starter-web' "$GRADLE_FILE" 2>/dev/null; then
        WEB_MODEL="servlet"
    fi
fi
echo -e "${BLUE}Web Model:${NC} $WEB_MODEL"

# ─── Migration Path ───
echo ""
echo "---------------------------------------------"
echo "  Migration Path"
echo "---------------------------------------------"
if [ "$SPRING_BOOT_MAJOR" = "2" ]; then
    echo -e "${YELLOW}PATH A: Full Migration${NC} (Spring Boot 2.x → 3.x + Java 17 → 21)"
    MIGRATION_PATH="A"
elif [ "$SPRING_BOOT_MAJOR" = "3" ]; then
    echo -e "${GREEN}PATH B: Java Upgrade Only${NC} (Spring Boot 3.x + Java 17 → 21)"
    MIGRATION_PATH="B"
else
    echo -e "${RED}Could not determine migration path. Spring Boot version: $SPRING_BOOT_VERSION${NC}"
    MIGRATION_PATH="unknown"
fi

# ─── Namespace Scanning ───
echo ""
echo "---------------------------------------------"
echo "  Namespace Analysis (javax vs jakarta)"
echo "---------------------------------------------"
SRC_DIR="src"
if [ -d "$SRC_DIR" ]; then
    JAVAX_COUNT=$(grep -r "import javax\." "$SRC_DIR" --include="*.java" 2>/dev/null | wc -l | tr -d ' ')
    JAKARTA_COUNT=$(grep -r "import jakarta\." "$SRC_DIR" --include="*.java" 2>/dev/null | wc -l | tr -d ' ')
    echo -e "javax.* imports:   ${RED}${JAVAX_COUNT}${NC}"
    echo -e "jakarta.* imports: ${GREEN}${JAKARTA_COUNT}${NC}"

    # Detailed javax breakdown
    if [ "$JAVAX_COUNT" -gt 0 ]; then
        echo ""
        echo "javax.* breakdown:"
        grep -r "import javax\." "$SRC_DIR" --include="*.java" 2>/dev/null | \
            sed 's/.*import javax\.\([a-zA-Z]*\).*/javax.\1/' | \
            sort | uniq -c | sort -rn | head -10 | \
            while read count pkg; do
                echo "  $pkg: $count"
            done
    fi
else
    echo -e "${YELLOW}src/ directory not found${NC}"
    JAVAX_COUNT=0
    JAKARTA_COUNT=0
fi

# ─── Virtual Thread Readiness ───
echo ""
echo "---------------------------------------------"
echo "  Virtual Thread Readiness"
echo "---------------------------------------------"
if [ -d "$SRC_DIR/main/java" ]; then
    SYNCHRONIZED_COUNT=$(grep -rn "synchronized" "$SRC_DIR/main/java" --include="*.java" 2>/dev/null | grep -v "//.*synchronized" | wc -l | tr -d ' ')
    THREADLOCAL_COUNT=$(grep -rn "ThreadLocal" "$SRC_DIR/main/java" --include="*.java" 2>/dev/null | wc -l | tr -d ' ')
    REENTRANTLOCK_COUNT=$(grep -rn "ReentrantLock" "$SRC_DIR/main/java" --include="*.java" 2>/dev/null | wc -l | tr -d ' ')

    echo -e "synchronized blocks/methods: ${YELLOW}${SYNCHRONIZED_COUNT}${NC}"
    echo -e "ThreadLocal usages:          ${YELLOW}${THREADLOCAL_COUNT}${NC}"
    echo -e "ReentrantLock usages:        ${GREEN}${REENTRANTLOCK_COUNT}${NC}"

    # Check if virtual threads already enabled
    VT_ENABLED="false"
    if grep -rq "spring.threads.virtual.enabled=true" "$SRC_DIR" 2>/dev/null || \
       grep -rq "spring.threads.virtual.enabled: true" "$SRC_DIR" 2>/dev/null; then
        VT_ENABLED="true"
    fi
    # Also check in root config files
    for cfg in application.properties application.yml application.yaml; do
        if [ -f "$SRC_DIR/main/resources/$cfg" ]; then
            if grep -q "virtual.enabled.*true" "$SRC_DIR/main/resources/$cfg" 2>/dev/null; then
                VT_ENABLED="true"
            fi
        fi
    done
    echo -e "Virtual threads enabled:     $([ "$VT_ENABLED" = "true" ] && echo -e "${GREEN}yes${NC}" || echo -e "${BLUE}no${NC}")"

    if [ "$SYNCHRONIZED_COUNT" -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}WARNING: synchronized blocks can pin virtual threads to carrier threads.${NC}"
        echo "These should be replaced with ReentrantLock before enabling virtual threads."
        echo ""
        echo "Files with synchronized usage:"
        grep -rln "synchronized" "$SRC_DIR/main/java" --include="*.java" 2>/dev/null | head -10 | while read f; do
            echo "  - $f"
        done
        SYNC_TOTAL=$(grep -rln "synchronized" "$SRC_DIR/main/java" --include="*.java" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$SYNC_TOTAL" -gt 10 ]; then
            echo "  ... and $((SYNC_TOTAL - 10)) more files"
        fi
    fi
else
    echo -e "${YELLOW}src/main/java/ not found${NC}"
    SYNCHRONIZED_COUNT=0
    THREADLOCAL_COUNT=0
    REENTRANTLOCK_COUNT=0
fi

# ─── Deprecated Pattern Detection ───
echo ""
echo "---------------------------------------------"
echo "  Deprecated Patterns"
echo "---------------------------------------------"
DEPRECATED_FOUND=0

check_pattern() {
    local pattern="$1"
    local description="$2"
    local count
    count=$(grep -rn "$pattern" "$SRC_DIR" --include="*.java" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$count" -gt 0 ]; then
        echo -e "  ${RED}[FOUND]${NC} $description ($count occurrences)"
        DEPRECATED_FOUND=$((DEPRECATED_FOUND + 1))
    fi
}

if [ -d "$SRC_DIR" ]; then
    check_pattern "WebSecurityConfigurerAdapter" "WebSecurityConfigurerAdapter (removed in Spring Security 6)"
    check_pattern "antMatchers" "antMatchers() (replaced by requestMatchers())"
    check_pattern "authorizeRequests\b" "authorizeRequests() (replaced by authorizeHttpRequests())"
    check_pattern "@EnableGlobalMethodSecurity" "@EnableGlobalMethodSecurity (replaced by @EnableMethodSecurity)"
    check_pattern "extends WebMvcConfigurerAdapter" "WebMvcConfigurerAdapter (removed, implement WebMvcConfigurer)"
    check_pattern "finalize()" "finalize() method override (deprecated for removal)"
    check_pattern "javax\.persistence" "javax.persistence imports (needs jakarta.persistence)"
    check_pattern "javax\.servlet" "javax.servlet imports (needs jakarta.servlet)"
    check_pattern "javax\.validation" "javax.validation imports (needs jakarta.validation)"
    check_pattern "javax\.annotation" "javax.annotation imports (needs jakarta.annotation)"

    if [ "$DEPRECATED_FOUND" -eq 0 ]; then
        echo -e "  ${GREEN}No deprecated patterns detected${NC}"
    fi
else
    echo -e "${YELLOW}src/ directory not found${NC}"
fi

# ─── Dependency Compatibility Check ───
echo ""
echo "---------------------------------------------"
echo "  Dependency Compatibility"
echo "---------------------------------------------"

check_dependency_maven() {
    local artifact="$1"
    local description="$2"
    local min_version="$3"
    if grep -q "$artifact" pom.xml 2>/dev/null; then
        local version
        version=$(grep -A3 "$artifact" pom.xml 2>/dev/null | grep -oP '(?<=<version>)[^<]+' | head -1 || echo "managed")
        echo -e "  ${BLUE}$description${NC}: $version (needs $min_version+ for Java 21)"
    fi
}

check_dependency_gradle() {
    local artifact="$1"
    local description="$2"
    local min_version="$3"
    local gradle_file="build.gradle"
    [ -f "build.gradle.kts" ] && gradle_file="build.gradle.kts"
    if grep -q "$artifact" "$gradle_file" 2>/dev/null; then
        local version
        version=$(grep "$artifact" "$gradle_file" 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "managed")
        echo -e "  ${BLUE}$description${NC}: $version (needs $min_version+ for Java 21)"
    fi
}

if [ "$BUILD_TOOL" = "maven" ]; then
    check_dependency_maven "lombok" "Lombok" "1.18.30"
    check_dependency_maven "mockito" "Mockito" "5.0"
    check_dependency_maven "mapstruct" "MapStruct" "1.5.5"
    check_dependency_maven "flyway" "Flyway" "9.22"
    check_dependency_maven "liquibase" "Liquibase" "4.24"
    check_dependency_maven "jackson" "Jackson" "2.15"
    check_dependency_maven "hibernate-core" "Hibernate" "6.2"
elif [ "$BUILD_TOOL" = "gradle" ]; then
    check_dependency_gradle "lombok" "Lombok" "1.18.30"
    check_dependency_gradle "mockito" "Mockito" "5.0"
    check_dependency_gradle "mapstruct" "MapStruct" "1.5.5"
    check_dependency_gradle "flyway" "Flyway" "9.22"
    check_dependency_gradle "liquibase" "Liquibase" "4.24"
    check_dependency_gradle "jackson" "Jackson" "2.15"
    check_dependency_gradle "hibernate-core" "Hibernate" "6.2"
fi

# ─── Build Configuration ───
echo ""
echo "---------------------------------------------"
echo "  Build Configuration"
echo "---------------------------------------------"
if [ "$BUILD_TOOL" = "maven" ]; then
    COMPILER_PLUGIN=$(grep -A5 'maven-compiler-plugin' pom.xml 2>/dev/null | grep -oP '(?<=<version>)[^<]+' | head -1 || echo "not specified")
    echo -e "  Maven Compiler Plugin: $COMPILER_PLUGIN (needs 3.11+ for Java 21)"
    MAVEN_VERSION=$(./mvnw --version 2>/dev/null | head -1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' || mvn --version 2>/dev/null | head -1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    echo -e "  Maven Version: $MAVEN_VERSION"
elif [ "$BUILD_TOOL" = "gradle" ]; then
    if [ -f "gradle/wrapper/gradle-wrapper.properties" ]; then
        GRADLE_VERSION=$(grep -oP 'gradle-\K[0-9]+\.[0-9]+(\.[0-9]+)?' gradle/wrapper/gradle-wrapper.properties 2>/dev/null || echo "unknown")
        echo -e "  Gradle Version: $GRADLE_VERSION (needs 8.4+ for Java 21)"
    fi
fi

# ─── Summary ───
echo ""
echo "============================================="
echo "  Migration Summary"
echo "============================================="
echo ""
echo "| Property                      | Value                          |"
echo "|-------------------------------|--------------------------------|"
echo "| Current Java Version          | $JAVA_VERSION                  |"
echo "| Target Java Version           | 21                             |"
echo "| Spring Boot Version           | $SPRING_BOOT_VERSION           |"
echo "| Build Tool                    | $BUILD_TOOL                    |"
echo "| Web Model                     | $WEB_MODEL                     |"
echo "| Migration Path                | $MIGRATION_PATH                |"
echo "| javax.* imports               | ${JAVAX_COUNT:-0}              |"
echo "| jakarta.* imports             | ${JAKARTA_COUNT:-0}            |"
echo "| synchronized blocks           | ${SYNCHRONIZED_COUNT:-0}       |"
echo "| ThreadLocal usages            | ${THREADLOCAL_COUNT:-0}        |"
echo "| Deprecated patterns           | $DEPRECATED_FOUND              |"
echo ""

if [ "$MIGRATION_PATH" = "A" ]; then
    echo -e "${YELLOW}Recommended: Path A - Full Migration${NC}"
    echo "  Phase 1: Upgrade to latest Spring Boot 2.7.x"
    echo "  Phase 2: Migrate to Spring Boot 3.2+ (javax -> jakarta)"
    echo "  Phase 3: Upgrade build to Java 21"
    echo "  Phase 4: Adopt Java 21 features (virtual threads, pattern matching, etc.)"
elif [ "$MIGRATION_PATH" = "B" ]; then
    echo -e "${GREEN}Recommended: Path B - Java Upgrade Only${NC}"
    echo "  Phase 1: Upgrade build to Java 21"
    echo "  Phase 2: Adopt Java 21 features (virtual threads, pattern matching, etc.)"
fi

echo ""
echo "Analysis complete."
