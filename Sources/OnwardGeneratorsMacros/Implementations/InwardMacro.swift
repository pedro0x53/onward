import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct InwardMacro: AccessorMacro, PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.notAVariable))
            return []
        }

        guard binding.typeAnnotation != nil
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.missingInwardType))
            return []
        }

        let varName = pattern.identifier.text
        let keyName = Self.keyName(for: varName)

        let getter = AccessorDeclSyntax(
            stringLiteral: """
            get { self[\(keyName).self] }
            """
        )

        let setter = AccessorDeclSyntax(
            stringLiteral: """
            set { self[\(keyName).self] = newValue }
            """
        )

        return [getter, setter]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.notAVariable))
            return []
        }

        guard let typeAnnotation = binding.typeAnnotation
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.missingInwardType))
            return []
        }

        guard let initializer = binding.initializer
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.missingInwardDefault))
            return []
        }

        let keyName = keyName(for: pattern.identifier.text)
        let typeText = typeAnnotation.type.trimmedDescription

        let keyStruct = DeclSyntax(
            """
            private struct \(raw: keyName): InwardKey {
                static var wrappedValue: \(raw: typeText) \(raw: initializer)
            }
            """
        )

        return [keyStruct]
    }

    private static func keyName(for varName: String) -> String {
        let capitalized = varName.prefix(1).uppercased() + varName.dropFirst()
        return "__Inward_\(capitalized)Key"
    }
}
