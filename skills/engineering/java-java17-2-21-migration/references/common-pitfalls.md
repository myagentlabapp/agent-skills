# Common Pitfalls and Compatibility Reference

## Library Compatibility Matrix for Java 21

### Core Dependencies

| Library | Minimum Version for Java 21 | Notes |
|---------|----------------------------|-------|
| Lombok | 1.18.30 | Earlier versions fail with annotation processing |
| MapStruct | 1.5.5.Final | Annotation processor compatibility |
| Mockito | 5.0.0 | Uses ByteBuddy which requires 1.14+ |
| JUnit 5 | 5.10.0 | Earlier versions may have issues |
| AssertJ | 3.24.0 | For full Java 21 support |
| Testcontainers | 1.19.0 | Docker integration compatibility |
| Jackson | 2.15.0 | Record handling improvements |
| Flyway | 9.22.0 | Schema migration Java 21 support |
| Liquibase | 4.24.0 | Database migration Java 21 support |
| Hibernate | 6.2.0 | Required for Spring Boot 3.x |
| HikariCP | 5.0.0 | Connection pooling (Spring Boot 3.x default) |

### Bytecode Manipulation Libraries

These libraries need specific versions for Java 21 bytecode support:

| Library | Minimum Version | Used By |
|---------|----------------|---------|
| ASM | 9.6 | Many frameworks internally |
| ByteBuddy | 1.14.10 | Mockito, Hibernate, Spring |
| CGLIB | 3.3.0 | Spring (legacy proxies) |
| Javassist | 3.29.0 | Some ORM tools |

CRITICAL: If you see `UnsupportedClassVersionError` or bytecode-related exceptions, check these libraries first.

---

## Build Tool Requirements

### Maven

| Component | Minimum Version | Recommended |
|-----------|----------------|-------------|
| Maven | 3.9.0 | 3.9.6+ |
| maven-compiler-plugin | 3.11.0 | 3.12.0+ |
| maven-surefire-plugin | 3.1.2 | 3.2.0+ |
| maven-failsafe-plugin | 3.1.2 | 3.2.0+ |

Maven pom.xml configuration:
```xml
<properties>
    <java.version>21</java.version>
    <maven.compiler.source>21</maven.compiler.source>
    <maven.compiler.target>21</maven.compiler.target>
    <maven.compiler.release>21</maven.compiler.release>
</properties>
```

### Gradle

| Component | Minimum Version | Recommended |
|-----------|----------------|-------------|
| Gradle | 8.4 | 8.5+ |
| Gradle Kotlin DSL | Compatible with 8.4+ | Latest |

build.gradle configuration:
```groovy
java {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}
```

build.gradle.kts configuration:
```kotlin
java {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(21))
    }
}
```

### Gradle Wrapper Update

```bash
./gradlew wrapper --gradle-version 8.5
```

---

## Docker Base Images

### Recommended Base Images

| Image | Size | Use Case |
|-------|------|----------|
| `eclipse-temurin:21-jre` | ~220MB | Standard production |
| `eclipse-temurin:21-jre-alpine` | ~100MB | Minimal production |
| `eclipse-temurin:21-jdk` | ~450MB | Build/development |
| `amazoncorretto:21` | ~200MB | AWS environments |
| `bellsoft/liberica-openjdk-alpine:21` | ~90MB | Smallest image |

### Dockerfile Update

Before:
```dockerfile
FROM eclipse-temurin:17-jre
```

After:
```dockerfile
FROM eclipse-temurin:21-jre
```

### Multi-stage Build Example

```dockerfile
# Build stage
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
COPY . .
RUN ./mvnw clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-XX:+UseZGC", "-jar", "app.jar"]
```

---

## IDE Setup

### IntelliJ IDEA

1. **Project SDK**: File -> Project Structure -> Project -> SDK -> Download JDK 21
2. **Language Level**: Set to "21 - Record patterns, pattern matching for switch"
3. **Compiler**: Settings -> Build -> Compiler -> Java Compiler -> Target bytecode version: 21
4. **Gradle/Maven**: Ensure JDK 21 is configured in build tool settings

Minimum IntelliJ version: **2023.2** for full Java 21 support

### Eclipse

1. Install Eclipse 2023-09 or later
2. Install Java 21 Support plugin if needed
3. Window -> Preferences -> Java -> Installed JREs -> Add JDK 21
4. Window -> Preferences -> Java -> Compiler -> Compiler compliance level: 21

### VS Code

1. Install Extension Pack for Java
2. Set `java.jdt.ls.java.home` to JDK 21 path in settings
3. Update `java.configuration.runtimes`:
```json
{
    "java.configuration.runtimes": [
        {
            "name": "JavaSE-21",
            "path": "/path/to/jdk-21",
            "default": true
        }
    ]
}
```

---

## CI/CD Pipeline Updates

### GitHub Actions

```yaml
- uses: actions/setup-java@v4
  with:
    distribution: 'temurin'
    java-version: '21'
```

### GitLab CI

```yaml
image: eclipse-temurin:21-jdk
```

### Jenkins

Update the JDK installation in Jenkins Global Tool Configuration to include JDK 21.

---

## Common Compilation Errors

### Error: "invalid source release: 21"

**Cause**: Build tool or plugin not configured for Java 21
**Fix**: Update maven-compiler-plugin to 3.11+ or Gradle to 8.4+

### Error: "java.lang.UnsupportedClassVersionError: ... class file version 65"

**Cause**: Running Java 21-compiled code on an older JVM
**Fix**: Ensure runtime JVM is Java 21. Check Docker base image, CI/CD config, and deployment scripts.

### Error: "java.lang.reflect.InaccessibleObjectException"

**Cause**: Library accessing internal JDK API that is now strongly encapsulated
**Fix**: Update the library to a Java 21-compatible version. As temporary workaround, add `--add-opens` flag.

### Error: "annotation processing not supported for Java 21"

**Cause**: Lombok, MapStruct, or other annotation processor is too old
**Fix**: Update to minimum compatible version (see Library Compatibility Matrix above)

### Error: "NoSuchMethodError" or "NoSuchFieldError" at runtime

**Cause**: Binary incompatibility between compiled code and runtime library version
**Fix**: Clean rebuild (`mvn clean install` or `gradle clean build`). If persists, check for conflicting dependency versions.

### Error: "Unsupported class file major version 65" from ASM/ByteBuddy

**Cause**: Bytecode manipulation library too old for Java 21 class format
**Fix**: Update ASM to 9.6+, ByteBuddy to 1.14.10+

---

## Multi-Module Project Considerations

- **All modules must target Java 21** simultaneously. You cannot have module-a on Java 17 and module-b on Java 21 in the same project.
- Update the parent POM / root build.gradle first, then verify each module compiles
- Run the full integration test suite after updating all modules
- If using Maven BOM (Bill of Materials), update the BOM to align all dependency versions

---

## Gradle Daemon Issues

When switching JDK versions, the Gradle daemon may cache the old JDK:

```bash
# Stop all Gradle daemons
./gradlew --stop

# Clean and rebuild
./gradlew clean build
```

If issues persist:
```bash
# Delete Gradle caches
rm -rf ~/.gradle/caches/
rm -rf .gradle/
```

---

## Known Spring Boot Issues with Java 21

| Issue | Spring Boot Version | Workaround |
|-------|-------------------|------------|
| Virtual thread pinning with Tomcat NIO | 3.2.0-3.2.1 | Upgrade to 3.2.2+ |
| CDS archive compatibility | 3.3.0 | Use 3.3.1+ for improved CDS support |
| RestClient connection leak | 3.2.0 | Upgrade to 3.2.1+ |
| AOT + records | 3.0.x-3.1.x | Limited record support in AOT, use 3.2+ |

Always use the **latest patch version** of your target Spring Boot minor version to avoid known issues.
