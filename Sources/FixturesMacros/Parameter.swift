import SwiftSyntax

/// Represents a parameter for fixture generation.
///
/// This struct encapsulates the metadata needed to generate fixture parameters
/// from struct properties during macro expansion.
struct Parameter {
  /// The property name identifier.
  let identifier: TokenSyntax

  /// The property type.
  let type: TypeSyntax

  /// Whether the property has a default value.
  let hasDefaultValue: Bool
}

extension Parameter {
  var fixtureParameterName: String {
    "fixture\(identifier.text)"
  }
}
