import Testing
import SwiftSyntaxMacros
@testable import OnwardGeneratorsMacros

let storeMacros: [String: Macro.Type] = [
    "Store": StoreMacro.self,
    "Interactor": InteractorMacro.self
]

@Suite("Store/Interactor @MainActor isolation")
struct StoreMacroTests {
    @Test func storeExpandsMainActorProxy() {
        let result = expand("""
        @MainActor
        @Store(ToDoInteractor.self)
        final class ToDo { var title: String = "" }
        """, macros: storeMacros)

        #expect(result.source.contains("@MainActor struct Proxy"))
        #expect(result.diagnostics.isEmpty)
    }

    @Test func storeOnMainActorObservableClassHasNoDiagnostics() {
        let result = expand("""
        @MainActor
        @Observable
        @Store(ToDoInteractor.self)
        final class ToDo { var title: String = "" }
        """, macros: storeMacros)

        #expect(result.diagnostics.isEmpty)
    }

    @Test func interactorOnMainActorClassHasNoDiagnostics() {
        let result = expand("""
        @MainActor
        @Interactor
        final class ToDoInteractor {}
        """, macros: storeMacros)

        #expect(result.source.contains("static func build() -> Self"))
        #expect(result.source.contains("extension ToDoInteractor: Interactor"))
        #expect(result.diagnostics.isEmpty)
    }

    @Test func storeWithoutMainActorEmitsDiagnostic() {
        let result = expand("""
        @Store(ToDoInteractor.self)
        final class ToDo { var title: String = "" }
        """, macros: storeMacros)

        #expect(result.diagnostics == [
            "@Store/@Interactor requires 'ToDo' to be @MainActor. Add '@MainActor' to the class declaration."
        ])
        // Members are still emitted, so the user sees only the actionable error.
        #expect(result.source.contains("struct Proxy"))
    }

    @Test func interactorWithoutMainActorEmitsDiagnostic() {
        let result = expand("""
        @Interactor
        final class ToDoInteractor {}
        """, macros: storeMacros)

        #expect(result.diagnostics.contains(
            "@Store/@Interactor requires 'ToDoInteractor' to be @MainActor. Add '@MainActor' to the class declaration."
        ))
        #expect(result.source.contains("static func build() -> Self"))
    }
}
