---
name: java-dependency-auditor
description: Scans Java Maven/Gradle projects for vulnerable dependencies (CVEs), outdated or end-of-life libraries, unused dependencies, license compliance issues, and duplicate libraries. Provides prioritized upgrade recommendations with safe migration paths. Use when user asks to "audit dependencies", "check for vulnerabilities", "find outdated libraries", "scan for CVEs", "dependency security check", "license compliance", "clean up dependencies", or "update dependencies". Do NOT use for adding new dependencies, general Java development, or build troubleshooting.
allowed-tools: "Bash(bash:*)"
compatibility: Requires bash shell. Intended for Java projects using Maven or Gradle.
license: MIT
metadata:
  author: claudioeduardodeoliveira
  version: 1.0.0
  category: java-security
  tags: [java, dependencies, security, cve, maven, gradle, license, audit]
---

# Java Dependency Auditor

## Instructions

### Step 1: Analyze the Project

Run the audit script to detect the current dependency state:

```bash
bash scripts/audit-dependencies.sh <project-root-directory>
```

The script detects:
- **Build tool**: Maven or Gradle
- **Dependency count**: By scope (compile, test, runtime, provided)
- **Vulnerability scanning**: Whether OWASP Dependency-Check, Snyk, or Trivy is configured
- **Version pinning**: SNAPSHOT deps, version ranges, dynamic versions
- **Outdated/EOL libraries**: JUnit 4, javax APIs, Log4j 1.x, Springfox, old Commons, etc.
- **License compliance**: Project license, license audit plugin presence
- **Build hygiene**: BOM usage, enforcer plugin, version catalogs, dependency locking
- **Duplicate libraries**: Overlapping JSON, logging, HTTP client, mocking, or testing libraries

If the script cannot be run, perform detection manually:
1. Check `pom.xml` or `build.gradle` for dependency list
2. Look for OWASP/Snyk/Trivy configuration
3. Search for known outdated artifacts: `grep -n "junit:junit\|springfox\|log4j.*1\.\|javax\." pom.xml`

### Step 2: Present Findings

Present findings organized by severity:

```
## Dependency Audit Results

| Category                   | Status          |
|----------------------------|-----------------|
| Build Tool                 | Maven / Gradle  |
| Total Dependencies         | N               |
| Vulnerability Scanner      | configured / MISSING |
| Outdated/EOL Libraries     | N found         |
| Potential Duplicates       | N found         |
| License Compliance         | configured / not configured |

### Critical (Fix Immediately)
- [CVE vulnerabilities, EOL libraries with known exploits]

### High Priority (Fix Soon)
- [Outdated libraries with security implications, missing vulnerability scanner]

### Medium Priority (Plan for Next Sprint)
- [EOL libraries, major version upgrades available, duplicate libraries]

### Low Priority (Nice to Have)
- [Minor version updates, build hygiene improvements, license plugin setup]
```

### Step 3: Run Deep Analysis

Based on the initial scan, perform deeper analysis in priority order:

**3a. Vulnerability Scan**

If OWASP Dependency-Check is configured:
```bash
# Maven
./mvnw dependency-check:check

# Gradle
./gradlew dependencyCheckAnalyze
```

If NOT configured, consult `references/vulnerability-scanning.md` to set it up, then run.

Review the generated report (usually `target/dependency-check-report.html`) and extract:
- CVE IDs and CVSS scores
- Affected libraries and versions
- Available fix versions

**3b. Outdated Dependency Check**

For Maven:
```bash
./mvnw versions:display-dependency-updates
```

For Gradle:
```bash
# If using the versions plugin
./gradlew dependencyUpdates
```

Consult `references/safe-upgrade-guide.md` for guidance on which updates are safe.

**3c. Unused Dependency Detection**

For Maven:
```bash
./mvnw dependency:analyze
```

This reports:
- **Used undeclared**: Dependencies your code uses but are only available transitively (fragile -- add them explicitly)
- **Unused declared**: Dependencies declared but not used by your code (candidates for removal)

CRITICAL: `dependency:analyze` uses bytecode analysis and can have false positives. ALWAYS verify before removing:
1. Check if the dependency is used via reflection (e.g., JDBC drivers, SPI providers)
2. Check if it is required at runtime but not compile time (logging implementations, Spring starters)
3. Check if it provides annotation processors needed at build time
4. Run full test suite after removing any dependency

**3d. License Audit**

Consult `references/license-compliance.md` for setting up license scanning.

For Maven:
```bash
./mvnw license:third-party-report
```

Review for:
- GPL/AGPL licenses in commercial projects (copyleft risk)
- Unknown/missing licenses
- License compatibility with project license

### Step 4: Provide Prioritized Recommendations

Organize recommendations into tiers:

**Tier 1 -- Critical Security Fixes** (do immediately):
- CVEs with CVSS score >= 7.0 (High/Critical)
- Libraries with known active exploits
- EOL libraries with unpatched vulnerabilities (Log4j 1.x, Commons Collections 3.x)

For each critical fix:
1. Show the CVE ID and CVSS score
2. Identify the vulnerable dependency and current version
3. Provide the exact upgrade version that fixes the CVE
4. Check for breaking changes in the upgrade path (consult `references/safe-upgrade-guide.md`)
5. If a direct upgrade is not possible, provide a workaround or mitigation

**Tier 2 -- High Priority Upgrades** (plan this sprint):
- CVEs with CVSS score 4.0-6.9 (Medium)
- Major version upgrades for key libraries (Spring, Hibernate, Jackson)
- Setting up vulnerability scanning if missing
- Adding explicit declarations for used-but-undeclared dependencies

For each upgrade:
1. Show current version and target version
2. List any breaking changes or migration steps needed
3. Note if the upgrade has a migration guide (link to `references/safe-upgrade-guide.md`)

**Tier 3 -- Cleanup and Hygiene** (plan for next sprint):
- Removing unused dependencies
- Removing duplicate libraries (pick one JSON lib, one HTTP client, etc.)
- Migrating from EOL to modern alternatives (JUnit 4 -> 5, javax -> jakarta)
- Setting up license compliance scanning
- Enabling dependency locking (Gradle) or versions-maven-plugin (Maven)
- Configuring Maven Enforcer plugin for dependency convergence

For each cleanup:
1. Explain what to change and why
2. Show the exact POM/build.gradle modification
3. Run tests after each removal

**Tier 4 -- Build Hardening** (ongoing):
- Setting up CI/CD vulnerability scanning pipeline
- Configuring CVSS threshold to fail builds
- Automating dependency update PRs (Dependabot, Renovate)
- Setting up SBOM generation

Consult `references/ci-cd-integration.md` for detailed setup instructions.

### Step 5: Implement Chosen Fixes

Ask the user which tier or specific items they want to address. Then:

1. Make changes one at a time, starting with the highest severity
2. Run the full test suite after each change
3. For major version upgrades:
   - Read the library's changelog/migration guide first
   - Make the version change
   - Fix any compilation errors
   - Run tests and fix failures
   - Commit as a checkpoint
4. After all changes, re-run the audit script to verify improvements

Present a before/after summary:
```
| Metric                     | Before | After |
|----------------------------|--------|-------|
| Critical CVEs              | N      | 0     |
| High CVEs                  | N      | 0     |
| Outdated Libraries         | N      | N     |
| Unused Dependencies        | N      | 0     |
| Duplicate Libraries        | N      | 0     |
```

## Important Notes

- NEVER remove a dependency without verifying it is truly unused (bytecode analysis has false positives)
- ALWAYS run the full test suite after each dependency change
- For major version upgrades, check the library's migration guide first
- JDBC drivers, SPI providers, and Spring starters may appear "unused" but are required at runtime
- When upgrading Spring Boot managed dependencies, prefer upgrading Spring Boot itself to get coordinated versions
- Dependency convergence issues (different versions of the same transitive dependency) can cause subtle runtime bugs
- SBOM (Software Bill of Materials) generation is increasingly required for compliance

## Examples

Example 1: Spring Boot project with no vulnerability scanning
User says: "Audit my project dependencies for security issues"
Actions:
1. Run audit-dependencies.sh, detect Maven, Spring Boot 3.1, no OWASP plugin
2. Flag missing vulnerability scanner as HIGH priority
3. Set up OWASP Dependency-Check plugin
4. Run initial scan, find 3 critical CVEs in transitive dependencies
5. Upgrade affected libraries, run tests
6. Configure CI pipeline to fail on CVSS >= 7.0

Example 2: Project with known outdated libraries
User says: "Help me clean up my dependencies"
Actions:
1. Run audit-dependencies.sh, detect Gradle, Spring Boot 2.7
2. Find: JUnit 4, Springfox, javax.* APIs, Commons Lang 2, duplicate JSON libs
3. Tier 1: No critical CVEs
4. Tier 2: Migrate JUnit 4 -> 5, Springfox -> springdoc-openapi
5. Tier 3: Remove duplicate Gson (keep Jackson), upgrade Commons Lang 2 -> 3
6. Suggest java17-2-21-migration skill for javax -> jakarta migration

Example 3: Enterprise project needing compliance audit
User says: "We need to check our dependency licenses before release"
Actions:
1. Run audit-dependencies.sh, detect Maven, no license plugin
2. Set up license-maven-plugin
3. Run license:third-party-report
4. Flag 2 GPL dependencies in commercial project
5. Find alternatives or isolate GPL components
6. Set up CI check to block new GPL dependencies

## Troubleshooting

Error: OWASP Dependency-Check is very slow
Cause: NVD API rate limiting without API key
Solution: Obtain a free NVD API key from https://nvd.nist.gov/developers/request-an-api-key and configure it. Consult `references/vulnerability-scanning.md`.

Error: dependency:analyze reports false positives
Cause: Runtime-only dependencies (JDBC drivers, logging implementations) appear unused
Solution: Use `<ignoredUnusedDeclaredDependencies>` configuration to suppress known false positives. Verify each before suppressing.

Error: Version upgrade breaks compilation
Cause: Breaking API changes in major version upgrade
Solution: Check the library's migration guide. Consult `references/safe-upgrade-guide.md` for common upgrade paths.

Error: Dependency convergence failure
Cause: Different modules pull different versions of the same transitive dependency
Solution: Use `<dependencyManagement>` (Maven) or `resolutionStrategy` (Gradle) to force a single version. Consult `references/safe-upgrade-guide.md`.
