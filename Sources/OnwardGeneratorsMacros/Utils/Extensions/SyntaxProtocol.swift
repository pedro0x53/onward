//
//  SyntaxProtocol.swift
//  onward
//
//  Created by Pedro Sousa on 24/12/25.
//

import SwiftSyntax

extension SyntaxProtocol {
    var plainDescription: String {
        description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
