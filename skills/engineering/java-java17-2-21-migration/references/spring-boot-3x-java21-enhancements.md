# Spring Boot 3.x + Java 21 Enhancements Reference

## Version Compatibility Matrix

| Spring Boot Version | Minimum Java | Virtual Threads | CDS Support | RestClient | Key Features |
|---------------------|-------------|-----------------|-------------|------------|--------------|
| 3.0.x               | Java 17     | No              | No          | No         | Jakarta EE 10, native images |
| 3.1.x               | Java 17     | No              | No          | No         | Docker Compose, Testcontainers |
| 3.2.x               | Java 17     | Yes             | No          | Yes        | Virtual threads, RestClient |
| 3.3.x               | Java 17     | Yes             | Yes         | Yes        | CDS, structured logging |
| 3.4.x               | Java 17     | Yes             | Yes         | Yes        | Latest improvements |

**Recommendation**: Target Spring Boot 3.2+ minimum for Java 21 migration. Target 3.3+ if you want CDS support.

---

## Virtual Threads in Spring Boot 3.2+

### Configuration

```properties
# application.properties
spring.threads.virtual.enabled=true
```

### What This Property Configures

When enabled, the following components use virtual threads:

| Component | Behavior |
|-----------|----------|
| Tomcat | Each HTTP request runs on a virtual thread |
| Jetty | Each HTTP request runs on a virtual thread |
| `@Async` methods | Run on virtual threads (via `SimpleAsyncTaskExecutor`) |
| `@Scheduled` tasks | Run on virtual threads |
| Spring MVC async | Virtual thread pool for async request processing |
| `TaskExecutor` beans | Auto-configured to use virtual threads |
| `ApplicationTaskExecutor` | Uses virtual threads |

### What Is NOT Affected

| Component | Reason |
|-----------|--------|
| Undertow | Does not support virtual threads (as of Spring Boot 3.4) |
| Netty (WebFlux) | Already non-blocking, virtual threads not applicable |
| Custom `ThreadPoolTaskExecutor` | Must be manually updated |
| Third-party thread pools | Not auto-configured |

### Custom Executor with Virtual Threads

If you need a custom executor:
```java
@Bean
public TaskExecutor customExecutor() {
    SimpleAsyncTaskExecutor executor = new SimpleAsyncTaskExecutor();
    executor.setVirtualThreads(true);
    executor.setThreadNamePrefix("custom-vt-");
    return executor;
}
```

---

## RestClient (Spring Boot 3.2+)

RestClient is a new synchronous HTTP client that pairs well with virtual threads. It replaces the need for `WebClient` in blocking scenarios.

### Why RestClient + Virtual Threads

Before (using WebClient for non-blocking):
```java
@Service
public class UserService {
    private final WebClient webClient;

    public Mono<User> getUser(String id) {
        return webClient.get()
            .uri("/users/{id}", id)
            .retrieve()
            .bodyToMono(User.class);
    }
}
```

After (RestClient + virtual threads -- simpler, same scalability):
```java
@Service
public class UserService {
    private final RestClient restClient;

    public User getUser(String id) {
        return restClient.get()
            .uri("/users/{id}", id)
            .retrieve()
            .body(User.class);
    }
}
```

### RestClient Configuration

```java
@Configuration
public class RestClientConfig {
    @Bean
    public RestClient restClient(RestClient.Builder builder) {
        return builder
            .baseUrl("https://api.example.com")
            .defaultHeader("Accept", "application/json")
            .build();
    }
}
```

### Migration from RestTemplate

| RestTemplate | RestClient |
|-------------|-----------|
| `restTemplate.getForObject(url, Type.class)` | `restClient.get().uri(url).retrieve().body(Type.class)` |
| `restTemplate.postForEntity(url, body, Type.class)` | `restClient.post().uri(url).body(body).retrieve().toEntity(Type.class)` |
| `restTemplate.exchange(...)` | Fluent API equivalent |

---

## CDS Support (Spring Boot 3.3+)

Class Data Sharing (CDS) can reduce startup time by 20-40% by pre-loading class metadata.

### Training Run

```bash
# Step 1: Generate the CDS archive during a training run
java -Dspring.context.exit=onRefresh \
     -XX:ArchiveClassesAtExit=application.jsa \
     -jar myapp.jar

# Step 2: Use the archive for fast startup
java -XX:SharedArchiveFile=application.jsa \
     -jar myapp.jar
```

### Docker Integration

```dockerfile
# Stage 1: Training run
FROM eclipse-temurin:21-jre AS training
WORKDIR /app
COPY target/myapp.jar .
RUN java -Dspring.context.exit=onRefresh \
         -XX:ArchiveClassesAtExit=application.jsa \
         -jar myapp.jar

# Stage 2: Production image
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=training /app/myapp.jar .
COPY --from=training /app/application.jsa .
ENTRYPOINT ["java", "-XX:SharedArchiveFile=application.jsa", "-jar", "myapp.jar"]
```

---

## AOT Processing (Spring Boot 3.0+)

Ahead-of-Time processing pre-computes bean definitions and configuration at build time.

### Maven Configuration

```xml
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <executions>
        <execution>
            <id>process-aot</id>
            <goals>
                <goal>process-aot</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

### Limitations

- Reflection-heavy code needs `@RegisterReflectionForBinding`
- Dynamic bean registration must be pre-declared
- Some runtime configuration becomes fixed at build time
- Profiles are frozen at AOT processing time

---

## SSL Bundle Auto-Configuration (Spring Boot 3.1+)

Simplified SSL/TLS configuration:

```properties
spring.ssl.bundle.jks.server.keystore.location=classpath:keystore.p12
spring.ssl.bundle.jks.server.keystore.password=secret
spring.ssl.bundle.jks.server.keystore.type=PKCS12

# Reference in server config
server.ssl.bundle=server
```

---

## Docker Compose Support (Spring Boot 3.1+)

Automatic service discovery from `compose.yaml`:

```properties
spring.docker.compose.enabled=true
spring.docker.compose.lifecycle-management=start-and-stop
```

Spring Boot automatically:
- Starts Docker Compose services before the application
- Configures connection properties (datasource URL, Redis host, etc.)
- Stops services when the application shuts down

---

## Structured Logging (Spring Boot 3.3+)

Native structured logging support without additional dependencies:

```properties
# Output logs as JSON
logging.structured.format.console=ecs
# Or logstash format
logging.structured.format.console=logstash
```
