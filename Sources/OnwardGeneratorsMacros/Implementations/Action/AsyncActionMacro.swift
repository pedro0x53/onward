import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct AsyncActionMacro: AccessorMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        try ActionFactory.makeActionDecl(of: node,
                                         providingAccessorsOf: declaration,
                                         in: context,
                                         isAsync: true)
    }
}
