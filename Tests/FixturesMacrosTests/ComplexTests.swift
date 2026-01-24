import FixturesMacros
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

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

        extension User.Rank: Fixtureable {
            #if DEBUG
            static var fixture: Self {
                .bronze
            }
            #endif
        }

        extension User: Fixtureable {
            #if DEBUG
            init(fixtureid: String, fixturevehicle: Vehicle, fixturemoney: Money, fixturerank: Rank) {
                id = fixtureid
                vehicle = fixturevehicle
                money = fixturemoney
                rank = fixturerank
            }
            static var fixture: Self {
                .init(fixtureid: .fixture, fixturevehicle: .fixture, fixturemoney: .fixture, fixturerank: .fixture)
            }
            struct FixtureBuilder {
                var id: String = .fixture
                var vehicle: Vehicle = .fixture
                var money: Money = .fixture
                var rank: Rank = .fixture
            }
            static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self {
                var builder = FixtureBuilder()
                configure(&builder)
                return .init(fixtureid: builder.id, fixturevehicle: builder.vehicle, fixturemoney: builder.money, fixturerank: builder.rank)
            }
            #endif
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }
}
