import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

import FixturesMacros

final class StructTests: XCTestCase {
  func testStruct() throws {
    assertMacroExpansion(
      """
      @Fixture
      struct User {
          let id: String
          let age: Int
          let isRich: Bool
      }
      """,
      expandedSource: """
      struct User {
          let id: String
          let age: Int
          let isRich: Bool
      }
      
      extension User: Fixtureable {
          init(fixtureid: String, fixtureage: Int, fixtureisRich: Bool) {
              id = fixtureid
              age = fixtureage
              isRich = fixtureisRich
          }
          public static var fixture: Self {
              .init(fixtureid: .fixture, fixtureage: .fixture, fixtureisRich: .fixture)
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
      }
      
      extension User.Money: Fixtureable {
          init(fixtureyen: Int) {
              yen = fixtureyen
          }
          public static var fixture: Self {
              .init(fixtureyen: .fixture)
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
          let nickname: String?
          let age: Int?
      }
      """,
      expandedSource: """
      struct User {
          let name: String
          let nickname: String?
          let age: Int?
      }
      
      extension User: Fixtureable {
          init(fixturename: String, fixturenickname: String?, fixtureage: Int?) {
              name = fixturename
              nickname = fixturenickname
              age = fixtureage
          }
          public static var fixture: Self {
              .init(fixturename: .fixture, fixturenickname: .fixture, fixtureage: .fixture)
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
      }
      
      extension Team: Fixtureable {
          init(fixturename: String, fixturemembers: [Item]) {
              name = fixturename
              members = fixturemembers
          }
          public static var fixture: Self {
              .init(fixturename: .fixture, fixturemembers: .fixture)
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
        }
        """,
        macros: ["Fixture": FixtureMacro.self]
    )
  }
}
