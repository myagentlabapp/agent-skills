#!/usr/bin/env bash
# Spring Boot Project Analyzer for startup optimization
# Usage: bash analyze-project.sh <project-root-directory>

set -euo pipefail

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "ERROR: Directory '$PROJECT_DIR' does not exist."
  exit 1
fi

echo "=========================================="
echo " Spring Boot Startup Optimizer - Analysis"
echo "=========================================="
echo ""

# --- Detect build tool ---
BUILD_TOOL="unknown"
BUILD_FILE=""
if [ -f "$PROJECT_DIR/pom.xml" ]; then
  BUILD_TOOL="maven"
  BUILD_FILE="$PROJECT_DIR/pom.xml"
elif [ -f "$PROJECT_DIR/build.gradle.kts" ]; then
  BUILD_TOOL="gradle"
  BUILD_FILE="$PROJECT_DIR/build.gradle.kts"
elif [ -f "$PROJECT_DIR/build.gradle" ]; then
  BUILD_TOOL="gradle"
  BUILD_FILE="$PROJECT_DIR/build.gradle"
fi
echo "Build Tool: $BUILD_TOOL"

if [ "$BUILD_TOOL" = "unknown" ]; then
  echo "ERROR: No pom.xml or build.gradle found in $PROJECT_DIR"
  echo "Please provide the path to the Spring Boot project root."
  exit 1
fi

# --- Detect web model (servlet vs reactive) ---
MODEL="unknown"
if grep -q "spring-boot-starter-webflux" "$BUILD_FILE" 2>/dev/null; then
  MODEL="reactive"
elif grep -q "spring-boot-starter-web" "$BUILD_FILE" 2>/dev/null; then
  MODEL="servlet"
fi
echo "Web Model: $MODEL"

# --- Detect Spring Boot version ---
SB_VERSION="unknown"
if [ "$BUILD_TOOL" = "maven" ]; then
  SB_VERSION=$(grep -A5 "spring-boot-starter-parent" "$BUILD_FILE" 2>/dev/null \
    | grep "<version>" | head -1 \
    | sed 's/.*<version>\(.*\)<\/version>.*/\1/' || true)
  if [ -z "$SB_VERSION" ] || [ "$SB_VERSION" = "unknown" ]; then
    SB_VERSION=$(grep "spring-boot.version" "$BUILD_FILE" 2>/dev/null \
      | sed 's/.*>\(.*\)<.*/\1/' || true)
  fi
  if [ -z "$SB_VERSION" ]; then
    SB_VERSION="unknown"
  fi
else
  SB_VERSION=$(grep -E "org.springframework.boot.*version" "$BUILD_FILE" 2>/dev/null \
    | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1 || true)
  if [ -z "$SB_VERSION" ]; then
    SB_VERSION=$(grep -E "springBootVersion|spring-boot" "$BUILD_FILE" 2>/dev/null \
      | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1 || true)
  fi
  if [ -z "$SB_VERSION" ]; then
    SB_VERSION="unknown"
  fi
fi
echo "Spring Boot Version: $SB_VERSION"

# --- Determine major version ---
SB_MAJOR="unknown"
if [[ "$SB_VERSION" =~ ^2\. ]]; then
  SB_MAJOR="2"
elif [[ "$SB_VERSION" =~ ^3\. ]]; then
  SB_MAJOR="3"
elif [[ "$SB_VERSION" =~ ^4\. ]]; then
  SB_MAJOR="4"
fi
echo "Spring Boot Major: $SB_MAJOR"

# --- Detect Java version ---
JAVA_VERSION="unknown"
if [ "$BUILD_TOOL" = "maven" ]; then
  JAVA_VERSION=$(grep -E "<java.version>|<maven.compiler.source>|<maven.compiler.release>" "$BUILD_FILE" 2>/dev/null \
    | head -1 | sed 's/.*>\(.*\)<.*/\1/' || true)
else
  JAVA_VERSION=$(grep -E "sourceCompatibility|jvmTarget|JavaVersion\.|java\.toolchain" "$BUILD_FILE" 2>/dev/null \
    | grep -oE "[0-9]+" | head -1 || true)
fi
if [ -z "$JAVA_VERSION" ] || [ "$JAVA_VERSION" = "unknown" ]; then
  if command -v java &>/dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -1 | grep -oE '"[0-9]+' | tr -d '"' || true)
  fi
fi
if [ -z "$JAVA_VERSION" ]; then
  JAVA_VERSION="unknown"
fi
echo "Java Version: $JAVA_VERSION"

# --- Detect embedded server ---
SERVER="unknown"
if [ "$MODEL" = "reactive" ]; then
  SERVER="netty"
  if grep -q "spring-boot-starter-undertow" "$BUILD_FILE" 2>/dev/null; then
    SERVER="undertow"
  elif grep -q "spring-boot-starter-tomcat" "$BUILD_FILE" 2>/dev/null; then
    SERVER="tomcat"
  fi
elif [ "$MODEL" = "servlet" ]; then
  SERVER="tomcat"
  if grep -q "spring-boot-starter-undertow" "$BUILD_FILE" 2>/dev/null; then
    SERVER="undertow"
  elif grep -q "spring-boot-starter-jetty" "$BUILD_FILE" 2>/dev/null; then
    SERVER="jetty"
  fi
fi
echo "Embedded Server: $SERVER"

# --- Count starters ---
STARTER_COUNT=$(grep -c "spring-boot-starter" "$BUILD_FILE" 2>/dev/null || echo "0")
echo "Spring Boot Starters: $STARTER_COUNT"

echo ""
echo "--- Existing Optimizations Detected ---"

# --- Check application properties/yml ---
PROPS_FILES=()
for f in "$PROJECT_DIR/src/main/resources/application.properties" \
         "$PROJECT_DIR/src/main/resources/application.yml" \
         "$PROJECT_DIR/src/main/resources/application.yaml"; do
  if [ -f "$f" ]; then
    PROPS_FILES+=("$f")
  fi
done

LAZY_INIT="no"
VIRTUAL_THREADS="no"
STARTUP_ACTUATOR="no"

for pf in "${PROPS_FILES[@]}"; do
  if grep -qE "spring\.(main\.)?lazy-initialization\s*[:=]\s*true" "$pf" 2>/dev/null; then
    LAZY_INIT="yes"
  fi
  if grep -qE "spring\.threads\.virtual\.enabled\s*[:=]\s*true" "$pf" 2>/dev/null; then
    VIRTUAL_THREADS="yes"
  fi
  if grep -qE "spring\.application\.startup\s*[:=]\s*buffering" "$pf" 2>/dev/null; then
    STARTUP_ACTUATOR="yes"
  fi
done

echo "Lazy Initialization: $LAZY_INIT"
echo "Virtual Threads: $VIRTUAL_THREADS"
echo "Startup Actuator: $STARTUP_ACTUATOR"

# --- Context indexer ---
CONTEXT_INDEXER="no"
if grep -q "spring-context-indexer" "$BUILD_FILE" 2>/dev/null; then
  CONTEXT_INDEXER="yes"
fi
echo "Spring Context Indexer: $CONTEXT_INDEXER"

# --- AOT processing ---
AOT_ENABLED="no"
if [ "$BUILD_TOOL" = "maven" ]; then
  if grep -q "process-aot" "$BUILD_FILE" 2>/dev/null; then
    AOT_ENABLED="yes"
  fi
else
  if grep -qE "aot|processAot" "$BUILD_FILE" 2>/dev/null; then
    AOT_ENABLED="yes"
  fi
fi
echo "AOT Processing: $AOT_ENABLED"

# --- GraalVM native ---
NATIVE="no"
if grep -qE "native-maven-plugin|org.graalvm|native-image|nativeCompile|spring-native" "$BUILD_FILE" 2>/dev/null; then
  NATIVE="yes"
fi
echo "GraalVM Native: $NATIVE"

# --- CDS ---
CDS="no"
for pf in "${PROPS_FILES[@]}"; do
  if grep -qE "ArchiveClassesAtExit|SharedArchiveFile|spring\.context\.exit" "$pf" 2>/dev/null; then
    CDS="yes"
  fi
done
if grep -qE "ArchiveClassesAtExit|SharedArchiveFile" "$BUILD_FILE" 2>/dev/null; then
  CDS="yes"
fi
echo "CDS (Class Data Sharing): $CDS"

# --- Component scan narrowing ---
NARROW_SCAN="no"
MAIN_CLASS=$(find "$PROJECT_DIR/src" -name "*.java" -exec grep -l "@SpringBootApplication\|@ComponentScan" {} \; 2>/dev/null | head -1 || true)
if [ -n "$MAIN_CLASS" ]; then
  if grep -q "@ComponentScan" "$MAIN_CLASS" 2>/dev/null; then
    NARROW_SCAN="yes"
  fi
fi
echo "Narrowed ComponentScan: $NARROW_SCAN"

# --- Spring Native (2.x) ---
SPRING_NATIVE="no"
if grep -q "spring-native" "$BUILD_FILE" 2>/dev/null; then
  SPRING_NATIVE="yes"
fi
echo "Spring Native (2.x): $SPRING_NATIVE"

echo ""
echo "--- Notable Dependencies ---"
grep -oE "spring-boot-starter-[a-zA-Z0-9-]+" "$BUILD_FILE" 2>/dev/null | sort -u || echo "(none found)"

echo ""
echo "--- Auto-Configuration Exclusions ---"
if [ -n "$MAIN_CLASS" ]; then
  if grep -q "exclude" "$MAIN_CLASS" 2>/dev/null; then
    grep -A5 "exclude" "$MAIN_CLASS" 2>/dev/null
  else
    echo "(none found)"
  fi
else
  echo "(could not locate main application class)"
fi

echo ""
echo "=========================================="
echo " Analysis Complete"
echo "=========================================="
