import SwiftSyntax

extension SyntaxProtocol {
    var plainDescription: String {
        description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
