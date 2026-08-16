# Safe Dependency Upgrade Guide

## General Upgrade Strategy

### SemVer Rules of Thumb

| Upgrade Type | Risk | Strategy |
|---|---|---|
| Patch (1.2.3 -> 1.2.4) | Low | Usually safe, apply directly |
| Minor (1.2.3 -> 1.3.0) | Low-Medium | Review changelog, run tests |
| Major (1.2.3 -> 2.0.0) | High | Read migration guide, plan carefully |

### Safe Upgrade Process

1. **Before upgrading**: Run all tests, ensure green baseline
2. **Read the changelog**: Look for breaking changes, deprecations, behavior changes
3. **Upgrade one dependency at a time**: Isolate failures
4. **Run full test suite after each upgrade**
5. **Commit each successful upgrade as a checkpoint**
6. **For major upgrades**: Create a separate branch/PR

---

## Common Library Upgrade Paths

### Spring Boot

Spring Boot manages most dependency versions. Upgrading Spring Boot is the safest way to update its managed dependencies.

| From | To | Key Changes |
|---|---|---|
| 2.7.x -> 3.0.x | Major | javax->jakarta, Security 6, Hibernate 6, Java 17 min |
| 3.0.x -> 3.1.x | Minor | Docker Compose, SSL bundles, Testcontainers |
| 3.1.x -> 3.2.x | Minor | Virtual threads, RestClient |
| 3.2.x -> 3.3.x | Minor | CDS support, structured logging |

CRITICAL: For Spring Boot 2.x to 3.x migration, use the `java17-2-21-migration` skill instead of doing it manually.

### JUnit 4 to JUnit 5

Step-by-step migration:

1. Add JUnit 5 dependency alongside JUnit 4:
```xml
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <scope>test</scope>
</dependency>
<!-- Keep vintage engine for gradual migration -->
<dependency>
    <groupId>org.junit.vintage</groupId>
    <artifactId>junit-vintage-engine</artifactId>
    <scope>test</scope>
</dependency>
```

2. Migrate test classes incrementally:

| JUnit 4 | JUnit 5 |
|---|---|
| `import org.junit.Test` | `import org.junit.jupiter.api.Test` |
| `import org.junit.Before` | `import org.junit.jupiter.api.BeforeEach` |
| `import org.junit.After` | `import org.junit.jupiter.api.AfterEach` |
| `import org.junit.BeforeClass` | `import org.junit.jupiter.api.BeforeAll` |
| `import org.junit.Ignore` | `import org.junit.jupiter.api.Disabled` |
| `@RunWith(SpringRunner.class)` | `@ExtendWith(SpringExtension.class)` or just `@SpringBootTest` |
| `@Rule ExpectedException` | `assertThrows()` |
| `@Rule TemporaryFolder` | `@TempDir` |

3. Once all tests migrated, remove JUnit 4 and vintage engine

### Springfox to SpringDoc OpenAPI

Springfox is unmaintained. Migrate to springdoc-openapi:

1. Remove Springfox dependencies:
```xml
<!-- REMOVE these -->
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-boot-starter</artifactId>
</dependency>
```

2. Add SpringDoc:
```xml
<!-- For Spring Boot 3.x -->
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.6.0</version>
</dependency>

<!-- For Spring Boot 2.x -->
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-ui</artifactId>
    <version>1.8.0</version>
</dependency>
```

3. Key annotation changes:

| Springfox | SpringDoc / OpenAPI |
|---|---|
| `@Api` | `@Tag` |
| `@ApiOperation` | `@Operation` |
| `@ApiParam` | `@Parameter` |
| `@ApiModel` | `@Schema` |
| `@ApiModelProperty` | `@Schema` |
| `@ApiResponse` | `@ApiResponse` (different package) |

4. Remove Swagger/Docket configuration class
5. SpringDoc auto-configures from `@RestController` annotations

### Apache Commons Upgrades

| Old | New | Migration |
|---|---|---|
| commons-lang 2.x | commons-lang3 3.x | Change package `org.apache.commons.lang` to `org.apache.commons.lang3` |
| commons-collections 3.x | commons-collections4 4.x | Change package `org.apache.commons.collections` to `org.apache.commons.collections4` |
| commons-io 2.x (old) | commons-io 2.15+ | Mostly compatible, check deprecated methods |

### Jackson Upgrades

Jackson is generally backward-compatible within the 2.x line:

| Upgrade | Notes |
|---|---|
| 2.12 -> 2.13 | Java 8 date/time improvements |
| 2.13 -> 2.14 | Java 17+ optimizations |
| 2.14 -> 2.15 | Record support improvements |
| 2.15 -> 2.16+ | Performance improvements |

CRITICAL: Keep all Jackson modules at the SAME version. Mixed versions cause subtle serialization bugs.

```xml
<!-- Use BOM to ensure version alignment -->
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.fasterxml.jackson</groupId>
            <artifactId>jackson-bom</artifactId>
            <version>2.17.0</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

### MySQL Connector

The MySQL connector changed its Maven coordinates:

```xml
<!-- OLD -->
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
</dependency>

<!-- NEW -->
<dependency>
    <groupId>com.mysql</groupId>
    <artifactId>mysql-connector-j</artifactId>
</dependency>
```

The JDBC driver class also changed:
- Old: `com.mysql.jdbc.Driver`
- New: `com.mysql.cj.jdbc.Driver` (auto-detected by Spring Boot)

### Lombok

| Version | Key Change |
|---|---|
| 1.18.28 | Java 20 support |
| 1.18.30 | Java 21 support |
| 1.18.32 | Java 22 support |

CRITICAL: Lombok is tightly coupled to the Java compiler. Always upgrade Lombok when upgrading Java.

### Flyway / Liquibase

| Tool | Spring Boot 2.x | Spring Boot 3.x |
|---|---|---|
| Flyway | 8.x-9.x | 9.x-10.x |
| Liquibase | 4.x | 4.x (24.0+) |

Flyway migration (if using Java migrations):
```java
// Flyway 9.x+: implements JavaMigration (same API, verify import)
// Flyway 10.x: some configuration properties renamed
```

---

## Handling Transitive Dependency Conflicts

### Maven: Dependency Convergence

Use the Maven Enforcer Plugin to detect version conflicts:

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-enforcer-plugin</artifactId>
    <version>3.4.1</version>
    <executions>
        <execution>
            <id>enforce</id>
            <goals><goal>enforce</goal></goals>
            <configuration>
                <rules>
                    <dependencyConvergence/>
                    <requireMavenVersion>
                        <version>3.9.0</version>
                    </requireMavenVersion>
                </rules>
            </configuration>
        </execution>
    </executions>
</plugin>
```

Fix convergence issues with `<dependencyManagement>`:
```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.google.guava</groupId>
            <artifactId>guava</artifactId>
            <version>33.0.0-jre</version>
        </dependency>
    </dependencies>
</dependencyManagement>
```

### Gradle: Resolution Strategy

```groovy
configurations.all {
    resolutionStrategy {
        // Force specific version
        force 'com.google.guava:guava:33.0.0-jre'

        // Fail on version conflict
        failOnVersionConflict()
    }
}
```

Or use `strictly`:
```groovy
dependencies {
    implementation('com.google.guava:guava') {
        version {
            strictly '33.0.0-jre'
        }
    }
}
```

---

## Dependency Exclusion Patterns

When a transitive dependency causes conflicts:

### Maven
```xml
<dependency>
    <groupId>com.example</groupId>
    <artifactId>some-lib</artifactId>
    <exclusions>
        <exclusion>
            <groupId>commons-logging</groupId>
            <artifactId>commons-logging</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

### Gradle
```groovy
implementation('com.example:some-lib') {
    exclude group: 'commons-logging', module: 'commons-logging'
}
```

Common exclusions in Spring Boot projects:
- `commons-logging` (Spring uses SLF4J bridge instead)
- `log4j-to-slf4j` when using Log4j2 as primary logger
- Old `javax.*` APIs when using `jakarta.*`
