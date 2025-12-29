//
//  FunctionDeclSyntax.swift
//  onward
//
//  Created by Pedro Sousa on 26/12/25.
//

import SwiftSyntax

extension FunctionDeclSyntax {
    var isStatic: Bool {
        modifiers.contains(where: { $0.name.text == "static" })
    }
}
