# Performance and JVM Reference for Java 21

## Generational ZGC (JEP 439)

### Overview

Generational ZGC is the default garbage collector behavior in Java 21. It adds generational support to ZGC, improving performance by collecting young objects more frequently.

### Key Benefits

- Sub-millisecond pause times (same as non-generational ZGC)
- Better throughput due to generational collection
- Lower memory overhead for short-lived objects
- No application code changes required

### Verifying ZGC is Active

```bash
# Check GC in use
java -XX:+PrintFlagsFinal -version 2>&1 | grep UseZGC

# In running application
jcmd <pid> VM.flags | grep GC
```

### Tuning Options

```bash
# Default -- Generational ZGC (Java 21+)
-XX:+UseZGC

# Explicit generational mode (default in 21, explicit for clarity)
-XX:+UseZGC -XX:+ZGenerational

# Soft max heap -- ZGC tries to stay under this but can exceed if needed
-XX:SoftMaxHeapSize=2g

# Collection interval hint (milliseconds)
-XX:ZCollectionInterval=60

# Uncommit delay -- how long before unused memory is returned to OS
-XX:ZUncommitDelay=300
```

### When to Use ZGC vs G1GC

| Use Case | Recommended GC |
|----------|---------------|
| Low-latency APIs (p99 matters) | ZGC |
| General-purpose microservices | ZGC or G1GC |
| Batch processing / throughput | G1GC |
| Very small heaps (under 256MB) | G1GC or Serial |
| Large heaps (over 4GB) | ZGC |

### Monitoring ZGC

```bash
# GC logs
-Xlog:gc*:file=gc.log:time,uptime,level,tags

# JFR recording
jcmd <pid> JFR.start name=gc settings=default duration=60s filename=gc.jfr
```

---

## CDS / AppCDS

### What is CDS?

Class Data Sharing (CDS) pre-loads and archives class metadata, reducing startup time and memory footprint.

### Default CDS Archive

Java 21 ships with a default CDS archive. Verify it is in use:
```bash
java -Xlog:class+load:file=classload.log -jar myapp.jar
# Check for "shared" entries in classload.log
```

### Application CDS (AppCDS)

For application-specific classes:

```bash
# Step 1: Create a class list during a training run
java -Xshare:off -XX:DumpLoadedClassList=classes.lst -jar myapp.jar

# Step 2: Create the archive
java -Xshare:dump -XX:SharedClassListFile=classes.lst \
     -XX:SharedArchiveFile=app-cds.jsa -jar myapp.jar

# Step 3: Run with the archive
java -XX:SharedArchiveFile=app-cds.jsa -jar myapp.jar
```

### Spring Boot 3.3+ CDS

Spring Boot 3.3+ simplifies this with built-in support (see `references/spring-boot-3x-java21-enhancements.md`).

### Expected Impact

- Startup time reduction: 20-40% typical
- Memory reduction: 10-20% typical (shared across JVM instances)
- No runtime performance impact

---

## JVM Flags for Java 21

### Recommended Flags -- Production

```bash
# Garbage collection
-XX:+UseZGC
-XX:+ZGenerational
-Xms512m
-Xmx2g
-XX:SoftMaxHeapSize=1536m

# Startup optimization
-XX:SharedArchiveFile=app-cds.jsa

# Virtual thread monitoring (optional, for debugging)
# -Djdk.tracePinnedThreads=short

# Useful diagnostics
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/var/log/myapp/
-Xlog:gc*:file=gc.log:time,uptime,level,tags:filecount=5,filesize=10M
```

### Recommended Flags -- Development

```bash
-XX:+UseZGC
-Xms256m
-Xmx1g
-Djdk.tracePinnedThreads=short
-XX:+HeapDumpOnOutOfMemoryError
```

### Flags to REMOVE (Obsolete in Java 21)

| Flag | Reason |
|------|--------|
| `-XX:+UseConcMarkSweepGC` | CMS removed in Java 14 |
| `-XX:+UseParNewGC` | Removed with CMS |
| `-noverify` / `-Xverify:none` | Ignored since Java 13, errors in 21 |
| `-XX:+AggressiveOpts` | Removed |
| `-XX:MaxPermSize` | PermGen removed in Java 8 |
| `-XX:PermSize` | PermGen removed in Java 8 |
| `-XX:+UseBiasedLocking` | Disabled in Java 15, removed in 19 |
| `-XX:BiasedLockingStartupDelay` | Removed with biased locking |
| `-XX:+PrintGCDetails` | Use `-Xlog:gc*` instead |
| `-XX:+PrintGCDateStamps` | Use `-Xlog:gc*` instead |
| `-XX:+PrintGCTimeStamps` | Use `-Xlog:gc*` instead |
| `-Xloggc:file` | Use `-Xlog:gc*:file=path` instead |

### Flags That Changed Behavior

| Flag | Change in Java 21 |
|------|-------------------|
| `-XX:+UseG1GC` | Still works but ZGC is now preferred for low-latency |
| `--illegal-access` | Removed. Strong encapsulation is enforced. Use `--add-opens` instead |
| `-XX:+UseZGC` | Now generational by default (previously non-generational) |

---

## Strong Encapsulation

Java 21 enforces strong encapsulation of JDK internals. Code that accessed internal APIs via reflection will fail.

### Identifying Issues

```bash
# Run with warnings before migration
java --illegal-access=warn -jar myapp.jar

# On Java 21 (strong encapsulation enforced)
# Look for: java.lang.reflect.InaccessibleObjectException
```

### Adding --add-opens as Workaround

```bash
# Common opens needed by frameworks
--add-opens java.base/java.lang=ALL-UNNAMED
--add-opens java.base/java.util=ALL-UNNAMED
--add-opens java.base/java.lang.reflect=ALL-UNNAMED
--add-opens java.base/java.text=ALL-UNNAMED
--add-opens java.desktop/java.awt.font=ALL-UNNAMED
```

IMPORTANT: `--add-opens` is a workaround, not a solution. The correct fix is to update the library that accesses internal APIs.

### Common Libraries Requiring --add-opens

| Library | Minimum Version Without --add-opens |
|---------|-------------------------------------|
| Spring Framework | 6.0+ |
| Hibernate | 6.0+ |
| Jackson | 2.14+ |
| Mockito | 5.0+ |
| ByteBuddy | 1.14+ |

---

## Deprecation of Finalization (JEP 421)

`Object.finalize()` is deprecated for removal. Scan for overrides:

```bash
grep -rn "protected void finalize" src/main/java/ --include="*.java"
```

### Migration

Before:
```java
public class ResourceHolder {
    @Override
    protected void finalize() throws Throwable {
        try { close(); } finally { super.finalize(); }
    }
}
```

After -- use `AutoCloseable` and try-with-resources:
```java
public class ResourceHolder implements AutoCloseable {
    @Override
    public void close() {
        // cleanup logic
    }
}
// Usage
try (var holder = new ResourceHolder()) {
    // use holder
}
```

Or use `Cleaner` for cases where try-with-resources is not possible:
```java
public class ResourceHolder implements AutoCloseable {
    private static final Cleaner CLEANER = Cleaner.create();
    private final Cleaner.Cleanable cleanable;

    public ResourceHolder() {
        cleanable = CLEANER.register(this, () -> { /* cleanup */ });
    }

    @Override
    public void close() {
        cleanable.clean();
    }
}
```

---

## Performance Benchmarking

### Before/After Migration Measurement

Record these metrics before and after migration:

1. **Startup time**: `time java -jar myapp.jar` until "Started in X seconds"
2. **Memory usage**: `jcmd <pid> GC.heap_info`
3. **GC pause times**: `-Xlog:gc*` analysis
4. **Request throughput**: Load test with `wrk`, `ab`, or `k6`
5. **P99 latency**: Application metrics or APM tool

### Quick Load Test for Virtual Threads

```bash
# Install wrk if not present: brew install wrk (macOS)
# Before enabling virtual threads
wrk -t12 -c400 -d30s http://localhost:8080/api/endpoint

# After enabling virtual threads
wrk -t12 -c400 -d30s http://localhost:8080/api/endpoint

# Compare: requests/sec, latency distribution
```

### JFR Recording for Deep Analysis

```bash
# Start recording
jcmd <pid> JFR.start name=migration settings=profile duration=60s

# Dump recording
jcmd <pid> JFR.dump name=migration filename=migration.jfr

# Analyze with JDK Mission Control (jmc) or IntelliJ
```
