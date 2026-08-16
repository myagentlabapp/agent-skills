# Java 21 Language Features Reference

## Record Patterns (JEP 440) -- Finalized

Record patterns allow you to destructure record values directly in `instanceof` checks and `switch` expressions.

### Basic Record Pattern

Before:
```java
record Point(int x, int y) {}

Object obj = new Point(1, 2);
if (obj instanceof Point p) {
    int x = p.x();
    int y = p.y();
    System.out.println("x=" + x + ", y=" + y);
}
```

After:
```java
Object obj = new Point(1, 2);
if (obj instanceof Point(int x, int y)) {
    System.out.println("x=" + x + ", y=" + y);
}
```

### Nested Record Patterns

```java
record Address(String city, String state) {}
record Customer(String name, Address address) {}

Object obj = getCustomer();
if (obj instanceof Customer(String name, Address(String city, String state))) {
    System.out.println(name + " lives in " + city + ", " + state);
}
```

### Record Patterns in Switch

```java
sealed interface Shape permits Circle, Rectangle {}
record Circle(double radius) implements Shape {}
record Rectangle(double width, double height) implements Shape {}

double area(Shape shape) {
    return switch (shape) {
        case Circle(double r)            -> Math.PI * r * r;
        case Rectangle(double w, double h) -> w * h;
    };
}
```

### Where to Apply

Scan your code for these patterns to refactor:
- `instanceof` followed by a cast and field access
- Methods that switch on record type and extract fields
- Visitor patterns that can be simplified with record patterns

---

## Pattern Matching for switch (JEP 441) -- Finalized

### Basic Type Patterns

Before:
```java
String format(Object obj) {
    if (obj instanceof Integer i) {
        return String.format("int %d", i);
    } else if (obj instanceof Long l) {
        return String.format("long %d", l);
    } else if (obj instanceof Double d) {
        return String.format("double %f", d);
    } else if (obj instanceof String s) {
        return String.format("String %s", s);
    }
    return obj.toString();
}
```

After:
```java
String format(Object obj) {
    return switch (obj) {
        case Integer i -> String.format("int %d", i);
        case Long l    -> String.format("long %d", l);
        case Double d  -> String.format("double %f", d);
        case String s  -> String.format("String %s", s);
        default        -> obj.toString();
    };
}
```

### Guarded Patterns (when clause)

```java
String classify(Shape shape) {
    return switch (shape) {
        case Circle c when c.radius() > 100   -> "large circle";
        case Circle c                          -> "small circle";
        case Rectangle r when r.width() == r.height() -> "square";
        case Rectangle r                       -> "rectangle";
    };
}
```

### Null Handling in Switch

Java 21 allows null as a case label:
```java
String handle(String input) {
    return switch (input) {
        case null      -> "no input";
        case "yes"     -> "affirmative";
        case "no"      -> "negative";
        case String s  -> "other: " + s;
    };
}
```

### Exhaustiveness with Sealed Types

With sealed interfaces/classes, the switch can be exhaustive without a default:
```java
sealed interface Result permits Success, Failure {}
record Success(String value) implements Result {}
record Failure(Exception error) implements Result {}

String handle(Result result) {
    return switch (result) {
        case Success(String value) -> "OK: " + value;
        case Failure(Exception e)  -> "Error: " + e.getMessage();
    };  // No default needed -- compiler verifies exhaustiveness
}
```

### Where to Apply

Scan for these refactoring opportunities:
- Chains of `if-else instanceof` -- convert to switch
- Switch on enum followed by type-specific logic
- Visitor pattern implementations
- Method dispatch based on object type

---

## Sealed Classes -- Finalized from Java 17

Sealed classes were introduced in Java 17 but are fully mature in Java 21. Key points for migration:

### Remove Preview Annotations

If you used sealed classes with `--enable-preview` in earlier Java versions:
```java
// Remove this if present
@SuppressWarnings("preview")
```

### Verify Permits Clauses

Ensure `permits` clauses are complete:
```java
public sealed interface PaymentMethod
    permits CreditCard, DebitCard, BankTransfer {
}
```

### Combine with Pattern Matching Switch

The real power of sealed classes comes with pattern matching:
```java
public sealed interface Event permits OrderPlaced, OrderShipped, OrderCancelled {}

String describe(Event event) {
    return switch (event) {
        case OrderPlaced e   -> "Order " + e.orderId() + " placed";
        case OrderShipped e  -> "Order " + e.orderId() + " shipped";
        case OrderCancelled e -> "Order " + e.orderId() + " cancelled";
    };
}
```

---

## Sequenced Collections (JEP 431) -- New in Java 21

### New Interfaces

Java 21 adds three new interfaces to the collections hierarchy:

- **SequencedCollection**: Collection with defined encounter order
- **SequencedSet**: Set with defined encounter order
- **SequencedMap**: Map with defined encounter order

### Key Methods

```java
// SequencedCollection methods
interface SequencedCollection<E> extends Collection<E> {
    SequencedCollection<E> reversed();
    void addFirst(E e);
    void addLast(E e);
    E getFirst();
    E getLast();
    E removeFirst();
    E removeLast();
}
```

### Refactoring Opportunities

Before:
```java
List<String> list = getItems();
String first = list.get(0);
String last = list.get(list.size() - 1);

// Reverse iteration
ListIterator<String> it = list.listIterator(list.size());
while (it.hasPrevious()) { /* ... */ }
```

After:
```java
List<String> list = getItems();
String first = list.getFirst();
String last = list.getLast();

// Reverse iteration
for (String item : list.reversed()) { /* ... */ }
```

### Collections that implement SequencedCollection

- `ArrayList`, `LinkedList` implement `SequencedCollection`
- `LinkedHashSet` implements `SequencedSet`
- `LinkedHashMap` implements `SequencedMap`
- `TreeSet` implements `SequencedSet`
- `TreeMap` implements `SequencedMap`
- `SortedSet` extends `SequencedSet`
- `SortedMap` extends `SequencedMap`
- `Deque` extends `SequencedCollection`

### Where to Apply

Scan for:
- `list.get(0)` -> `list.getFirst()`
- `list.get(list.size() - 1)` -> `list.getLast()`
- Manual reverse iteration -> `collection.reversed()`
- `Collections.reverse(list)` for iteration -> `list.reversed()` (non-destructive view)

---

## String Templates -- Preview in Java 21

**Status**: Preview feature. Requires `--enable-preview`. Do NOT use in production code.

String templates provide a safer, more readable way to compose strings with embedded expressions.

```java
// Preview syntax -- DO NOT use in production
String name = "World";
String greeting = STR."Hello, \{name}!";  // "Hello, World!"

// Multiline
String json = STR."""
    {
        "name": "\{name}",
        "age": \{age}
    }
    """;
```

**Recommendation**: Awareness only. Continue using `String.format()`, `MessageFormat`, or string concatenation until String Templates exit preview.

---

## Migration Patterns Quick Reference

| Old Pattern | New Java 21 Pattern | Feature |
|------------|---------------------|---------|
| `if (x instanceof Foo f) { f.bar(); }` | `switch (x) { case Foo f -> f.bar(); }` | Pattern matching switch |
| `if (x instanceof Rec(var a, var b))` after cast | Direct destructure | Record patterns |
| `list.get(0)` | `list.getFirst()` | Sequenced collections |
| `list.get(list.size()-1)` | `list.getLast()` | Sequenced collections |
| Manual reverse iteration | `list.reversed()` | Sequenced collections |
| if-else chain on types | switch with type patterns | Pattern matching switch |
| Visitor pattern boilerplate | sealed + switch | Sealed + patterns |
| `@SuppressWarnings("preview")` on sealed | Remove annotation | Sealed finalization |
