# PITest Setup Guide for Java 21

## Prerequisites

Before setting up PITest:
1. **Java 21** installed and configured in your build
2. **JUnit 5** as your test framework (JUnit Jupiter 5.9+)
3. **All tests passing** -- PITest requires a green test suite before running mutations
4. **Build wrapper** (mvnw/gradlew) available for consistent execution

### Version Compatibility Matrix

| Component               | Recommended Version | Minimum Version |
|-------------------------|--------------------:|----------------:|
| PITest                  | 1.19.1              | 1.15.0          |
| pitest-junit5-plugin    | 1.2.3               | 1.1.0           |
| JUnit Platform          | 1.10.x              | 1.5.0           |
| JUnit Jupiter           | 5.10.x              | 5.5.0           |
| Java                    | 21                  | 11              |
| Maven                   | 3.9+                | 3.6+            |
| Gradle                  | 8.4+                | 6.4+            |
| gradle-pitest-plugin    | 1.15.0              | 1.9.0           |

## Maven Setup

### Complete Plugin Configuration

Add the following to your `pom.xml` inside the `<build><plugins>` section:

```xml
<plugin>
    <groupId>org.pitest</groupId>
    <artifactId>pitest-maven</artifactId>
    <version>1.19.1</version>
    <dependencies>
        <!-- CRITICAL: pitest-junit5-plugin must be a plugin dependency, NOT a project dependency -->
        <dependency>
            <groupId>org.pitest</groupId>
            <artifactId>pitest-junit5-plugin</artifactId>
            <version>1.2.3</version>
        </dependency>
    </dependencies>
    <configuration>
        <!-- Mutation operators: STRONGER recommended for Java 21 projects -->
        <mutators>
            <mutator>STRONGER</mutator>
        </mutators>

        <!-- Target your application classes (adjust package pattern) -->
        <targetClasses>
            <param>com.example.**</param>
        </targetClasses>

        <!-- Target your test classes -->
        <targetTests>
            <param>com.example.**</param>
        </targetTests>

        <!-- Parallel execution: set to CPU core count -->
        <threads>4</threads>

        <!-- Timeout: increase for Spring Boot projects (default 4000ms) -->
        <timeoutConstant>4000</timeoutConstant>

        <!-- Incremental analysis: saves results between runs -->
        <withHistory>true</withHistory>

        <!-- Report formats -->
        <outputFormats>
            <outputFormat>HTML</outputFormat>
            <outputFormat>XML</outputFormat>
        </outputFormats>

        <!-- Exclude generated and infrastructure code -->
        <excludedClasses>
            <param>com.example.config.**</param>
            <param>com.example.**.config.**</param>
            <param>**.*Config</param>
            <param>**.*Configuration</param>
            <param>**.*Properties</param>
            <param>**.*Application</param>
        </excludedClasses>

        <!-- Exclude trivial methods -->
        <excludedMethods>
            <param>toString</param>
            <param>hashCode</param>
            <param>equals</param>
        </excludedMethods>

        <!-- Skip mutation of logging calls -->
        <avoidCallsTo>
            <avoidCallsTo>org.slf4j</avoidCallsTo>
            <avoidCallsTo>org.apache.logging</avoidCallsTo>
            <avoidCallsTo>java.util.logging</avoidCallsTo>
            <avoidCallsTo>org.apache.log4j</avoidCallsTo>
        </avoidCallsTo>

        <!-- Exclude integration tests from mutation analysis -->
        <excludedTestClasses>
            <param>**.*IT</param>
            <param>**.*IntegrationTest</param>
        </excludedTestClasses>

        <!-- Initial threshold: 60% for new adoption, increase over time -->
        <mutationThreshold>60</mutationThreshold>

        <!-- Do not fail when no mutations found (useful for filtered modules) -->
        <failWhenNoMutations>false</failWhenNoMutations>
    </configuration>
</plugin>
```

### Running PITest with Maven

```bash
# Full mutation analysis
./mvnw test-compile org.pitest:pitest-maven:mutationCoverage

# Scoped to a specific package (recommended for first run)
./mvnw test-compile org.pitest:pitest-maven:mutationCoverage \
  -DtargetClasses="com.example.domain.*"

# With verbose logging (useful for debugging)
./mvnw test-compile org.pitest:pitest-maven:mutationCoverage \
  -DverboseLogging=true
```

Report location: `target/pit-reports/YYYYMMDDHHMI/index.html`

## Gradle Setup

### build.gradle (Groovy DSL)

```groovy
plugins {
    id 'info.solidsoft.pitest' version '1.15.0'
}

pitest {
    // PITest version
    pitestVersion = '1.19.1'

    // JUnit 5 support
    junit5PluginVersion = '1.2.3'

    // Mutation operators
    mutators = ['STRONGER']

    // Target classes (adjust package pattern)
    targetClasses = ['com.example.**']

    // Target tests
    targetTests = ['com.example.**']

    // Parallel execution
    threads = Runtime.runtime.availableProcessors()

    // Timeout (increase for Spring Boot)
    timeoutConstInMillis = 4000

    // Incremental analysis
    historyInputLocation = file("${buildDir}/pitest-history.bin")
    historyOutputLocation = file("${buildDir}/pitest-history.bin")

    // Report formats
    outputFormats = ['HTML', 'XML']

    // Exclusions
    excludedClasses = [
        'com.example.config.**',
        '**.*Config',
        '**.*Configuration',
        '**.*Properties',
        '**.*Application'
    ]

    excludedMethods = ['toString', 'hashCode', 'equals']

    avoidCallsTo = [
        'org.slf4j',
        'org.apache.logging',
        'java.util.logging',
        'org.apache.log4j'
    ]

    excludedTestClasses = ['**.*IT', '**.*IntegrationTest']

    // Threshold
    mutationThreshold = 60

    failWhenNoMutations = false
}
```

### build.gradle.kts (Kotlin DSL)

```kotlin
plugins {
    id("info.solidsoft.pitest") version "1.15.0"
}

pitest {
    pitestVersion.set("1.19.1")
    junit5PluginVersion.set("1.2.3")
    mutators.set(listOf("STRONGER"))
    targetClasses.set(listOf("com.example.**"))
    targetTests.set(listOf("com.example.**"))
    threads.set(Runtime.getRuntime().availableProcessors())
    timeoutConstInMillis.set(4000)
    historyInputLocation.set(file("${layout.buildDirectory.get()}/pitest-history.bin"))
    historyOutputLocation.set(file("${layout.buildDirectory.get()}/pitest-history.bin"))
    outputFormats.set(listOf("HTML", "XML"))
    excludedClasses.set(listOf(
        "com.example.config.**",
        "**.*Config",
        "**.*Configuration",
        "**.*Properties",
        "**.*Application"
    ))
    excludedMethods.set(listOf("toString", "hashCode", "equals"))
    avoidCallsTo.set(listOf(
        "org.slf4j",
        "org.apache.logging",
        "java.util.logging",
        "org.apache.log4j"
    ))
    excludedTestClasses.set(listOf("**.*IT", "**.*IntegrationTest"))
    mutationThreshold.set(60)
    failWhenNoMutations.set(false)
}
```

### Running PITest with Gradle

```bash
# Full mutation analysis
./gradlew pitest

# With info logging
./gradlew pitest --info
```

Report location: `build/reports/pitest/index.html`

## Understanding the PITest Report

### HTML Report Structure

The HTML report is organized by package and class:

1. **Package Summary**: Shows mutation score per package as a percentage
2. **Class Detail**: Each class shows line-by-line mutation results
3. **Line Detail**: Each mutated line shows:
   - The mutation operator applied
   - Whether the mutant was KILLED (test detected the change) or SURVIVED (test missed it)
   - Which test killed the mutant (if killed)

### Color Coding

| Color  | Meaning                     | Action                          |
|--------|-----------------------------|---------------------------------|
| Green  | Mutant killed               | Good -- tests detected the change |
| Red    | Mutant survived             | Test gap -- consider adding assertions |
| Light green | Line covered, all mutants killed | Fully tested line |
| Light red   | Line covered, some mutants survived | Partially tested line |
| Orange | No coverage                 | Line not reached by any test    |

### Mutation Score Calculation

```
Mutation Score = (Killed Mutants / Total Mutants) * 100
```

Where Total Mutants = Killed + Survived (excluding timed-out and non-viable mutations)

## First Run Strategy

### Recommended Progression

1. **Start small**: Run on a single core domain package
   ```bash
   # Maven
   ./mvnw test-compile org.pitest:pitest-maven:mutationCoverage \
     -DtargetClasses="com.example.domain.*"

   # Gradle: temporarily set targetClasses in build file
   ```

2. **Review the report**: Understand the mutation score and surviving mutants

3. **Expand gradually**: Add more packages one at a time
   ```
   com.example.domain.*     -> com.example.service.*     -> com.example.**
   ```

4. **Full analysis**: Once comfortable, run across the entire codebase

### Threshold Guidance

| Project Stage       | Recommended Threshold | Enforcement      |
|---------------------|-----------------------|------------------|
| New adoption        | 60%                   | Report only      |
| After 1-2 months    | 70%                   | Fail nightly     |
| Established (3+ mo) | 80%                   | Fail nightly     |
| Mature              | 80% (90% for domain)  | Fail on PR + nightly |

## Java 21 Specifics

### Records

PITest 1.19.1 automatically filters record-generated bytecode:
- Canonical constructor
- Component accessor methods (`name()`, `value()`, etc.)
- `equals()`, `hashCode()`, `toString()`

You do NOT need to exclude records -- PITest handles them transparently. Custom logic inside record methods IS mutated (which is correct behavior).

### Sealed Classes

Sealed classes compile to standard bytecode with access control checks. PITest handles them transparently. Exhaustive switch statements over sealed hierarchies may generate a default branch in bytecode -- PITest may create mutations there, which is expected.

### Pattern Matching (switch and instanceof)

Pattern matching compiles to standard bytecode comparisons. PITest mutates the individual branches normally. No special configuration needed.

### Virtual Threads

Virtual threads are a runtime feature with no bytecode impact. PITest works normally. However, if your tests use virtual threads (especially with Spring Boot `spring.threads.virtual.enabled=true`):
- Increase `timeoutConstant` to account for potential scheduling differences
- Virtual thread-based tests may have slightly different timing characteristics

### Spring Boot Projects

For Spring Boot projects, make these adjustments:
- Increase `timeoutConstant` to **10000ms** (or higher if tests load full application context)
- Exclude Spring Boot test classes that load the full context: `@SpringBootTest`
- Keep slice tests (`@WebMvcTest`, `@DataJpaTest`) if they are fast enough
- Exclude configuration classes: `*Config`, `*Configuration`, `*Application`
