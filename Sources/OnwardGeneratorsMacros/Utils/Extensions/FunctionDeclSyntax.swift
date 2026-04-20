import SwiftSyntax

extension FunctionDeclSyntax {
    var isStatic: Bool {
        modifiers.contains(where: { $0.name.text == "static" })
    }
}
