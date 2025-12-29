//
//  VariableDeclSyntax.swift
//  onward
//
//  Created by Pedro Sousa on 24/12/25.
//

import SwiftSyntax

extension VariableDeclSyntax {
    var plainName: String {
        guard let binding = bindings.first,
              let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            return description.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return identifierPattern.identifier.text
    }

    var isStatic: Bool {
        modifiers.contains(where: { $0.name.text == "static" })
    }
}
