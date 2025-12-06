import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

import FixturesMacros

final class ClassTests: XCTestCase {
  func testClass() throws {
    assertMacroExpansion(
      """
      @Fixture
      class Room {
          let name: String
      
          init(name: String) {
              self.name = name
          }
      
          init() {
              self.name = "test"
          }
      }
      """,
      expandedSource: """
      class Room {
          let name: String
      
          init(name: String) {
              self.name = name
          }
      
          init() {
              self.name = "test"
          }
      }
      
      extension Room {
          public static var fixture: Room {
              return .init(name: .fixture)
          }
      }
      """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }
}
