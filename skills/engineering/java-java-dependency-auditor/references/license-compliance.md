# License Compliance Reference

## License Categories

### Permissive Licenses (Generally Safe for Commercial Use)

| License | Key Terms | Commercial OK |
|---|---|---|
| MIT | Do anything, keep copyright notice | Yes |
| Apache 2.0 | Do anything, keep notice, state changes | Yes |
| BSD 2-Clause | Do anything, keep notice | Yes |
| BSD 3-Clause | Do anything, keep notice, no endorsement | Yes |
| ISC | Similar to MIT | Yes |
| Unlicense | Public domain dedication | Yes |

### Weak Copyleft (Use Carefully)

| License | Key Terms | Risk |
|---|---|---|
| LGPL 2.1/3.0 | Must share changes to the library itself; your code stays proprietary if dynamically linked | Medium -- OK for Java (JAR linking is generally considered dynamic linking) |
| MPL 2.0 | File-level copyleft; modified files must be shared | Low-Medium |
| EPL 1.0/2.0 | Similar to LGPL, module-level copyleft | Low-Medium |
| CDDL 1.0 | File-level copyleft | Low-Medium |

### Strong Copyleft (High Risk for Commercial)

| License | Key Terms | Risk |
|---|---|---|
| GPL 2.0/3.0 | Derivative works must also be GPL | HIGH -- may require open-sourcing your application |
| AGPL 3.0 | Like GPL + network use triggers copyleft | CRITICAL -- even SaaS usage triggers copyleft |

### No License / Unknown

If a dependency has no license, you legally have NO permission to use it. Contact the author or find an alternative.

---

## Maven License Plugin Setup

### license-maven-plugin (MojoHaus)

```xml
<plugin>
    <groupId>org.codehaus.mojo</groupId>
    <artifactId>license-maven-plugin</artifactId>
    <version>2.4.0</version>
    <configuration>
        <excludedScopes>test</excludedScopes>
        <sortArtifactByName>true</sortArtifactByName>
    </configuration>
</plugin>
```

Commands:
```bash
# Generate third-party license report
./mvnw license:third-party-report

# Add license headers to source files
./mvnw license:format

# Check for missing headers
./mvnw license:check
```

Report location: `target/site/third-party-report.html`

### licensescan-maven-plugin (Deny-list Approach)

```xml
<plugin>
    <groupId>com.github.carlomorelli</groupId>
    <artifactId>licensescan-maven-plugin</artifactId>
    <version>3.3</version>
    <configuration>
        <printLicenses>true</printLicenses>
        <failBuildOnBlacklisted>true</failBuildOnBlacklisted>
        <blacklistedLicenses>
            <license>GNU General Public License, v2.0</license>
            <license>GNU General Public License, v3.0</license>
            <license>GNU Affero General Public License, v3.0</license>
        </blacklistedLicenses>
    </configuration>
    <executions>
        <execution>
            <phase>verify</phase>
            <goals><goal>audit</goal></goals>
        </execution>
    </executions>
</plugin>
```

---

## Gradle License Plugin Setup

### com.github.jk1.dependency-license-report

```groovy
plugins {
    id 'com.github.jk1.dependency-license-report' version '2.7'
}

licenseReport {
    renderers = [new com.github.jk1.license.render.JsonReportRenderer()]
    filters = [new com.github.jk1.license.filter.LicenseBundleNormalizer()]
    excludeGroups = ['com.mycompany'] // Exclude internal libs
}
```

Run: `./gradlew generateLicenseReport`

### License Check with Allowed List

```groovy
import com.github.jk1.license.filter.DependencyFilter

licenseReport {
    allowedLicensesFile = new File("$projectDir/allowed-licenses.json")
}
```

`allowed-licenses.json`:
```json
{
    "allowedLicenses": [
        { "moduleLicense": "Apache License, Version 2.0" },
        { "moduleLicense": "MIT License" },
        { "moduleLicense": "BSD License" },
        { "moduleLicense": "Eclipse Public License - v 2.0" }
    ]
}
```

---

## Common Java Libraries and Their Licenses

| Library | License | Risk |
|---|---|---|
| Spring Framework | Apache 2.0 | Safe |
| Spring Boot | Apache 2.0 | Safe |
| Hibernate | LGPL 2.1 | Safe (JAR linking) |
| Jackson | Apache 2.0 | Safe |
| Guava | Apache 2.0 | Safe |
| SLF4J | MIT | Safe |
| Logback | LGPL 2.1 / EPL 1.0 | Safe |
| Log4j 2 | Apache 2.0 | Safe |
| Apache Commons | Apache 2.0 | Safe |
| Lombok | MIT | Safe |
| JUnit 5 | EPL 2.0 | Safe (test scope) |
| Mockito | MIT | Safe (test scope) |
| Testcontainers | MIT | Safe (test scope) |
| MySQL Connector/J | GPL 2.0 (with FOSS exception) | Review FOSS exception |
| MariaDB Connector/J | LGPL 2.1 | Safe |
| PostgreSQL JDBC | BSD 2-Clause | Safe |
| H2 Database | MPL 2.0 / EPL 1.0 | Safe (usually test) |
| iText | AGPL 3.0 | HIGH RISK for commercial |
| GNU Trove | LGPL 2.1 | Safe |

### MySQL Connector/J GPL Note

The MySQL Connector/J is licensed under GPL 2.0 with a FOSS exception that allows use with certain open-source licensed applications. For commercial closed-source projects:
- Option 1: Purchase a commercial license from Oracle
- Option 2: Use MariaDB Connector/J (LGPL, drop-in compatible) instead
- Option 3: Verify your project qualifies under the FOSS exception

---

## CI/CD License Enforcement

### GitHub Actions Example

```yaml
- name: License Check
  run: ./mvnw license:third-party-report

- name: Check for GPL
  run: |
    if grep -qi "GNU General Public License" target/site/third-party-report.html; then
      echo "GPL dependency detected!"
      exit 1
    fi
```

### Best Practices

1. **Scan on every PR**: Catch license issues before merge
2. **Maintain an allowed-list**: Explicitly approve each license type
3. **Review transitive dependencies**: A safe library may pull in a GPL transitive dependency
4. **Document exceptions**: If you accept a specific GPL library, document why in a LICENSES.md
5. **Re-audit periodically**: Libraries can change their license between versions
