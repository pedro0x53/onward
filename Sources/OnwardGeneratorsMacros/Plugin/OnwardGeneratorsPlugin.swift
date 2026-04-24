import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct OnwardGeneratorsPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StoreMacro.self,
        ReducerMacro.self,
        MiddlewareMacro.self,
        ActionMacro.self,
        AsyncActionMacro.self,
        InwardMacro.self,
        InteractorMacro.self,
        OnwardContainerMacro.self
    ]
}
