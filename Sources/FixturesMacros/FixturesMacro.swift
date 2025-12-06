import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - Diagnostic Messages

enum FixtureMacroError: String, DiagnosticMessage {
  case noEnumCases = "Enum must have at least one case to generate fixture"
  
  var message: String { rawValue }
  
  var diagnosticID: MessageID {
    MessageID(domain: "StubKitMacroDemo", id: rawValue)
  }
  
  var severity: DiagnosticSeverity { .error }
}

// MARK: - Macro Implementation

public struct FixtureMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    if let structDecl = declaration.as(StructDeclSyntax.self) {
      return processStruct(decl: structDecl, type: type)
    } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
      return processClass(decl: classDecl, type: type)
    } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
      return processEnum(node: node, decl: enumDecl, type: type, context: context)
    } else {
      fatalError("Not supported type")
    }
  }
}

// MARK: - Constants

private extension FixtureMacro {
  static let fixtureableProtocol = "Fixtureable"
  static let fixturePropertyName = "fixture"
}

// MARK: - Processing Methods

private extension FixtureMacro {
  static func processStruct(
    decl: StructDeclSyntax,
    type: some TypeSyntaxProtocol
  ) -> [ExtensionDeclSyntax] {
    let parameters = extractParameters(from: decl)
    return [
      ExtensionDeclSyntax(
        extensionKeyword: .keyword(.extension),
        extendedType: type,
        inheritanceClause: InheritanceClauseSyntax {
          InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier(fixtureableProtocol)))
        },
        memberBlock: MemberBlockSyntax(
          members: MemberBlockItemListSyntax {
            MemberBlockItemSyntax(decl: createFixtureInitializer(for: parameters))
            MemberBlockItemSyntax(decl: createStaticFixtureProperty(for: parameters))
          }
        )
      )
    ]
  }
  
  static func processClass(
    decl: ClassDeclSyntax,
    type: some TypeSyntaxProtocol
  ) -> [ExtensionDeclSyntax] {
    let initializers = decl.memberBlock.members.compactMap { member in
      member.decl.as(InitializerDeclSyntax.self)
    }
    guard let initializer = initializers.first else {
      return []
    }
    
    let arguments = initializer.signature.parameterClause.parameters.map { parameter in
      LabeledExprSyntax(
        label: parameter.firstName,
        colon: .colonToken(),
        expression: createFixtureAccessExpression()
      )
    }
    
    let variableDecl = VariableDeclSyntax(
      modifiers: [
        DeclModifierSyntax(name: .keyword(.public)),
        DeclModifierSyntax(name: .keyword(.static))
      ],
      bindingSpecifier: .keyword(.var),
      bindings: PatternBindingListSyntax {
        PatternBindingSyntax(
          pattern: IdentifierPatternSyntax(identifier: .identifier(fixturePropertyName)),
          typeAnnotation: TypeAnnotationSyntax(type: type),
          accessorBlock: AccessorBlockSyntax(
            accessors: AccessorBlockSyntax.Accessors(
              CodeBlockItemListSyntax {
                CodeBlockItemSyntax(
                  item: .stmt(
                    StmtSyntax(
                      ReturnStmtSyntax(
                        expression: FunctionCallExprSyntax(
                          calledExpression: MemberAccessExprSyntax(
                            declName: DeclReferenceExprSyntax(
                              baseName: .keyword(.`init`)
                            )
                          ),
                          leftParen: .leftParenToken(),
                          arguments: LabeledExprListSyntax {
                            for argument in arguments {
                              argument
                            }
                          },
                          rightParen: .rightParenToken()
                        )
                      )
                    )
                  )
                )
              }
            )
          )
        )
      }
    )
    
    return [
      ExtensionDeclSyntax(
        extensionKeyword: .keyword(.extension),
        extendedType: type,
        memberBlock: MemberBlockSyntax(
          members: MemberBlockItemListSyntax {
            MemberBlockItemSyntax(
              decl: variableDecl
            )
          }
        )
      )
    ]
  }
  
  static func processEnum(
    node: AttributeSyntax,
    decl: EnumDeclSyntax,
    type: some TypeSyntaxProtocol,
    context: some MacroExpansionContext
  ) -> [ExtensionDeclSyntax] {
    let enumCaseDecls = decl.memberBlock.members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
    let enumCaseElements = enumCaseDecls.flatMap { $0.elements }
    
    guard let firstEnumCase = enumCaseElements.first else {
      context.diagnose(
        Diagnostic(
          node: Syntax(node),
          message: FixtureMacroError.noEnumCases
        )
      )
      return []
    }
    
    let mockExpression = createEnumCaseFixtureExpression(for: firstEnumCase)
    
    return [
      ExtensionDeclSyntax(
        extensionKeyword: .keyword(.extension),
        extendedType: type,
        inheritanceClause: InheritanceClauseSyntax {
          InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier(fixtureableProtocol)))
        },
        memberBlock: MemberBlockSyntax(
          members: MemberBlockItemListSyntax {
            MemberBlockItemSyntax(
              decl: VariableDeclSyntax(
                modifiers: [
                  DeclModifierSyntax(name: .keyword(.public)),
                  DeclModifierSyntax(name: .keyword(.static))
                ],
                bindingSpecifier: .keyword(.var),
                bindings: PatternBindingListSyntax {
                  PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(identifier: .identifier(fixturePropertyName)),
                    typeAnnotation: TypeAnnotationSyntax(type: IdentifierTypeSyntax(name: "Self")),
                    accessorBlock: AccessorBlockSyntax(
                      accessors: AccessorBlockSyntax.Accessors(
                        CodeBlockItemListSyntax {
                          CodeBlockItemSyntax(
                            item: .expr(ExprSyntax(mockExpression))
                          )
                        }
                      )
                    )
                  )
                }
              )
            )
          }
        )
      )
    ]
  }
}

// MARK: - Helper Methods

private extension FixtureMacro {
  static func createFixtureAccessExpression() -> MemberAccessExprSyntax {
    MemberAccessExprSyntax(
      declName: DeclReferenceExprSyntax(baseName: .identifier(fixturePropertyName))
    )
  }
  
  static func createEnumCaseFixtureExpression(for enumCase: EnumCaseElementSyntax) -> ExprSyntax {
    let caseName = enumCase.name.text
    let memberAccess = MemberAccessExprSyntax(
      declName: DeclReferenceExprSyntax(baseName: .identifier(caseName))
    )
    
    // Check if the enum case has associated values
    guard let parameterClause = enumCase.parameterClause else {
      // No associated values, return simple member access like .normal
      return ExprSyntax(memberAccess)
    }
    
    // Has associated values, create function call with .fixture for each parameter
    let functionCall = FunctionCallExprSyntax(
      calledExpression: memberAccess,
      leftParen: .leftParenToken(),
      arguments: LabeledExprListSyntax {
        for _ in parameterClause.parameters {
          LabeledExprSyntax(
            expression: createFixtureAccessExpression()
          )
        }
      },
      rightParen: .rightParenToken()
    )
    
    return ExprSyntax(functionCall)
  }
  
  static func extractParameters(
    from declaration: some DeclGroupSyntax
  ) -> [Parameter] {
    return declaration.memberBlock.members.compactMap { member in
      guard let variable = member.decl.as(VariableDeclSyntax.self),
            let patternBinding = variable.bindings.first,
            let identifierPattern = patternBinding.pattern.as(IdentifierPatternSyntax.self),
            let typeAnnotation = patternBinding.typeAnnotation else {
        return nil
      }
      
      // Exclude computed properties (properties with accessor blocks like { get } or { willSet })
      // We only want stored properties for fixture initialization
      if patternBinding.accessorBlock != nil {
        return nil
      }
      
      // Check if the property has a default value
      let hasDefaultValue = patternBinding.initializer != nil
      
      return Parameter(
        identifier: identifierPattern.identifier,
        type: typeAnnotation.type,
        hasDefaultValue: hasDefaultValue
      )
    }
  }
  
  static func createFixtureInitializer(
    for parameters: [Parameter]
  ) -> InitializerDeclSyntax {
    let functionParameters = parameters.map { parameter in
      FunctionParameterSyntax(
        firstName: .identifier(parameter.fixtureParameterName),
        type: parameter.type,
        defaultValue: parameter.hasDefaultValue ? InitializerClauseSyntax(
          value: createFixtureAccessExpression()
        ) : nil
      )
    }
    
    let assignments = parameters.map { parameter in
      SequenceExprSyntax(elements: ExprListSyntax {
        DeclReferenceExprSyntax(baseName: parameter.identifier)
        AssignmentExprSyntax()
        DeclReferenceExprSyntax(baseName: .identifier(parameter.fixtureParameterName))
      })
    }
    
    return InitializerDeclSyntax(
      signature: FunctionSignatureSyntax(
        parameterClause: FunctionParameterClauseSyntax(
          parametersBuilder: {
            functionParameters.map { $0 }
          }
        )
      ),
      body: CodeBlockSyntax(
        statements: CodeBlockItemListSyntax(itemsBuilder: {
          assignments.map { $0 }
        })
      )
    )
  }
  
  static func createStaticFixtureProperty(
    for properties: [Parameter]
  ) -> VariableDeclSyntax {
    // Only include properties without default values in the .fixture initializer call
    // Properties with default values will use their default argument (.fixture)
    let arguments = properties
      .filter { !$0.hasDefaultValue }
      .map { property in
        LabeledExprSyntax(
          label: .identifier(property.fixtureParameterName),
          colon: .colonToken(),
          expression: createFixtureAccessExpression()
        )
      }
    
    return VariableDeclSyntax(
      modifiers: [
        DeclModifierSyntax(name: .keyword(.public)),
        DeclModifierSyntax(name: .keyword(.static))
      ],
      bindingSpecifier: .keyword(.var),
      bindings: PatternBindingListSyntax {
        PatternBindingSyntax(
          pattern: IdentifierPatternSyntax(identifier: .identifier(fixturePropertyName)),
          typeAnnotation: TypeAnnotationSyntax(type: IdentifierTypeSyntax(name: "Self")),
          accessorBlock: AccessorBlockSyntax(
            accessors: AccessorBlockSyntax.Accessors(
              CodeBlockItemListSyntax {
                CodeBlockItemSyntax(
                  item: .expr(ExprSyntax(
                    FunctionCallExprSyntax(
                      calledExpression: MemberAccessExprSyntax(
                        declName: DeclReferenceExprSyntax(
                          baseName: .keyword(.`init`)
                        )
                      ),
                      leftParen: .leftParenToken(),
                      arguments: LabeledExprListSyntax {
                        for argument in arguments {
                          argument
                        }
                      },
                      rightParen: .rightParenToken()
                    )
                  ))
                )
              }
            )
          )
        )
      }
    )
  }
}

// MARK: - Compiler Plugin

@main
struct StubKitMacroDemoPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    FixtureMacro.self,
  ]
}
