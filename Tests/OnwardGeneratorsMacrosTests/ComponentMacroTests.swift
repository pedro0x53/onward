import Testing
import SwiftSyntaxMacros
@testable import OnwardGeneratorsMacros

private let componentMacros: [String: Macro.Type] = [
    "Interactor": InteractorMacro.self,
    "Reducer": ReducerMacro.self,
    "Middleware": MiddlewareMacro.self,
    "Action": ActionMacro.self,
    "AsyncAction": AsyncActionMacro.self
]

@Suite("Component macros under isolated core")
struct ComponentMacroTests {
    @Test func reducerAndMiddlewareExpandWithoutExtraAnnotations() {
        let result = expand("""
        @MainActor
        @Interactor
        final class ToDoInteractor {
            @Reducer(ToDo.self, set: \\.isCompleted)
            func complete() -> Bool { true }

            @Middleware(ToDo.self)
            func log(_ proxy: ToDo.Proxy) {}
        }
        """, macros: componentMacros)

        #expect(result.diagnostics.isEmpty)
        #expect(!result.source.contains("@Sendable"))
        #expect(!result.source.contains("nonisolated"))
    }

    @Test func asyncReducerAndMiddlewareExpandWithoutExtraAnnotations() {
        let result = expand("""
        @MainActor
        @Interactor
        final class ToDoInteractor {
            @Reducer(ToDo.self, set: \\.isCompleted)
            func complete() async -> Bool { true }

            @Middleware(ToDo.self)
            func fetch(_ proxy: ToDo.Proxy) async {}
        }
        """, macros: componentMacros)

        #expect(result.diagnostics.isEmpty)
        #expect(!result.source.contains("@Sendable"))
        #expect(!result.source.contains("nonisolated"))
    }
}
