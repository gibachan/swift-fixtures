import Foundation

// MARK: - Fixtureable Protocol

/// A protocol that provides fixture values for types.
///
/// Types conforming to `Fixtureable` can provide a default fixture value
/// that can be used in tests and other scenarios where a sample instance is needed.
public protocol Fixtureable {
  /// A default fixture value for this type.
  static var fixture: Self { get }
}

// MARK: - Basic Types

extension String: Fixtureable {
  public static var fixture: Self { "a" }
}

extension Int: Fixtureable {
  public static var fixture: Self { 1 }
}

extension Bool: Fixtureable {
  public static var fixture: Self { true }
}

// MARK: - Numeric Types

extension Double: Fixtureable {
  public static var fixture: Self { 1.0 }
}

extension Float: Fixtureable {
  public static var fixture: Self { 1.0 }
}

extension UInt: Fixtureable {
  public static var fixture: Self { 1 }
}

extension UInt8: Fixtureable {
  public static var fixture: Self { 1 }
}

extension UInt16: Fixtureable {
  public static var fixture: Self { 1 }
}

extension UInt32: Fixtureable {
  public static var fixture: Self { 1 }
}

extension UInt64: Fixtureable {
  public static var fixture: Self { 1 }
}

extension Int8: Fixtureable {
  public static var fixture: Self { 1 }
}

extension Int16: Fixtureable {
  public static var fixture: Self { 1 }
}

extension Int32: Fixtureable {
  public static var fixture: Self { 1 }
}

extension Int64: Fixtureable {
  public static var fixture: Self { 1 }
}

// MARK: - Foundation Types

extension Date: Fixtureable {
  public static var fixture: Self { Date(timeIntervalSince1970: 0) }
}

extension URL: Fixtureable {
  public static var fixture: Self { URL(string: "https://example.com")! }
}

extension UUID: Fixtureable {
  public static var fixture: Self { UUID(uuidString: "00000000-0000-0000-0000-000000000000")! }
}

extension Data: Fixtureable {
  public static var fixture: Self { Data() }
}

// MARK: - Collection Types

extension Array: Fixtureable where Element: Fixtureable {
  public static var fixture: Self {
    (0..<3).map { _ in Element.fixture }
  }
}

extension Optional: Fixtureable {
  public static var fixture: Self {
    nil
  }
}

// MARK: - Macro Definition

/// A macro that generates fixture support for structs and enums.
///
/// The `@Fixture` macro automatically generates:
/// - Conformance to the `Fixtureable` protocol
/// - A static `fixture` property that returns a sample instance
/// - A fixture initializer with `fixture` prefixed parameters
/// - A `FixtureBuilder` struct for customizable fixture creation
/// - A closure-based `fixture` method for property customization
///
/// ## Usage
///
/// ```swift
/// @Fixture
/// struct User {
///   let name: String
///   var age: Int
/// }
///
/// let user = User.fixture
/// let customUser = User.fixture { $0.name = "Alice" }
/// ```
///
/// ## Supported Types
/// - ✅ Structs: Full fixture generation with builder pattern
/// - ✅ Enums: Uses first case as fixture value, handles associated values
/// - ❌ Classes: Not supported (value types only)
@attached(
  extension,
  conformances: Fixtureable,
  names: named(init), named(fixture), named(FixtureBuilder)
)
public macro Fixture() =
  #externalMacro(
    module: "FixturesMacros",
    type: "FixtureMacro"
  )
