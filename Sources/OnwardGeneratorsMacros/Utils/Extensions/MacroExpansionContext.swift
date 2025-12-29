//
//  MacroExpansionContext.swift
//  onward
//
//  Created by Pedro Sousa on 24/12/25.
//

import SwiftSyntax
import SwiftSyntaxMacros

extension MacroExpansionContext {
    var enclosingTypes: [DeclGroupSyntax] {
        self.lexicalContext.compactMap { syntax in
            guard let declGroup = syntax.asProtocol(DeclGroupSyntax.self),
                  let namedDecl = declGroup.asProtocol(NamedDeclSyntax.self)
            else { return nil }

            return declGroup
        }
    }

    var ownerType: DeclGroupSyntax? {
        self.enclosingTypes.first
    }

    var ownerTypeName: String? {
        guard let ownerType = self.ownerType?.asProtocol(NamedDeclSyntax.self)
        else { return nil }

        return ownerType.name.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
