import Foundation

// MARK: - Fixtureable Protocol

public protocol Fixtureable {
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

@attached(
  extension,
  conformances: Fixtureable,
  names: named(init), named(fixture)
)
public macro Fixture() = #externalMacro(
  module: "FixturesMacros",
  type: "FixtureMacro"
)

