//
//  DeclSyntaxProtocol.swift
//  onward
//
//  Created by Pedro Sousa on 24/12/25.
//

import SwiftSyntax

extension DeclSyntaxProtocol {
    var isVariable: Bool {
        guard let variable = self.as(VariableDeclSyntax.self)
        else { return false }

        return true
    }
}
