//
//  ActionFactory.swift
//  onward
//
//  Created by Pedro Sousa on 26/12/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct ActionFactory {
    static func makeActionDecl(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext,
        isAsync: Bool
    ) throws -> [AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self)
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.notAVariable))
            return []
        }

        guard case .argumentList(let arguments) = node.arguments,
              arguments.count > 0
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.missingActionComponents))
            return []
        }

        guard let metatype = extractMetatype(from: varDecl)
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.missingActionType))
            return []
        }

        let keyPaths = arguments.extractArguments(conformingTo: KeyPathExprSyntax.self)

        guard !keyPaths.isEmpty
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.invalidKeyPaths))
            return []
        }

        guard let parent = context.ownerTypeName,
              let owner = keyPaths.compactMap { $0.rootName }.first,
              owner == parent || owner == "Self"
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.invalidAction))
            return []
        }

        let decl = try buildActionDeclaration(
            metatype: metatype,
            varName: varDecl.plainName,
            properties: keyPaths.compactMap(\.name),
            isStatic: varDecl.isStatic,
            isAsync: isAsync
        )

        return [decl]
    }

    private static func extractMetatype(from variableDecl: VariableDeclSyntax) -> String? {
        guard let type = variableDecl.bindings.compactMap { $0.typeAnnotation?.type.description }.first
        else {
            return nil
        }

        return type
    }

    private static func buildActionDeclaration(
        metatype: String,
        varName: String,
        properties: [String],
        isStatic: Bool,
        isAsync: Bool
    ) throws -> AccessorDeclSyntax {
        let selfReference = isStatic ? "Self" : "self"
        let actionInit = isAsync ? "AsyncAction" : "Action"

        let componentsList = properties.map { property in
            "\(selfReference)\(property)"
        }.joined(separator: "\n")

        let declarationString = """
        get {
            \(actionInit) {
                \(componentsList)
            }
        }
        """

        return AccessorDeclSyntax(stringLiteral: declarationString)
    }
}
