# Java 21 Concurrency Features Reference

## Virtual Threads (JEP 444) -- Finalized

### What Are Virtual Threads?

Virtual threads are lightweight threads managed by the JVM rather than the OS. They allow you to write blocking I/O code while achieving the scalability of asynchronous code.

- **Platform threads**: 1:1 mapping with OS threads. ~1MB stack each. Limited to ~thousands.
- **Virtual threads**: Many-to-few mapping onto carrier (platform) threads. ~few KB stack each. Can create millions.

### When Virtual Threads Help

- I/O-bound applications (REST APIs, database queries, external service calls)
- Applications with high request concurrency
- Workloads where threads spend most time waiting (network, disk, DB)

### When Virtual Threads Do NOT Help

- CPU-bound computation (use parallel streams or platform threads)
- Already-reactive applications (WebFlux is already non-blocking)
- Applications with very few concurrent requests

### Spring Boot 3.2+ Integration

Enable with one property:
```properties
# application.properties
spring.threads.virtual.enabled=true
```

This configures:
- Tomcat/Jetty to use virtual threads for HTTP request processing
- `@Async` methods to run on virtual threads
- Spring MVC async request handling
- `TaskExecutor` beans to use virtual threads
- `ScheduledTaskExecutor` to use virtual threads

### CRITICAL: Audit Before Enabling

Before enabling virtual threads, you MUST audit and fix two patterns:

#### 1. Replace synchronized with ReentrantLock

`synchronized` blocks **pin** virtual threads to their carrier platform thread, eliminating the concurrency benefit.

Before (pins virtual thread):
```java
public class AccountService {
    private final Object lock = new Object();

    public void transfer(Account from, Account to, BigDecimal amount) {
        synchronized (lock) {
            from.debit(amount);
            to.credit(amount);
        }
    }
}
```

After (virtual-thread-safe):
```java
public class AccountService {
    private final ReentrantLock lock = new ReentrantLock();

    public void transfer(Account from, Account to, BigDecimal amount) {
        lock.lock();
        try {
            from.debit(amount);
            to.credit(amount);
        } finally {
            lock.unlock();
        }
    }
}
```

For `synchronized` methods:
```java
// Before
public synchronized void process() { ... }

// After
private final ReentrantLock lock = new ReentrantLock();
public void process() {
    lock.lock();
    try { ... } finally { lock.unlock(); }
}
```

#### 2. Audit ThreadLocal Usage

ThreadLocal works with virtual threads but has caveats:
- Virtual threads are cheap and numerous -- ThreadLocal instances are NOT pooled
- Each virtual thread gets its own ThreadLocal copy (correct behavior but high memory if millions of threads)
- Thread-pool-based assumptions break (virtual threads are not pooled)

Review ThreadLocal usages:
- **Safe to keep**: Small, lightweight values (request context, user info)
- **Consider migrating**: Large objects, connection caches, expensive-to-create values
- **For new code**: Prefer ScopedValue (preview) over ThreadLocal

### Connection Pool Tuning

With virtual threads, your app may handle significantly more concurrent requests. This can exhaust database connection pools:

```properties
# Before (with platform threads, typically matches thread pool size)
spring.datasource.hikari.maximum-pool-size=10

# After (with virtual threads, may need more connections)
# Start conservative, monitor, and increase as needed
spring.datasource.hikari.maximum-pool-size=20
```

CRITICAL: Increasing pool size without corresponding database capacity will cause issues. Monitor your database connection count after enabling virtual threads.

### Detecting Pinning at Runtime

Add this JVM flag to detect pinning:
```
-Djdk.tracePinnedThreads=short
```

This prints a stack trace whenever a virtual thread is pinned. Use during testing to find remaining issues.

Full output mode (very verbose):
```
-Djdk.tracePinnedThreads=full
```

### Monitoring Virtual Threads

Thread dump showing virtual threads:
```bash
jcmd <pid> Thread.dump_to_file -format=json threads.json
```

JDK Flight Recorder events for virtual threads:
```bash
jcmd <pid> JFR.start name=vt settings=default
```

### Virtual Threads with Reactive (WebFlux)

WebFlux is already non-blocking, so virtual threads are less impactful. However:
- `spring.threads.virtual.enabled=true` still helps with `@Scheduled` tasks
- Can help when using `Schedulers.boundedElastic()` for occasional blocking calls
- Does NOT replace the reactive model -- they serve different purposes

---

## Structured Concurrency (JEP 453) -- Preview in Java 21

**Status**: Preview feature. Requires `--enable-preview` compiler and runtime flag. Do NOT use in production code.

### Concept

Treats multiple concurrent tasks as a single unit of work. If one subtask fails, the others are automatically cancelled.

### API: StructuredTaskScope

```java
// Requires --enable-preview
try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
    Subtask<User> userTask = scope.fork(() -> fetchUser(userId));
    Subtask<Order> orderTask = scope.fork(() -> fetchOrder(orderId));

    scope.join();           // Wait for both
    scope.throwIfFailed();  // Propagate any failure

    User user = userTask.get();
    Order order = orderTask.get();
    return new UserOrder(user, order);
}
```

### Comparison with CompletableFuture

Before (CompletableFuture -- error handling is manual):
```java
CompletableFuture<User> userFuture = CompletableFuture.supplyAsync(() -> fetchUser(userId));
CompletableFuture<Order> orderFuture = CompletableFuture.supplyAsync(() -> fetchOrder(orderId));
CompletableFuture.allOf(userFuture, orderFuture).join();
User user = userFuture.get();
Order order = orderFuture.get();
```

After (Structured Concurrency -- automatic cleanup on failure):
```java
try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
    var userTask = scope.fork(() -> fetchUser(userId));
    var orderTask = scope.fork(() -> fetchOrder(orderId));
    scope.join().throwIfFailed();
    return new UserOrder(userTask.get(), orderTask.get());
}
```

### ShutdownOnSuccess Pattern

Returns the result of the first subtask to succeed:
```java
try (var scope = new StructuredTaskScope.ShutdownOnSuccess<String>()) {
    scope.fork(() -> fetchFromPrimaryCache(key));
    scope.fork(() -> fetchFromSecondaryCache(key));
    scope.join();
    return scope.result();
}
```

---

## Scoped Values (JEP 446) -- Preview in Java 21

**Status**: Preview feature. Requires `--enable-preview`. Do NOT use in production code.

### Concept

Scoped values are immutable, inheritable values available within a bounded scope. They are designed as a better alternative to ThreadLocal for virtual threads.

### API: ScopedValue

```java
// Requires --enable-preview
private static final ScopedValue<UserContext> CURRENT_USER = ScopedValue.newInstance();

public void handleRequest(UserContext user) {
    ScopedValue.where(CURRENT_USER, user).run(() -> {
        processRequest();  // Can access CURRENT_USER.get() anywhere in this scope
    });
}

private void processRequest() {
    UserContext user = CURRENT_USER.get();  // Available within the scope
    // ...
}
```

### Comparison with ThreadLocal

| Feature          | ThreadLocal                     | ScopedValue                      |
|------------------|---------------------------------|----------------------------------|
| Mutability       | Mutable (get/set)               | Immutable within scope           |
| Inheritance      | InheritableThreadLocal          | Automatic with structured scope  |
| Cleanup          | Manual (remove())               | Automatic (scope-based)          |
| Memory           | Can leak if not cleaned up      | Cannot leak                      |
| Virtual threads  | Works but expensive per-thread  | Designed for virtual threads     |
| Thread pooling   | Assumes thread reuse            | No such assumption               |

### When to Migrate from ThreadLocal

- **Migrate now**: If ThreadLocal is only read (never set after initialization), switch is straightforward
- **Migrate later**: If ThreadLocal is mutated within the thread's lifecycle, wait for ScopedValue to exit preview
- **Keep ThreadLocal**: If the library API requires it (e.g., security context, MDC logging)
