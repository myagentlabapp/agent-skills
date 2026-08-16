# CI/CD Integration for Mutation Testing

## Strategy Overview

Mutation testing in CI/CD should follow a **tiered approach**:

| Tier          | Trigger        | Scope             | Speed      | Enforcement        |
|---------------|----------------|-------------------|------------|-------------------|
| PR Analysis   | Pull request   | Changed code only | Seconds    | Warn / comment     |
| Nightly Full  | Scheduled      | Entire codebase   | Minutes    | Fail on threshold  |

**Never run full mutation testing on every PR** -- it blocks developers and wastes CI resources. Use change-based analysis for PRs and full analysis on a schedule.

## GitHub Actions -- PR Workflow

### Change-Based Analysis with pitest-git-plugin

This workflow runs mutation testing only on code changed in the PR:

```yaml
name: Mutation Testing (PR)

on:
  pull_request:
    branches: [main, develop]
    paths:
      - 'src/main/java/**'
      - 'src/test/java/**'
      - 'pom.xml'

jobs:
  mutation-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout with full history
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Required for git diff

      - name: Set up JDK 21
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'
          cache: 'maven'

      - name: Run mutation testing (changed code only)
        run: |
          ./mvnw test-compile org.pitest:pitest-maven:mutationCoverage \
            -DfailWhenNoMutations=false

      - name: Upload mutation report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: pitest-report-pr
          path: target/pit-reports/
          retention-days: 7
```

### Gradle Equivalent

```yaml
      - name: Set up JDK 21
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'
          cache: 'gradle'

      - name: Run mutation testing (changed code only)
        run: ./gradlew pitest
```

### Key Configuration Notes

- `fetch-depth: 0` is required for pitest-git-plugin to compute the diff
- `failWhenNoMutations=false` prevents build failure when a PR does not touch testable code
- The `paths` filter avoids running mutation testing on documentation-only changes
- Report is uploaded as an artifact for review

## GitHub Actions -- Nightly Full Analysis

### Complete Codebase Analysis with Threshold Enforcement

```yaml
name: Mutation Testing (Nightly)

on:
  schedule:
    - cron: '0 2 * * 1-5'  # Weekdays at 2 AM UTC
  workflow_dispatch:  # Allow manual trigger

jobs:
  mutation-test-full:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up JDK 21
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'
          cache: 'maven'

      - name: Restore PITest history
        uses: actions/cache@v4
        with:
          path: target/pitest-history.bin
          key: pitest-history-${{ github.ref }}-${{ github.sha }}
          restore-keys: |
            pitest-history-${{ github.ref }}-
            pitest-history-

      - name: Run full mutation testing
        run: |
          ./mvnw test-compile org.pitest:pitest-maven:mutationCoverage \
            -DmutationThreshold=80

      - name: Upload mutation report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: pitest-report-nightly
          path: target/pit-reports/
          retention-days: 30

      - name: Save PITest history
        if: always()
        uses: actions/cache/save@v4
        with:
          path: target/pitest-history.bin
          key: pitest-history-${{ github.ref }}-${{ github.sha }}
```

### Key Configuration Notes

- `mutationThreshold=80` fails the build if mutation score drops below 80%
- PITest history file is cached between runs for incremental analysis speedup
- Reports are kept for 30 days for trend analysis
- `workflow_dispatch` allows manual triggering for ad-hoc analysis
- Schedule runs only on weekdays to avoid wasting CI resources

## GitLab CI

### .gitlab-ci.yml Configuration

```yaml
stages:
  - test
  - quality

mutation-test-mr:
  stage: quality
  image: eclipse-temurin:21-jdk
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - src/main/java/**/*
        - src/test/java/**/*
        - pom.xml
  script:
    - ./mvnw test-compile org.pitest:pitest-maven:mutationCoverage
        -DfailWhenNoMutations=false
  artifacts:
    paths:
      - target/pit-reports/
    expire_in: 7 days
  cache:
    key: pitest-history
    paths:
      - target/pitest-history.bin

mutation-test-nightly:
  stage: quality
  image: eclipse-temurin:21-jdk
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
  script:
    - ./mvnw test-compile org.pitest:pitest-maven:mutationCoverage
        -DmutationThreshold=80
  artifacts:
    paths:
      - target/pit-reports/
    expire_in: 30 days
  cache:
    key: pitest-history
    paths:
      - target/pitest-history.bin
```

## Threshold Strategy

### Progressive Enforcement Schedule

Do not enforce strict thresholds from day one. Ramp up gradually:

| Phase                  | Duration   | Threshold | Enforcement           | Goal                              |
|------------------------|------------|-----------|----------------------|-----------------------------------|
| Baseline               | Week 1     | None      | Report only          | Establish current mutation score  |
| Awareness              | Month 1-2  | None      | Nightly report       | Team reviews surviving mutants    |
| Soft enforcement       | Month 3-4  | 60%       | Fail nightly only    | Prevent score regression          |
| Standard enforcement   | Month 5+   | 80%       | Fail nightly, warn PR| Maintain quality bar              |
| Strict enforcement     | Mature     | 80%/90%   | Fail on both         | Domain logic held to higher bar   |

### Per-Module Thresholds (Maven Multi-Module)

For multi-module projects, configure different thresholds per module:

```xml
<!-- In the domain module's pom.xml -->
<plugin>
    <groupId>org.pitest</groupId>
    <artifactId>pitest-maven</artifactId>
    <configuration>
        <mutationThreshold>90</mutationThreshold>
    </configuration>
</plugin>

<!-- In the infrastructure module's pom.xml -->
<plugin>
    <groupId>org.pitest</groupId>
    <artifactId>pitest-maven</artifactId>
    <configuration>
        <mutationThreshold>60</mutationThreshold>
    </configuration>
</plugin>
```

### Recommended Thresholds by Module Type

| Module Type           | Threshold | Rationale                                    |
|-----------------------|-----------|----------------------------------------------|
| Domain / core logic   | 90%       | Business rules must be thoroughly tested      |
| Service layer         | 80%       | Orchestration logic should be well covered    |
| API / controller      | 70%       | Input validation and routing                  |
| Infrastructure        | 60%       | Integration-heavy, harder to unit test        |
| Utilities             | 80%       | Reusable code should be reliable              |

## Arcmutate PR Comments (Optional, Commercial)

Arcmutate provides plugins that post mutation testing results as PR comments, showing which new surviving mutants were introduced by the PR.

### Maven Setup

```xml
<plugin>
    <groupId>org.pitest</groupId>
    <artifactId>pitest-maven</artifactId>
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
        <dependency>
            <groupId>com.arcmutate</groupId>
            <artifactId>pitest-github-plugin</artifactId>
            <version>1.0.1</version>
        </dependency>
    </dependencies>
    <configuration>
        <features>
            <feature>+GIT(from[main])</feature>
            <feature>+GITHUB</feature>
        </features>
    </configuration>
</plugin>
```

### GitHub Actions Step

```yaml
      - name: Run mutation testing with PR comments
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          ./mvnw test-compile org.pitest:pitest-maven:mutationCoverage \
            -DfailWhenNoMutations=false
```

The `GITHUB_TOKEN` is automatically available in GitHub Actions. The plugin uses it to post comments on the PR.

**Note**: Arcmutate plugins are commercial. Free for open-source projects. Check licensing for commercial use.

## Integration with JaCoCo

PITest and JaCoCo serve different purposes and can coexist:

| Tool    | Measures                    | Speed  | Use For                          |
|---------|----------------------------|--------|----------------------------------|
| JaCoCo  | Line and branch coverage    | Fast   | PR gating, basic coverage check  |
| PITest  | Mutation score (test quality)| Slower | Quality insights, nightly analysis|

### Recommended Strategy

1. **JaCoCo on every PR**: Fast, provides basic coverage guarantee
2. **PITest on PRs (change-based)**: Quick check on changed code only
3. **PITest nightly (full)**: Comprehensive mutation analysis

### Maven Configuration for Both

```xml
<!-- JaCoCo for coverage -->
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.12</version>
    <executions>
        <execution>
            <goals><goal>prepare-agent</goal></goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals><goal>report</goal></goals>
        </execution>
    </executions>
</plugin>

<!-- PITest for mutation testing -->
<plugin>
    <groupId>org.pitest</groupId>
    <artifactId>pitest-maven</artifactId>
    <!-- full configuration as in pitest-setup-guide.md -->
</plugin>
```

Do NOT gate PRs on both JaCoCo coverage AND PITest mutation score -- it creates too much friction. Use JaCoCo for gating and PITest for quality insights.
