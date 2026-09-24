import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
@testable import OnwardGeneratorsMacros

struct ExpansionResult {
    let source: String
    let diagnostics: [String]
}

/// Expands the given macros over `source` and returns the expanded text plus
/// every diagnostic message emitted. Unlike `assertMacroExpansion`, results are
/// plain values so `#expect` (swift-testing) can assert on them.
func expand(_ source: String, macros: [String: Macro.Type]) -> ExpansionResult {
    let file = Parser.parse(source: source)
    let context = BasicMacroExpansionContext(
        sourceFiles: [file: .init(moduleName: "TestModule", fullFilePath: "test.swift")]
    )
    let specs = macros.mapValues { MacroSpec(type: $0) }
    let expanded = file.expand(macroSpecs: specs, contextGenerator: { _ in context }, indentationWidth: .spaces(4))
    return ExpansionResult(
        source: expanded.description,
        diagnostics: context.diagnostics.map { $0.message }
    )
}
