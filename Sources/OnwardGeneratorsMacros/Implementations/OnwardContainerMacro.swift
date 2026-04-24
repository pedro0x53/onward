import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

struct OnwardContainerMacro: MemberMacro, ExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let namedDecl = declaration.asProtocol(NamedDeclSyntax.self)
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.notNamedDecl))
            return []
        }

        let name = namedDecl.name.text

        return [
            DeclSyntax("public static let container: \(raw: name) = .init()"),
            DeclSyntax("public init() {}")
        ]
    }

    static func expansion(
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

        let name = namedDecl.name.text

        guard let extensionDecl = ExtensionDeclSyntax(DeclSyntax(stringLiteral: "extension \(name) : OnwardContainerSchema {}"))
        else { return [] }

        return [extensionDecl]
    }
}
