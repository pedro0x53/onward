//
//  ReducerMacro.swift
//  onward
//
//  Created by Pedro Sousa on 13/12/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

struct ReducerMacro: PeerMacro {
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

        let functionParams = extractFuncParams(from: funcDecl)
        let funcReturn = extractFuncReturn(from: funcDecl)
        let getKeyPaths = extractGetKeyPaths(from: arguments)
        let setKeyPaths = extractSetKeyPaths(from: arguments)

        guard !(getKeyPaths.isEmpty && setKeyPaths.isEmpty)
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.invalidReducer))
            return []
        }

        guard functionParams.count == getKeyPaths.count
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.getterCountMismatch))
            return []
        }

        guard funcReturn.count == setKeyPaths.count
        else {
            context.diagnose(Diagnostic(node: Syntax(node), message: OnwardMacroError.setterCountMismatch))
            return []
        }

        let decl = try buildReducerDeclaration(
            metatype: metatype,
            funcName: funcName,
            isAsync: isAsync,
            isStatic: funcDecl.isStatic,
            functionParams: functionParams,
            getKeyPaths: getKeyPaths,
            setKeyPaths: setKeyPaths
        )

        return [decl]
    }

    private static func extractMetatype(from args: LabeledExprListSyntax) -> String? {
        guard let firstArg = args.first,
              firstArg.label == nil,
              let memberAccess = firstArg.expression.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.text == "self"
        else {
            return nil
        }

        if let base = memberAccess.base?.as(DeclReferenceExprSyntax.self) {
            return base.baseName.text
        }

        return nil
    }

    private static func extractFuncParams(from funcDecl: FunctionDeclSyntax) -> [(name: String, label: String?)] {
        funcDecl.signature.parameterClause.parameters.map { parameterSyntax in
            let name = parameterSyntax.secondName?.text ?? parameterSyntax.firstName.text
            let label = parameterSyntax.firstName.text == "_" ? nil : parameterSyntax.firstName.text
            return (name: name, label: label)
        }
    }

    private static func extractFuncReturn(from funcDecl: FunctionDeclSyntax) -> [String] {
        if let singleType = funcDecl.signature.returnClause?.type.as(IdentifierTypeSyntax.self) {
            return [singleType.name.text]
        }

        if let arrayType = funcDecl.signature.returnClause?.type.as(ArrayTypeSyntax.self) {
            return [arrayType.description]
        }

        if let tupleType = funcDecl.signature.returnClause?.type.as(TupleTypeSyntax.self) {
            return tupleType.elements.compactMap { tupleElement in
                guard let singleType = tupleElement.type.as(IdentifierTypeSyntax.self)
                else {
                    return nil
                }

                return singleType.name.text
            }
        }

        return []
    }

    private static func extractGetKeyPaths(from args: LabeledExprListSyntax) -> [String] {
        args.compactMap { expr in
            guard let label = expr.label?.text,
                  label == "get",
                  let keyPathExpr = expr.expression.as(KeyPathExprSyntax.self)
            else { return nil }

            return keyPathExpr.description.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static func extractSetKeyPaths(from args: LabeledExprListSyntax) -> [String] {
        args.compactMap { expr in
            guard let label = expr.label?.text,
                  label == "set",
                  let keyPathExpr = expr.expression.as(KeyPathExprSyntax.self)
            else { return nil }

            return keyPathExpr.description.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static func buildReducerDeclaration(
        metatype: String,
        funcName: String,
        isAsync: Bool,
        isStatic: Bool,
        functionParams: [(name: String, label: String?)],
        getKeyPaths: [String],
        setKeyPaths: [String]
    ) throws -> DeclSyntax {
        let capitalizedFuncName = funcName.prefix(1).uppercased() + funcName.dropFirst()
        let lowercasedMetatype = metatype.prefix(1).lowercased() + metatype.dropFirst()
        let propertyName = "\(lowercasedMetatype)\(capitalizedFuncName)Reducer"

        let closureParams = functionParams.map { $0.name }

        let selfReference = isStatic ? "Self" : "self"
        let staticKeyword = isStatic ? "static " : ""

        let rawAwaitKeyword = isAsync ? "await " : ""
        let rawAsync = isAsync ? "Async" : ""


        let functionCallString: String
        if functionParams.isEmpty {
            functionCallString = "\(selfReference).\(funcName)()"
        } else {
            let callArgs = functionParams.map { param in
                if let label = param.label {
                    return "\(label): \(param.name)"
                } else {
                    return param.name
                }
            }.joined(separator: ", ")
            functionCallString = "\(selfReference).\(funcName)(\(callArgs))"
        }

        let closureSignature: String = closureParams.isEmpty ? "" : "\(closureParams.joined(separator: ", ")) in"

        let returnKeyword = setKeyPaths.isEmpty ? "" : "return "
        let closureBodyString: String = "\(returnKeyword)\(rawAwaitKeyword)\(functionCallString)"

        let reducerInitString: String
        if getKeyPaths.isEmpty {
            reducerInitString = "\(rawAsync)Reducer(setter: \(setKeyPaths.joined(separator: ", ")))"
        } else if setKeyPaths.isEmpty {
            reducerInitString = "\(rawAsync)Reducer(getter: \(getKeyPaths.joined(separator: ", ")))"
        } else {
            reducerInitString = "\(rawAsync)Reducer(get: \(getKeyPaths.joined(separator: ", ")), set: \(setKeyPaths.joined(separator: ", ")))"
        }

        let declarationString: String = """
        \(staticKeyword)var \(propertyName): \(rawAsync)Reducer<\(metatype)> {
            \(reducerInitString) { \(closureSignature)
                \(closureBodyString)
            }
        }
        """

        return DeclSyntax(stringLiteral: declarationString)
    }
}
