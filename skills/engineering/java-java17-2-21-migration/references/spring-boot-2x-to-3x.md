# Spring Boot 2.x to 3.x Migration Reference

## Prerequisites Checklist

Before starting the migration:
1. Upgrade to the **latest Spring Boot 2.7.x** -- this resolves most deprecations within the 2.x lifecycle
2. Fix all deprecation warnings at the 2.7.x level
3. Ensure Java 17 is the baseline
4. All tests must pass before starting the migration
5. Commit a stable checkpoint

## Phase 1: javax to jakarta Namespace Migration

This is the most pervasive change. Spring Boot 3.x requires Jakarta EE 10.

### Package Rename Map

| Old (javax.\*)              | New (jakarta.\*)              |
|-----------------------------|-------------------------------|
| javax.persistence.\*        | jakarta.persistence.\*        |
| javax.servlet.\*            | jakarta.servlet.\*            |
| javax.validation.\*         | jakarta.validation.\*         |
| javax.annotation.\*         | jakarta.annotation.\*         |
| javax.transaction.\*        | jakarta.transaction.\*        |
| javax.inject.\*             | jakarta.inject.\*             |
| javax.ws.rs.\*              | jakarta.ws.rs.\*              |
| javax.mail.\*               | jakarta.mail.\*               |
| javax.activation.\*         | jakarta.activation.\*         |
| javax.xml.bind.\*           | jakarta.xml.bind.\*           |

### Packages That Do NOT Change

These javax packages are part of the JDK itself and do NOT migrate to jakarta:
- `javax.crypto.*`
- `javax.net.*`
- `javax.security.auth.*`
- `javax.sql.*`
- `javax.naming.*`
- `javax.swing.*`

### Automation with OpenRewrite

For Maven projects, add the OpenRewrite plugin to automate the migration:

```xml
<plugin>
    <groupId>org.openrewrite.maven</groupId>
    <artifactId>rewrite-maven-plugin</artifactId>
    <version>5.37.0</version>
    <configuration>
        <activeRecipes>
            <recipe>org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_2</recipe>
        </activeRecipes>
    </configuration>
    <dependencies>
        <dependency>
            <groupId>org.openrewrite.recipe</groupId>
            <artifactId>rewrite-spring</artifactId>
            <version>5.16.0</version>
        </dependency>
    </dependencies>
</plugin>
```

Run: `./mvnw rewrite:run`

For Gradle, use the OpenRewrite Gradle plugin equivalently.

### Manual Migration Steps

1. Find all javax imports: `grep -rn "import javax\." src/ --include="*.java"`
2. Replace each occurrence with the corresponding jakarta package
3. Update XML files: `persistence.xml`, `web.xml`, `orm.xml`
4. Update dependency coordinates in pom.xml / build.gradle:
   - `javax.validation:javax.validation-api` -> `jakarta.validation:jakarta.validation-api`
   - `javax.servlet:javax.servlet-api` -> `jakarta.servlet:jakarta.servlet-api`
   - `javax.annotation:javax.annotation-api` -> `jakarta.annotation:jakarta.annotation-api`

## Phase 2: Spring Security 6.0 Migration

### WebSecurityConfigurerAdapter Removal

Before (Spring Security 5.x):
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
            .authorizeRequests()
            .antMatchers("/public/**").permitAll()
            .antMatchers("/admin/**").hasRole("ADMIN")
            .anyRequest().authenticated()
            .and()
            .formLogin();
    }
}
```

After (Spring Security 6.x):
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/public/**").permitAll()
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .formLogin(Customizer.withDefaults());
        return http.build();
    }
}
```

### Key API Changes

| Old API                            | New API                              |
|------------------------------------|--------------------------------------|
| `authorizeRequests()`              | `authorizeHttpRequests()`            |
| `antMatchers()`                    | `requestMatchers()`                  |
| `mvcMatchers()`                    | `requestMatchers()`                  |
| `regexMatchers()`                  | `requestMatchers()`                  |
| `access("hasRole('ADMIN')")`      | `hasRole("ADMIN")`                   |
| `.and()`                           | Use lambda DSL instead               |
| `@EnableGlobalMethodSecurity`      | `@EnableMethodSecurity`              |

### Method Security

Before:
```java
@EnableGlobalMethodSecurity(prePostEnabled = true, securedEnabled = true)
```

After:
```java
@EnableMethodSecurity  // prePostEnabled=true is the default
```

### CSRF Token Handling

Spring Security 6.x uses `XorCsrfTokenRequestAttributeHandler` by default. If your frontend relies on the raw CSRF token value, you may need to configure:

```java
.csrf(csrf -> csrf
    .csrfTokenRequestHandler(new CsrfTokenRequestAttributeHandler())
)
```

## Phase 3: Hibernate 5 to 6

### ID Generation Strategy

Hibernate 6 changes the default ID generation strategy. If you use `@GeneratedValue(strategy = GenerationType.AUTO)`, the behavior may differ.

To preserve Hibernate 5 behavior, add to `application.properties`:
```properties
spring.jpa.properties.hibernate.id.new_generator_mappings=false
```

Or explicitly set the strategy:
```java
@GeneratedValue(strategy = GenerationType.IDENTITY)
// or
@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "my_seq")
@SequenceGenerator(name = "my_seq", sequenceName = "my_sequence", allocationSize = 1)
```

### HQL/JPQL Changes

- Some implicit type casts no longer work
- `FROM Entity` without `SELECT` is deprecated in HQL
- Criteria API changes for type safety

### Type System Changes

- `IntegerType`, `StringType`, etc. are reorganized
- If using custom types, review Hibernate 6 type contributor API

## Phase 4: Property Changes

### Renamed Properties

| Old Property                                | New Property                                     |
|---------------------------------------------|--------------------------------------------------|
| `spring.redis.*`                            | `spring.data.redis.*`                            |
| `spring.elasticsearch.*`                    | `spring.elasticsearch.uris` (restructured)       |
| `server.max-http-header-size`               | `server.max-http-request-header-size`            |
| `spring.mvc.throw-exception-if-no-handler`  | Removed (now always true)                        |

### Trailing Slash Matching

Spring Boot 3.x disables trailing slash matching by default:
- `/api/users` works
- `/api/users/` returns 404

To restore old behavior (not recommended long-term):
```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void configurePathMatch(PathMatchConfigurer configurer) {
        configurer.setUseTrailingSlashMatch(true);
    }
}
```

Better approach: update clients and documentation to use URLs without trailing slashes.

## Phase 5: HttpClient Migration (if applicable)

If using Apache HttpClient directly:

| Old (HttpClient 4.x)                | New (HttpClient 5.x)                            |
|--------------------------------------|--------------------------------------------------|
| `org.apache.http.client.*`           | `org.apache.hc.client5.*`                        |
| `org.apache.http.impl.client.*`      | `org.apache.hc.client5.http.impl.classic.*`      |
| `CloseableHttpClient`               | `CloseableHttpClient` (same name, new package)   |
| `HttpGet`, `HttpPost`               | Same names, new packages                         |

## Phase 6: Spring Data Changes

- `CrudRepository.findById()` and others remain the same
- Some return types and nullability annotations updated
- `QuerydslPredicateExecutor` changes
- `@Query` native queries may need `nativeQuery = true` explicitly

## Phase 7: Actuator Changes

- `/actuator/env` POST endpoint removed
- Health group configuration changes
- Some endpoint properties renamed

## Phase 8: Testing Changes

- `@SpringBootTest` + `@MockBean` behavior may differ
- `TestRestTemplate` cookie handling changes
- WebFlux `WebTestClient` improvements

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `ClassNotFoundException: javax.servlet.Filter` | javax dependency still referenced | Replace with jakarta.servlet-api |
| `NoSuchMethodError` in Security config | Old Security API used | Migrate to SecurityFilterChain pattern |
| `PropertyNotFoundException` | Renamed property | Check renamed properties table above |
| `HibernateException: Unknown sequence` | Hibernate 6 ID generation change | Set explicit generation strategy |
| `Bean not found` for `WebSecurityConfigurerAdapter` | Class removed in Security 6 | Migrate to SecurityFilterChain bean |
| `ClassCastException` in Hibernate queries | Type system changes in Hibernate 6 | Review and update HQL/criteria queries |
| `NoClassDefFoundError: javax/xml/bind/*` | JAXB removed from JDK | Add jakarta.xml.bind dependency |
| Test failures with `@MockBean` | Behavior changes | Review Spring Boot 3 test migration guide |
