import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

enum MainActorCheck {
    /// Diagnoses `.missingMainActor` when the annotated class carries no `@MainActor`
    /// (or legacy `@MainActor(unsafe)`) attribute. Emission of members continues either way.
    static func diagnoseIfMissing(
        on classDecl: ClassDeclSyntax,
        node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) {
        let isMainActor = classDecl.attributes.contains { element in
            guard case .attribute(let attribute) = element else { return false }
            return attribute.attributeName.trimmedDescription == "MainActor"
        }

        guard !isMainActor else { return }

        context.diagnose(Diagnostic(
            node: Syntax(node),
            message: OnwardClassDiagnostic(error: .missingMainActor, className: classDecl.name.text)
        ))
    }
}
