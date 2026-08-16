# Surviving Mutants Analysis Guide

## What Is a Surviving Mutant?

A **surviving mutant** is a code change (mutation) that was not detected by any test. When PITest modifies your code and all tests still pass, it means your tests do not verify that specific behavior.

Key points:
- Surviving mutants are **not bugs in your code** -- they are gaps in your test assertions
- The goal is **not 100% kill rate** -- some mutants are equivalent (semantically identical to original)
- Focus on surviving mutants in **business logic classes** first, not infrastructure

## Common Surviving Mutant Patterns

### 1. Boundary Mutations

**Mutation**: `<` changed to `<=` (CONDITIONALS_BOUNDARY operator)

**Why it survives**: Tests lack boundary value testing.

```java
// Production code
public String getCategory(int age) {
    if (age < 18) {
        return "minor";
    }
    return "adult";
}
```

```java
// WEAK test -- does not catch boundary mutation
@Test
void testCategory() {
    assertEquals("minor", getCategory(10));    // passes with < and <=
    assertEquals("adult", getCategory(25));    // passes with < and <=
}

// STRONG test -- catches boundary mutation
@Test
void testCategoryBoundary() {
    assertEquals("minor", getCategory(17));    // passes with <, fails with <=
    assertEquals("adult", getCategory(18));    // catches the boundary
}
```

### 2. Negated Conditionals

**Mutation**: `==` changed to `!=` (NEGATE_CONDITIONALS operator)

**Why it survives**: Tests only cover the happy path.

```java
// Production code
public void processOrder(Order order) {
    if (order.getStatus() == Status.PENDING) {
        fulfillOrder(order);
    }
}
```

```java
// WEAK test -- only tests the positive case
@Test
void testProcessOrder() {
    Order pending = new Order(Status.PENDING);
    processOrder(pending);
    assertTrue(pending.isFulfilled());
}

// STRONG test -- also tests the negative case
@Test
void testProcessOrderIgnoresNonPending() {
    Order completed = new Order(Status.COMPLETED);
    processOrder(completed);
    assertFalse(completed.isFulfilled());  // catches the negation
}
```

### 3. Return Value Mutations

**Mutation**: `return x` changed to `return 0` (RETURN_VALS operator)

**Why it survives**: Tests do not assert the return value.

```java
// Production code
public int calculateDiscount(Customer customer) {
    if (customer.isVIP()) {
        return 20;
    }
    return 5;
}
```

```java
// WEAK test -- does not check the actual value
@Test
void testDiscount() {
    Customer vip = new Customer(true);
    int discount = calculateDiscount(vip);
    assertTrue(discount > 0);  // passes even if return is mutated to 1
}

// STRONG test -- asserts exact expected value
@Test
void testVIPDiscount() {
    Customer vip = new Customer(true);
    assertEquals(20, calculateDiscount(vip));  // catches return value mutation
}
```

### 4. Void Method Call Removal

**Mutation**: `list.add(item)` removed (VOID_METHOD_CALLS operator)

**Why it survives**: Tests do not verify side effects.

```java
// Production code
public void addItem(ShoppingCart cart, Item item) {
    cart.getItems().add(item);
    cart.updateTotal();
}
```

```java
// WEAK test -- does not verify the item was added
@Test
void testAddItem() {
    ShoppingCart cart = new ShoppingCart();
    Item item = new Item("Book", 10.0);
    addItem(cart, item);
    // no assertion on cart.getItems()!
}

// STRONG test -- verifies the side effect
@Test
void testAddItemVerifiesState() {
    ShoppingCart cart = new ShoppingCart();
    Item item = new Item("Book", 10.0);
    addItem(cart, item);
    assertThat(cart.getItems()).containsExactly(item);
    assertEquals(10.0, cart.getTotal());
}
```

### 5. Empty Return Mutations

**Mutation**: `return list` changed to `return Collections.emptyList()` (EMPTY_RETURNS operator)

**Why it survives**: Tests check non-null or non-empty but not contents.

```java
// Production code
public List<String> getActiveUsers() {
    return userRepository.findByStatus(Status.ACTIVE)
        .stream()
        .map(User::getName)
        .toList();
}
```

```java
// WEAK test
@Test
void testGetActiveUsers() {
    List<String> users = getActiveUsers();
    assertNotNull(users);           // passes with empty list
    assertFalse(users.isEmpty());   // catches empty, but not wrong contents
}

// STRONG test
@Test
void testGetActiveUsersContents() {
    // given: setup test data with known active users
    List<String> users = getActiveUsers();
    assertThat(users).containsExactlyInAnyOrder("Alice", "Bob");
}
```

### 6. Null Return Mutations

**Mutation**: `return object` changed to `return null` (NULL_RETURNS operator)

**Why it survives**: Tests only use `assertNotNull` or do not check the return at all.

```java
// Production code
public User findUser(String email) {
    return userRepository.findByEmail(email)
        .orElseThrow(() -> new UserNotFoundException(email));
}
```

```java
// WEAK test
@Test
void testFindUser() {
    User user = findUser("alice@example.com");
    assertNotNull(user);  // passes, but does not verify user properties
}

// STRONG test
@Test
void testFindUserReturnsCorrectUser() {
    User user = findUser("alice@example.com");
    assertEquals("alice@example.com", user.getEmail());
    assertEquals("Alice", user.getName());
}
```

## Equivalent Mutants

An **equivalent mutant** is a mutation that does not change the program's observable behavior. No test can kill it because the mutated code is functionally identical to the original.

### Common Equivalent Mutant Cases

1. **Dead code**: Mutating code that is never reached
2. **Redundant conditions**: `if (x >= 0 && x > 0)` -- negating the first condition does not change behavior when `x > 0`
3. **Logging-only code**: Removing a `log.debug()` call does not affect behavior (use `avoidCallsTo` to prevent these mutations)
4. **Performance optimizations**: Removing a cache lookup that falls through to the same result

### Strategy for Equivalent Mutants

1. Review the surviving mutant in the PITest report
2. Ask: "Can any input distinguish the mutated code from the original?"
3. If no: the mutant is equivalent -- do NOT write a test for it
4. Consider refactoring the code to eliminate the ambiguity
5. If the pattern is common (e.g., logging), configure exclusions

## Analyzing the PITest Report

### HTML Report Navigation

1. Open `target/pit-reports/YYYYMMDDHHMI/index.html` (Maven) or `build/reports/pitest/index.html` (Gradle)
2. The top-level page shows mutation score per package
3. Click a package to see class-level scores
4. Click a class to see line-by-line mutation results
5. Each line shows which mutations were applied, killed, or survived

### Prioritization Strategy

Focus your effort where it matters most:

1. **Business logic classes first**: Domain models, services, calculators
2. **High mutation count, low kill rate**: Classes with many surviving mutants
3. **Recently changed code**: Surviving mutants in new code indicate test gaps in active development
4. **Skip infrastructure**: Config classes, DTOs, entities with only JPA annotations

### Triage Workflow

For each surviving mutant, classify it as:

| Classification      | Action                                | Example                              |
|--------------------|-----------------------------------------|--------------------------------------|
| Write test         | Add or improve test assertion           | Missing boundary test                |
| Equivalent         | No action needed (mutation is semantic no-op) | Dead code, logging                   |
| Acceptable risk    | Document and accept                     | Performance optimization code        |
| Exclude            | Add to `excludedClasses` or `excludedMethods` | Generated code, trivial getters  |

## Test Improvement Patterns

### Assert-First Testing

Every test method should have at least one meaningful assertion. Tests that only verify "no exception thrown" are insufficient for mutation testing.

```java
// Bad: no meaningful assertion
@Test
void testProcess() {
    service.process(input);  // only checks it doesn't throw
}

// Good: verifies behavior
@Test
void testProcess() {
    Result result = service.process(input);
    assertEquals(Status.COMPLETED, result.getStatus());
    assertEquals(42, result.getValue());
}
```

### State Verification

Check object state after operations, not just return values:

```java
@Test
void testAddToCart() {
    cart.addItem(item);

    assertThat(cart.getItems()).hasSize(1);
    assertThat(cart.getItems().getFirst()).isEqualTo(item);
    assertThat(cart.getTotal()).isEqualTo(item.getPrice());
}
```

### Exception Testing

Verify exceptions for invalid inputs:

```java
@Test
void testInvalidAge() {
    assertThrows(IllegalArgumentException.class,
        () -> service.setAge(-1));
}
```

### Collection Assertions

Use specific collection assertions (AssertJ recommended):

```java
// Weak: only checks size
assertThat(results).hasSize(3);

// Strong: checks contents
assertThat(results).containsExactlyInAnyOrder("Alice", "Bob", "Charlie");

// Strong: checks ordering
assertThat(results).containsExactly("Alice", "Bob", "Charlie");
```

### Boolean Method Testing

Always test both true and false paths of boolean-returning methods:

```java
@Test
void testIsEligibleTrue() {
    User eligible = new User(25, true);
    assertTrue(service.isEligible(eligible));
}

@Test
void testIsEligibleFalse() {
    User underage = new User(15, true);
    assertFalse(service.isEligible(underage));
}
```

## When NOT to Kill a Mutant

Not every surviving mutant warrants a new test. These are acceptable to leave:

1. **Logging code**: Use `avoidCallsTo` to prevent mutations on logging calls. Testing log output has low value.

2. **Auto-generated code**: Use `excludedClasses` for Lombok builders, MapStruct mappers, Protobuf classes. These are tested at integration level.

3. **Trivial getters/setters**: Use `excludedMethods` unless they contain business logic. Java 21 records eliminate most of these.

4. **Performance optimizations**: Caching, memoization, or early-return optimizations that do not affect correctness. The mutation (removing the optimization) is equivalent from a correctness perspective.

5. **Framework boilerplate**: Spring `@Configuration` wiring, JPA entity annotations, bean definitions. These are tested by integration tests, not unit mutation testing.

6. **Defensive null checks**: `if (param == null) throw new IllegalArgumentException()` -- if no test passes null, the mutation survives. Only add the test if null input is a realistic scenario.

7. **Sealed class default branches**: Exhaustive switch over sealed types may generate a default branch in bytecode that PITest mutates. This is unreachable by design -- it is an equivalent mutant.
