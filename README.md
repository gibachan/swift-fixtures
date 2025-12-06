# swift-fixtures

A Swift package that simplifies unit test writing by providing fixtures for Swift value types through a macro system.

## Motivation

When writing unit tests, you often need to create model objects that are not the focus of your test logic. This library helps you generate these objects easily with `.fixture`, allowing you to focus on what you're actually testing rather than spending time on boilerplate object creation.

The `@Fixture` macro generates fixture methods for structs and enums, making test data creation simple and consistent.

## Installation

Add swift-fixtures to your project using Swift Package Manager:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/gibachan/swift-fixtures.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "Fixtures", package: "swift-fixtures")
        ]
    )
]
```

## Features

- ✅ **Struct support** - Generate fixtures for struct types
- ✅ **Enum support** - Generate fixtures for enum types
- ✅ **Nested types** - Support for nested structs and enums
- ✅ **Builder pattern** - Customize properties using closures
- ✅ **Default values** - Automatic handling of properties with default values
- ❌ **Class support** - Classes (reference types) are not supported

## Usage

```swift
@Fixture
struct User {
  let id: String
  let name: String
  var age: Int

  @Fixture
  enum Role {
    case guest
    case user(String)
    case admin(String, permissions: [String])
  }
  var role: Role
}

// Generate fixture with default values
let user: User = .fixture
// User(id: "a", name: "a", age: 1, role: .guest)

// Customize specific properties
let bob = User.fixture {
  $0.name = "Bob"
  $0.age = 30
  $0.role = .admin("admin123", permissions: ["read", "write"])
}
// User(id: "a", name: "Bob", age: 30, role: .admin("admin123", permissions: ["read", "write"]))
```

## Requirements

- Swift 5.9+
- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+

## Development

```bash
make build    # Build project
make test     # Run tests
make format   # Format code
make lint     # Lint code
make clean    # Clean build artifacts
make help     # Show all commands
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.