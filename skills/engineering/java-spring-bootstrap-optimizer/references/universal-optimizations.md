# Universal Spring Boot Startup Optimizations

These techniques apply to both servlet (Spring MVC) and reactive (WebFlux) projects.

## 1. Dependency Cleanup

**Impact: Medium-High | Effort: Low | Risk: Low | Version: All**

Every Spring Boot starter triggers auto-configuration classes. Unused starters add unnecessary bean creation at startup.

### How to identify unused dependencies
1. Review all `spring-boot-starter-*` in your build file
2. For each starter, ask: "Does the application actively use this feature?"
3. Common culprits:
   - `spring-boot-starter-mail` (included but email not used)
   - `spring-boot-starter-cache` (included but no caching configured)
   - `spring-boot-starter-validation` (included but not actively used)
   - `spring-boot-starter-aop` (included transitively but no aspects defined)

### Maven - removing unused dependency
```xml
<!-- Remove if not used -->
<!-- <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-mail</artifactId>
</dependency> -->
```

### Gradle
```groovy
// Remove if not used
// implementation 'org.springframework.boot:spring-boot-starter-mail'
```

## 2. Exclude Unnecessary Auto-Configurations

**Impact: Medium | Effort: Low | Risk: Low | Version: All**

Spring Boot auto-configures many features even when unused. Exclude them explicitly.

### Identify candidates
Use `--debug` flag at startup to see the auto-configuration report. Look for auto-configurations marked as "matched" that you do not use.

### Apply exclusions

Spring Boot 2.x and 3.x:
```java
@SpringBootApplication(exclude = {
    DataSourceAutoConfiguration.class,
    HibernateJpaAutoConfiguration.class,
    MongoAutoConfiguration.class,
    RedisAutoConfiguration.class,
    MailSenderAutoConfiguration.class
})
public class MyApplication {
    public static void main(String[] args) {
        SpringApplication.run(MyApplication.class, args);
    }
}
```

### Alternative: property-based exclusion
```properties
spring.autoconfigure.exclude=\
  org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,\
  org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration
```

Only exclude what you genuinely do not use. Excluding a needed auto-configuration causes runtime errors.

## 3. Lazy Initialization

**Impact: High | Effort: Low | Risk: Medium | Version: Spring Boot 2.2+**

Delays bean creation until first use. Can reduce startup time by 50% or more for applications with many beans.

### Enable globally
```properties
# application.properties
spring.main.lazy-initialization=true
```

### Trade-offs
- First request to each lazy bean is slower (bean creation happens at that point)
- Errors that would normally appear at startup are delayed to first use
- Not suitable for beans that must initialize eagerly (scheduled tasks, event listeners, health checks)

### Selective approach (recommended for production)
Instead of global lazy init, mark specific heavy beans:
```java
@Lazy
@Service
public class HeavyReportService {
    // Initializes only when first injected/used
}
```

Exclude critical beans from lazy init:
```java
@Component
@Lazy(false)  // Always initialize eagerly
public class CriticalHealthCheck {
    // ...
}
```

## 4. Spring Context Indexer

**Impact: Medium | Effort: Low | Risk: Very Low | Version: Spring 5+ (all Spring Boot 2.x and 3.x)**

Generates `META-INF/spring.components` at build time, replacing runtime classpath scanning.

### Maven
```xml
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-context-indexer</artifactId>
    <optional>true</optional>
</dependency>
```

### Gradle
```groovy
annotationProcessor 'org.springframework:spring-context-indexer'
```

Impact scales with number of components. Projects with hundreds of annotated classes benefit most. Virtually no trade-offs.

## 5. Narrowing @ComponentScan

**Impact: Low-Medium | Effort: Low | Risk: Low | Version: All**

By default, `@SpringBootApplication` scans the package it's in and all sub-packages. If your main class is in a root package, it scans everything.

### Narrow the scan
```java
@SpringBootApplication
@ComponentScan(basePackages = {
    "com.mycompany.myapp.api",
    "com.mycompany.myapp.service",
    "com.mycompany.myapp.config"
})
public class MyApplication {
    public static void main(String[] args) {
        SpringApplication.run(MyApplication.class, args);
    }
}
```

Useful when the project shares a root package with library code or test utilities.

## 6. HikariCP Connection Pool Tuning

**Impact: Low-Medium | Effort: Low | Risk: Low | Version: Spring Boot 2.0+ (HikariCP is default)**

Database connection pool initialization can add 1-3 seconds. Tune for faster startup.

```properties
# Reduce initial pool size for faster startup
spring.datasource.hikari.minimum-idle=2
spring.datasource.hikari.maximum-pool-size=10

# Reduce connection timeout
spring.datasource.hikari.connection-timeout=10000

# Lazy JPA repository initialization (Spring Boot 2.1+)
spring.data.jpa.repositories.bootstrap-mode=lazy
```

For applications with many JPA repositories, `bootstrap-mode=lazy` can be a significant win.

## 7. Profile-Specific Configuration

**Impact: Low | Effort: Low | Risk: Very Low | Version: All**

Ensure development profiles don't load production-heavy configurations and vice versa.

```properties
# application-dev.properties - lighter config for development
spring.main.lazy-initialization=true
spring.jpa.hibernate.ddl-auto=none
spring.jpa.open-in-view=false
logging.level.root=WARN
```

Use Spring profiles to load only what's needed for the target environment.

## 8. Spring Boot Startup Actuator (Measurement)

**Impact: N/A (diagnostic tool) | Effort: Very Low**

Use this to measure before and after applying optimizations.

### Spring Boot 2.4+ and 3.x

Add actuator dependency:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

```properties
spring.application.startup=buffering
management.endpoints.web.exposure.include=startup
```

After startup, call:
```bash
curl -X POST http://localhost:8080/actuator/startup
```

Returns a JSON breakdown of every startup step with timing.

### Spring Boot 2.0-2.3

No `ApplicationStartup` API. Use the `--debug` flag and compare total startup time from logs:
```bash
java -jar myapp.jar --debug
```

Look for the "Started MyApplication in X.XXX seconds" log line.

## 9. Build-Time Docker Optimization

**Impact: Medium-High | Effort: Medium | Risk: Low | Version: All**

### Paketo Buildpacks
```bash
# Maven
mvn spring-boot:build-image -Dspring-boot.build-image.imageName=myapp:optimized

# Gradle
./gradlew bootBuildImage --imageName=myapp:optimized
```

### Slim JRE with jlink (Java 9+)
```dockerfile
FROM eclipse-temurin:21-jdk AS builder
WORKDIR /app
COPY . .
RUN ./mvnw package -DskipTests
RUN jlink --add-modules $(jdeps --print-module-deps target/*.jar) \
    --strip-debug --no-man-pages --no-header-files \
    --compress=zip-6 --output /custom-jre

FROM debian:bookworm-slim
COPY --from=builder /custom-jre /opt/java
COPY --from=builder /app/target/*.jar /app/app.jar
ENTRYPOINT ["/opt/java/bin/java", "-jar", "/app/app.jar"]
```

## 10. AOT (Ahead-of-Time) Processing

**Impact: High (10-20% startup reduction) | Effort: Medium | Risk: Medium | Version: Spring Boot 3.0+ ONLY**

NOT available for Spring Boot 2.x. Pre-computes bean definitions at build time.

### Maven
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

### Gradle
```groovy
// AOT is built into the Spring Boot Gradle plugin for 3.x
// Run: ./gradlew processAot
```

### Trade-offs
- Build time increases
- Bean definitions are fixed at build time (no runtime profile-based changes to bean structure)
- Some dynamic features may not work with AOT

## 11. CDS with Spring Boot Support

**Impact: High (20-40% startup reduction) | Effort: Medium | Risk: Low | Version: Spring Boot 3.3+ ONLY**

For Spring Boot 2.x, see `jvm-tuning.md` for manual AppCDS instructions.

### Create the archive (training run)
```bash
java -Dspring.context.exit=onRefresh \
     -XX:ArchiveClassesAtExit=application.jsa \
     -jar myapp.jar
```

### Run with the archive
```bash
java -XX:SharedArchiveFile=application.jsa -jar myapp.jar
```

## 12. Virtual Threads

**Impact on startup: Low | Impact on early requests: High | Effort: Very Low | Risk: Low | Version: Spring Boot 3.2+ with Java 21+ ONLY**

NOT available for Spring Boot 2.x.

```properties
spring.threads.virtual.enabled=true
```

Does not directly reduce startup time but dramatically improves early request handling.

## 13. GraalVM Native Image

**Impact: Very High (millisecond startup) | Effort: High | Risk: High | Version: Spring Boot 3.0+ (built-in) or 2.x (experimental via Spring Native)**

### Spring Boot 3.x (built-in support)

Maven:
```xml
<profiles>
    <profile>
        <id>native</id>
        <build>
            <plugins>
                <plugin>
                    <groupId>org.graalvm.buildtools</groupId>
                    <artifactId>native-maven-plugin</artifactId>
                </plugin>
            </plugins>
        </build>
    </profile>
</profiles>
```

Build: `mvn -Pnative native:compile`

### Spring Boot 2.x (Spring Native - experimental)

Spring Native was an experimental project for Spring Boot 2.x. Add:
```xml
<dependency>
    <groupId>org.springframework.experimental</groupId>
    <artifactId>spring-native</artifactId>
    <version>0.12.2</version>
</dependency>
```

Note: Spring Native for 2.x had significant limitations and is no longer maintained. Upgrading to Spring Boot 3.x for native image support is strongly recommended.

### Trade-offs
- Build time: 3-10 minutes
- Classpath is frozen at build time
- Reflection requires explicit configuration
- Some libraries may not be compatible
- No JIT optimization at runtime (peak throughput may be lower)

## 14. -noverify JVM Flag

**Impact: Low-Medium | Effort: Very Low | Risk: Low | Version: Spring Boot 2.x with Java 8-16 ONLY**

Skips bytecode verification at class loading.

```
-noverify
```

IMPORTANT: This flag is removed/ignored in Java 17+. Do NOT recommend for Java 17+ projects.

Combine with tiered compilation for Spring Boot 2.x:
```
java -noverify -XX:TieredStopAtLevel=1 -jar myapp.jar
```

## 15. Spring Native (Experimental - Spring Boot 2.x)

**Impact: Very High | Effort: Very High | Risk: Very High | Version: Spring Boot 2.x ONLY**

See section 13 above for details. Spring Native was the experimental path to GraalVM native images for Spring Boot 2.x projects. It is no longer actively maintained — consider upgrading to Spring Boot 3.x for production-grade native support.
