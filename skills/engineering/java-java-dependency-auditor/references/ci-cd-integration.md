# CI/CD Integration Reference

## GitHub Actions

### Complete Dependency Audit Workflow

```yaml
name: Dependency Audit

on:
  pull_request:
    paths:
      - 'pom.xml'
      - 'build.gradle*'
      - 'gradle/libs.versions.toml'
  schedule:
    # Run weekly on Monday at 8:00 UTC
    - cron: '0 8 * * 1'
  workflow_dispatch:

jobs:
  vulnerability-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'
          cache: 'maven'

      - name: OWASP Dependency Check
        run: ./mvnw dependency-check:check -DfailBuildOnCVSS=7
        env:
          NVD_API_KEY: ${{ secrets.NVD_API_KEY }}

      - name: Upload OWASP Report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: dependency-check-report
          path: target/dependency-check-report.html

  unused-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'
          cache: 'maven'

      - name: Analyze Dependencies
        run: ./mvnw dependency:analyze -DignoreNonCompile=true

  license-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'
          cache: 'maven'

      - name: License Report
        run: ./mvnw license:third-party-report

      - name: Check for Copyleft
        run: |
          if grep -qiE "GNU General Public|AGPL" target/site/third-party-report.html 2>/dev/null; then
            echo "::warning::Copyleft license detected in dependencies"
          fi
```

### Gradle Version

Replace Maven commands with:
```yaml
      - name: OWASP Dependency Check
        run: ./gradlew dependencyCheckAnalyze

      - name: Dependency Updates
        run: ./gradlew dependencyUpdates
```

---

## GitLab CI

```yaml
stages:
  - audit

dependency-audit:
  stage: audit
  image: eclipse-temurin:21-jdk
  script:
    - ./mvnw dependency-check:check -DfailBuildOnCVSS=7
  artifacts:
    when: always
    paths:
      - target/dependency-check-report.html
    expire_in: 30 days
  rules:
    - changes:
        - pom.xml
    - if: $CI_PIPELINE_SOURCE == "schedule"

license-audit:
  stage: audit
  image: eclipse-temurin:21-jdk
  script:
    - ./mvnw license:third-party-report
  artifacts:
    paths:
      - target/site/third-party-report.html
    expire_in: 30 days
  rules:
    - changes:
        - pom.xml
```

---

## Dependabot Configuration

### Maven

`.github/dependabot.yml`:
```yaml
version: 2
updates:
  - package-ecosystem: "maven"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "automated"
    reviewers:
      - "your-team"
    groups:
      # Group Spring updates together
      spring:
        patterns:
          - "org.springframework*"
        update-types:
          - "minor"
          - "patch"
      # Group test dependency updates
      testing:
        patterns:
          - "org.junit*"
          - "org.mockito*"
          - "org.assertj*"
          - "org.testcontainers*"
        update-types:
          - "minor"
          - "patch"
      # Group Apache Commons
      commons:
        patterns:
          - "org.apache.commons*"
          - "commons-*"
    ignore:
      # Ignore major updates for manual review
      - dependency-name: "org.springframework.boot:*"
        update-types: ["version-update:semver-major"]
```

### Gradle

```yaml
version: 2
updates:
  - package-ecosystem: "gradle"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      spring:
        patterns:
          - "org.springframework*"
```

---

## Renovate Configuration

`renovate.json`:
```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:recommended",
    ":dependencyDashboard"
  ],
  "labels": ["dependencies", "automated"],
  "packageRules": [
    {
      "description": "Auto-merge patch updates for stable libs",
      "matchUpdateTypes": ["patch"],
      "matchPackagePrefixes": [
        "org.springframework",
        "com.fasterxml.jackson"
      ],
      "automerge": true,
      "automergeType": "pr"
    },
    {
      "description": "Group Spring Boot updates",
      "matchPackagePrefixes": ["org.springframework.boot"],
      "groupName": "Spring Boot"
    },
    {
      "description": "Group test dependencies",
      "matchPackagePrefixes": [
        "org.junit",
        "org.mockito",
        "org.assertj",
        "org.testcontainers"
      ],
      "groupName": "Test Dependencies"
    },
    {
      "description": "Block major updates for manual review",
      "matchUpdateTypes": ["major"],
      "dependencyDashboardApproval": true
    }
  ],
  "vulnerabilityAlerts": {
    "enabled": true,
    "labels": ["security"]
  }
}
```

---

## Build Failure Thresholds

### Recommended CVSS Thresholds by Environment

| Environment | Fail Build On | Rationale |
|---|---|---|
| Production services | CVSS >= 7.0 | Block high/critical vulnerabilities |
| Internal tools | CVSS >= 9.0 | Block only critical |
| Libraries you publish | CVSS >= 4.0 | Higher standard for distributed code |
| Development/POC | Warn only | Don't block development velocity |

### Progressive Enforcement

If you have an existing project with many vulnerabilities:

1. **Week 1**: Set threshold to 10.0 (only critical -- fail on nothing initially)
2. **Week 2**: Fix all CVSS 9.0+ and set threshold to 9.0
3. **Month 1**: Fix all CVSS 7.0+ and set threshold to 7.0
4. **Month 2**: Fix all CVSS 4.0+ and set threshold to 4.0 (optional)

This prevents build failures from blocking the team while steadily improving security posture.

---

## Scheduling Best Practices

| Audit Type | Frequency | Trigger |
|---|---|---|
| OWASP Dependency-Check | Weekly (scheduled) + on POM/Gradle changes | Catches new CVEs and new dependency additions |
| Unused dependency analysis | On PRs that modify build files | Catches bloat early |
| License compliance | On PRs that modify build files | Catches license issues before merge |
| Dependabot/Renovate | Weekly auto-PRs | Keeps dependencies current |
| Full audit (manual) | Quarterly | Deep review with team |
