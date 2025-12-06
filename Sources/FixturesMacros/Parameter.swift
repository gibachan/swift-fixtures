import SwiftSyntax

struct Parameter {
    let identifier: TokenSyntax
    let type: TypeSyntax
    let hasDefaultValue: Bool
}

extension Parameter {
    var fixtureParameterName: String {
        "fixture\(identifier.text)"
    }
}
