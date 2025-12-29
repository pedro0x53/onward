//
//  ActionMacro.swift
//  onward
//
//  Created by Pedro Sousa on 23/12/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct ActionMacro: AccessorMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        try ActionFactory.makeActionDecl(of: node,
                                         providingAccessorsOf: declaration,
                                         in: context,
                                         isAsync: false)
    }
}
