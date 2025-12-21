# Basic Usage

Learn the fundamental patterns for using fixtures in your tests.

## Overview

The `@Fixture` macro provides several convenient ways to create test instances. This guide covers the most common usage patterns.

## Simple Fixture Access

The most straightforward way to use fixtures is through the static `fixture` property:

```swift
@Fixture
struct User {
    let name: String
    let age: Int
    let email: String
}

let user = User.fixture
// Creates: User(name: "a", age: 1, email: "a")
```

## Customizing Properties

Use the closure-based `fixture` method to customize specific properties:

```swift
let customUser = User.fixture {
    $0.name = "Alice Johnson"
    $0.age = 28
}
// email remains "a" (default fixture value)
```

## Using the Fixture Initializer

Access the generated initializer with `fixture` prefixed parameters:

```swift
let specificUser = User(
    fixtureName: "Bob Smith",
    fixtureAge: 35,
    fixtureEmail: "bob@example.com"
)
```

## Working with Default Values

Properties with default values use those defaults in the fixture initializer:

```swift
@Fixture
struct Settings {
    let theme: String = "dark"
    let notifications: Bool
    let language: String = "en"
}

// Only notifications needs to be specified
let settings = Settings(fixtureNotifications: true)
// theme = "dark", language = "en" (from defaults)
```

## Enum Fixtures

Enums use their first case as the fixture value:

```swift
@Fixture
enum Status {
    case pending
    case approved
    case rejected
}

let status = Status.fixture
// Returns: .pending
```

### Enums with Associated Values

The macro automatically provides fixture values for associated types:

```swift
@Fixture
enum Result {
    case success(data: String)
    case failure(error: String)
}

let result = Result.fixture
// Returns: .success(data: .fixture) which is .success(data: "a")
```

## Collection Types

Arrays and other collections work seamlessly with fixtures:

```swift
@Fixture
struct Team {
    let name: String
    let members: [User]
    let settings: Settings?
}

let team = Team.fixture
// Creates team with 3 User fixtures and nil settings
```

## Builder Pattern

The `@Fixture` macro generates a `FixtureBuilder` struct that provides a powerful way to create customized test instances. This pattern offers type-safe property modification and clear test intent.

### How FixtureBuilder Works

For every struct with `@Fixture`, a corresponding `FixtureBuilder` is generated:

```swift
@Fixture
struct Product {
    let id: UUID
    let name: String
    let price: Double
    let category: String
    let inStock: Bool
}

// Generated FixtureBuilder (conceptual)
struct FixtureBuilder {
    var id: UUID = .fixture
    var name: String = .fixture
    var price: Double = .fixture
    var category: String = .fixture
    var inStock: Bool = .fixture
}
```

### Builder Advantages

#### Type Safety

The builder ensures you can only set valid properties with correct types:

```swift
Product.fixture {
    $0.name = "Test Product"    // ✅ Valid
    $0.price = "expensive"      // ❌ Compile error - wrong type
    $0.invalidProperty = true   // ❌ Compile error - property doesn't exist
}
```

#### Clear Test Intent

Builders make test setup self-documenting:

```swift
func testDiscountCalculation() {
    let regularProduct = Product.fixture {
        $0.price = 100.0
        $0.category = "Regular"
    }

    let premiumProduct = Product.fixture {
        $0.price = 100.0
        $0.category = "Premium"
    }

    // Test logic is clear about what differs between products
}
```

#### Partial Customization

Only modify the properties that matter for your test:

```swift
let outOfStockProduct = Product.fixture {
    $0.inStock = false
    // All other properties use their fixture defaults
}
```

### Advanced Builder Patterns

#### Builder Extensions

Add convenience methods to builders:

```swift
extension Product {
    static func premiumFixture(_ configure: (inout FixtureBuilder) -> Void = { _ in }) -> Product {
        Product.fixture {
            // Set premium defaults
            $0.category = "Premium"
            $0.price = 500.0
            $0.inStock = true
            // Apply additional customizations
            configure(&$0)
        }
    }

    static func budgetFixture(_ configure: (inout FixtureBuilder) -> Void = { _ in }) -> Product {
        Product.fixture {
            $0.category = "Budget"
            $0.price = 50.0
            configure(&$0)
        }
    }
}

// Usage
let customPremium = Product.premiumFixture {
    $0.name = "Custom Premium Product"
}

let customBudget = Product.budgetFixture {
    $0.name = "Custom Budget Product"
}
```

#### Nested Builder Patterns

Handle complex object graphs:

```swift
@Fixture
struct Order {
    let id: UUID
    let customer: Customer
    let items: [Product]
    let total: Double
    let status: OrderStatus
}

@Fixture
struct Customer {
    let id: UUID
    let name: String
    let email: String
    let isPremium: Bool
}

let complexOrder = Order.fixture {
    $0.customer = Customer.fixture {
        $0.name = "John Doe"
        $0.email = "john@example.com"
        $0.isPremium = true
    }

    $0.items = [
        Product.fixture {
            $0.name = "Product A"
            $0.price = 25.0
        },
        Product.fixture {
            $0.name = "Product B"
            $0.price = 75.0
        }
    ]

    $0.total = $0.items.reduce(0) { $0 + $1.price }
    $0.status = .confirmed
}
```

## Best Practices

### Test Readability

Focus on the data that matters for your test:

```swift
func testUserValidation() {
    let invalidUser = User.fixture {
        $0.email = "invalid-email"
    }

    XCTAssertThrowsError(try validateUser(invalidUser))
}
```

### Reusable Fixtures

Create helper methods for commonly used fixture variations:

```swift
extension User {
    static var adminFixture: User {
        User.fixture {
            $0.name = "Admin User"
            $0.email = "admin@company.com"
        }
    }

    static var readOnlyUserFixture: User {
        User.fixture {
            $0.role = .user
            $0.permissions = [.read]
            $0.isActive = true
        }
    }

    static var suspendedUserFixture: User {
        User.fixture {
            $0.isActive = false
            $0.permissions = []
        }
    }
}
```

### Complex Objects

Build complex test scenarios step by step:

```swift
let project = Project.fixture {
    $0.name = "Test Project"
    $0.owner = User.adminFixture
    $0.team = Team.fixture {
        $0.members = [User.fixture, User.fixture, User.adminFixture]
    }
}
```

### Use Builders for Edge Cases

Test boundary conditions with specific builders:

```swift
extension BankAccount {
    static var overdraftFixture: BankAccount {
        BankAccount.fixture {
            $0.balance = -100.0  // Negative balance
            $0.overdraftLimit = 500.0
            $0.isActive = true
        }
    }

    static var zeroBalanceFixture: BankAccount {
        BankAccount.fixture {
            $0.balance = 0.0
        }
    }
}
```

## Custom Fixture Implementations

### Manual Fixtureable Conformance

When you need custom fixture logic, implement `Fixtureable` directly:

```swift
struct ComplexCalculation {
    let input: Double
    let algorithmType: String
    let result: Double

    init(input: Double, algorithmType: String) {
        self.input = input
        self.algorithmType = algorithmType
        self.result = performCalculation(input, algorithmType)
    }
}

extension ComplexCalculation: Fixtureable {
    static var fixture: Self {
        // Create a meaningful test case
        ComplexCalculation(input: 100.0, algorithmType: "fast")
    }
}
```

### External Type Extensions

Add fixture support to types you don't own:

```swift
// For a third-party library type
import ExternalLibrary

extension ExternalType: Fixtureable {
    static var fixture: Self {
        ExternalType(
            name: .fixture,
            value: .fixture
        )
    }
}

// Now you can use .fixture with external types
let external: ExternalType = .fixture
```
