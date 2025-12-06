import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

import FixturesMacros

final class EnumTests: XCTestCase {
  func testEnum() throws {
    assertMacroExpansion(
      """
      @Fixture
      enum AccountType {
          case normal, premium
          case administrator
      }
      """,
      expandedSource: """
      enum AccountType {
          case normal, premium
          case administrator
      }
      
      extension AccountType: Fixtureable {
          public static var fixture: Self {
              .normal
          }
      }
      """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testEmptyEnum() throws {
    assertMacroExpansion(
      """
      @Fixture
      enum EmptyEnum {
      }
      """,
      expandedSource: """
      enum EmptyEnum {
      }
      """,
      diagnostics: [
        DiagnosticSpec(message: "Enum must have at least one case to generate fixture", line: 1, column: 1)
      ],
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testEnumWithAssociatedValue() throws {
    assertMacroExpansion(
      """
      @Fixture
      enum Result {
          case success(String)
          case failure(Error)
      }
      """,
      expandedSource: """
      enum Result {
          case success(String)
          case failure(Error)
      }
      
      extension Result: Fixtureable {
          public static var fixture: Self {
              .success(.fixture)
          }
      }
      """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testEnumWithMultipleAssociatedValues() throws {
    assertMacroExpansion(
      """
      @Fixture
      enum Complex {
          case data(String, Int, Bool)
          case simple
      }
      """,
      expandedSource: """
      enum Complex {
          case data(String, Int, Bool)
          case simple
      }
      
      extension Complex: Fixtureable {
          public static var fixture: Self {
              .data(.fixture, .fixture, .fixture)
          }
      }
      """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }
}
