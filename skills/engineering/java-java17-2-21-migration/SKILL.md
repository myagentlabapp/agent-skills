---
name: java17-2-21-migration
description: Guides migration of Java 17 applications to Java 21 with Spring Boot 2.x-to-3.x and Spring Boot 3.x upgrade paths. Analyzes project for javax imports, synchronized blocks, ThreadLocal usage, deprecated APIs, and dependency compatibility. Suggests virtual threads, pattern matching, record patterns, sequenced collections, and JVM performance improvements. Use when user asks to "migrate Java 17 to 21", "upgrade to Java 21", "adopt virtual threads", "migrate Spring Boot 2 to 3", "update javax to jakarta", "modernize Java application", or "enable virtual threads in Spring Boot". Do NOT use for greenfield Java 21 projects or non-Spring-Boot Java applications.
allowed-tools: "Bash(bash:*)"
compatibility: Requires bash shell. Intended for Spring Boot 2.x-3.x projects using Maven or Gradle with Java 17.
license: MIT
metadata:
  author: claudioeduardodeoliveira
  version: 1.0.0
  category: java-migration
  tags: [java-21, java-17, spring-boot, migration, virtual-threads, jakarta, spring-boot-3]
---

# Java 17 to 21 Migration Guide

## Instructions

### Step 1: Analyze the Project

Run the analysis script to detect the current project state:

```bash
bash scripts/analyze-migration.sh <project-root-directory>
```

The script detects:
- **Java version**: From build config (pom.xml / build.gradle) or JAVA_HOME
- **Spring Boot version**: 2.x or 3.x (determines migration path)
- **Build tool**: Maven or Gradle
- **Web model**: Servlet (Spring MVC) or Reactive (WebFlux)
- **Namespace usage**: javax.* vs jakarta.* import counts
- **Virtual thread readiness**: synchronized blocks, ThreadLocal usage, pinning risks
- **Deprecated API usage**: WebSecurityConfigurerAdapter, antMatchers, old property names
- **Dependency compatibility**: Libraries requiring updates for Java 21

If the script cannot be run, perform detection manually:
1. Check `pom.xml` or `build.gradle` for `java.version` / `sourceCompatibility`
2. Check Spring Boot parent version or plugin version
3. Search source files for `javax.*` imports: `grep -r "import javax\." src/`
4. Search for `synchronized` blocks: `grep -rn "synchronized" src/main/java/`
5. Search for ThreadLocal usage: `grep -rn "ThreadLocal" src/main/java/`

### Step 2: Present Findings and Determine Migration Path

Present a clear summary:

```
## Project Migration Analysis

| Property                  | Value                    |
|---------------------------|--------------------------|
| Current Java Version      | 17                       |
| Target Java Version       | 21                       |
| Spring Boot Version       | X.Y.Z                    |
| Build Tool                | Maven / Gradle           |
| Web Model                 | Servlet / Reactive       |
| Migration Path            | Path A or Path B         |

### Namespace Status
- javax.* imports found: N files
- jakarta.* imports found: N files

### Virtual Thread Readiness
- synchronized blocks found: N occurrences
- ThreadLocal usages found: N occurrences
- ReentrantLock already used: N occurrences

### Deprecated Patterns Detected
- [list patterns found by analysis]

### Dependencies Requiring Attention
- [list any flagged dependencies]
```

Determine the migration path:
- **Path A (Full Migration)**: Spring Boot 2.x detected -- must migrate to Spring Boot 3.x first, then leverage Java 21 features
- **Path B (Java Upgrade Only)**: Spring Boot 3.x detected -- upgrade Java 17 to 21 and adopt new features

CRITICAL: Always confirm the migration path with the user before proceeding. Ask if they want a full migration plan or want to tackle it in phases.

### Step 3: Execute Migration (Path A -- Spring Boot 2.x to 3.x + Java 21)

This path has four phases. Complete each phase before moving to the next. Consult the appropriate reference files for detailed guidance.

**Phase 1: Prepare for Spring Boot 3.x**

Consult `references/spring-boot-2x-to-3x.md` for detailed instructions.

1. Upgrade to the latest Spring Boot 2.7.x first (if not already)
2. Verify Java 17 baseline is in place
3. Address all deprecation warnings in Spring Boot 2.7.x
4. Run the project and all tests to establish a green baseline
5. Commit this as a stable checkpoint

For each change:
- Explain what is changing and why
- Show the exact code/config modification
- Run tests after each significant change

**Phase 2: Migrate to Spring Boot 3.x**

Consult `references/spring-boot-2x-to-3x.md` for detailed instructions.

1. Update Spring Boot parent/plugin to 3.2+ (recommend latest 3.2+ for virtual thread support)
2. Migrate `javax.*` to `jakarta.*` namespace
   - Update all import statements
   - Update dependency coordinates (javax.validation -> jakarta.validation, etc.)
   - Update `persistence.xml`, `web.xml`, or other XML configs if present
3. Migrate Spring Security configuration
   - Replace `WebSecurityConfigurerAdapter` with `SecurityFilterChain` bean
   - Replace `antMatchers()` with `requestMatchers()`
   - Replace `authorizeRequests()` with `authorizeHttpRequests()`
   - Replace `@EnableGlobalMethodSecurity` with `@EnableMethodSecurity`
4. Update HttpClient from 4.x to 5.x if using Apache HttpClient
5. Update Hibernate 5 to 6 changes
   - ID generation strategy changes
   - Query/criteria API changes
6. Fix property name changes (consult reference for full list)
7. Fix trailing slash behavior (disabled by default in Spring Boot 3.x)
8. Update Spring Data repository method signatures if affected
9. Run full test suite -- fix all failures before proceeding
10. Commit as a stable checkpoint

**Phase 3: Upgrade to Java 21**

1. Update build config to target Java 21:
   - Maven: set `<java.version>21</java.version>`
   - Gradle: set `sourceCompatibility = '21'`
2. Update Maven compiler plugin to 3.11+ or Gradle to 8.4+
3. Update CI/CD pipelines and Docker base images to use JDK 21
4. Build and run full test suite on Java 21
5. Fix any compilation or runtime issues (consult `references/common-pitfalls.md`)
6. Commit as a stable checkpoint

**Phase 4: Adopt Java 21 Features and Optimizations**

Proceed to Step 4 (shared with Path B).

### Step 3: Execute Migration (Path B -- Spring Boot 3.x, Java 17 to 21)

This path has two phases.

**Phase 1: Upgrade to Java 21**

1. Update to Spring Boot 3.2+ if currently on 3.0 or 3.1 (needed for virtual thread support)
2. Update build config to target Java 21:
   - Maven: set `<java.version>21</java.version>`
   - Gradle: set `sourceCompatibility = '21'`
3. Update Maven compiler plugin to 3.11+ or Gradle to 8.4+
4. Update CI/CD pipelines and Docker base images to use JDK 21
5. Build and run full test suite on Java 21
6. Fix any compilation or runtime issues (consult `references/common-pitfalls.md`)
7. Commit as a stable checkpoint

**Phase 2: Adopt Java 21 Features and Optimizations**

Proceed to Step 4.

### Step 4: Adopt Java 21 Features (Both Paths)

Ask the user which categories they want to adopt. Present them as tiers:

**Tier 1 -- Quick Wins** (low risk, immediate benefit):

Consult `references/java21-language-features.md` for detailed examples.

- **Pattern matching for switch**: Replace if-else-instanceof chains with switch expressions
  ```java
  // Before
  if (obj instanceof String s) { ... }
  else if (obj instanceof Integer i) { ... }
  // After
  switch (obj) {
      case String s  -> ...
      case Integer i -> ...
      default        -> ...
  }
  ```
- **Record patterns**: Destructure records directly in switch/instanceof
  ```java
  // Before
  if (obj instanceof Point p) { int x = p.x(); int y = p.y(); }
  // After
  if (obj instanceof Point(int x, int y)) { /* use x, y directly */ }
  ```
- **Sealed class finalization**: Remove `@SuppressWarnings("preview")` annotations if present
- **Sequenced collections**: Use `SequencedCollection`, `getFirst()`, `getLast()`, `reversed()`
  ```java
  // Before
  list.get(0);  list.get(list.size() - 1);
  // After
  list.getFirst();  list.getLast();
  ```

**Tier 2 -- Concurrency Modernization** (moderate effort, significant impact):

Consult `references/java21-concurrency.md` for detailed instructions.

- **Virtual threads via Spring Boot** (Spring Boot 3.2+ required):
  1. First, audit and replace `synchronized` blocks with `ReentrantLock`:
     ```java
     // Before (pins virtual thread)
     synchronized (lock) { doWork(); }
     // After (virtual-thread-safe)
     private final ReentrantLock lock = new ReentrantLock();
     lock.lock();
     try { doWork(); } finally { lock.unlock(); }
     ```
  2. Then enable virtual threads: `spring.threads.virtual.enabled=true`
  3. Audit ThreadLocal usage -- consider migrating to ScopedValue for new code
  4. Review connection pool sizing -- virtual threads allow more concurrent requests, so database connection pools (HikariCP `maximumPoolSize`) may need adjustment

CRITICAL virtual thread rules:
- NEVER enable virtual threads without first auditing synchronized blocks
- ALWAYS replace synchronized blocks with ReentrantLock before enabling
- For reactive (WebFlux) projects: virtual threads are less impactful since the model is already non-blocking, but can help with occasional blocking calls

- **Structured concurrency** (preview in Java 21, requires `--enable-preview`):
  - Mention as future-looking pattern for managing concurrent subtasks
  - Do NOT recommend for production code yet

- **Scoped values** (preview in Java 21, requires `--enable-preview`):
  - Mention as ThreadLocal replacement for virtual threads
  - Do NOT recommend for production code yet

**Tier 3 -- Performance and JVM** (infrastructure changes):

Consult `references/performance-and-jvm.md` for detailed instructions.

- **Generational ZGC**: Default in Java 21, verify it is active, tune if needed
- **CDS with Spring Boot 3.3+**: Use `spring.context.exit=onRefresh` training run for class data sharing
- **AOT processing**: For startup improvement with Spring Boot 3.0+
- **JVM flag cleanup**: Remove obsolete Java 17 flags, add Java 21 optimizations
- **Docker base image**: Update to `eclipse-temurin:21-jre` or `eclipse-temurin:21-jre-alpine`

For each adopted feature:
1. Explain the feature and its benefit
2. Show the exact code change
3. Note any trade-offs or risks
4. Specify how to verify it works
5. Commit after each category

### Step 5: Validation and Verification

After all changes:

1. Run the full test suite
2. Verify application starts correctly on Java 21
3. Check for runtime warnings about illegal reflective access or deprecated flags
4. If virtual threads were enabled:
   - Verify no thread pinning: run with `-Djdk.tracePinnedThreads=short` JVM flag
   - Monitor with `jcmd <pid> Thread.dump_to_file -format=json threads.json` to verify virtual threads are in use
   - Load test to verify behavior under concurrent requests
5. Review application logs for any new warnings or errors
6. Re-run the analysis script to confirm the migration is complete:

```bash
bash scripts/analyze-migration.sh <project-root-directory>
```

Present a before/after comparison summary showing:
- Java version: 17 -> 21
- Spring Boot version: old -> new
- javax imports remaining: should be 0
- synchronized blocks: should be replaced or acknowledged
- New features adopted: list

## Important Notes

- This skill handles ONLY Java 17 to 21 migration for Spring Boot projects
- NEVER make changes without explaining them first and getting user confirmation for each phase
- ALWAYS maintain a working build between phases -- commit stable checkpoints
- For Path A (2.x to 3.x): the javax-to-jakarta migration is the most pervasive change and should be done systematically, not piecemeal
- Virtual threads are NOT a replacement for reactive programming -- they solve different problems
- String Templates are preview in Java 21 -- mention but do NOT recommend for production code
- Some preview features (structured concurrency, scoped values) require `--enable-preview` flag
- Always check third-party library compatibility with Java 21 before upgrading
- Consider using OpenRewrite recipes for automated javax-to-jakarta migration

## Examples

Example 1: Spring Boot 2.7 + Java 17 project
User says: "I need to migrate my Spring Boot app to Java 21"
Actions:
1. Run analyze-migration.sh, detect Spring Boot 2.7, Java 17
2. Identify Path A (full migration needed)
3. Phase 1: Upgrade to latest 2.7.x, fix deprecations
4. Phase 2: Migrate to Spring Boot 3.2+ (javax->jakarta, Security, Hibernate)
5. Phase 3: Update build to Java 21, fix issues
6. Phase 4: Adopt virtual threads, pattern matching, ZGC
Note: This is a significant migration -- suggest phasing over multiple PRs

Example 2: Spring Boot 3.1 + Java 17 project
User says: "Help me upgrade to Java 21 and use virtual threads"
Actions:
1. Run analyze-migration.sh, detect Spring Boot 3.1, Java 17
2. Identify Path B (Java upgrade only)
3. Recommend upgrading Spring Boot to 3.2+ first (virtual thread support)
4. Update build to Java 21
5. Audit synchronized blocks, replace with ReentrantLock
6. Enable `spring.threads.virtual.enabled=true`
7. Adopt language features (pattern matching, records)

Example 3: Spring Boot 3.3 + Java 17 reactive project
User says: "Modernize my WebFlux project for Java 21"
Actions:
1. Run analyze-migration.sh, detect Spring Boot 3.3, Java 17, reactive model
2. Identify Path B
3. Update build to Java 21
4. Adopt language features (pattern matching, sequenced collections)
5. Enable virtual threads with caveat: less impactful for reactive but helps blocking calls
6. Enable Generational ZGC, CDS for startup improvement
7. Review ThreadLocal usage in reactive context

## Troubleshooting

Error: Script cannot detect Spring Boot version
Cause: Version defined in parent POM or BOM not in main build file
Solution: Ask user for their Spring Boot version or run `./mvnw dependency:tree | grep spring-boot`

Error: javax imports remain after migration
Cause: Some libraries bundle javax.* classes internally
Solution: These are transitive -- check if library has a jakarta-compatible version. Use `mvn dependency:tree` to trace the source.

Error: Tests fail after Spring Boot 3.x migration
Cause: Many possible causes -- most common are namespace changes, Security API changes, Hibernate ID generation
Solution: Consult `references/spring-boot-2x-to-3x.md` troubleshooting section for pattern-specific fixes

Error: Application hangs after enabling virtual threads
Cause: Virtual thread pinning due to synchronized blocks
Solution: Find synchronized blocks with `-Djdk.tracePinnedThreads=short` and replace with ReentrantLock. Consult `references/java21-concurrency.md`.

Error: Build fails on Java 21 with "illegal reflective access"
Cause: Libraries using internal JDK APIs that are now strongly encapsulated
Solution: Update the offending library. If no update exists, add `--add-opens` flags as a temporary workaround. Consult `references/common-pitfalls.md`.

Error: Cannot determine Java version
Cause: Not specified in build file and JAVA_HOME not set
Solution: Ask user for their Java version or check `java -version` output
