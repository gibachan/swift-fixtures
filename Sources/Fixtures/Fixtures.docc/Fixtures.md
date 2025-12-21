# ``Fixtures``

Simplify unit test writing by providing fixtures for Swift types through a macro system.

## Overview

The Fixtures library provides a simple and powerful way to create test fixtures for your Swift types. By applying the `@Fixture` macro to your structs and enums, you can automatically generate fixture values that make writing unit tests faster and more maintainable.

### Key Features

- **Zero Boilerplate**: Apply `@Fixture` and get instant fixture support
- **Type Safety**: All fixtures are statically typed and compile-time verified
- **Flexible Creation**: Multiple ways to create and customize fixture instances
- **Built-in Support**: Common types like `String`, `Int`, `Date`, and collections already supported

### Quick Example

```swift
import Fixtures

@Fixture
struct User {
    let id: UUID
    let name: String
    let age: Int
    let isActive: Bool
}

// Use in tests
let user = User.fixture
let customUser = User.fixture {
    $0.name = "Alice"
    $0.age = 25
}
```

## Topics

### Getting Started

- <doc:GettingStarted>
- <doc:BasicUsage>

### Core Components

- ``Fixtureable``
- ``Fixture()``

