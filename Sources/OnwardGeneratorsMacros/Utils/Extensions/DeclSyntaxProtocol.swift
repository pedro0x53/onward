import SwiftSyntax

extension DeclSyntaxProtocol {
    var isVariable: Bool {
        self.as(VariableDeclSyntax.self) != nil
    }
}
