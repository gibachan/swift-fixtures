# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Swift package that simplifies unit test writing by providing fixtures for Swift types through a macro system.

### Purpose

The library aims to simplify unit test writing by:
- Reducing boilerplate code for creating test objects
- Allowing developers to focus on testing logic rather than object creation
- Providing consistent fixture generation for value types (structs and enums)
- Making test data creation simple with `.fixture` syntax

### Components

It consists of:

- **Fixtures Library** (`Sources/Fixtures/`): Core protocol and built-in type extensions
- **FixturesMacros** (`Sources/FixturesMacros/`): Compiler plugin that implements the `@Fixture` macro
- **FixturesClient** (`Sources/FixturesClient/`): Example client demonstrating usage
- **Tests** (`Tests/`): Comprehensive test suite

## Architecture

### Core Components

1. **Fixtureable Protocol** (`Sources/Fixtures/Fixtures.swift:9-12`): Defines the contract for types that can provide fixtures
2. **@Fixture Macro** (`Sources/Fixtures/Fixtures.swift:174-183`): Attached extension macro that generates fixture implementations
3. **FixtureMacro Implementation** (`Sources/FixturesMacros/FixtureMacro.swift:63-95`): Handles struct and enum fixture generation
4. **Parameter Helper** (`Sources/FixturesMacros/Parameter.swift`): Represents macro expansion parameters

### Built-in Fixtureable Extensions

The library provides fixture support for common types:

- **Basic Types**: `String` ("a"), `Int` (1), `Bool` (true)
- **Numeric Types**: `Double` (1.0), `Float` (1.0), `UInt`/`UInt8`/`UInt16`/`UInt32`/`UInt64` (1), `Int8`/`Int16`/`Int32`/`Int64` (1)
- **Foundation Types**: `Date` (Unix epoch), `URL` (https://example.com), `UUID` (zero UUID), `Data` (empty)
- **Collection Types**: `Array` (3 fixture elements), `Optional` (nil)

### Macro Implementation Details

The `@Fixture` macro generates different implementations based on the target type:

**For Structs**:
- `init(fixture...:)` initializer with `fixture` prefixed parameters
- `static var fixture` property returning default fixture instance
- `FixtureBuilder` struct for builder pattern support
- `static func fixture(_ configure:)` closure-based method for customization

**For Enums**:
- `static var fixture` property using the first enum case
- Automatic handling of associated values (labeled, unlabeled, and mixed)

### Supported Features

- **Computed Properties**: Automatically excluded from fixture generation
- **Property Observers**: Properties with `didSet`/`willSet` are excluded
- **Default Values**: Properties with default values get optional fixture parameters
- **Comma-separated Properties**: Supports `let id, name: String` syntax
- **Nested Types**: Full support for nested structs and enums
- **Access Modifiers**: Inherits `public`/`internal`/`fileprivate`/`private`/`package` from the type
- **Debug-only Code**: All generated fixture code is wrapped in `#if DEBUG`, ensuring no fixture code is included in release builds

## Common Development Commands

### Building
```bash
swift build
```

### Testing
```bash
# Run all tests
swift test

# Run specific test target
swift test --filter FixturesTests
swift test --filter FixturesMacrosTests

# Run a specific test
swift test --filter FixturesTests.FixtureTests/fixtureInt
```

### Running the Example
```bash
swift run FixturesClient
```

## Code Style

- **Indentation**: 2 spaces (configured in `.editorconfig`)
- **Macro Naming**: Use `FixtureMacro` for the main macro implementation
- **Parameter Naming**: Prefix with `fixture` for generated initializer parameters (e.g., `fixtureName`)
- **Error Handling**: Use `FixtureMacroError` enum for diagnostic messages

## Testing Framework

The project uses **XCTest**. Key patterns:

- **FixturesTests**: Tests for built-in Fixtureable extensions and runtime behavior
- **FixturesMacrosTests**: Tests for macro expansion verification using `SwiftSyntaxMacrosTestSupport`
  - `StructTests.swift`: Struct fixture generation tests
  - `EnumTests.swift`: Enum fixture generation tests
  - `ComplexTests.swift`: Nested types and complex scenarios
- Macro testing uses `assertMacroExpansion()` for expansion verification

## Target Dependencies

- **Fixtures**: Depends on FixturesMacros
- **FixturesMacros**: Depends on swift-syntax 602.0.0+ (SwiftSyntaxMacros, SwiftCompilerPlugin)
- **FixturesClient**: Depends on Fixtures
- **FixturesTests**: Depends on Fixtures
- **FixturesMacrosTests**: Depends on FixturesMacros, SwiftSyntaxMacrosTestSupport

## Platform Support

- **Swift tools version**: 6.2
- **Platforms**: iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+, macCatalyst 13+
- **Upcoming Features**: ExistentialAny enabled