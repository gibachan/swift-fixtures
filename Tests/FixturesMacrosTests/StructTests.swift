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
            init(fixtureid: String, fixtureage: Int, fixtureisAdmin: Bool) {
                id = fixtureid
                age = fixtureage
                isAdmin = fixtureisAdmin
            }
            public static var fixture: Self {
                .init(fixtureid: .fixture, fixtureage: .fixture, fixtureisAdmin: .fixture)
            }
            public struct FixtureBuilder {
                public var id: String = .fixture
                public var age: Int = .fixture
                public var isAdmin: Bool = .fixture
            }
            public static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixtureid: builder.id, fixtureage: builder.age, fixtureisAdmin: builder.isAdmin)
            }
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
            init(fixturename: String) {
                name = fixturename
            }
            public static var fixture: Self {
                .init(fixturename: .fixture)
            }
            public struct FixtureBuilder {
                public var name: String = .fixture
            }
            public static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturename: builder.name)
            }
        }

        extension User.Money: Fixtureable {
            init(fixtureyen: Int) {
                yen = fixtureyen
            }
            public static var fixture: Self {
                .init(fixtureyen: .fixture)
            }
            public struct FixtureBuilder {
                public var yen: Int = .fixture
            }
            public static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixtureyen: builder.yen)
            }
        }

        extension User: Fixtureable {
            init(fixtureid: String, fixturevehicle: Vehicle, fixturemoney: Money) {
                id = fixtureid
                vehicle = fixturevehicle
                money = fixturemoney
            }
            public static var fixture: Self {
                .init(fixtureid: .fixture, fixturevehicle: .fixture, fixturemoney: .fixture)
            }
            public struct FixtureBuilder {
                public var id: String = .fixture
                public var vehicle: Vehicle = .fixture
                public var money: Money = .fixture
            }
            public static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixtureid: builder.id, fixturevehicle: builder.vehicle, fixturemoney: builder.money)
            }
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
            init(fixturefirstName: String, fixturelastName: String) {
                firstName = fixturefirstName
                lastName = fixturelastName
            }
            public static var fixture: Self {
                .init(fixturefirstName: .fixture, fixturelastName: .fixture)
            }
            public struct FixtureBuilder {
                public var firstName: String = .fixture
                public var lastName: String = .fixture
            }
            public static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturefirstName: builder.firstName, fixturelastName: builder.lastName)
            }
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
            init() {
            }
            public static var fixture: Self {
                .init()
            }
            public struct FixtureBuilder {
            }
            public static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init()
            }
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
            init(fixturename: String, fixtureage: Int?) {
                name = fixturename
                age = fixtureage
            }
            public static var fixture: Self {
                .init(fixturename: .fixture, fixtureage: .fixture)
            }
            public struct FixtureBuilder {
                public var name: String = .fixture
                public var age: Int? = .fixture
            }
            public static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturename: builder.name, fixtureage: builder.age)
            }
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
            init(fixturename: String) {
                name = fixturename
            }
            public static var fixture: Self {
                .init(fixturename: .fixture)
            }
            public struct FixtureBuilder {
                public var name: String = .fixture
            }
            public static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturename: builder.name)
            }
        }

        extension Team: Fixtureable {
            init(fixturename: String, fixturemembers: [Item]) {
                name = fixturename
                members = fixturemembers
            }
            public static var fixture: Self {
                .init(fixturename: .fixture, fixturemembers: .fixture)
            }
            public struct FixtureBuilder {
                public var name: String = .fixture
                public var members: [Item] = .fixture
            }
            public static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturename: builder.name, fixturemembers: builder.members)
            }
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
            init(fixturetimeout: Int = .fixture, fixtureretryCount: Int = .fixture, fixturename: String) {
                timeout = fixturetimeout
                retryCount = fixtureretryCount
                name = fixturename
            }
            public static var fixture: Self {
                .init(fixturename: .fixture)
            }
            public struct FixtureBuilder {
                public var timeout: Int = .fixture
                public var retryCount: Int = .fixture
                public var name: String = .fixture
            }
            public static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixturetimeout: builder.timeout, fixtureretryCount: builder.retryCount, fixturename: builder.name)
            }
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }
}
