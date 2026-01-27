import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - Diagnostic Messages

/// Error types that can occur during `@Fixture` macro expansion.
///
/// These diagnostic messages provide clear feedback when the macro encounters
/// unsupported types or invalid declarations during compilation.
enum FixtureMacroError: String, DiagnosticMessage {
  /// Indicates that an enum declaration has no cases defined.
  /// The `@Fixture` macro requires at least one enum case to generate a fixture value.
  case noEnumCases = "Enum must have at least one case to generate fixture"

  /// Indicates that the macro was applied to an unsupported declaration type.
  /// The `@Fixture` macro only supports struct and enum declarations.
  case unsupportedType = "Only structs and enums are supported for @Fixture macro"

  var message: String { rawValue }

  var diagnosticID: MessageID {
    MessageID(domain: "swift-fixtures", id: rawValue)
  }

  var severity: DiagnosticSeverity { .error }
}

// MARK: - Macro Implementation

/// The main implementation of the `@Fixture` macro.
///
/// `FixtureMacro` is an extension macro that generates fixture support for Swift types.
/// It implements the `ExtensionMacro` protocol to provide automatic conformance to the
/// `Fixtureable` protocol along with fixture generation methods.
///
/// ## How It Works
///
/// When applied to a declaration, the macro analyzes the type and generates:
/// - **For Structs**: Complete fixture infrastructure including initializers, static properties, and builder patterns
/// - **For Enums**: Simple fixture support using the first enum case
///
/// All generated members are wrapped in `#if DEBUG ... #endif` to ensure they are only
/// included in debug builds. The `Fixtureable` conformance is also only applied in
/// debug builds.
///
/// ## Generated Code
///
/// For structs, the macro generates:
/// ```swift
/// extension YourStruct: Fixtureable {
///   #if DEBUG
///   init(fixtureName: String = .fixture, fixtureAge: Int = .fixture, ...)
///   static var fixture: Self { ... }
///   struct FixtureBuilder { ... }
///   static func fixture(_ configure: (inout FixtureBuilder) -> Void) -> Self { ... }
///   #endif
/// }
/// ```
///
/// For enums, it generates:
/// ```swift
/// extension YourEnum: Fixtureable {
///   #if DEBUG
///   static var fixture: Self { .firstCase }
///   #endif
/// }
/// ```
public struct FixtureMacro: ExtensionMacro {
  /// Expands the `@Fixture` macro for supported declaration types.
  ///
  /// - Parameters:
  ///   - node: The attribute syntax node representing the `@Fixture` macro
  ///   - declaration: The declaration the macro is attached to (struct or enum)
  ///   - type: The type syntax for the target type
  ///   - protocols: The protocols to conform to (includes `Fixtureable`)
  ///   - context: The macro expansion context for diagnostics
  /// - Returns: An array of extension declarations providing fixture functionality
  /// - Throws: Compilation errors for unsupported types
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    // Extract access modifier from enclosing extension if present
    let enclosingAccessModifier = extractEnclosingAccessModifier(from: context)

    if let structDecl = declaration.as(StructDeclSyntax.self) {
      return [processStruct(decl: structDecl, type: type, enclosingAccessModifier: enclosingAccessModifier)]
    } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
      if let extensionDecl = processEnum(node: node, decl: enumDecl, type: type, context: context, enclosingAccessModifier: enclosingAccessModifier) {
        return [extensionDecl]
      }
      return []
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

  /// Wraps member declarations in `#if DEBUG ... #endif`.
  fileprivate static func wrapMembersInIfDebug(_ members: [MemberBlockItemSyntax]) -> MemberBlockItemListSyntax {
    let ifConfigDecl = IfConfigDeclSyntax(
      clauses: IfConfigClauseListSyntax {
        IfConfigClauseSyntax(
          poundKeyword: .poundIfToken(),
          condition: DeclReferenceExprSyntax(baseName: .identifier("DEBUG")),
          elements: .decls(MemberBlockItemListSyntax(members))
        )
      },
      poundEndif: .poundEndifToken()
    )
    return MemberBlockItemListSyntax {
      MemberBlockItemSyntax(decl: ifConfigDecl)
    }
  }

  /// Creates an extension declaration with Fixtureable conformance.
  ///
  /// This helper function reduces code duplication between `processStruct` and `processEnum`
  /// by centralizing the extension creation logic.
  ///
  /// - Parameters:
  ///   - type: The type syntax for the extended type
  ///   - members: The member declarations to include in the extension
  /// - Returns: An extension declaration with Fixtureable conformance
  fileprivate static func createExtension(
    type: some TypeSyntaxProtocol,
    members: [MemberBlockItemSyntax]
  ) -> ExtensionDeclSyntax {
    return ExtensionDeclSyntax(
      extensionKeyword: .keyword(.extension),
      extendedType: type,
      inheritanceClause: InheritanceClauseSyntax {
        InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier(fixtureableProtocol)))
      },
      memberBlock: MemberBlockSyntax(
        members: wrapMembersInIfDebug(members)
      )
    )
  }
}

// MARK: - Constants

extension FixtureMacro {
  fileprivate static let fixtureableProtocol = "Fixtureable"
  fileprivate static let fixturePropertyName = "fixture"
}

// MARK: - Processing Methods

extension FixtureMacro {
  /// Processes a struct declaration to generate fixture support.
  ///
  /// This method analyzes the struct's properties and generates a complete
  /// fixture infrastructure including initializers, static properties, and
  /// builder patterns for flexible test data creation. All members are wrapped
  /// in `#if DEBUG` to exclude them from release builds.
  ///
  /// - Parameters:
  ///   - decl: The struct declaration syntax to process
  ///   - type: The type syntax for the struct
  ///   - enclosingAccessModifier: Access modifier from the enclosing extension, if any
  /// - Returns: Extension declaration providing fixture functionality
  fileprivate static func processStruct(
    decl: StructDeclSyntax,
    type: some TypeSyntaxProtocol,
    enclosingAccessModifier: DeclModifierSyntax?
  ) -> ExtensionDeclSyntax {
    let parameters = extractParameters(from: decl)
    // Use the type's explicit access modifier, or fall back to enclosing extension's modifier
    let typeAccessModifier = extractAccessModifier(from: decl) ?? enclosingAccessModifier
    // Compute effective access level considering property access modifiers
    // This ensures we don't expose types with more restrictive access levels
    let effectiveAccessModifier = computeEffectiveAccessModifier(
      typeAccessModifier: typeAccessModifier,
      parameters: parameters
    )
    // Note: `static var fixture: Self` uses the type's access modifier because
    // its signature only exposes `Self`, not internal property types.
    // This allows it to satisfy the Fixtureable protocol requirement.
    // Other members (init, FixtureBuilder, closure method) use the effective
    // access modifier because they expose property types in their signatures.
    var members: [MemberBlockItemSyntax] = []
    // Only generate init for structs with parameters.
    // Empty structs already have a synthesized init() which would conflict.
    if !parameters.isEmpty {
      members.append(MemberBlockItemSyntax(decl: createFixtureInitializer(for: parameters, accessModifier: effectiveAccessModifier)))
    }
    members.append(MemberBlockItemSyntax(decl: createStaticFixtureProperty(for: parameters, accessModifier: typeAccessModifier)))
    members.append(MemberBlockItemSyntax(decl: createFixtureBuilderStruct(for: parameters, accessModifier: effectiveAccessModifier)))
    members.append(MemberBlockItemSyntax(decl: createClosureBasedFixtureMethod(for: parameters, accessModifier: effectiveAccessModifier)))
    return createExtension(type: type, members: members)
  }

  /// Processes an enum declaration to generate fixture support.
  ///
  /// This method analyzes the enum's cases and generates a fixture implementation
  /// using the first available case. For cases with associated values, it automatically
  /// provides fixture values for all associated types. All members are wrapped
  /// in `#if DEBUG` to exclude them from release builds.
  ///
  /// - Parameters:
  ///   - node: The attribute syntax node for error reporting
  ///   - decl: The enum declaration syntax to process
  ///   - type: The type syntax for the enum
  ///   - context: The macro expansion context for diagnostics
  ///   - enclosingAccessModifier: Access modifier from the enclosing extension, if any
  /// - Returns: Extension declaration providing fixture functionality, or nil if no cases
  fileprivate static func processEnum(
    node: AttributeSyntax,
    decl: EnumDeclSyntax,
    type: some TypeSyntaxProtocol,
    context: some MacroExpansionContext,
    enclosingAccessModifier: DeclModifierSyntax?
  ) -> ExtensionDeclSyntax? {
    let enumCaseDecls = decl.memberBlock.members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
    let enumCaseElements = enumCaseDecls.flatMap { $0.elements }

    guard let firstEnumCase = enumCaseElements.first else {
      context.diagnose(
        Diagnostic(
          node: Syntax(node),
          message: FixtureMacroError.noEnumCases
        )
      )
      return nil
    }

    let fixtureExpression = createEnumCaseFixtureExpression(for: firstEnumCase)
    // Use the type's explicit access modifier, or fall back to enclosing extension's modifier
    let accessModifier = extractAccessModifier(from: decl) ?? enclosingAccessModifier

    let members = [
      MemberBlockItemSyntax(
        decl: createStaticFixturePropertyWithBody(accessModifier: accessModifier, body: fixtureExpression)
      )
    ]

    return createExtension(type: type, members: members)
  }
}

// MARK: - Modifier Helpers

extension FixtureMacro {
  /// Creates a `static var fixture: Self` property with the given body expression.
  ///
  /// This helper centralizes the static fixture property generation to reduce code
  /// duplication between struct and enum processing.
  ///
  /// - Parameters:
  ///   - accessModifier: Optional access modifier (public, internal, etc.)
  ///   - body: The expression to use as the property's getter body
  /// - Returns: A VariableDeclSyntax for `static var fixture: Self { body }`
  fileprivate static func createStaticFixturePropertyWithBody(
    accessModifier: DeclModifierSyntax?,
    body: ExprSyntax
  ) -> VariableDeclSyntax {
    VariableDeclSyntax(
      modifiers: buildModifiers(accessModifier: accessModifier, includeStatic: true),
      bindingSpecifier: .keyword(.var),
      bindings: PatternBindingListSyntax {
        PatternBindingSyntax(
          pattern: IdentifierPatternSyntax(identifier: .identifier(fixturePropertyName)),
          typeAnnotation: TypeAnnotationSyntax(type: IdentifierTypeSyntax(name: "Self")),
          accessorBlock: AccessorBlockSyntax(
            accessors: .getter(
              CodeBlockItemListSyntax {
                CodeBlockItemSyntax(item: .expr(body))
              }
            )
          )
        )
      }
    )
  }

  /// Creates a DeclModifierListSyntax with optional access modifier and static keyword.
  ///
  /// This helper centralizes modifier list construction to reduce code duplication
  /// across multiple code generation methods.
  ///
  /// - Parameters:
  ///   - accessModifier: Optional access modifier (public, internal, etc.)
  ///   - includeStatic: Whether to include the `static` keyword
  /// - Returns: A modifier list suitable for declaration syntax nodes
  fileprivate static func buildModifiers(
    accessModifier: DeclModifierSyntax?,
    includeStatic: Bool = false
  ) -> DeclModifierListSyntax {
    var modifiers: [DeclModifierSyntax] = []
    if let accessModifier = accessModifier {
      modifiers.append(DeclModifierSyntax(name: accessModifier.name.trimmed))
    }
    if includeStatic {
      modifiers.append(DeclModifierSyntax(name: .keyword(.static)))
    }
    return DeclModifierListSyntax(modifiers)
  }
}

// MARK: - Access Modifier Helper

extension FixtureMacro {
  /// Extracts access modifier from the enclosing lexical context (e.g., extension).
  ///
  /// When a type is defined inside an extension with an access modifier like
  /// `package extension Parent { struct Child { } }`, this function extracts
  /// that access modifier so generated code can match the effective access level.
  fileprivate static func extractEnclosingAccessModifier(
    from context: some MacroExpansionContext
  ) -> DeclModifierSyntax? {
    for lexicalContext in context.lexicalContext {
      if let extensionDecl = lexicalContext.as(ExtensionDeclSyntax.self) {
        return extractAccessModifier(from: extensionDecl)
      }
    }
    return nil
  }

  /// Access level ranking from most restrictive (0) to least restrictive (4).
  /// Used to determine the effective access level for generated code.
  fileprivate static let accessLevelRank: [Keyword: Int] = [
    .private: 0,
    .fileprivate: 1,
    .internal: 2,
    .package: 3,
    .public: 4,
  ]

  /// Extracts access modifier from a syntax node.
  fileprivate static func extractAccessModifier(
    from node: some WithModifiersSyntax
  ) -> DeclModifierSyntax? {
    let accessKeywords: [Keyword] = [.public, .internal, .fileprivate, .private, .package]
    return node.modifiers.first { modifier in
      guard case .keyword(let keyword) = modifier.name.tokenKind else {
        return false
      }
      return accessKeywords.contains(keyword)
    }
  }

  /// Computes the effective access modifier by taking the most restrictive
  /// between the type's access level and all properties' access levels.
  ///
  /// This ensures generated code doesn't expose types with more restrictive
  /// access levels than the generated members.
  fileprivate static func computeEffectiveAccessModifier(
    typeAccessModifier: DeclModifierSyntax?,
    parameters: [Parameter]
  ) -> DeclModifierSyntax? {
    // Get the rank of the type's access level (default to internal = 2)
    let typeRank: Int
    if let typeModifier = typeAccessModifier,
      case .keyword(let keyword) = typeModifier.name.tokenKind,
      let rank = accessLevelRank[keyword]
    {
      typeRank = rank
    } else {
      typeRank = accessLevelRank[.internal]!
    }

    // Find the minimum rank among all properties
    var minRank = typeRank
    var minModifier = typeAccessModifier

    for param in parameters {
      let propRank: Int
      if let modifier = param.accessModifier,
        case .keyword(let keyword) = modifier.name.tokenKind,
        let rank = accessLevelRank[keyword]
      {
        propRank = rank
      } else {
        // Properties without an explicit access modifier default to internal.
        propRank = accessLevelRank[.internal]!
      }

      if propRank < minRank {
        minRank = propRank
        minModifier = param.accessModifier
      }
    }

    return minModifier
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
    let caseName = enumCase.name.trimmed.text
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
            label: parameter.firstName?.trimmed,
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
    return declaration.memberBlock.members.flatMap { member in
      guard let variable = member.decl.as(VariableDeclSyntax.self) else {
        return [Parameter]()
      }

      // Exclude static and lazy properties
      // Static properties are type-level, not instance-level
      // Lazy properties cannot be initialized in a memberwise initializer
      let hasStaticOrLazy = variable.modifiers.contains { modifier in
        guard case .keyword(let keyword) = modifier.name.tokenKind else {
          return false
        }
        return keyword == .static || keyword == .lazy
      }
      if hasStaticOrLazy {
        return [Parameter]()
      }

      // Extract the access modifier for this property
      let propertyAccessModifier = extractAccessModifier(from: variable)

      return variable.bindings.compactMap { patternBinding in
        guard let identifierPattern = patternBinding.pattern.as(IdentifierPatternSyntax.self) else {
          return nil
        }

        // Exclude computed properties (properties with accessor blocks like { get } or { willSet })
        // We only want stored properties for fixture initialization
        if patternBinding.accessorBlock != nil {
          return nil
        }

        // For comma-separated declarations, the type might be on the binding or inherited from the variable
        let typeAnnotation = patternBinding.typeAnnotation ?? variable.bindings.last?.typeAnnotation
        guard let typeAnnotation = typeAnnotation else {
          return nil
        }

        // Check if the property has a default value
        let hasDefaultValue = patternBinding.initializer != nil

        return Parameter(
          identifier: identifierPattern.identifier.trimmed,
          type: typeAnnotation.type.trimmed,
          hasDefaultValue: hasDefaultValue,
          accessModifier: propertyAccessModifier
        )
      }
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

    return InitializerDeclSyntax(
      modifiers: buildModifiers(accessModifier: accessModifier),
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

    let initCall = ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          declName: DeclReferenceExprSyntax(baseName: .keyword(.`init`))
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

    return createStaticFixturePropertyWithBody(accessModifier: accessModifier, body: initCall)
  }

  fileprivate static func createFixtureBuilderStruct(
    for parameters: [Parameter],
    accessModifier: DeclModifierSyntax?
  ) -> StructDeclSyntax {
    let propertyModifiers = buildModifiers(accessModifier: accessModifier)

    let properties = parameters.map { parameter in
      MemberBlockItemSyntax(
        decl: VariableDeclSyntax(
          modifiers: propertyModifiers,
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

    // Check if explicit init is needed (for public/package access levels)
    // Swift's auto-generated memberwise init is always internal,
    // so we need to generate an explicit init for cross-module access
    let needsExplicitInit: Bool = {
      guard let accessModifier = accessModifier,
        case .keyword(let keyword) = accessModifier.name.tokenKind
      else {
        return false
      }
      return keyword == .public || keyword == .package
    }()

    return StructDeclSyntax(
      modifiers: buildModifiers(accessModifier: accessModifier),
      name: .identifier("FixtureBuilder"),
      memberBlock: MemberBlockSyntax(
        members: MemberBlockItemListSyntax {
          for property in properties {
            property
          }
          if needsExplicitInit {
            MemberBlockItemSyntax(
              decl: InitializerDeclSyntax(
                modifiers: propertyModifiers,
                signature: FunctionSignatureSyntax(
                  parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax {}
                  )
                ),
                body: CodeBlockSyntax(
                  statements: CodeBlockItemListSyntax {}
                )
              )
            )
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

    return FunctionDeclSyntax(
      modifiers: buildModifiers(accessModifier: accessModifier, includeStatic: true),
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

/// The compiler plugin that registers the `FixtureMacro` with the Swift compiler.
///
/// This plugin serves as the entry point for the macro system, making the
/// `@Fixture` macro available for use in Swift code during compilation.
@main
struct FixturesCompilerPlugin: CompilerPlugin {
  /// The list of macros provided by this plugin.
  let providingMacros: [any Macro.Type] = [
    FixtureMacro.self
  ]
}
