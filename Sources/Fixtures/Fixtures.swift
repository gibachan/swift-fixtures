import Foundation

// MARK: - Fixtureable Protocol

#if DEBUG

/// A protocol that provides fixture values for types.
///
/// Types conforming to `Fixtureable` can provide a default fixture value
/// that can be used in tests and other scenarios where a sample instance is needed.
///
/// - Note: This protocol's functionality is only available in DEBUG builds.
///   In release builds, the protocol has no requirements.
public protocol Fixtureable {
  /// A default fixture value for this type.
  static var fixture: Self { get }
}

#else

/// Empty protocol for release builds.
/// Types will automatically conform with no requirements.
public protocol Fixtureable {}

#endif

#if DEBUG

// MARK: - Basic Types

/// Built-in fixture support for `String` type.
/// Returns a single character "a" as the default fixture value.
extension String: Fixtureable {
  public static var fixture: Self { "a" }
}

/// Built-in fixture support for `Int` type.
/// Returns `1` as the default fixture value.
extension Int: Fixtureable {
  public static var fixture: Self { 1 }
}

/// Built-in fixture support for `Bool` type.
/// Returns `true` as the default fixture value.
extension Bool: Fixtureable {
  public static var fixture: Self { true }
}

// MARK: - Numeric Types

/// Built-in fixture support for `Double` type.
/// Returns `1.0` as the default fixture value.
extension Double: Fixtureable {
  public static var fixture: Self { 1.0 }
}

/// Built-in fixture support for `Float` type.
/// Returns `1.0` as the default fixture value.
extension Float: Fixtureable {
  public static var fixture: Self { 1.0 }
}

/// Built-in fixture support for `UInt` type.
/// Returns `1` as the default fixture value.
extension UInt: Fixtureable {
  public static var fixture: Self { 1 }
}

/// Built-in fixture support for `UInt8` type.
/// Returns `1` as the default fixture value.
extension UInt8: Fixtureable {
  public static var fixture: Self { 1 }
}

/// Built-in fixture support for `UInt16` type.
/// Returns `1` as the default fixture value.
extension UInt16: Fixtureable {
  public static var fixture: Self { 1 }
}

/// Built-in fixture support for `UInt32` type.
/// Returns `1` as the default fixture value.
extension UInt32: Fixtureable {
  public static var fixture: Self { 1 }
}

/// Built-in fixture support for `UInt64` type.
/// Returns `1` as the default fixture value.
extension UInt64: Fixtureable {
  public static var fixture: Self { 1 }
}

/// Built-in fixture support for `Int8` type.
/// Returns `1` as the default fixture value.
extension Int8: Fixtureable {
  public static var fixture: Self { 1 }
}

/// Built-in fixture support for `Int16` type.
/// Returns `1` as the default fixture value.
extension Int16: Fixtureable {
  public static var fixture: Self { 1 }
}

/// Built-in fixture support for `Int32` type.
/// Returns `1` as the default fixture value.
extension Int32: Fixtureable {
  public static var fixture: Self { 1 }
}

/// Built-in fixture support for `Int64` type.
/// Returns `1` as the default fixture value.
extension Int64: Fixtureable {
  public static var fixture: Self { 1 }
}

// MARK: - Foundation Types

/// Built-in fixture support for `Date` type.
/// Returns Unix epoch (January 1, 1970 at 00:00:00 UTC) as the default fixture value.
extension Date: Fixtureable {
  public static var fixture: Self { Date(timeIntervalSince1970: 0) }
}

/// Built-in fixture support for `URL` type.
/// Returns `https://example.com` as the default fixture value.
extension URL: Fixtureable {
  public static var fixture: Self { URL(string: "https://example.com")! }
}

/// Built-in fixture support for `UUID` type.
/// Returns a zero UUID (`00000000-0000-0000-0000-000000000000`) as the default fixture value.
extension UUID: Fixtureable {
  public static var fixture: Self { UUID(uuidString: "00000000-0000-0000-0000-000000000000")! }
}

/// Built-in fixture support for `Data` type.
/// Returns empty `Data` as the default fixture value.
extension Data: Fixtureable {
  public static var fixture: Self { Data() }
}

// MARK: - Collection Types

/// Built-in fixture support for `Array` type where elements conform to `Fixtureable`.
/// Returns an array with 3 fixture elements as the default fixture value.
extension Array: Fixtureable where Element: Fixtureable {
  public static var fixture: Self {
    (0..<3).map { _ in Element.fixture }
  }
}

/// Built-in fixture support for `Optional` type.
/// Returns `nil` as the default fixture value.
extension Optional: Fixtureable {
  public static var fixture: Self {
    nil
  }
}

#endif

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
