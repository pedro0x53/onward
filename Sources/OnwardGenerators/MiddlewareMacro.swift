//
//  MiddlewareMacro.swift
//  onward
//
//  Created by Pedro Sousa on 26/12/25.
//

import OnwardCore

@attached(peer, names: arbitrary)
public macro Middleware<S: Store>(
    _ store: S.Type
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "MiddlewareMacro")

@attached(peer, names: arbitrary)
public macro Middleware<T, S: Store>(
    _ store: S.Type,
    then: KeyPath<T, Reducer<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "MiddlewareMacro")

@attached(peer, names: arbitrary)
public macro Middleware<T, S: Store>(
    _ store: S.Type,
    then: KeyPath<T, AsyncReducer<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "MiddlewareMacro")
