import FixturesMacros
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

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
            static var fixture: Self {
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
        DiagnosticSpec(
          message: "Enum must have at least one case to generate fixture", line: 1, column: 1)
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
            static var fixture: Self {
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
            static var fixture: Self {
                .data(.fixture, .fixture, .fixture)
            }
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }
  func testEnumWithMultipleNamedAssociatedValues() throws {
    assertMacroExpansion(
      """
      @Fixture
      enum Event {
          case userAction(userId: String, action: String, timestamp: Int)
          case systemEvent(code: Int)
      }
      """,
      expandedSource: """
        enum Event {
            case userAction(userId: String, action: String, timestamp: Int)
            case systemEvent(code: Int)
        }

        extension Event: Fixtureable {
            static var fixture: Self {
                .userAction(userId: .fixture, action: .fixture, timestamp: .fixture)
            }
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testEnumWithMixedAssociatedValues() throws {
    assertMacroExpansion(
      """
      @Fixture
      enum Mixed {
          case mixed(String, named: Int, Bool)
      }
      """,
      expandedSource: """
        enum Mixed {
            case mixed(String, named: Int, Bool)
        }

        extension Mixed: Fixtureable {
            static var fixture: Self {
                .mixed(.fixture, named: .fixture, .fixture)
            }
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testPublicEnum() throws {
    assertMacroExpansion(
      """
      @Fixture
      public enum Status {
          case active
          case inactive
      }
      """,
      expandedSource: """
        public enum Status {
            case active
            case inactive
        }

        extension Status: Fixtureable {
            public static var fixture: Self {
                .active
            }
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testImplicitInternalEnum() throws {
    assertMacroExpansion(
      """
      @Fixture
      enum Status {
          case active
          case inactive
      }
      """,
      expandedSource: """
        enum Status {
            case active
            case inactive
        }

        extension Status: Fixtureable {
            static var fixture: Self {
                .active
            }
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testEnumWithComment() throws {
    assertMacroExpansion(
      """
      @Fixture
      enum Status {
          case active // This is active status
          case inactive
      }
      """,
      expandedSource: """
        enum Status {
            case active // This is active status
            case inactive
        }

        extension Status: Fixtureable {
            static var fixture: Self {
                .active
            }
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }

  func testEnumWithAssociatedValueAndComment() throws {
    assertMacroExpansion(
      """
      @Fixture
      enum Result {
          case success(String) // Success with value
          case failure(Error)
      }
      """,
      expandedSource: """
        enum Result {
            case success(String) // Success with value
            case failure(Error)
        }

        extension Result: Fixtureable {
            static var fixture: Self {
                .success(.fixture)
            }
        }
        """,
      macros: ["Fixture": FixtureMacro.self]
    )
  }
}
