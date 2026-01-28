# swift-fixtures

![CI](https://github.com/gibachan/swift-fixtures/workflows/CI/badge.svg)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)
![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

A Swift package that simplifies unit test writing by providing fixtures for Swift value types through a macro system.

## Motivation

When writing unit tests, you often need to create model objects that are not the focus of your test logic. This library helps you generate these objects easily with `.fixture`, allowing you to focus on what you're actually testing rather than spending time on boilerplate object creation.

The `@Fixture` macro generates fixture methods for structs and enums, making test data creation simple and consistent.

## Installation

Add swift-fixtures to your project using Swift Package Manager:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/gibachan/swift-fixtures.git", from: "0.4.0")
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

- ✅ **Struct fixtures** - Generate `.fixture` static property and customizable initializers
- ✅ **Enum fixtures** - Generate fixtures for enum types
- ✅ **Builder pattern** - Customize properties using closures: `Type.fixture { $0.property = value }`
- ✅ **Nested types** - Support for nested structs and enums
- ✅ **Standard type support** - 15+ pre-built fixtures for common types (String, Int, Date, URL, UUID, Arrays, etc.)
- ✅ **Type safety** - Recursive fixture generation for custom types conforming to `Fixtureable`
- ✅ **Debug-only code** - Fixture code is excluded from release builds using `#if DEBUG`
- ❌ **Class support** - Classes (reference types) are not supported
- 🚧 **Actor support** - Actors are not yet supported

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
    case user(name: String)
    case admin(id: String, permissions: [String])
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
  $0.role = .admin(id: "admin123", permissions: ["read", "write"])
}
// User(id: "a", name: "Bob", age: 30, role: .admin(id: "admin123", permissions: ["read", "write"]))
```

## External Library Types

The `@Fixture` macro can only be applied to types you define. For types from external libraries, you can manually conform to `Fixtureable`:

```swift
import ExternalLibrary
import Fixtures

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

## Documentation

Full DocC documentation is available:

- **Online**: [Swift Package Index](https://swiftpackageindex.com/gibachan/swift-fixtures/documentation) (automatically updated)
- **Local Generation**:
  ```bash
  # Generate and open documentation
  ./scripts/generate-docs.sh

  # Or using swift-docc-plugin
  swift package generate-documentation --target Fixtures

  # Or manually with xcodebuild
  xcodebuild docbuild -scheme Fixtures -destination 'platform=macOS'
  ```

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
