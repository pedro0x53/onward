import SwiftSyntax

extension DeclSyntaxProtocol {
    var isVariable: Bool {
        guard let variable = self.as(VariableDeclSyntax.self)
        else { return false }

        return true
    }
}
