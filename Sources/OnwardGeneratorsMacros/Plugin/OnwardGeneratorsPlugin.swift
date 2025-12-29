//
//  OnwardGeneratorsPlugin.swift
//  onward
//
//  Created by Pedro Sousa on 11/11/25.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct OnwardGeneratorsPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StoreMacro.self,
        ReducerMacro.self,
        MiddlewareMacro.self,
        ActionMacro.self,
        AsyncActionMacro.self
    ]
}
