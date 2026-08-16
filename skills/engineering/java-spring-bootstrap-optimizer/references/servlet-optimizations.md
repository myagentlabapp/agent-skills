# Servlet-Specific Optimizations (Spring MVC)

These recommendations apply only to projects using `spring-boot-starter-web` (servlet model).
All techniques in this file work with both Spring Boot 2.x and 3.x unless noted otherwise.

## 1. Switch from Tomcat to Undertow

**Impact: Medium (10-15% startup improvement, lower memory) | Effort: Low | Risk: Low | Version: All**

Undertow is lighter than Tomcat and generally starts faster with a lower memory footprint.

### Maven
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <exclusions>
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-tomcat</artifactId>
        </exclusion>
    </exclusions>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-undertow</artifactId>
</dependency>
```

### Gradle
```groovy
implementation('org.springframework.boot:spring-boot-starter-web') {
    exclude group: 'org.springframework.boot', module: 'spring-boot-starter-tomcat'
}
implementation 'org.springframework.boot:spring-boot-starter-undertow'
```

### When NOT to switch
- Application relies on JSP (Undertow has no JSP engine)
- Uses Tomcat-specific JNDI or valve configurations
- Organization has operational expertise around Tomcat tuning
- Using Tomcat-specific features like custom Realm implementations

## 2. Optimize Tomcat Thread Pool (if keeping Tomcat)

**Impact: Low on startup, Medium on early request handling | Effort: Low | Risk: Low | Version: All**

```properties
# Reduce initial thread allocation for faster startup
server.tomcat.threads.min-spare=5
server.tomcat.threads.max=50

# Accept queue
server.tomcat.accept-count=50
```

For Spring Boot 2.x (before 2.7), the property names are:
```properties
server.tomcat.min-spare-threads=5
server.tomcat.max-threads=50
```

Smaller thread pools mean less memory allocated at startup. Tune `max` based on expected concurrency.

## 3. Control Servlet Initialization Timing

**Impact: Low | Effort: Very Low | Risk: Very Low | Version: All**

```properties
# Load DispatcherServlet on startup (value >= 0) rather than on first request
spring.mvc.servlet.load-on-startup=1
```

Setting to `1` ensures the servlet initializes during startup rather than on the first HTTP request. This does not reduce total startup time but makes the first request faster.

Set to `-1` to defer and make measured startup faster at the cost of first-request latency.

## 4. Disable Unnecessary Servlet Filters

**Impact: Low-Medium | Effort: Low | Risk: Low | Version: All**

Spring Boot registers several filters by default. Disable ones you do not need:

```properties
# Disable hidden method filter if not using PUT/DELETE via form POST
spring.mvc.hiddenmethod.filter.enabled=false

# Disable form content filter if not processing form data
spring.mvc.formcontent.filter.enabled=false
```

### Programmatic filter exclusion
```java
@Bean
public FilterRegistrationBean<HiddenHttpMethodFilter> disableHiddenMethodFilter(
        HiddenHttpMethodFilter filter) {
    FilterRegistrationBean<HiddenHttpMethodFilter> registration =
        new FilterRegistrationBean<>(filter);
    registration.setEnabled(false);
    return registration;
}
```

## 5. Static Resource Handling

**Impact: Low | Effort: Very Low | Risk: Very Low | Version: All**

If you serve no static resources from the Spring Boot app (e.g., using a CDN or separate frontend):

```properties
spring.web.resources.add-mappings=false
```

For Spring Boot 2.x (before 2.4):
```properties
spring.resources.add-mappings=false
```

This skips the static resource handler registration during startup.
