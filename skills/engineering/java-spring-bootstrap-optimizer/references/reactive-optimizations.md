# Reactive-Specific Optimizations (WebFlux)

These recommendations apply only to projects using `spring-boot-starter-webflux` (reactive model).
All techniques work with both Spring Boot 2.x and 3.x unless noted otherwise.

## 1. Netty Event Loop Tuning

**Impact: Low on startup, Medium on early request handling | Effort: Low | Risk: Low | Version: All**

Netty is the default and optimal server for WebFlux. Tune event loop threads based on your workload.

```properties
# Default is Runtime.getRuntime().availableProcessors()
# For startup optimization in resource-constrained environments:
reactor.netty.ioWorkerCount=4
```

Or programmatically:
```java
@Bean
public NettyReactiveWebServerFactory nettyFactory() {
    NettyReactiveWebServerFactory factory = new NettyReactiveWebServerFactory();
    factory.addServerCustomizers(httpServer ->
        httpServer.runOn(LoopResources.create("custom", 4, true))
    );
    return factory;
}
```

### Trade-off
Fewer event loop threads means lower startup overhead but reduced parallelism for I/O. Only reduce in environments where core count is low or startup is the primary concern (e.g., serverless).

## 2. Avoid Blocking Calls

**Impact: N/A on startup, Critical for correctness | Effort: Varies | Risk: High if present | Version: All**

Blocking calls on Netty event loop threads can cause thread starvation during early request handling, making the application appear slow after startup.

### Detection
Enable Reactor's BlockHound in development:
```xml
<dependency>
    <groupId>io.projectreactor.tools</groupId>
    <artifactId>blockhound</artifactId>
    <scope>test</scope>
</dependency>
```

```java
// In test or dev main class
BlockHound.install();
```

### Common blocking offenders at startup
- JDBC calls in `@PostConstruct` or `ApplicationRunner`
- Synchronous HTTP calls during bean initialization
- File I/O during configuration loading

### Solution
Wrap unavoidable blocking calls:
```java
Mono.fromCallable(() -> blockingOperation())
    .subscribeOn(Schedulers.boundedElastic())
```

## 3. R2DBC Instead of JDBC

**Impact: Medium (eliminates synchronous JDBC pool init) | Effort: High | Risk: Medium | Version: Spring Boot 2.3+ (R2DBC support) and 3.x**

JDBC connection pool initialization (HikariCP) is synchronous and can add 1-3 seconds to startup. R2DBC pools initialize asynchronously.

### Maven
```xml
<!-- Remove JDBC starter -->
<!-- <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency> -->

<!-- Add R2DBC -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-r2dbc</artifactId>
</dependency>
<!-- Driver example for PostgreSQL: -->
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>r2dbc-postgresql</artifactId>
</dependency>
```

### Configuration
```properties
spring.r2dbc.url=r2dbc:postgresql://localhost:5432/mydb
spring.r2dbc.username=user
spring.r2dbc.password=pass
```

### Trade-offs
- Significant code rewrite: repositories return `Mono`/`Flux` instead of blocking types
- No JPA/Hibernate with R2DBC (use `ReactiveCrudRepository`)
- Schema migration tools (Flyway/Liquibase) still run synchronously
- Only recommend if the project is fully committed to reactive

## 4. Reactive Cache Implementations

**Impact: Low on startup | Effort: Medium | Risk: Low | Version: All**

If using caching, ensure implementations are reactive-compatible.

### Caffeine (non-blocking for local cache)
```java
@Bean
public CacheManager cacheManager() {
    CaffeineCacheManager manager = new CaffeineCacheManager();
    manager.setCaffeine(Caffeine.newBuilder()
        .maximumSize(1000)
        .expireAfterWrite(Duration.ofMinutes(10)));
    return manager;
}
```

### Redis with Lettuce (reactive)
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis-reactive</artifactId>
</dependency>
```

```java
@Bean
public ReactiveRedisTemplate<String, Object> reactiveRedisTemplate(
        ReactiveRedisConnectionFactory factory) {
    return new ReactiveRedisTemplate<>(factory,
        RedisSerializationContext.fromSerializer(
            new GenericJackson2JsonRedisSerializer()));
}
```

## 5. WebFlux-Specific Auto-Configuration Exclusions

**Impact: Low-Medium | Effort: Low | Risk: Low | Version: All**

Common auto-configurations to exclude in reactive projects that may have been pulled in transitively:

```java
@SpringBootApplication(exclude = {
    // Servlet-based auto-configs that may be pulled transitively
    WebMvcAutoConfiguration.class,
    SecurityFilterAutoConfiguration.class,
    // JDBC auto-configs if using R2DBC
    DataSourceAutoConfiguration.class,
    HibernateJpaAutoConfiguration.class
})
public class MyReactiveApplication {
    public static void main(String[] args) {
        SpringApplication.run(MyReactiveApplication.class, args);
    }
}
```

Verify with `--debug` flag to see which auto-configurations are being evaluated but not needed.
