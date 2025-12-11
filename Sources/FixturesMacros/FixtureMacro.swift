import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - Diagnostic Messages

enum FixtureMacroError: String, DiagnosticMessage {
  case noEnumCases = "Enum must have at least one case to generate fixture"
  case unsupportedType = "Only structs and enums are supported for @Fixture macro"

  var message: String { rawValue }

  var diagnosticID: MessageID {
    MessageID(domain: "swift-fixtures", id: rawValue)
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
    } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
      return processEnum(node: node, decl: enumDecl, type: type, context: context)
    } else {
      context.diagnose(
        Diagnostic(
          node: Syntax(node),
          message: FixtureMacroError.unsupportedType
        )
      )
      return []
    }
  }
}

// MARK: - Constants

extension FixtureMacro {
  fileprivate static let fixtureableProtocol = "Fixtureable"
  fileprivate static let fixturePropertyName = "fixture"
}

// MARK: - Processing Methods

extension FixtureMacro {
  fileprivate static func processStruct(
    decl: StructDeclSyntax,
    type: some TypeSyntaxProtocol
  ) -> [ExtensionDeclSyntax] {
    let parameters = extractParameters(from: decl)
    let accessModifier = extractAccessModifier(from: decl)
    return [
      ExtensionDeclSyntax(
        extensionKeyword: .keyword(.extension),
        extendedType: type,
        inheritanceClause: InheritanceClauseSyntax {
          InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier(fixtureableProtocol)))
        },
        memberBlock: MemberBlockSyntax(
          members: MemberBlockItemListSyntax {
            MemberBlockItemSyntax(decl: createFixtureInitializer(for: parameters, accessModifier: accessModifier))
            MemberBlockItemSyntax(decl: createStaticFixtureProperty(for: parameters, accessModifier: accessModifier))
            MemberBlockItemSyntax(decl: createFixtureBuilderStruct(for: parameters, accessModifier: accessModifier))
            MemberBlockItemSyntax(decl: createClosureBasedFixtureMethod(for: parameters, accessModifier: accessModifier))
          }
        )
      )
    ]
  }

  fileprivate static func processEnum(
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
    let accessModifier = extractAccessModifier(from: decl)

    var modifiers: [DeclModifierSyntax] = []
    if let accessModifier = accessModifier {
      modifiers.append(DeclModifierSyntax(name: accessModifier.name))
    }
    modifiers.append(DeclModifierSyntax(name: .keyword(.static)))

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
                modifiers: DeclModifierListSyntax(modifiers),
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

// MARK: - Access Modifier Helper

extension FixtureMacro {
  fileprivate static func extractAccessModifier(
    from declaration: some DeclGroupSyntax
  ) -> DeclModifierSyntax? {
    let accessKeywords: [Keyword] = [.public, .internal, .fileprivate, .private, .package]
    return declaration.modifiers.first { modifier in
      guard case .keyword(let keyword) = modifier.name.tokenKind else {
        return false
      }
      return accessKeywords.contains(keyword)
    }
  }

  fileprivate static func createAccessModifiers(
    from declaration: some DeclGroupSyntax,
    includeStatic: Bool = false
  ) -> DeclModifierListSyntax {
    var modifiers: [DeclModifierSyntax] = []
    if let accessModifier = extractAccessModifier(from: declaration) {
      modifiers.append(DeclModifierSyntax(name: accessModifier.name))
    }
    if includeStatic {
      modifiers.append(DeclModifierSyntax(name: .keyword(.static)))
    }
    return DeclModifierListSyntax(modifiers)
  }
}

// MARK: - Helper Methods

extension FixtureMacro {
  fileprivate static func createFixtureAccessExpression() -> MemberAccessExprSyntax {
    MemberAccessExprSyntax(
      declName: DeclReferenceExprSyntax(baseName: .identifier(fixturePropertyName))
    )
  }

  fileprivate static func createEnumCaseFixtureExpression(for enumCase: EnumCaseElementSyntax)
    -> ExprSyntax
  {
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
        for parameter in parameterClause.parameters {
          LabeledExprSyntax(
            label: parameter.firstName,
            colon: parameter.firstName != nil ? .colonToken() : nil,
            expression: createFixtureAccessExpression()
          )
        }
      },
      rightParen: .rightParenToken()
    )

    return ExprSyntax(functionCall)
  }

  fileprivate static func extractParameters(
    from declaration: some DeclGroupSyntax
  ) -> [Parameter] {
    return declaration.memberBlock.members.compactMap { member in
      guard let variable = member.decl.as(VariableDeclSyntax.self),
        let patternBinding = variable.bindings.first,
        let identifierPattern = patternBinding.pattern.as(IdentifierPatternSyntax.self),
        let typeAnnotation = patternBinding.typeAnnotation
      else {
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

  fileprivate static func createFixtureInitializer(
    for parameters: [Parameter],
    accessModifier: DeclModifierSyntax?
  ) -> InitializerDeclSyntax {
    let functionParameters = parameters.map { parameter in
      FunctionParameterSyntax(
        firstName: .identifier(parameter.fixtureParameterName),
        type: parameter.type,
        defaultValue: parameter.hasDefaultValue
          ? InitializerClauseSyntax(
            value: createFixtureAccessExpression()
          ) : nil
      )
    }

    let assignments = parameters.map { parameter in
      SequenceExprSyntax(
        elements: ExprListSyntax {
          DeclReferenceExprSyntax(baseName: parameter.identifier)
          AssignmentExprSyntax()
          DeclReferenceExprSyntax(baseName: .identifier(parameter.fixtureParameterName))
        })
    }

    var modifiers: [DeclModifierSyntax] = []
    if let accessModifier = accessModifier {
      modifiers.append(DeclModifierSyntax(name: accessModifier.name))
    }

    return InitializerDeclSyntax(
      modifiers: DeclModifierListSyntax(modifiers),
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

  fileprivate static func createStaticFixtureProperty(
    for properties: [Parameter],
    accessModifier: DeclModifierSyntax?
  ) -> VariableDeclSyntax {
    // Only include properties without default values in the .fixture initializer call
    // Properties with default values will use their default argument (.fixture)
    let arguments =
      properties
      .filter { !$0.hasDefaultValue }
      .map { property in
        LabeledExprSyntax(
          label: .identifier(property.fixtureParameterName),
          colon: .colonToken(),
          expression: createFixtureAccessExpression()
        )
      }

    var modifiers: [DeclModifierSyntax] = []
    if let accessModifier = accessModifier {
      modifiers.append(DeclModifierSyntax(name: accessModifier.name))
    }
    modifiers.append(DeclModifierSyntax(name: .keyword(.static)))

    return VariableDeclSyntax(
      modifiers: DeclModifierListSyntax(modifiers),
      bindingSpecifier: .keyword(.var),
      bindings: PatternBindingListSyntax {
        PatternBindingSyntax(
          pattern: IdentifierPatternSyntax(identifier: .identifier(fixturePropertyName)),
          typeAnnotation: TypeAnnotationSyntax(type: IdentifierTypeSyntax(name: "Self")),
          accessorBlock: AccessorBlockSyntax(
            accessors: AccessorBlockSyntax.Accessors(
              CodeBlockItemListSyntax {
                CodeBlockItemSyntax(
                  item: .expr(
                    ExprSyntax(
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

  fileprivate static func createFixtureBuilderStruct(
    for parameters: [Parameter],
    accessModifier: DeclModifierSyntax?
  ) -> StructDeclSyntax {
    var propertyModifiers: [DeclModifierSyntax] = []
    if let accessModifier = accessModifier {
      propertyModifiers.append(DeclModifierSyntax(name: accessModifier.name))
    }

    let properties = parameters.map { parameter in
      MemberBlockItemSyntax(
        decl: VariableDeclSyntax(
          modifiers: DeclModifierListSyntax(propertyModifiers),
          bindingSpecifier: .keyword(.var),
          bindings: PatternBindingListSyntax {
            PatternBindingSyntax(
              pattern: IdentifierPatternSyntax(identifier: parameter.identifier),
              typeAnnotation: TypeAnnotationSyntax(type: parameter.type),
              initializer: InitializerClauseSyntax(
                value: createFixtureAccessExpression()
              )
            )
          }
        )
      )
    }

    var structModifiers: [DeclModifierSyntax] = []
    if let accessModifier = accessModifier {
      structModifiers.append(DeclModifierSyntax(name: accessModifier.name))
    }

    return StructDeclSyntax(
      modifiers: DeclModifierListSyntax(structModifiers),
      name: .identifier("FixtureBuilder"),
      memberBlock: MemberBlockSyntax(
        members: MemberBlockItemListSyntax {
          for property in properties {
            property
          }
        }
      )
    )
  }

  fileprivate static func createClosureBasedFixtureMethod(
    for parameters: [Parameter],
    accessModifier: DeclModifierSyntax?
  ) -> FunctionDeclSyntax {
    let arguments = parameters.map { parameter in
      LabeledExprSyntax(
        label: .identifier(parameter.fixtureParameterName),
        colon: .colonToken(),
        expression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(baseName: .identifier("builder")),
          declName: DeclReferenceExprSyntax(baseName: parameter.identifier)
        )
      )
    }

    var modifiers: [DeclModifierSyntax] = []
    if let accessModifier = accessModifier {
      modifiers.append(DeclModifierSyntax(name: accessModifier.name))
    }
    modifiers.append(DeclModifierSyntax(name: .keyword(.static)))

    return FunctionDeclSyntax(
      modifiers: DeclModifierListSyntax(modifiers),
      name: .identifier("fixture"),
      signature: FunctionSignatureSyntax(
        parameterClause: FunctionParameterClauseSyntax(
          parameters: FunctionParameterListSyntax {
            FunctionParameterSyntax(
              firstName: .wildcardToken(),
              secondName: .identifier("configure"),
              type: FunctionTypeSyntax(
                parameters: TupleTypeElementListSyntax {
                  TupleTypeElementSyntax(
                    type: AttributedTypeSyntax(
                      specifiers: TypeSpecifierListSyntax {
                        SimpleTypeSpecifierSyntax(specifier: .keyword(.inout))
                      },
                      baseType: IdentifierTypeSyntax(name: .identifier("FixtureBuilder"))
                    )
                  )
                },
                returnClause: ReturnClauseSyntax(type: IdentifierTypeSyntax(name: "Void"))
              )
            )
          }
        ),
        returnClause: ReturnClauseSyntax(type: IdentifierTypeSyntax(name: "Self"))
      ),
      body: CodeBlockSyntax(
        statements: CodeBlockItemListSyntax {
          // var builder = FixtureBuilder()
          CodeBlockItemSyntax(
            item: .decl(
              DeclSyntax(
                VariableDeclSyntax(
                  bindingSpecifier: .keyword(.var),
                  bindings: PatternBindingListSyntax {
                    PatternBindingSyntax(
                      pattern: IdentifierPatternSyntax(identifier: .identifier("builder")),
                      initializer: InitializerClauseSyntax(
                        value: FunctionCallExprSyntax(
                          calledExpression: DeclReferenceExprSyntax(
                            baseName: .identifier("FixtureBuilder")),
                          leftParen: .leftParenToken(),
                          arguments: LabeledExprListSyntax {},
                          rightParen: .rightParenToken()
                        )
                      )
                    )
                  }
                )
              ))
          )
          // configure(&builder)
          CodeBlockItemSyntax(
            item: .expr(
              ExprSyntax(
                FunctionCallExprSyntax(
                  calledExpression: DeclReferenceExprSyntax(baseName: .identifier("configure")),
                  leftParen: .leftParenToken(),
                  arguments: LabeledExprListSyntax {
                    LabeledExprSyntax(
                      expression: PrefixOperatorExprSyntax(
                        operator: .prefixAmpersandToken(),
                        expression: DeclReferenceExprSyntax(baseName: .identifier("builder"))
                      )
                    )
                  },
                  rightParen: .rightParenToken()
                )
              ))
          )
          // return Self(fixtureName: builder.name, ...)
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
              ))
          )
        }
      )
    )
  }
}

// MARK: - Compiler Plugin

@main
struct StubKitMacroDemoPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] = [
    FixtureMacro.self
  ]
}
