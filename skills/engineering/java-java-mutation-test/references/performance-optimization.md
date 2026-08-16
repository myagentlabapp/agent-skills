# PITest Performance Optimization Guide

## Understanding PITest Performance

PITest execution time is determined by:

```
Total Time = Number of Mutations x Average Test Execution Time per Mutation
```

Each mutation requires re-running the relevant tests (not the entire suite -- PITest tracks which tests cover each line). The key levers for optimization:

1. **Reduce mutations**: Scope to specific classes, exclude generated code
2. **Reduce test time per mutation**: Threading, history, timeout tuning
3. **Scope to changes only**: PR-based analysis with pitest-git-plugin

## Incremental Analysis with History

The single most impactful optimization. PITest saves mutation results to a history file and only re-analyzes changed code on subsequent runs.

**Impact**: 80-90% faster on subsequent runs.

### Maven Configuration

```xml
<configuration>
    <withHistory>true</withHistory>
    <!-- Optional: specify custom history file location -->
    <historyInputFile>${project.build.directory}/pitest-history.bin</historyInputFile>
    <historyOutputFile>${project.build.directory}/pitest-history.bin</historyOutputFile>
</configuration>
```

### Gradle Configuration

```groovy
pitest {
    historyInputLocation = file("${buildDir}/pitest-history.bin")
    historyOutputLocation = file("${buildDir}/pitest-history.bin")
}
```

### Gradle KTS Configuration

```kotlin
pitest {
    historyInputLocation.set(file("${layout.buildDirectory.get()}/pitest-history.bin"))
    historyOutputLocation.set(file("${layout.buildDirectory.get()}/pitest-history.bin"))
}
```

### Trade-offs

- First run is not affected (no history exists yet)
- History file must be persisted between CI runs (cache the file)
- If tests change significantly, the history may cause stale results -- delete the history file periodically

## Threading

PITest forks separate JVM processes for mutation testing. Increasing threads allows parallel mutation analysis.

**Impact**: Near-linear speedup up to CPU core count.

### Maven Configuration

```xml
<configuration>
    <threads>4</threads>
    <!-- Or use a Maven property for dynamic core count -->
</configuration>
```

### Gradle Configuration

```groovy
pitest {
    threads = Runtime.runtime.availableProcessors()
}
```

### Guidelines

| Environment        | Recommended Threads       |
|--------------------|---------------------------|
| Developer machine  | CPU cores - 1             |
| CI/CD server       | CPU cores                 |
| Shared CI runner   | 2-4 (avoid hogging)       |
| Memory-constrained | 2 (each thread forks a JVM) |

### Memory Consideration

Each thread forks a child JVM. Monitor memory usage:
- 4 threads with default JVM settings = ~4 x 256MB = ~1GB
- For memory-constrained environments, reduce threads or set child JVM memory:

**Maven:**
```xml
<configuration>
    <jvmArgs>
        <value>-Xmx512m</value>
    </jvmArgs>
</configuration>
```

**Gradle:**
```groovy
pitest {
    jvmArgs = ['-Xmx512m']
}
```

## Scope Reduction

Limiting the scope of mutation analysis is the most straightforward way to reduce execution time.

### Target Classes

Limit mutation analysis to specific packages:

**Maven:**
```xml
<targetClasses>
    <param>com.example.domain.**</param>
    <param>com.example.service.**</param>
</targetClasses>
```

**Gradle:**
```groovy
pitest {
    targetClasses = ['com.example.domain.**', 'com.example.service.**']
}
```

### Excluded Classes

Exclude classes that should not be mutated:

**Generated code:**
- Lombok: `**.*Builder`, `**.*_` (delombok artifacts)
- MapStruct: `**.*MapperImpl`
- Protobuf: `**.*Proto`, `**.*Grpc`

**Infrastructure/config:**
- `**.*Config`, `**.*Configuration`
- `**.*Properties`
- `**.*Application` (Spring Boot main class)
- `**.*DTO` (if they contain no business logic)
- `**.*Entity` (if they contain no business logic beyond JPA annotations)

**Maven:**
```xml
<excludedClasses>
    <param>com.example.config.**</param>
    <param>**.*Config</param>
    <param>**.*Configuration</param>
    <param>**.*Properties</param>
    <param>**.*Application</param>
    <param>**.*MapperImpl</param>
</excludedClasses>
```

**Gradle:**
```groovy
pitest {
    excludedClasses = [
        'com.example.config.**',
        '**.*Config',
        '**.*Configuration',
        '**.*Properties',
        '**.*Application',
        '**.*MapperImpl'
    ]
}
```

### Excluded Methods

Exclude trivial methods that do not contain business logic:

**Maven:**
```xml
<excludedMethods>
    <param>toString</param>
    <param>hashCode</param>
    <param>equals</param>
</excludedMethods>
```

**Gradle:**
```groovy
pitest {
    excludedMethods = ['toString', 'hashCode', 'equals']
}
```

**Note**: Only exclude `equals`/`hashCode` if they are auto-generated. If your business logic depends on custom equality, keep them in scope.

### Avoid Calls To

Prevents PITest from mutating calls to specific packages (primarily logging):

**Maven:**
```xml
<avoidCallsTo>
    <avoidCallsTo>org.slf4j</avoidCallsTo>
    <avoidCallsTo>org.apache.logging</avoidCallsTo>
    <avoidCallsTo>java.util.logging</avoidCallsTo>
    <avoidCallsTo>org.apache.log4j</avoidCallsTo>
</avoidCallsTo>
```

**Gradle:**
```groovy
pitest {
    avoidCallsTo = [
        'org.slf4j',
        'org.apache.logging',
        'java.util.logging',
        'org.apache.log4j'
    ]
}
```

### Excluded Test Classes

Exclude slow tests from mutation analysis (integration tests, Spring Boot context tests):

**Maven:**
```xml
<excludedTestClasses>
    <param>**.*IT</param>
    <param>**.*IntegrationTest</param>
</excludedTestClasses>
```

**Gradle:**
```groovy
pitest {
    excludedTestClasses = ['**.*IT', '**.*IntegrationTest']
}
```

For Spring Boot: tests annotated with `@SpringBootTest` load the full application context and are very slow for mutation testing. Prefer excluding them and relying on unit tests and slice tests (`@WebMvcTest`, `@DataJpaTest`).

## Timeout Tuning

PITest uses a timeout formula to detect infinite loops caused by mutations:

```
Timeout = timeoutFactor * normalTestTime + timeoutConstant
```

**Defaults**: factor = 1.25, constant = 4000ms

### When to Increase

| Scenario                        | Recommended timeoutConstant |
|---------------------------------|-----------------------------|
| Plain Java project              | 4000ms (default)            |
| Spring Boot (slice tests)       | 8000ms                      |
| Spring Boot (full context)      | 12000-15000ms               |
| Testcontainers usage            | 15000ms+ or exclude tests   |
| Virtual threads in tests        | 8000-10000ms                |

### Diagnosis

If you see many `TIMED_OUT` mutations in the report, your timeoutConstant is likely too low. Increase it.

**Maven:**
```xml
<timeoutConstant>10000</timeoutConstant>
<timeoutFactor>1.25</timeoutFactor>
```

**Gradle:**
```groovy
pitest {
    timeoutConstInMillis = 10000
    timeoutFactor = 1.25
}
```

## PR-Scoped Analysis with pitest-git-plugin

Arcmutate's `pitest-git-plugin` analyzes only code changed in the current branch compared to a base branch. This is the recommended approach for PR pipelines.

**Impact**: Mutation testing runs in seconds instead of minutes.

### Maven Setup

Add the plugin as a PITest dependency:

```xml
<plugin>
    <groupId>org.pitest</groupId>
    <artifactId>pitest-maven</artifactId>
    <version>1.19.1</version>
    <dependencies>
        <dependency>
            <groupId>org.pitest</groupId>
            <artifactId>pitest-junit5-plugin</artifactId>
            <version>1.2.3</version>
        </dependency>
        <dependency>
            <groupId>com.arcmutate</groupId>
            <artifactId>pitest-git-plugin</artifactId>
            <version>1.2.2</version>
        </dependency>
    </dependencies>
    <configuration>
        <features>
            <feature>+GIT(from[main])</feature>
        </features>
        <!-- rest of configuration -->
    </configuration>
</plugin>
```

### Gradle Setup

```groovy
pitest {
    features = ['+GIT(from[main])']
}

dependencies {
    pitest 'com.arcmutate:pitest-git-plugin:1.2.2'
}
```

### Usage

The plugin automatically detects changed files by comparing the current branch with the specified base branch (`main` by default). Only mutations in changed code are analyzed.

**Note**: The pitest-git-plugin is a commercial plugin from Arcmutate. It is free for open-source projects. For commercial use, check Arcmutate licensing.

## Performance Benchmarks

Typical execution times by project size (approximate, varies by test speed):

| Project Size       | Full (no tuning) | Full (tuned)   | Incremental  | PR-scoped    |
|--------------------|------------------|----------------|--------------|--------------|
| Small (50 classes) | 2-5 min          | 30s - 1 min    | 10-20s       | 5-15s        |
| Medium (200 classes) | 15-30 min      | 3-5 min        | 30s - 1 min  | 10-30s       |
| Large (500+ classes) | 1-3 hours      | 10-20 min      | 2-5 min      | 15-45s       |

**"Tuned" configuration means:**
- STRONGER mutator group
- Threads set to CPU core count
- History enabled (incremental analysis)
- Generated code and config classes excluded
- Integration tests excluded
- Logging calls excluded via avoidCallsTo

### Optimization Checklist

Apply these optimizations in order of impact:

1. Enable `withHistory` (incremental analysis) -- **80-90% speedup on subsequent runs**
2. Increase `threads` to CPU core count -- **near-linear speedup**
3. Exclude integration tests -- **removes slowest tests from mutation analysis**
4. Exclude generated/config code -- **reduces mutation count**
5. Add `avoidCallsTo` for logging -- **reduces void method call mutations**
6. Use pitest-git-plugin for PRs -- **seconds instead of minutes**
7. Scope `targetClasses` to business logic -- **skip infrastructure code**
