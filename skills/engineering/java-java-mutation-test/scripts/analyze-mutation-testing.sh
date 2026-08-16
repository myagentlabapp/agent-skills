#!/usr/bin/env bash
# Java Mutation Testing Analyzer
# Detects PITest configuration, test framework, and project structure for mutation testing adoption

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
echo "  Java Mutation Testing Analysis"
echo "============================================="
echo ""

# ─── Build Tool Detection ───
BUILD_TOOL="unknown"
GRADLE_FILE=""
if [ -f "pom.xml" ]; then
    BUILD_TOOL="maven"
elif [ -f "build.gradle.kts" ]; then
    BUILD_TOOL="gradle"
    GRADLE_FILE="build.gradle.kts"
elif [ -f "build.gradle" ]; then
    BUILD_TOOL="gradle"
    GRADLE_FILE="build.gradle"
fi
echo -e "${BLUE}Build Tool:${NC} $BUILD_TOOL"

if [ "$BUILD_TOOL" = "unknown" ]; then
    echo -e "${RED}Error: No pom.xml or build.gradle found. Not a Maven/Gradle project.${NC}"
    exit 1
fi

# ─── Build Wrapper Detection ───
BUILD_WRAPPER="none"
if [ "$BUILD_TOOL" = "maven" ]; then
    if [ -x "mvnw" ] || [ -f "mvnw" ]; then
        BUILD_WRAPPER="./mvnw"
    else
        BUILD_WRAPPER="mvn"
    fi
elif [ "$BUILD_TOOL" = "gradle" ]; then
    if [ -x "gradlew" ] || [ -f "gradlew" ]; then
        BUILD_WRAPPER="./gradlew"
    else
        BUILD_WRAPPER="gradle"
    fi
fi
echo -e "${BLUE}Build Wrapper:${NC} $BUILD_WRAPPER"

# ─── Java Version Detection ───
JAVA_VERSION="unknown"
if [ "$BUILD_TOOL" = "maven" ]; then
    JAVA_VERSION=$(grep -oP '(?<=<java.version>)[^<]+' pom.xml 2>/dev/null || echo "")
    if [ -z "$JAVA_VERSION" ]; then
        JAVA_VERSION=$(grep -oP '(?<=<maven.compiler.source>)[^<]+' pom.xml 2>/dev/null || echo "")
    fi
    if [ -z "$JAVA_VERSION" ]; then
        JAVA_VERSION=$(grep -oP '(?<=<maven.compiler.release>)[^<]+' pom.xml 2>/dev/null || echo "")
    fi
elif [ "$BUILD_TOOL" = "gradle" ]; then
    JAVA_VERSION=$(grep -oP "sourceCompatibility\s*=\s*['\"]?\K[^'\"\\s]+" "$GRADLE_FILE" 2>/dev/null || echo "")
    if [ -z "$JAVA_VERSION" ]; then
        JAVA_VERSION=$(grep -oP "JavaVersion\.VERSION_\K[0-9]+" "$GRADLE_FILE" 2>/dev/null | head -1 || echo "")
    fi
fi
if [ -z "$JAVA_VERSION" ]; then
    JAVA_VERSION=$(java -version 2>&1 | head -1 | grep -oP '"([0-9]+)' | tr -d '"' 2>/dev/null || echo "unknown")
fi
echo -e "${BLUE}Java Version:${NC} $JAVA_VERSION"
if [ "$JAVA_VERSION" != "21" ] && [ "$JAVA_VERSION" != "unknown" ]; then
    echo -e "${YELLOW}  WARNING: Target is Java 21. Detected version: $JAVA_VERSION${NC}"
fi

# ─── Spring Boot Version Detection ───
SPRING_BOOT_VERSION="not detected"
if [ "$BUILD_TOOL" = "maven" ]; then
    SPRING_BOOT_VERSION=$(grep -A5 'spring-boot-starter-parent' pom.xml 2>/dev/null | grep -oP '(?<=<version>)[^<]+' | head -1 || echo "")
    if [ -z "$SPRING_BOOT_VERSION" ]; then
        SPRING_BOOT_VERSION=$(grep -oP '(?<=<spring-boot.version>)[^<]+' pom.xml 2>/dev/null || echo "not detected")
    fi
elif [ "$BUILD_TOOL" = "gradle" ]; then
    SPRING_BOOT_VERSION=$(grep -oP "org.springframework.boot['\"]?\s*(version\s*)?['\"]?[0-9]+\.[0-9]+\.[0-9]+[^'\"]*" "$GRADLE_FILE" 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+.*' | head -1 || echo "not detected")
fi
echo -e "${BLUE}Spring Boot Version:${NC} $SPRING_BOOT_VERSION"

# ─── JUnit Version Detection ───
echo ""
echo "---------------------------------------------"
echo "  Test Framework Detection"
echo "---------------------------------------------"

JUNIT_VERSION="unknown"
JUNIT5_DETECTED="false"
JUNIT4_DETECTED="false"
TESTNG_DETECTED="false"
VINTAGE_ENGINE="false"

if [ "$BUILD_TOOL" = "maven" ]; then
    if grep -q "junit-jupiter\|junit-jupiter-api\|junit-jupiter-engine" pom.xml 2>/dev/null; then
        JUNIT5_DETECTED="true"
    fi
    if grep -q "junit:junit\|junit4" pom.xml 2>/dev/null; then
        JUNIT4_DETECTED="true"
    fi
    if grep -q "testng" pom.xml 2>/dev/null; then
        TESTNG_DETECTED="true"
    fi
    if grep -q "junit-vintage-engine" pom.xml 2>/dev/null; then
        VINTAGE_ENGINE="true"
    fi
elif [ "$BUILD_TOOL" = "gradle" ]; then
    if grep -q "junit-jupiter\|junit-jupiter-api\|junit-jupiter-engine\|useJUnitPlatform" "$GRADLE_FILE" 2>/dev/null; then
        JUNIT5_DETECTED="true"
    fi
    if grep -q "'junit:junit'\|\"junit:junit\"\|junit4" "$GRADLE_FILE" 2>/dev/null; then
        JUNIT4_DETECTED="true"
    fi
    if grep -q "testng" "$GRADLE_FILE" 2>/dev/null; then
        TESTNG_DETECTED="true"
    fi
    if grep -q "junit-vintage-engine" "$GRADLE_FILE" 2>/dev/null; then
        VINTAGE_ENGINE="true"
    fi
fi

if [ "$JUNIT5_DETECTED" = "true" ] && [ "$JUNIT4_DETECTED" = "true" ]; then
    JUNIT_VERSION="JUnit 5 + JUnit 4 (mixed)"
    echo -e "${YELLOW}JUnit Version: Mixed (JUnit 5 + JUnit 4)${NC}"
    if [ "$VINTAGE_ENGINE" = "true" ]; then
        echo -e "  ${BLUE}junit-vintage-engine detected (JUnit 4 compatibility layer)${NC}"
    else
        echo -e "  ${YELLOW}WARNING: JUnit 4 present without vintage engine -- PITest may not run JUnit 4 tests${NC}"
    fi
elif [ "$JUNIT5_DETECTED" = "true" ]; then
    JUNIT_VERSION="JUnit 5"
    echo -e "${GREEN}JUnit Version: JUnit 5${NC}"
elif [ "$JUNIT4_DETECTED" = "true" ]; then
    JUNIT_VERSION="JUnit 4"
    echo -e "${YELLOW}JUnit Version: JUnit 4 (recommend migrating to JUnit 5)${NC}"
elif [ "$TESTNG_DETECTED" = "true" ]; then
    JUNIT_VERSION="TestNG"
    echo -e "${YELLOW}JUnit Version: TestNG (PITest supports TestNG via pitest-testng-plugin)${NC}"
else
    echo -e "${RED}No test framework detected${NC}"
fi

# ─── Test File Count ───
UNIT_TEST_COUNT=0
INTEGRATION_TEST_COUNT=0
SPRING_BOOT_TEST_COUNT=0

if [ -d "src/test/java" ]; then
    UNIT_TEST_COUNT=$(find src/test/java -name "*Test.java" ! -name "*IT.java" ! -name "*IntegrationTest.java" 2>/dev/null | wc -l | tr -d ' ')
    INTEGRATION_TEST_COUNT=$(find src/test/java \( -name "*IT.java" -o -name "*IntegrationTest.java" \) 2>/dev/null | wc -l | tr -d ' ')
    SPRING_BOOT_TEST_COUNT=$(grep -rl "@SpringBootTest\|@DataJpaTest\|@WebMvcTest\|@DataMongoTest\|@WebFluxTest" src/test/java 2>/dev/null | wc -l | tr -d ' ')
fi

echo -e "Unit test files (*Test.java): ${CYAN}${UNIT_TEST_COUNT}${NC}"
echo -e "Integration test files (*IT.java, *IntegrationTest.java): ${CYAN}${INTEGRATION_TEST_COUNT}${NC}"
echo -e "Spring Boot test files (@SpringBootTest etc.): ${CYAN}${SPRING_BOOT_TEST_COUNT}${NC}"

if [ "$INTEGRATION_TEST_COUNT" -gt 0 ] || [ "$SPRING_BOOT_TEST_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}  NOTE: Integration/Spring Boot tests should be excluded from mutation testing${NC}"
fi

# ─── PITest Detection ───
echo ""
echo "---------------------------------------------"
echo "  PITest Configuration"
echo "---------------------------------------------"

PITEST_CONFIGURED="false"
PITEST_VERSION="not configured"
JUNIT5_PLUGIN="not configured"
GIT_PLUGIN="not configured"
MUTATOR_GROUP="not configured"
PITEST_THREADS="not configured"
TIMEOUT_CONSTANT="not configured"
HISTORY_ENABLED="not configured"
EXCLUDED_CLASSES="not configured"
EXCLUDED_METHODS="not configured"
AVOID_CALLS_TO="not configured"
MUTATION_THRESHOLD="not configured"
OUTPUT_FORMATS="not configured"
TARGET_CLASSES="not configured"
FAIL_WHEN_NO_MUTATIONS="not configured"

if [ "$BUILD_TOOL" = "maven" ]; then
    if grep -q "pitest-maven\|pitest" pom.xml 2>/dev/null; then
        PITEST_CONFIGURED="true"
        echo -e "${GREEN}PITest Maven Plugin: CONFIGURED${NC}"

        # Version
        PITEST_VERSION=$(grep -A3 "pitest-maven" pom.xml 2>/dev/null | grep -oP '(?<=<version>)[^<]+' | head -1 || echo "unknown")
        echo -e "  Version: ${CYAN}$PITEST_VERSION${NC}"

        # JUnit 5 plugin
        if grep -q "pitest-junit5-plugin" pom.xml 2>/dev/null; then
            JUNIT5_PLUGIN=$(grep -A3 "pitest-junit5-plugin" pom.xml 2>/dev/null | grep -oP '(?<=<version>)[^<]+' | head -1 || echo "detected")
            echo -e "  ${GREEN}pitest-junit5-plugin: $JUNIT5_PLUGIN${NC}"
        else
            JUNIT5_PLUGIN="MISSING"
            if [ "$JUNIT5_DETECTED" = "true" ]; then
                echo -e "  ${RED}pitest-junit5-plugin: MISSING (required for JUnit 5)${NC}"
            else
                echo -e "  ${YELLOW}pitest-junit5-plugin: not configured${NC}"
            fi
        fi

        # Git plugin (Arcmutate)
        if grep -q "pitest-git-plugin\|arcmutate" pom.xml 2>/dev/null; then
            GIT_PLUGIN="configured"
            echo -e "  ${GREEN}pitest-git-plugin (Arcmutate): configured${NC}"
        else
            echo -e "  ${YELLOW}pitest-git-plugin (Arcmutate): not configured${NC}"
        fi

        # Mutator group
        MUTATOR_GROUP=$(grep -oP '(?<=<mutator>)[^<]+\|(?<=<mutators>)[^<]+' pom.xml 2>/dev/null | head -1 || echo "")
        if [ -n "$MUTATOR_GROUP" ]; then
            echo -e "  Mutator group: ${CYAN}$MUTATOR_GROUP${NC}"
        else
            MUTATOR_GROUP="DEFAULTS (implicit)"
            echo -e "  Mutator group: ${YELLOW}DEFAULTS (implicit -- consider STRONGER)${NC}"
        fi

        # Threads
        PITEST_THREADS=$(grep -oP '(?<=<threads>)[^<]+' pom.xml 2>/dev/null | head -1 || echo "")
        if [ -n "$PITEST_THREADS" ]; then
            echo -e "  Threads: ${CYAN}$PITEST_THREADS${NC}"
        else
            PITEST_THREADS="1 (default)"
            echo -e "  Threads: ${YELLOW}1 (default -- increase to CPU core count)${NC}"
        fi

        # Timeout constant
        TIMEOUT_CONSTANT=$(grep -oP '(?<=<timeoutConstant>)[^<]+' pom.xml 2>/dev/null | head -1 || echo "")
        if [ -n "$TIMEOUT_CONSTANT" ]; then
            echo -e "  Timeout constant: ${CYAN}${TIMEOUT_CONSTANT}ms${NC}"
        else
            TIMEOUT_CONSTANT="4000 (default)"
            if [ "$SPRING_BOOT_VERSION" != "not detected" ]; then
                echo -e "  Timeout constant: ${YELLOW}4000ms (default -- increase to 8000-15000ms for Spring Boot)${NC}"
            else
                echo -e "  Timeout constant: ${BLUE}4000ms (default)${NC}"
            fi
        fi

        # History
        if grep -q "<withHistory>true</withHistory>" pom.xml 2>/dev/null; then
            HISTORY_ENABLED="true"
            echo -e "  ${GREEN}Incremental analysis (withHistory): enabled${NC}"
        else
            HISTORY_ENABLED="false"
            echo -e "  ${YELLOW}Incremental analysis (withHistory): not enabled${NC}"
        fi

        # Excluded classes
        if grep -q "<excludedClasses>" pom.xml 2>/dev/null; then
            EXCLUDED_CLASSES="configured"
            echo -e "  ${GREEN}Excluded classes: configured${NC}"
        else
            EXCLUDED_CLASSES="not configured"
            echo -e "  ${YELLOW}Excluded classes: not configured (recommend excluding generated/config classes)${NC}"
        fi

        # Excluded methods
        if grep -q "<excludedMethods>" pom.xml 2>/dev/null; then
            EXCLUDED_METHODS="configured"
            echo -e "  ${GREEN}Excluded methods: configured${NC}"
        else
            EXCLUDED_METHODS="not configured"
            echo -e "  ${YELLOW}Excluded methods: not configured${NC}"
        fi

        # Avoid calls to
        if grep -q "<avoidCallsTo>" pom.xml 2>/dev/null; then
            AVOID_CALLS_TO="configured"
            echo -e "  ${GREEN}avoidCallsTo: configured${NC}"
        else
            AVOID_CALLS_TO="not configured"
            echo -e "  ${YELLOW}avoidCallsTo: not configured (recommend excluding logging calls)${NC}"
        fi

        # Mutation threshold
        MUTATION_THRESHOLD=$(grep -oP '(?<=<mutationThreshold>)[^<]+' pom.xml 2>/dev/null | head -1 || echo "")
        if [ -n "$MUTATION_THRESHOLD" ]; then
            echo -e "  Mutation threshold: ${CYAN}${MUTATION_THRESHOLD}%${NC}"
        else
            MUTATION_THRESHOLD="none"
            echo -e "  Mutation threshold: ${YELLOW}none (builds will not fail on low mutation score)${NC}"
        fi

        # Output formats
        OUTPUT_FORMATS=$(grep -oP '(?<=<outputFormats>)[^<]+' pom.xml 2>/dev/null | head -1 || echo "")
        if [ -n "$OUTPUT_FORMATS" ]; then
            echo -e "  Output formats: ${CYAN}$OUTPUT_FORMATS${NC}"
        else
            OUTPUT_FORMATS="HTML (default)"
            echo -e "  Output formats: ${BLUE}HTML (default)${NC}"
        fi

        # Target classes
        TARGET_CLASSES=$(grep -oP '(?<=<targetClasses>)[^<]+' pom.xml 2>/dev/null | head -1 || echo "")
        if [ -n "$TARGET_CLASSES" ]; then
            echo -e "  Target classes: ${CYAN}$TARGET_CLASSES${NC}"
        fi

    else
        echo -e "${RED}PITest Maven Plugin: NOT CONFIGURED${NC}"
    fi

elif [ "$BUILD_TOOL" = "gradle" ]; then
    if grep -q "pitest\|info.solidsoft.pitest\|gradle-pitest-plugin" "$GRADLE_FILE" 2>/dev/null; then
        PITEST_CONFIGURED="true"
        echo -e "${GREEN}PITest Gradle Plugin: CONFIGURED${NC}"

        # Version
        PITEST_VERSION=$(grep -oP "info.solidsoft.pitest['\"]?\s*version\s*['\"]?\K[0-9]+\.[0-9]+\.[0-9]+" "$GRADLE_FILE" 2>/dev/null | head -1 || echo "unknown")
        echo -e "  Plugin version: ${CYAN}$PITEST_VERSION${NC}"

        # JUnit 5 plugin
        if grep -q "junit5PluginVersion\|pitest-junit5-plugin" "$GRADLE_FILE" 2>/dev/null; then
            JUNIT5_PLUGIN=$(grep -oP "junit5PluginVersion\s*=?\s*['\"]?\K[0-9]+\.[0-9]+\.[0-9]+" "$GRADLE_FILE" 2>/dev/null || echo "detected")
            echo -e "  ${GREEN}pitest-junit5-plugin: $JUNIT5_PLUGIN${NC}"
        else
            JUNIT5_PLUGIN="MISSING"
            if [ "$JUNIT5_DETECTED" = "true" ]; then
                echo -e "  ${RED}pitest-junit5-plugin: MISSING (required for JUnit 5)${NC}"
            fi
        fi

        # Threads
        PITEST_THREADS=$(grep -oP "threads\s*=?\s*\K[0-9]+" "$GRADLE_FILE" 2>/dev/null | head -1 || echo "")
        if [ -n "$PITEST_THREADS" ]; then
            echo -e "  Threads: ${CYAN}$PITEST_THREADS${NC}"
        else
            PITEST_THREADS="1 (default)"
            echo -e "  Threads: ${YELLOW}1 (default -- increase to CPU core count)${NC}"
        fi

        # History
        if grep -q "historyInputLocation\|withHistory" "$GRADLE_FILE" 2>/dev/null; then
            HISTORY_ENABLED="true"
            echo -e "  ${GREEN}Incremental analysis: enabled${NC}"
        else
            HISTORY_ENABLED="false"
            echo -e "  ${YELLOW}Incremental analysis: not enabled${NC}"
        fi

        # Mutators
        MUTATOR_GROUP=$(grep -oP "mutators\s*=?\s*\[?\s*['\"]?\K[A-Z_]+" "$GRADLE_FILE" 2>/dev/null | head -1 || echo "")
        if [ -n "$MUTATOR_GROUP" ]; then
            echo -e "  Mutator group: ${CYAN}$MUTATOR_GROUP${NC}"
        else
            MUTATOR_GROUP="DEFAULTS (implicit)"
            echo -e "  Mutator group: ${YELLOW}DEFAULTS (implicit -- consider STRONGER)${NC}"
        fi

        # Timeout
        TIMEOUT_CONSTANT=$(grep -oP "timeoutConstInMillis\s*=?\s*\K[0-9]+" "$GRADLE_FILE" 2>/dev/null | head -1 || echo "")
        if [ -n "$TIMEOUT_CONSTANT" ]; then
            echo -e "  Timeout constant: ${CYAN}${TIMEOUT_CONSTANT}ms${NC}"
        else
            TIMEOUT_CONSTANT="4000 (default)"
            if [ "$SPRING_BOOT_VERSION" != "not detected" ]; then
                echo -e "  Timeout constant: ${YELLOW}4000ms (default -- increase for Spring Boot)${NC}"
            else
                echo -e "  Timeout constant: ${BLUE}4000ms (default)${NC}"
            fi
        fi

        # Mutation threshold
        MUTATION_THRESHOLD=$(grep -oP "mutationThreshold\s*=?\s*\K[0-9]+" "$GRADLE_FILE" 2>/dev/null | head -1 || echo "")
        if [ -n "$MUTATION_THRESHOLD" ]; then
            echo -e "  Mutation threshold: ${CYAN}${MUTATION_THRESHOLD}%${NC}"
        else
            MUTATION_THRESHOLD="none"
            echo -e "  Mutation threshold: ${YELLOW}none${NC}"
        fi
    else
        echo -e "${RED}PITest Gradle Plugin: NOT CONFIGURED${NC}"
    fi
fi

# ─── JaCoCo Detection ───
echo ""
echo "---------------------------------------------"
echo "  Code Coverage Detection"
echo "---------------------------------------------"

JACOCO_CONFIGURED="false"
if [ "$BUILD_TOOL" = "maven" ]; then
    if grep -q "jacoco-maven-plugin" pom.xml 2>/dev/null; then
        JACOCO_CONFIGURED="true"
        echo -e "${GREEN}JaCoCo Maven Plugin: configured${NC}"
        echo -e "  ${BLUE}JaCoCo and PITest can coexist -- use JaCoCo for line coverage, PITest for mutation score${NC}"
    else
        echo -e "${YELLOW}JaCoCo Maven Plugin: not configured${NC}"
    fi
elif [ "$BUILD_TOOL" = "gradle" ]; then
    if grep -q "jacoco" "$GRADLE_FILE" 2>/dev/null; then
        JACOCO_CONFIGURED="true"
        echo -e "${GREEN}JaCoCo Gradle Plugin: configured${NC}"
        echo -e "  ${BLUE}JaCoCo and PITest can coexist${NC}"
    else
        echo -e "${YELLOW}JaCoCo Gradle Plugin: not configured${NC}"
    fi
fi

# ─── Generated Code Detection ───
echo ""
echo "---------------------------------------------"
echo "  Generated Code Detection"
echo "---------------------------------------------"

LOMBOK_DETECTED="false"
MAPSTRUCT_DETECTED="false"
PROTOBUF_DETECTED="false"
GENERATED_CODE="none"

BUILD_FILE="pom.xml"
if [ "$BUILD_TOOL" = "gradle" ]; then
    BUILD_FILE="$GRADLE_FILE"
fi

if grep -q "lombok" "$BUILD_FILE" 2>/dev/null; then
    LOMBOK_DETECTED="true"
    echo -e "${BLUE}Lombok: detected (exclude *Builder, generated code from mutation testing)${NC}"
fi

if grep -q "mapstruct" "$BUILD_FILE" 2>/dev/null; then
    MAPSTRUCT_DETECTED="true"
    echo -e "${BLUE}MapStruct: detected (exclude *MapperImpl from mutation testing)${NC}"
fi

if grep -q "protobuf\|grpc" "$BUILD_FILE" 2>/dev/null; then
    PROTOBUF_DETECTED="true"
    echo -e "${BLUE}Protobuf/gRPC: detected (exclude *Proto, *Grpc from mutation testing)${NC}"
fi

if [ "$LOMBOK_DETECTED" = "true" ] || [ "$MAPSTRUCT_DETECTED" = "true" ] || [ "$PROTOBUF_DETECTED" = "true" ]; then
    GENERATED_CODE="detected"
else
    echo -e "${GREEN}No generated code libraries detected${NC}"
fi

# ─── CI/CD Detection ───
echo ""
echo "---------------------------------------------"
echo "  CI/CD Mutation Testing Detection"
echo "---------------------------------------------"

CI_MUTATION_TESTING="false"
if [ -d ".github/workflows" ]; then
    if grep -rl "pitest\|mutation" .github/workflows/ 2>/dev/null | head -1 > /dev/null 2>&1; then
        CI_MUTATION_TESTING="true"
        echo -e "${GREEN}Mutation testing in GitHub Actions: detected${NC}"
    else
        echo -e "${YELLOW}GitHub Actions found but no mutation testing workflow${NC}"
    fi
elif [ -f ".gitlab-ci.yml" ]; then
    if grep -q "pitest\|mutation" .gitlab-ci.yml 2>/dev/null; then
        CI_MUTATION_TESTING="true"
        echo -e "${GREEN}Mutation testing in GitLab CI: detected${NC}"
    else
        echo -e "${YELLOW}GitLab CI found but no mutation testing stage${NC}"
    fi
else
    echo -e "${YELLOW}No CI/CD configuration detected${NC}"
fi

# ─── Adoption Path Recommendation ───
echo ""
echo "---------------------------------------------"
echo "  Recommended Adoption Path"
echo "---------------------------------------------"

if [ "$PITEST_CONFIGURED" = "false" ]; then
    echo -e "${CYAN}Path A (New Setup):${NC} PITest is not configured."
    echo "  -> Full setup needed: plugin, JUnit 5 support, mutators, exclusions"
    echo "  -> Consult references/pitest-setup-guide.md"
    ADOPTION_PATH="A"
elif [ "$CI_MUTATION_TESTING" = "false" ]; then
    echo -e "${CYAN}Path C (CI/CD Integration):${NC} PITest is configured but no CI pipeline."
    echo "  -> Add mutation testing to CI/CD: PR-scoped + nightly full analysis"
    echo "  -> Consult references/ci-cd-integration.md"
    ADOPTION_PATH="C"
else
    echo -e "${CYAN}Path B (Optimization):${NC} PITest is configured with CI."
    echo "  -> Review configuration for performance and coverage improvements"
    echo "  -> Consult references/performance-optimization.md"
    ADOPTION_PATH="B"
fi

# ─── Summary ───
echo ""
echo "============================================="
echo "  Analysis Summary"
echo "============================================="
echo ""
echo "| Property                        | Value                              |"
echo "|---------------------------------|------------------------------------|"
echo "| Build Tool                      | $BUILD_TOOL                        |"
echo "| Build Wrapper                   | $BUILD_WRAPPER                     |"
echo "| Java Version                    | $JAVA_VERSION                      |"
echo "| Spring Boot Version             | $SPRING_BOOT_VERSION               |"
echo "| JUnit Version                   | $JUNIT_VERSION                     |"
echo "| PITest Plugin                   | $([ "$PITEST_CONFIGURED" = "true" ] && echo "configured ($PITEST_VERSION)" || echo "NOT CONFIGURED") |"
echo "| pitest-junit5-plugin            | $JUNIT5_PLUGIN                     |"
echo "| pitest-git-plugin (Arcmutate)   | $GIT_PLUGIN                        |"
echo "| Mutator Group                   | $MUTATOR_GROUP                     |"
echo "| Threads                         | $PITEST_THREADS                    |"
echo "| History (Incremental)           | $HISTORY_ENABLED                   |"
echo "| Timeout Constant                | $TIMEOUT_CONSTANT                  |"
echo "| Mutation Threshold              | $MUTATION_THRESHOLD                |"
echo "| Unit Test Files                 | $UNIT_TEST_COUNT                   |"
echo "| Integration Test Files          | $INTEGRATION_TEST_COUNT            |"
echo "| Spring Boot Test Files          | $SPRING_BOOT_TEST_COUNT            |"
echo "| JaCoCo                          | $([ "$JACOCO_CONFIGURED" = "true" ] && echo "configured" || echo "not configured") |"
echo "| Generated Code                  | $GENERATED_CODE                    |"
echo "| CI Mutation Testing             | $([ "$CI_MUTATION_TESTING" = "true" ] && echo "configured" || echo "not configured") |"
echo "| Recommended Path                | Path $ADOPTION_PATH                |"
echo ""
echo "Analysis complete. Review findings above for detailed recommendations."
