//
//  KeyPathExprSyntax.swift
//  onward
//
//  Created by Pedro Sousa on 24/12/25.
//

import SwiftSyntax

extension KeyPathExprSyntax {
    var name: String? {
        String(self.plainDescription.dropFirst((rootName?.count ?? 0) + 1))
    }

    var rootName: String? {
        guard let root else { return nil }
        return root.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
