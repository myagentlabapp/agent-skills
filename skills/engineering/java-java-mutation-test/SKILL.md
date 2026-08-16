---
name: java-mutation-test
description: Analyzes Java 21 Maven/Gradle projects and guides adoption of mutation testing with PITest. Configures PITest plugin with JUnit 5, selects mutation operators, optimizes performance with incremental analysis and threading, and integrates with CI/CD pipelines. Use when user asks to "set up mutation testing", "add PITest", "mutation testing too slow", "improve PITest configuration", "add mutation testing to CI", "mutation testing for PRs", "analyze surviving mutants", or "improve test quality with mutation testing". Do NOT use for non-Java projects, writing business logic tests, or code coverage without mutation testing.
allowed-tools: "Bash(bash:*)"
compatibility: Requires bash shell. Intended for Java 21 projects using Maven or Gradle with JUnit 5.
license: MIT
metadata:
  author: claudioeduardodeoliveira
  version: 1.0.0
  category: java-testing
  tags: [java-21, mutation-testing, pitest, junit5, test-quality]
---

# Java Mutation Testing Adoption Guide

## Instructions

### Step 1: Analyze the Project

Run the analysis script to detect the current project state:

```bash
bash scripts/analyze-mutation-testing.sh <project-root-directory>
```

The script detects:
- **Build tool**: Maven or Gradle
- **Java version**: From build config or JAVA_HOME (warns if not 21)
- **JUnit version**: JUnit 4, JUnit 5, or TestNG
- **Existing PITest configuration**: Plugin presence, version, mutator group, threads, timeoutConstant, history settings, exclusions, thresholds, output formats
- **pitest-junit5-plugin**: Presence and version
- **pitest-git-plugin**: Presence (Arcmutate change-based analysis)
- **Test count and structure**: Unit tests (`*Test.java`) vs integration tests (`*IT.java`, `*IntegrationTest.java`)
- **Spring Boot test annotations**: `@SpringBootTest`, `@DataJpaTest`, etc.
- **Code coverage tools**: JaCoCo plugin presence
- **Generated code markers**: Lombok, MapStruct, Protobuf
- **Build wrapper**: mvnw/gradlew presence

If the script cannot be run, perform detection manually:
1. Check `pom.xml` or `build.gradle` for `pitest-maven` or `gradle-pitest-plugin`
2. Check test directories for JUnit imports: `grep -r "import org.junit.jupiter" src/test/`
3. Count test files: `find src/test -name "*Test.java" | wc -l`
4. Check for integration tests: `find src/test -name "*IT.java" -o -name "*IntegrationTest.java" | wc -l`

### Step 2: Present Findings

Present findings organized as a summary table:

```
## Mutation Testing Analysis

| Property                    | Value                    |
|-----------------------------|--------------------------|
| Build Tool                  | Maven / Gradle           |
| Java Version                | 21                       |
| JUnit Version               | 5.x / 4.x               |
| Spring Boot Version         | X.Y.Z / not detected     |
| PITest Plugin               | configured vX.Y.Z / NOT CONFIGURED |
| pitest-junit5-plugin        | configured / MISSING     |
| Mutator Group               | STRONGER / DEFAULTS / custom |
| Threads                     | N                        |
| History Enabled             | yes / no                 |
| Timeout Constant            | N ms                     |
| Test Files (Unit)           | N                        |
| Test Files (Integration)    | N                        |
| JaCoCo Configured           | yes / no                 |
| Generated Code (Lombok etc) | detected / none          |

### Already Configured
- [list any existing PITest settings detected]

### Potential Issues
- [JUnit 4 without JUnit 5 migration]
- [missing pitest-junit5-plugin]
- [outdated PITest version]
- [no test separation (unit vs integration)]
- [low thread count]
```

### Step 3: Deep Analysis

Based on the initial scan, determine the adoption path:

**Path A (New Setup)** -- PITest not configured:

Consult `references/pitest-setup-guide.md` for complete setup instructions.

1. Add pitest-maven plugin (1.19.1) or gradle-pitest-plugin (1.15.0)
2. Add pitest-junit5-plugin (1.2.3) as a plugin dependency (NOT a project dependency)
3. Configure `STRONGER` mutator group
4. Set threads to CPU core count
5. Configure exclusions for generated code and integration tests
6. Set initial mutation score threshold at 60%
7. Run on a single package first to validate setup
8. Review the HTML report to understand mutation coverage

**Path B (Optimization)** -- PITest configured but suboptimal:

Consult `references/performance-optimization.md` for tuning guidance.

Analyze current configuration for:
- Mutator group appropriateness (DEFAULTS -> STRONGER upgrade)
- Thread count vs available CPU cores
- History file configuration for incremental analysis
- Exclusion completeness (generated code, integration tests, logging)
- Timeout tuning for Spring Boot projects
- PITest version currency (upgrade to 1.19.1 if older)

**Path C (CI/CD Integration)** -- PITest configured but no CI pipeline:

Consult `references/ci-cd-integration.md` for pipeline setup.

Provide tiered CI approach:
- PR workflow: change-based analysis with pitest-git-plugin (runs in seconds)
- Nightly workflow: full analysis with threshold enforcement
- Report artifact upload for team review

CRITICAL: Always confirm the adoption path with the user before proceeding.

### Step 4: Provide Prioritized Recommendations

Organize recommendations into tiers:

**Tier 1 -- Quick Wins** (minimal risk, immediate value):
- Add PITest plugin with JUnit 5 support (pitest-junit5-plugin 1.2.3)
- Configure `STRONGER` mutator group (or `DEFAULTS` for gentler start)
- Exclude generated code (Lombok `*Builder`, MapStruct `*MapperImpl`, config classes `*Config`, `*Configuration`)
- Exclude integration tests from mutation analysis (`*IT`, `*IntegrationTest`)
- Set threads to match available CPU cores
- Set initial mutation score threshold at 60%
- Configure `outputFormats` to include HTML for human-readable reports

For each recommendation:
1. Explain what it does and the expected impact
2. Show the exact Maven/Gradle configuration change
3. Note any prerequisites or trade-offs

**Tier 2 -- Moderate Effort** (significant improvement):
- Enable incremental analysis with `withHistory` (80-90% faster subsequent runs)
- Add pitest-git-plugin for change-based analysis on PRs (Arcmutate)
- Tune timeouts for Spring Boot projects (increase `timeoutConstant` to 8000-15000ms)
- Add `avoidCallsTo` for logging frameworks (SLF4J, Log4j, java.util.logging)
- Add `excludedMethods` for toString, hashCode, equals, getters, setters
- Integrate mutation testing alongside existing JaCoCo coverage

For each recommendation:
1. Explain the performance or quality improvement
2. Show exact configuration for both Maven and Gradle
3. Note if it requires additional dependencies

**Tier 3 -- Advanced** (requires infrastructure/process changes):
- CI/CD pipeline with tiered mutation testing (PR-scoped + nightly full)
- Arcmutate PR comment integration (posts surviving mutants as PR comments)
- Custom mutation operator sets for business-critical modules
- Per-module thresholds (90% for domain logic, 60% for infrastructure)
- Team workflow for reviewing and triaging surviving mutants
- Progressive threshold enforcement schedule

For each recommendation:
1. Explain the organizational benefit
2. Provide complete CI/CD configuration
3. Consult `references/ci-cd-integration.md` for detailed setup

CRITICAL rules for recommendations:
- NEVER recommend `ALL` mutator group in CI -- too slow and generates many equivalent mutants
- NEVER suggest chasing 100% mutation score -- some mutants are equivalent and unkillable
- ALWAYS exclude integration tests from mutation analysis -- they slow execution dramatically
- ALWAYS warn about initial run time on large codebases -- suggest starting with one package

### Step 5: Implement Chosen Optimizations

Ask the user which tier or specific items they want to address. Then:

1. Make changes one at a time, starting with Tier 1
2. After each change, verify by running mutation testing:
   - Maven: `./mvnw test-compile org.pitest:pitest-maven:mutationCoverage`
   - Gradle: `./gradlew pitest`
3. For first-time setup, scope the initial run to a single package:
   - Maven: add `-DtargetClasses="com.example.domain.*"` to the command
   - Gradle: configure `targetClasses` in the `pitest` block
4. Review the HTML report (usually at `target/pit-reports/` or `build/reports/pitest/`)
5. If surviving mutants are found, consult `references/surviving-mutants-guide.md` for analysis
6. Commit as a checkpoint after each tier is complete

Present a before/after summary:

```
| Metric                     | Before         | After          |
|----------------------------|----------------|----------------|
| PITest Version             | not configured | 1.19.1         |
| Mutator Group              | N/A            | STRONGER       |
| Threads                    | N/A            | 8              |
| History Enabled            | N/A            | yes            |
| Mutation Score             | N/A            | 72%            |
| Surviving Mutants          | N/A            | 28             |
| Execution Time             | N/A            | 45s            |
```

## Important Notes

- This skill helps adopt and optimize mutation testing, NOT write the underlying tests
- Mutation testing is computationally expensive -- always start with a subset of classes
- NEVER include integration tests (`*IT.java`, `*IntegrationTest.java`, `@SpringBootTest`) in mutation testing scope
- PITest requires compilable code with ALL tests passing before running mutations
- Java 21 record-generated bytecode (constructors, accessors, equals/hashCode/toString) is automatically filtered by PITest 1.19.1+
- For Spring Boot projects, increase `timeoutConstant` to 8000-15000ms due to context initialization time
- Surviving mutants are NOT bugs in your code -- they indicate gaps in test assertions
- Running mutation testing on the full codebase of a large project for the first time can take hours
- Recommend `STRONGER` group as default; use `DEFAULTS` for first-time adopters wanting a gentler start
- The pitest-junit5-plugin MUST be added as a dependency of the pitest-maven plugin, NOT as a project dependency

## Examples

Example 1: Spring Boot 3.2 + Java 21 project with no mutation testing
User says: "Help me set up mutation testing for my Java project"
Actions:
1. Run analyze-mutation-testing.sh, detect Maven, Spring Boot 3.2, Java 21, JUnit 5, no PITest
2. Identify Path A (new setup needed)
3. Tier 1: Add pitest-maven 1.19.1 + pitest-junit5-plugin 1.2.3, configure STRONGER mutators, 4 threads, exclude `*Config.java` and `*IT.java`, set 60% threshold
4. Run on domain package first: `./mvnw test-compile org.pitest:pitest-maven:mutationCoverage -DtargetClasses="com.example.domain.*"`
5. Review HTML report, identify 15 surviving mutants
6. Tier 2: Enable withHistory, increase timeoutConstant to 10000ms for Spring Boot, add avoidCallsTo for SLF4J
7. Suggest CI setup as next step

Example 2: Gradle project with existing PITest but slow performance
User says: "My mutation tests take too long"
Actions:
1. Run analyze-mutation-testing.sh, detect Gradle, Java 21, PITest 1.15.0, DEFAULTS group, 1 thread, no history
2. Identify Path B (optimization needed)
3. Upgrade PITest to 1.19.1 (performance improvements + Java 21 support)
4. Switch from DEFAULTS to STRONGER (better mutant detection, not significantly slower)
5. Increase threads from 1 to 8 (match CPU cores)
6. Enable withHistory for incremental analysis
7. Add pitest-git-plugin for change-based analysis on PRs
8. Add exclusions for generated code (Lombok builders, MapStruct mappers)
9. Expected improvement: 70-80% reduction in execution time

Example 3: Maven project wanting CI/CD integration
User says: "Add mutation testing to our CI pipeline"
Actions:
1. Run analyze-mutation-testing.sh, detect Maven, PITest 1.19.1 configured, STRONGER, no CI pipeline
2. Identify Path C (CI/CD integration needed)
3. Create GitHub Actions PR workflow with pitest-git-plugin (change-based, ~15 seconds per PR)
4. Create GitHub Actions nightly workflow (full analysis, 80% threshold, fail on regression)
5. Configure report artifact upload for team review
6. Set failWhenNoMutations=false for PR workflow (not all PRs touch testable code)
7. Suggest Arcmutate PR comments for inline feedback (optional, commercial)

## Troubleshooting

Error: "No mutations found" or empty report
Cause: Exclusion patterns too broad, targetClasses does not match any classes, or no test classes found matching the naming convention
Solution: Review `excludedClasses` and `targetClasses` patterns. Ensure test classes follow `*Test.java` naming. Verify with: `./mvnw test-compile org.pitest:pitest-maven:mutationCoverage -DtargetClasses="com.example.*" -DverboseLogging=true`

Error: PITest execution takes more than 30 minutes
Cause: Running against entire codebase with ALL mutators, single thread, no history, integration tests included
Solution: Switch to STRONGER mutator group, increase threads to CPU core count, enable withHistory, exclude integration tests and generated code. Consult `references/performance-optimization.md`.

Error: Tests timeout during mutation testing (many TIMED_OUT mutations)
Cause: Default `timeoutConstant` (4000ms) too low for Spring Boot projects or projects using Testcontainers
Solution: Increase `timeoutConstant` to 8000-15000ms. For projects with Testcontainers, consider excluding those test classes from mutation analysis entirely.

Error: Mutation score is 0% despite having tests
Cause: Tests compile and run but do not actually assert behavior (tests without assertions, tests that only check no exception is thrown)
Solution: Review test quality. Ensure tests contain meaningful assertions (not just `assertNotNull`). Consult `references/surviving-mutants-guide.md` for test improvement patterns.

Error: "Could not find or load main class org.pitest.mutationtest.MutationCoverageReport"
Cause: Missing pitest-junit5-plugin for JUnit 5 projects, or plugin misconfiguration
Solution: Add pitest-junit5-plugin 1.2.3 as a dependency of the pitest-maven plugin (inside the plugin's dependencies section, NOT as a project dependency). Consult `references/pitest-setup-guide.md`.

Error: OutOfMemoryError during mutation testing
Cause: Too many threads consuming JVM memory, or very large codebase analyzed at once
Solution: Reduce thread count, increase JVM heap for surefire/failsafe (`-Xmx` settings), scope analysis to specific packages with `targetClasses`. For multi-module projects, run mutation testing per module.
