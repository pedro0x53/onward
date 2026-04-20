import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct InteractorMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return [
            DeclSyntax(stringLiteral:
            """
                init() {}
            """)
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let namedDecl = declaration.asProtocol(NamedDeclSyntax.self)
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.notNamedDecl))
            return []
        }

        let interactorName = namedDecl.name.text

        let extensionDecl = try ExtensionDeclSyntax("extension \(raw: interactorName): Interactor") {
            DeclSyntax(
                """
                public static func build() -> Self {
                    return Self()
                } 
                """
            )
        }

        return [extensionDecl]
    }
}
