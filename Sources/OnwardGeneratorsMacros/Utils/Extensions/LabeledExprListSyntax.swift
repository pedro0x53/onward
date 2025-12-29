//
//  LabeledExprListSyntax.swift
//  onward
//
//  Created by Pedro Sousa on 24/12/25.
//

import SwiftSyntax

extension LabeledExprListSyntax {
    func extractArguments<ExprSyntax: ExprSyntaxProtocol>(
        conformingTo exprSyntaxType: ExprSyntax.Type
    ) -> [ExprSyntax] {
        self.compactMap { expr in
            guard let exprSyntax = expr.expression.as(exprSyntaxType.self)
            else { return nil }

            return exprSyntax
        }
    }

    func extractArguments<ExprSyntax: ExprSyntaxProtocol>(
        conformingTo exprSyntaxType: ExprSyntax.Type,
        where condition: (LabeledExprListSyntax.Element, ExprSyntax) -> Bool
    ) -> [ExprSyntax] {
        self.compactMap { expr in
            guard let exprSyntax = expr.expression.as(exprSyntaxType.self),
                  condition(expr, exprSyntax)
            else { return nil }

            return exprSyntax
        }
    }
}
