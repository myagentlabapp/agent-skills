# JVM Tuning for Spring Boot Startup

## 1. Tiered Compilation

**Impact: Medium (20-30% faster startup) | Effort: Very Low | Risk: Low | Version: All**

```
-XX:TieredStopAtLevel=1
```

Stops JIT compilation at C1 (client compiler) level. The JVM starts faster because it skips C2 (server compiler) optimizations.

### Trade-off
- Peak runtime throughput will be lower (C2 produces more optimized code)
- Suitable for: development, testing, short-lived processes, serverless
- NOT recommended for: long-running production services where throughput matters

### Application
In Dockerfile:
```dockerfile
ENTRYPOINT ["java", "-XX:TieredStopAtLevel=1", "-jar", "app.jar"]
```

As environment variable:
```bash
JAVA_OPTS="-XX:TieredStopAtLevel=1"
java $JAVA_OPTS -jar app.jar
```

## 2. -noverify Flag (Spring Boot 2.x / Java 8-16 ONLY)

**Impact: Low-Medium | Effort: Very Low | Risk: Low | Version: Java 8-16 only**

Skips bytecode verification at class loading.

```
-noverify
```

IMPORTANT:
- This flag is **removed in Java 17+** (JEP 396). It is silently ignored or may produce a warning.
- Do NOT recommend for projects using Java 17 or later.
- Safe to use with Spring Boot 2.x projects on Java 8, 11, or 16.

```bash
# Spring Boot 2.x with Java 11
java -noverify -XX:TieredStopAtLevel=1 -jar myapp.jar
```

## 3. Garbage Collector Selection

**Impact: Low-Medium | Effort: Very Low | Risk: Very Low | Version: All**

| Scenario | Recommended GC | Flags |
|----------|---------------|-------|
| Startup-critical, small heap (<512MB) | Serial | `-XX:+UseSerialGC` |
| Startup-critical, medium heap | Parallel | `-XX:+UseParallelGC` |
| Balanced (startup + throughput) | G1 (default since Java 9) | (no flag needed) |
| Low latency, large heap | ZGC (Java 15+) | `-XX:+UseZGC` |

For startup-focused use cases:
```
-XX:+UseParallelGC
```

ParallelGC has better startup characteristics than G1GC.

For serverless / very small containers:
```
-XX:+UseSerialGC
```

SerialGC has the least overhead for small-heap applications.

## 4. Manual AppCDS (Spring Boot 2.x)

**Impact: Medium-High (15-30% startup reduction) | Effort: Medium | Risk: Low | Version: Java 10+ with any Spring Boot version**

For Spring Boot 2.x projects that cannot use the Spring Boot 3.3+ CDS support, manual AppCDS is available.

### Step 1: Generate class list (training run)
```bash
java -Xshare:off -XX:DumpLoadedClassList=classes.lst -jar myapp.jar
# Let the app start fully, then stop it (Ctrl+C)
```

### Step 2: Create the shared archive
```bash
java -Xshare:dump -XX:SharedClassListFile=classes.lst \
     -XX:SharedArchiveFile=application.jsa \
     -cp myapp.jar
```

### Step 3: Run with the archive
```bash
java -Xshare:on -XX:SharedArchiveFile=application.jsa -jar myapp.jar
```

### Trade-offs
- Archive must be regenerated when dependencies change
- Training run must exercise the same classpath as production
- Archive is platform-specific (not portable across OS/architecture)
- More manual than Spring Boot 3.3+ CDS support

## 5. CDS with Spring Boot Support (3.3+) / AOT Cache (Java 24+)

**Impact: High (20-40% startup reduction) | Effort: Medium | Risk: Low | Version: Spring Boot 3.3+ or Java 24+**

### Spring Boot 3.3+ CDS

#### Create the archive (training run)
```bash
java -Dspring.context.exit=onRefresh \
     -XX:ArchiveClassesAtExit=application.jsa \
     -jar myapp.jar
```

This starts the application, lets Spring initialize the context (non-lazy beans), then exits and writes the archive.

#### Run with the archive
```bash
java -XX:SharedArchiveFile=application.jsa -jar myapp.jar
```

### Java 24+ AOT Cache (JEP 483)

Supersedes AppCDS with a more comprehensive approach that caches JIT-compiled code:

```bash
# Training run
java -XX:AOTMode=record -XX:AOTConfiguration=app.aotconf -jar myapp.jar

# Production run
java -XX:AOTMode=load -XX:AOTConfiguration=app.aotconf -jar myapp.jar
```

### Docker integration (Spring Boot 3.3+ CDS)
```dockerfile
FROM eclipse-temurin:21-jre AS builder
WORKDIR /app
COPY target/myapp.jar app.jar
# Training run to generate archive
RUN java -Dspring.context.exit=onRefresh \
    -XX:ArchiveClassesAtExit=application.jsa \
    -jar app.jar || true

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=builder /app/app.jar .
COPY --from=builder /app/application.jsa .
ENTRYPOINT ["java", "-XX:SharedArchiveFile=application.jsa", "-jar", "app.jar"]
```

## 6. Memory Settings for Startup

**Impact: Low-Medium | Effort: Very Low | Risk: Low | Version: All**

Setting initial heap size equal to max avoids heap resizing during startup:
```
-Xms512m -Xmx512m
```

For container environments, let the JVM detect container limits:
```
-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=75.0
```

Reduce thread stack size for applications with many threads:
```
-Xss256k
```

## 7. Combined JVM Flag Profiles

### Spring Boot 2.x + Java 8/11 (Development)
```
-noverify -XX:TieredStopAtLevel=1 -XX:+UseParallelGC -Xss256k
```

### Spring Boot 2.x + Java 11 (Production with manual AppCDS)
```
-XX:SharedArchiveFile=application.jsa -Xms512m -Xmx512m
```

### Spring Boot 3.x + Java 17 (Development)
```
-XX:TieredStopAtLevel=1 -XX:+UseParallelGC -Xss256k
```

### Spring Boot 3.x + Java 17 (Production)
```
-Xms512m -Xmx512m
```

### Spring Boot 3.x + Java 21+ (Production with CDS + AOT)
```
-XX:SharedArchiveFile=application.jsa -Dspring.aot.enabled=true -Xms512m -Xmx512m
```

### Serverless / Container Cold Start (any version)
```
-XX:TieredStopAtLevel=1 -XX:+UseSerialGC -Xss256k -XX:SharedArchiveFile=application.jsa
```

## 8. Measuring JVM Startup Impact

### Enable JVM timing logs
```
-Xlog:class+load:file=classload.log
-Xlog:gc:file=gc.log
```

Note: `-Xlog` syntax requires Java 9+. For Java 8, use:
```
-XX:+TraceClassLoading -verbose:gc
```

### Quick startup measurement
```bash
time java -jar myapp.jar &
# Wait for "Started" log line, then kill
```

### Comparing configurations
Run startup 3-5 times with each configuration and average the results. Use the Spring Boot Startup Actuator for application-level timing and JVM flags for JVM-level timing.
