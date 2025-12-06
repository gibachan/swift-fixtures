# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Swift package that provides fixtures for Swift types through a macro system. It consists of:

- **Fixtures Library** (`Sources/Fixtures/`): Core protocol and built-in type extensions
- **FixturesMacros** (`Sources/FixturesMacros/`): Compiler plugin that implements the `@Fixture` macro
- **FixturesClient** (`Sources/FixturesClient/`): Example client demonstrating usage
- **Tests** (`Tests/`): Comprehensive test suite using Swift Testing framework

## Architecture

### Core Components

1. **Fixtureable Protocol** (`Sources/Fixtures/Fixtures.swift:5-7`): Defines the contract for types that can provide fixtures
2. **@Fixture Macro** (`Sources/Fixtures/Fixtures.swift:75-83`): Attached extension macro that generates fixture implementations
3. **FixtureMacro Implementation** (`Sources/FixturesMacros/FixturesMacro.swift:23-40`): Handles struct and enum fixture generation
4. **Parameter Helper** (`Sources/FixturesMacros/Parameter.swift`): Represents macro expansion parameters

### Macro Implementation Details

The `@Fixture` macro generates different implementations based on the target type:

- **Structs**: Creates an initializer with `fixture` prefixed parameters and a static `fixture` property
- **Enums**: Uses the first case as the fixture value, handling associated values automatically

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

The project uses **Swift Testing** (not XCTest). Key patterns:

- Tests are marked with `@Test` attribute
- Assertions use `#expect()` instead of `XCTAssert`
- Test structs are marked with `@MainActor`
- Macro testing uses `SwiftSyntaxMacrosTestSupport` for expansion verification

## Target Dependencies

- **Fixtures**: Depends on FixturesMacros
- **FixturesMacros**: Depends on swift-syntax (SwiftSyntaxMacros, SwiftCompilerPlugin)
- **FixturesClient**: Depends on Fixtures
- **Tests**: Use SwiftSyntaxMacrosTestSupport for macro testing

## Platform Support

Supports iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+, and macCatalyst 13+.