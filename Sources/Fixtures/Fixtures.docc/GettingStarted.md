# Getting Started

Learn how to add the Fixtures library to your project and create your first fixtures.

## Installation

### Swift Package Manager

Add the Fixtures library to your project's `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/gibachan/swift-fixtures", from: "0.2.0")
]
```

Then add the library to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Fixtures", package: "swift-fixtures")
    ]
)
```

### Xcode Project

1. Go to **File → Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/gibachan/swift-fixtures`
3. Choose the version and add to your project

## Basic Setup

Import the Fixtures library in your Swift files:

```swift
import Fixtures
```

## Your First Fixture

Apply the `@Fixture` macro to any struct or enum:

```swift
@Fixture
struct Product {
    let id: UUID
    let name: String
    let price: Double
    let inStock: Bool
}
```

Now you can use the generated fixture in your tests:

```swift
func testProductCreation() {
    let product = Product.fixture
    XCTAssertNotNil(product.id)
    XCTAssertEqual(product.name, "a")
    XCTAssertEqual(product.price, 1.0)
    XCTAssertTrue(product.inStock)
}
```

## What Gets Generated

The `@Fixture` macro automatically generates:

1. **Conformance to `Fixtureable`** protocol
2. **Static fixture property** for quick access
3. **Fixture initializer** with prefixed parameters
4. **FixtureBuilder struct** for customization
5. **Closure-based fixture method** for property modification

## Next Steps

- Learn about <doc:BasicUsage> patterns, the builder pattern, and custom fixture implementations
