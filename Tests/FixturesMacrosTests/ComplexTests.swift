import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

import FixturesMacros

final class ComplexTests: XCTestCase {
  func testComplexStruct() throws {
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
      
          @Fixture
          enum Rank {
              case bronze, silver, gold
          }
          var rank: Rank
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
          enum Rank {
              case bronze, silver, gold
          }
          var rank: Rank
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
      
      extension User.Rank: Fixtureable {
          public static var fixture: Self {
              .bronze
          }
      }
      
      extension User: Fixtureable {
          init(fixtureid: String, fixturevehicle: Vehicle, fixturemoney: Money, fixturerank: Rank) {
              id = fixtureid
              vehicle = fixturevehicle
              money = fixturemoney
              rank = fixturerank
          }
          public static var fixture: Self {
              .init(fixtureid: .fixture, fixturevehicle: .fixture, fixturemoney: .fixture, fixturerank: .fixture)
          }
      }
      """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }
}
