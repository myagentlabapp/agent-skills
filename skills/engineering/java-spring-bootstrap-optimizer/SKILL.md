---
name: spring-bootstrap-optimizer
description: Analyzes Spring Boot projects and provides prioritized recommendations to reduce application startup/bootstrap time. Use when a user asks to optimize Spring Boot startup, reduce bootstrap time, speed up Spring Boot application, improve startup performance, slow Spring Boot startup, or reduce cold start time. Detects whether the project uses servlet (Spring MVC) or reactive (WebFlux) model and optimizes within the chosen model without switching it. Supports Spring Boot 2.x and 3.x with Java 8-24+. Do NOT use for general Spring Boot development guidance, runtime throughput tuning, or memory optimization unrelated to startup.
allowed-tools: "Bash(bash:*)"
compatibility: Requires bash shell. Intended for Spring Boot 2.x-3.x projects with Maven or Gradle.
license: MIT
metadata:
  author: claudioeduardodeoliveira
  version: 1.0.0
  category: java-performance
  tags: [spring-boot, startup-optimization, performance, java]
---

# Spring Boot Startup Optimizer

## Instructions

### Step 1: Analyze the Project

Run the analysis script to detect the project setup:

```bash
bash scripts/analyze-project.sh <project-root-directory>
```

The script detects:
- **Model type**: Servlet (Spring MVC) or Reactive (WebFlux)
- **Spring Boot version**: 2.x or 3.x (critical for version-gated recommendations)
- **Java version**: From build config or JAVA_HOME
- **Build tool**: Maven or Gradle
- **Embedded server**: Tomcat, Undertow, Jetty, or Netty
- **Current optimizations already in place**
- **Dependency count and notable starters**

If the script cannot be run, perform detection manually by examining:
- `pom.xml` or `build.gradle` for `spring-boot-starter-web` (servlet) vs `spring-boot-starter-webflux` (reactive)
- `application.properties` or `application.yml` for existing optimization settings
- Java version from build configuration

### Step 2: Present Findings

Present a clear summary:

```
## Project Analysis Results

| Property            | Value                  |
|---------------------|------------------------|
| Model               | Servlet / Reactive     |
| Spring Boot Version | X.Y.Z                  |
| Java Version        | XX                     |
| Build Tool          | Maven / Gradle         |
| Embedded Server     | Tomcat / Netty / etc   |
| Starter Count       | N                      |

### Already Applied Optimizations
- [list any detected optimizations]

### Potential Issues
- [list any detected issues]
```

### Step 3: Provide Prioritized Recommendations

CRITICAL RULES:
- NEVER recommend switching from servlet to reactive or vice versa. Optimize within the detected model only.
- ALWAYS check Spring Boot version before recommending. Do NOT recommend AOT, CDS, or Virtual Threads for Spring Boot 2.x projects.
- Do NOT recommend `-noverify` for Java 17+ (flag is removed/ignored).
- For Spring Boot 2.x projects considering GraalVM, mention Spring Native (experimental) instead of built-in native support.

Load the appropriate reference files based on detection:
- Always consult `references/universal-optimizations.md`
- If servlet detected: also consult `references/servlet-optimizations.md`
- If reactive detected: also consult `references/reactive-optimizations.md`
- For JVM-level tuning: consult `references/jvm-tuning.md`

Organize recommendations into three tiers:

**Tier 1 - Quick Wins** (minimal risk, immediate impact):
- Configuration property changes
- Excluding unused auto-configurations
- Dependency cleanup
- Narrowing `@ComponentScan`
- Disabling unnecessary filters (servlet)

**Tier 2 - Moderate Effort** (some trade-offs, significant impact):
- Spring Context Indexer
- Lazy initialization (global or selective)
- Server swap (servlet only: Tomcat to Undertow)
- HikariCP pool tuning
- JVM flags (`-XX:TieredStopAtLevel=1`, GC selection)
- Virtual Threads (Spring Boot 3.2+ / Java 21+ only)

**Tier 3 - Advanced** (requires build/infrastructure changes):
- AOT processing (Spring Boot 3.0+ only)
- CDS / AppCDS (Spring Boot 3.3+ or manual for 2.x)
- GraalVM Native Image (3.0+ built-in, or Spring Native for 2.x)
- Docker layer optimization with Buildpacks
- Slim JRE with jlink

For each recommendation:
1. Explain what it does and expected impact
2. State prerequisites (Java version, Spring Boot version)
3. Note trade-offs clearly
4. Provide the exact code/config change needed

Skip recommendations that are already applied (detected in Step 1).
Skip recommendations incompatible with the detected Spring Boot or Java version.

### Step 4: Implement Chosen Optimizations

Ask the user which tier or specific recommendations they want to apply. Then:

1. Make the changes one at a time
2. After each change, explain how to verify it worked
3. Suggest using Spring Boot Startup Actuator for before/after measurement:
   - Add `spring-boot-starter-actuator` if not present
   - For Spring Boot 2.4+: set `spring.application.startup=buffering`
   - After startup, call `POST /actuator/startup` to see timing breakdown
   - For Spring Boot 2.0-2.3: use `--debug` flag and compare startup log times

## Important Notes

- This skill optimizes **startup/bootstrap time only**, not runtime throughput or memory
- Never change the project's web model (servlet to reactive or vice versa)
- Always explain trade-offs before applying any optimization
- Some optimizations are version-gated: always check Java and Spring Boot versions
- For GraalVM Native Image, warn about reflection limitations and frozen classpath
- Lazy initialization delays error detection — warn about this trade-off

## Examples

Example 1: Spring MVC project on Java 11 with Spring Boot 2.7
User says: "My Spring Boot 2 app takes 20 seconds to start"
Actions:
1. Run analyze-project.sh on project root
2. Detect: Servlet model, Spring Boot 2.7, Java 11, Tomcat, 15 starters
3. Tier 1: exclude unused auto-configs, dependency cleanup, narrow component scan
4. Tier 2: lazy init, context indexer, switch to Undertow, JVM flags with -noverify
5. Tier 3: manual AppCDS, Spring Native (experimental), Docker optimization
Note: Do NOT recommend AOT, CDS (Spring Boot support), or Virtual Threads — these require 3.x

Example 2: Spring MVC project on Java 17 with Spring Boot 3.2
User says: "Help me optimize my Spring Boot microservice startup"
Actions:
1. Run analyze-project.sh on project root
2. Detect: Servlet model, Spring Boot 3.2, Java 17, Tomcat, 10 starters
3. Tier 1: dependency cleanup, exclude auto-configs, narrow component scan
4. Tier 2: lazy init, context indexer, Undertow swap, JVM tiered compilation
5. Tier 3: AOT processing, manual AppCDS, GraalVM native image
Note: Do NOT recommend -noverify (Java 17), Virtual Threads (needs Java 21), or CDS Spring support (needs 3.3)

Example 3: WebFlux project on Java 21 with Spring Boot 3.3
User says: "Speed up my reactive Spring Boot microservice startup"
Actions:
1. Run analyze-project.sh on project root
2. Detect: Reactive model, Spring Boot 3.3, Java 21, Netty, 8 starters
3. Tier 1: dependency cleanup, exclude auto-configs (especially any servlet auto-configs pulled transitively)
4. Tier 2: lazy init, context indexer, virtual threads, Netty tuning
5. Tier 3: AOT + CDS combo, GraalVM native image, R2DBC if still using JDBC

## Troubleshooting

Error: Script cannot detect model type
Cause: Neither spring-boot-starter-web nor spring-boot-starter-webflux found
Solution: Ask user to confirm which model they use, then proceed manually

Error: Cannot determine Spring Boot version
Cause: Version defined in a parent POM or BOM not in the main build file
Solution: Ask user for their Spring Boot version or check `./mvnw dependency:tree` output

Error: Cannot determine Java version
Cause: Not specified in build file and JAVA_HOME not set
Solution: Ask user for their Java version or check `java -version` output
