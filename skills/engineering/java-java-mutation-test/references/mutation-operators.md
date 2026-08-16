# PITest Mutation Operators Guide

## What Are Mutation Operators?

Mutation operators make small, targeted changes (mutations) to your compiled bytecode and check if your tests detect the change. Each change produces a **mutant**:

- **Killed mutant**: A test failed when the mutation was applied -- your tests are effective
- **Survived mutant**: All tests still passed despite the mutation -- you have a test gap
- **Timed out mutant**: The mutation caused an infinite loop or excessive delay -- counted as killed
- **Non-viable mutant**: The mutation caused the class to fail verification -- excluded from scoring

## PITest Mutator Groups

PITest organizes operators into predefined groups. Choose the group that matches your project's maturity:

| Group      | Operators | Speed  | Coverage | Recommended For                    |
|------------|-----------|--------|----------|------------------------------------|
| DEFAULTS   | 7         | Fast   | Good     | First-time adoption, large codebases |
| STRONGER   | 11        | Medium | Better   | Most Java 21 projects (recommended)  |
| ALL        | ~20+      | Slow   | Maximum  | NEVER in CI. Research/audit only     |
| OLD_DEFAULTS | 10      | Medium | Legacy   | Not recommended (use STRONGER)       |

**Recommendation**: Use `STRONGER` for Java 21 projects. Use `DEFAULTS` only for initial adoption on very large codebases where execution time is a concern.

**CRITICAL**: Never use `ALL` in CI/CD pipelines. It generates many equivalent mutants and is extremely slow.

## DEFAULTS Group (7 Operators)

These operators are included in the `DEFAULTS` group:

### CONDITIONALS_BOUNDARY

Changes relational operators at boundary conditions.

| Original | Mutated |
|----------|---------|
| `<`      | `<=`    |
| `<=`     | `<`     |
| `>`      | `>=`    |
| `>=`     | `>`     |

```java
// Original
if (age < 18) { deny(); }
// Mutated
if (age <= 18) { deny(); }
```

**Why it matters**: Catches missing boundary value tests. A common source of off-by-one errors.

### INCREMENTS

Replaces integer increments and decrements.

| Original | Mutated |
|----------|---------|
| `i++`    | `i--`   |
| `i--`    | `i++`   |
| `++i`    | `--i`   |
| `--i`    | `++i`   |

```java
// Original
for (int i = 0; i < n; i++) { process(i); }
// Mutated
for (int i = 0; i < n; i--) { process(i); }
```

### INVERT_NEGS

Inverts negation of numbers.

| Original | Mutated |
|----------|---------|
| `-x`     | `x`     |

```java
// Original
return -balance;
// Mutated
return balance;
```

### MATH

Replaces binary arithmetic operations.

| Original | Mutated |
|----------|---------|
| `+`      | `-`     |
| `-`      | `+`     |
| `*`      | `/`     |
| `/`      | `*`     |
| `%`      | `*`     |
| `&`      | `\|`    |
| `\|`     | `&`     |
| `^`      | `&`     |
| `<<`     | `>>`    |
| `>>`     | `<<`    |
| `>>>`    | `<<`    |

```java
// Original
int total = price * quantity;
// Mutated
int total = price / quantity;
```

### NEGATE_CONDITIONALS

Replaces relational and equality operators with their negation.

| Original | Mutated |
|----------|---------|
| `==`     | `!=`    |
| `!=`     | `==`    |
| `<`      | `>=`    |
| `>=`     | `<`     |
| `>`      | `<=`    |
| `<=`     | `>`     |

```java
// Original
if (status == Status.ACTIVE) { process(); }
// Mutated
if (status != Status.ACTIVE) { process(); }
```

### RETURN_VALS (EMPTY_RETURNS for objects)

Mutates method return values.

| Return Type | Original     | Mutated             |
|-------------|-------------|---------------------|
| boolean     | `true`       | `false`             |
| boolean     | `false`      | `true`              |
| int         | non-zero     | `0`                 |
| int         | `0`          | `1`                 |
| Object      | non-null     | `null`              |
| Object      | `null`       | `throw RuntimeException` |

```java
// Original
return Optional.of(user);
// Mutated
return Optional.empty();
```

### VOID_METHOD_CALLS

Removes calls to void methods.

```java
// Original
void processOrder(Order order) {
    validate(order);         // this call may be removed
    repository.save(order);  // this call may be removed
    notify(order);           // this call may be removed
}
```

**Why it matters**: Catches untested side effects. If removing `repository.save(order)` does not fail any test, your tests are not verifying persistence.

## STRONGER Additional Operators (4 more)

These operators are added by the `STRONGER` group on top of `DEFAULTS`:

### EMPTY_RETURNS

Returns "empty" values for object-returning methods.

| Return Type         | Mutated To                   |
|--------------------|------------------------------|
| `String`           | `""`                         |
| `Optional`         | `Optional.empty()`           |
| `List`             | `Collections.emptyList()`    |
| `Set`              | `Collections.emptySet()`     |
| `Map`              | `Collections.emptyMap()`     |
| `Stream`           | `Stream.empty()`             |
| `Integer`/`Long`   | `0`                          |

```java
// Original
return userRepository.findAll();
// Mutated
return Collections.emptyList();
```

### FALSE_RETURNS

Forces all boolean-returning methods to return `false`.

```java
// Original
public boolean isEligible(User user) {
    return user.getAge() >= 18 && user.isActive();
}
// Mutated
public boolean isEligible(User user) {
    return false;
}
```

### TRUE_RETURNS

Forces all boolean-returning methods to return `true`.

```java
// Original
public boolean isBlocked(User user) {
    return blocklist.contains(user.getId());
}
// Mutated
public boolean isBlocked(User user) {
    return true;
}
```

### NULL_RETURNS

Returns `null` for all object-returning methods.

```java
// Original
public User findById(Long id) {
    return userRepository.findById(id).orElseThrow();
}
// Mutated
public User findById(Long id) {
    return null;
}
```

**Why it matters**: Tests that do not check for null returns or that only check `assertNotNull` will miss this mutation.

## Extended Operators (Use Selectively)

These operators are NOT included in STRONGER. Use them only for critical business logic modules:

### AOR (Arithmetic Operator Replacement)

Full arithmetic substitution -- replaces each arithmetic operator with every other operator. Generates many mutations.

### ROR (Relational Operator Replacement)

Full relational substitution -- replaces each relational operator with every other operator. More thorough than NEGATE_CONDITIONALS.

### UOI (Unary Operator Insertion)

Inserts unary operators (negation, increment, decrement) before variables.

### Arcmutate Extended Operators (Commercial)

Arcmutate provides additional operators for:
- **Spring-aware mutations**: Mutates `@Transactional`, `@Cacheable`, `@Async` annotations
- **Stream mutations**: Mutates stream operations (filter, map, flatMap)
- **Builder pattern mutations**: Mutates builder method calls
- **Reactive mutations**: Mutates Reactor/RxJava operators

### Custom Mutator Group Configuration

**Maven:**
```xml
<mutators>
    <mutator>STRONGER</mutator>
    <!-- Add individual extended operators -->
    <mutator>AOR</mutator>
    <mutator>ROR</mutator>
</mutators>
```

**Gradle:**
```groovy
pitest {
    mutators = ['STRONGER', 'AOR', 'ROR']
}
```

## Java 21 Bytecode Considerations

### Records

PITest 1.19.1 automatically detects and filters record-generated bytecode:
- Generated canonical constructor, accessors, `equals()`, `hashCode()`, `toString()`
- Custom logic inside compact constructors and custom methods IS mutated (correct behavior)
- No configuration needed -- PITest handles this automatically

### Switch Expressions with Pattern Matching

```java
// PITest mutates each case branch independently
return switch (shape) {
    case Circle c    -> Math.PI * c.radius() * c.radius();  // math operators mutated
    case Rectangle r -> r.width() * r.height();              // math operators mutated
    case Triangle t  -> 0.5 * t.base() * t.height();        // math operators mutated
};
```

The compiler generates standard bytecode for pattern matching -- PITest applies operators normally to each branch.

### Sealed Class Hierarchies

Sealed classes compile with access control checks. Exhaustive switch over sealed types may produce a default branch in bytecode. PITest may mutate this branch -- if it survives, it is likely an equivalent mutant (the default is unreachable). This is safe to ignore.

### Text Blocks

Text blocks compile to regular String constants. String mutations apply normally.
