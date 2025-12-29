//
//  MiddlewareMacro.swift
//  onward
//
//  Created by Pedro Sousa on 26/12/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

struct MiddlewareMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self)
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.notAFunction))
            return []
        }

        guard case .argumentList(let arguments) = node.arguments,
              let metatype = extractMetatype(from: arguments)
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.missingStore))
            return []
        }

        let funcName = funcDecl.name.text
        let isAsync = funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil

        guard !isBadFormatted(from: funcDecl)
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.invalidMiddleware))
            return []
        }

        let hasProxy = funcDecl.signature.parameterClause.parameters.count == 1

        let decl = try buildMiddlewareDeclaration(
            metatype: metatype,
            funcName: funcName,
            hasProxy: hasProxy,
            isStatic: funcDecl.isStatic,
            isAsync: isAsync
        )

        return [decl]
    }

    private static func extractMetatype(from args: LabeledExprListSyntax) -> String? {
        guard let firstArg = args.first,
              firstArg.label == nil,
              let memberAccess = firstArg.expression.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.text == "self"
        else { return nil }

        if let base = memberAccess.base?.as(DeclReferenceExprSyntax.self) {
            return base.baseName.text
        }

        return nil
    }

    private static func isBadFormatted(from funcDecl: FunctionDeclSyntax) -> Bool {
        let numOfParams = funcDecl.signature.parameterClause.parameters.count

        if numOfParams == 1,
           let param = funcDecl.signature.parameterClause.parameters.first,
           let secondName = param.secondName?.text,
           secondName == "proxy" {
            return false
        }

        return numOfParams != 0
    }

    private static func buildMiddlewareDeclaration(
        metatype: String,
        funcName: String,
        hasProxy: Bool,
        isStatic: Bool,
        isAsync: Bool
    ) throws -> DeclSyntax {
        let middlewareInitString = isAsync ? "AsyncMiddleware" : "Middleware"

        let lowercasedMetatype = metatype.prefix(1).lowercased() + metatype.dropFirst()
        let capitalizedFuncName = funcName.prefix(1).uppercased() + funcName.dropFirst()
        let propertyName = "\(funcName)Middleware"

        let selfReference = isStatic ? "Self" : "self"
        let staticKeyword = isStatic ? "static " : ""

        let rawAwaitKeyword = isAsync ? "await " : ""

        let functionCallString: String = "\(selfReference).\(funcName)(\(hasProxy ? "proxy" : ""))"
        let closureBodyString: String = "\(rawAwaitKeyword)\(functionCallString)"
        let closureParam = hasProxy ? "proxy" : "_"


        let declarationString: String = """
        \(staticKeyword)var \(propertyName): \(middlewareInitString)<\(metatype)> {
            \(middlewareInitString) { \(closureParam) in
                \(closureBodyString)
            }
        }
        """

        return DeclSyntax(stringLiteral: declarationString)
    }
}
