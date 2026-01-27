import FixturesMacros
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class StructTests: XCTestCase {
  func testStruct() throws {
    assertMacroExpansion(
      """
      @Fixture
      struct User {
          let id: String
          let age: Int
          let isAdmin: Bool
      }
      """,
      expandedSource: """
        struct User {
            let id: String
            let age: Int
            let isAdmin: Bool
        }

        extension User: Fixtureable {
            #if DEBUG
            init(fixtureid: String, fixtureage: Int, fixtureisAdmin: Bool) {
                id = fixtureid
                age = fixtureage
                isAdmin = fixtureisAdmin
            }
            static var fixture: Self {
                .init(fixtureid: .fixture, fixtureage: .fixture, fixtureisAdmin: .fixture)
            }
            struct FixtureBuilder {
                var id: String = .fixture
                var age: Int = .fixture
                var isAdmin: Bool = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixtureid: builder.id, fixtureage: builder.age, fixtureisAdmin: builder.isAdmin)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testNestedStruct() throws {
    assertMacroExpansion(
      """
      @Fixture
      struct Vehicle {
          let name: String
      }
      @Fixture
      struct User {
          let id: String
          var vehicle: Vehicle

          @Fixture
          struct Money {
              var yen: Int
          }
          var money: Money
      }
      """,
      expandedSource: """
        struct Vehicle {
            let name: String
        }
        struct User {
            let id: String
            var vehicle: Vehicle
            struct Money {
                var yen: Int
            }
            var money: Money
        }

        extension Vehicle: Fixtureable {
            #if DEBUG
            init(fixturename: String) {
                name = fixturename
            }
            static var fixture: Self {
                .init(fixturename: .fixture)
            }
            struct FixtureBuilder {
                var name: String = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturename: builder.name)
            }
            #endif
        }

        extension User.Money: Fixtureable {
            #if DEBUG
            init(fixtureyen: Int) {
                yen = fixtureyen
            }
            static var fixture: Self {
                .init(fixtureyen: .fixture)
            }
            struct FixtureBuilder {
                var yen: Int = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixtureyen: builder.yen)
            }
            #endif
        }

        extension User: Fixtureable {
            #if DEBUG
            init(fixtureid: String, fixturevehicle: Vehicle, fixturemoney: Money) {
                id = fixtureid
                vehicle = fixturevehicle
                money = fixturemoney
            }
            static var fixture: Self {
                .init(fixtureid: .fixture, fixturevehicle: .fixture, fixturemoney: .fixture)
            }
            struct FixtureBuilder {
                var id: String = .fixture
                var vehicle: Vehicle = .fixture
                var money: Money = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixtureid: builder.id, fixturevehicle: builder.vehicle, fixturemoney: builder.money)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testStructWithComputedProperty() throws {
    assertMacroExpansion(
      """
      @Fixture
      struct User {
          let firstName: String
          let lastName: String
          var fullName: String {
              "\\(firstName) \\(lastName)"
          }
      }
      """,
      expandedSource: """
        struct User {
            let firstName: String
            let lastName: String
            var fullName: String {
                "\\(firstName) \\(lastName)"
            }
        }

        extension User: Fixtureable {
            #if DEBUG
            init(fixturefirstName: String, fixturelastName: String) {
                firstName = fixturefirstName
                lastName = fixturelastName
            }
            static var fixture: Self {
                .init(fixturefirstName: .fixture, fixturelastName: .fixture)
            }
            struct FixtureBuilder {
                var firstName: String = .fixture
                var lastName: String = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturefirstName: builder.firstName, fixturelastName: builder.lastName)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testStructWithPropertyObserver() throws {
    assertMacroExpansion(
      """
      @Fixture
      struct Counter {
          var count: Int {
              didSet {
                  print("Changed")
              }
          }
      }
      """,
      expandedSource: """
        struct Counter {
            var count: Int {
                didSet {
                    print("Changed")
                }
            }
        }

        extension Counter: Fixtureable {
            #if DEBUG
            static var fixture: Self {
                .init()
            }
            struct FixtureBuilder {
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init()
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testStructWithOptionalProperty() throws {
    assertMacroExpansion(
      """
      @Fixture
      struct User {
          let name: String
          let age: Int?
      }
      """,
      expandedSource: """
        struct User {
            let name: String
            let age: Int?
        }

        extension User: Fixtureable {
            #if DEBUG
            init(fixturename: String, fixtureage: Int?) {
                name = fixturename
                age = fixtureage
            }
            static var fixture: Self {
                .init(fixturename: .fixture, fixtureage: .fixture)
            }
            struct FixtureBuilder {
                var name: String = .fixture
                var age: Int? = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturename: builder.name, fixtureage: builder.age)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testStructWithCustomArrayProperty() throws {
    assertMacroExpansion(
      """
      @Fixture
      struct Item {
          let name: String
      }
      @Fixture
      struct Team {
          let name: String
          let members: [Item]
      }
      """,
      expandedSource: """
        struct Item {
            let name: String
        }
        struct Team {
            let name: String
            let members: [Item]
        }

        extension Item: Fixtureable {
            #if DEBUG
            init(fixturename: String) {
                name = fixturename
            }
            static var fixture: Self {
                .init(fixturename: .fixture)
            }
            struct FixtureBuilder {
                var name: String = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturename: builder.name)
            }
            #endif
        }

        extension Team: Fixtureable {
            #if DEBUG
            init(fixturename: String, fixturemembers: [Item]) {
                name = fixturename
                members = fixturemembers
            }
            static var fixture: Self {
                .init(fixturename: .fixture, fixturemembers: .fixture)
            }
            struct FixtureBuilder {
                var name: String = .fixture
                var members: [Item] = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturename: builder.name, fixturemembers: builder.members)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testStructWithDefaultValues() throws {
    assertMacroExpansion(
      """
      @Fixture
      struct Config {
          var timeout: Int = 30
          var retryCount: Int = 3
          let name: String
      }
      """,
      expandedSource: """
        struct Config {
            var timeout: Int = 30
            var retryCount: Int = 3
            let name: String
        }

        extension Config: Fixtureable {
            #if DEBUG
            init(fixturetimeout: Int = .fixture, fixtureretryCount: Int = .fixture, fixturename: String) {
                timeout = fixturetimeout
                retryCount = fixtureretryCount
                name = fixturename
            }
            static var fixture: Self {
                .init(fixturename: .fixture)
            }
            struct FixtureBuilder {
                var timeout: Int = .fixture
                var retryCount: Int = .fixture
                var name: String = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturetimeout: builder.timeout, fixtureretryCount: builder.retryCount, fixturename: builder.name)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testPublicStruct() throws {
    // When a public struct has properties without explicit access modifiers,
    // those properties are implicitly internal. The generated init, FixtureBuilder,
    // and closure method use internal (no modifier) to avoid potentially exposing
    // internal types. The static var fixture remains public for protocol conformance.
    assertMacroExpansion(
      """
      @Fixture
      public struct User {
          let name: String
      }
      """,
      expandedSource: """
        public struct User {
            let name: String
        }

        extension User: Fixtureable {
            #if DEBUG
            init(fixturename: String) {
                name = fixturename
            }
            public static var fixture: Self {
                .init(fixturename: .fixture)
            }
            struct FixtureBuilder {
                var name: String = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturename: builder.name)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testInternalStruct() throws {
    assertMacroExpansion(
      """
      @Fixture
      internal struct User {
          let name: String
      }
      """,
      expandedSource: """
        internal struct User {
            let name: String
        }

        extension User: Fixtureable {
            #if DEBUG
            internal init(fixturename: String) {
                name = fixturename
            }
            internal static var fixture: Self {
                .init(fixturename: .fixture)
            }
            internal struct FixtureBuilder {
                internal var name: String = .fixture
            }
            internal static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturename: builder.name)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testImplicitInternalStruct() throws {
    assertMacroExpansion(
      """
      @Fixture
      struct User {
          let name: String
      }
      """,
      expandedSource: """
        struct User {
            let name: String
        }

        extension User: Fixtureable {
            #if DEBUG
            init(fixturename: String) {
                name = fixturename
            }
            static var fixture: Self {
                .init(fixturename: .fixture)
            }
            struct FixtureBuilder {
                var name: String = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturename: builder.name)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testPackageStruct() throws {
    // When a package struct has properties without explicit access modifiers,
    // those properties are implicitly internal. The generated init, FixtureBuilder,
    // and closure method use internal (no modifier) to avoid potentially exposing
    // internal types. The static var fixture remains package for protocol conformance.
    assertMacroExpansion(
      """
      @Fixture
      package struct Config {
          let timeout: Int
      }
      """,
      expandedSource: """
        package struct Config {
            let timeout: Int
        }

        extension Config: Fixtureable {
            #if DEBUG
            init(fixturetimeout: Int) {
                timeout = fixturetimeout
            }
            package static var fixture: Self {
                .init(fixturetimeout: .fixture)
            }
            struct FixtureBuilder {
                var timeout: Int = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturetimeout: builder.timeout)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testComment() throws {
    assertMacroExpansion(
      """
      @Fixture
      struct User {
          let id: String // comment
      }
      """,
      expandedSource: """
        struct User {
            let id: String // comment
        }

        extension User: Fixtureable {
            #if DEBUG
            init(fixtureid: String) {
                id = fixtureid
            }
            static var fixture: Self {
                .init(fixtureid: .fixture)
            }
            struct FixtureBuilder {
                var id: String = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixtureid: builder.id)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testCommaSeparatedProperties() throws {
    assertMacroExpansion(
      """
      @Fixture
      struct User {
          let id, name: String
          var age: Int
      }
      """,
      expandedSource: """
        struct User {
            let id, name: String
            var age: Int
        }

        extension User: Fixtureable {
            #if DEBUG
            init(fixtureid: String, fixturename: String, fixtureage: Int) {
                id = fixtureid
                name = fixturename
                age = fixtureage
            }
            static var fixture: Self {
                .init(fixtureid: .fixture, fixturename: .fixture, fixtureage: .fixture)
            }
            struct FixtureBuilder {
                var id: String = .fixture
                var name: String = .fixture
                var age: Int = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixtureid: builder.id, fixturename: builder.name, fixtureage: builder.age)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testStructWithStaticProperty() throws {
    assertMacroExpansion(
      """
      @Fixture
      struct Config {
          static let defaultTimeout: Int = 30
          static var sharedInstance: Config?
          let name: String
      }
      """,
      expandedSource: """
        struct Config {
            static let defaultTimeout: Int = 30
            static var sharedInstance: Config?
            let name: String
        }

        extension Config: Fixtureable {
            #if DEBUG
            init(fixturename: String) {
                name = fixturename
            }
            static var fixture: Self {
                .init(fixturename: .fixture)
            }
            struct FixtureBuilder {
                var name: String = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturename: builder.name)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testStructWithLazyProperty() throws {
    assertMacroExpansion(
      """
      @Fixture
      struct Cache {
          lazy var data: String = "cached"
          let id: String
      }
      """,
      expandedSource: """
        struct Cache {
            lazy var data: String = "cached"
            let id: String
        }

        extension Cache: Fixtureable {
            #if DEBUG
            init(fixtureid: String) {
                id = fixtureid
            }
            static var fixture: Self {
                .init(fixtureid: .fixture)
            }
            struct FixtureBuilder {
                var id: String = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixtureid: builder.id)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testPublicStructWithPackageProperty() throws {
    // When a public struct has a property with package access level,
    // the generated init, FixtureBuilder, and closure method should use package
    // to avoid exposing package types in public API.
    // However, `static var fixture: Self` can remain public since it only exposes Self.
    assertMacroExpansion(
      """
      @Fixture
      public struct Parent {
          package let child: String
      }
      """,
      expandedSource: """
        public struct Parent {
            package let child: String
        }

        extension Parent: Fixtureable {
            #if DEBUG
            package init(fixturechild: String) {
                child = fixturechild
            }
            public static var fixture: Self {
                .init(fixturechild: .fixture)
            }
            package struct FixtureBuilder {
                package var child: String = .fixture
                package init() {
                }
            }
            package static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturechild: builder.child)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testPublicStructWithPrivateProperty() throws {
    // When a public struct has a property with private access level,
    // the generated init, FixtureBuilder, and closure method should use private.
    assertMacroExpansion(
      """
      @Fixture
      public struct Container {
          private let value: Int
      }
      """,
      expandedSource: """
        public struct Container {
            private let value: Int
        }

        extension Container: Fixtureable {
            #if DEBUG
            private init(fixturevalue: Int) {
                value = fixturevalue
            }
            public static var fixture: Self {
                .init(fixturevalue: .fixture)
            }
            private struct FixtureBuilder {
                private var value: Int = .fixture
            }
            private static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturevalue: builder.value)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testPublicStructWithImplicitInternalProperty() throws {
    // When a public struct has a property with no explicit access modifier,
    // that property is implicitly internal. The generated init, FixtureBuilder,
    // and closure method should use internal (no modifier) to avoid exposing
    // internal types in public API.
    assertMacroExpansion(
      """
      @Fixture
      public struct Container {
          let value: String
      }
      """,
      expandedSource: """
        public struct Container {
            let value: String
        }

        extension Container: Fixtureable {
            #if DEBUG
            init(fixturevalue: String) {
                value = fixturevalue
            }
            public static var fixture: Self {
                .init(fixturevalue: .fixture)
            }
            struct FixtureBuilder {
                var value: String = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturevalue: builder.value)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }
}
