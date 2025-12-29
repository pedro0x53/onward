//
//  ActionMacro.swift
//  onward
//
//  Created by Pedro Sousa on 23/12/25.
//

import OnwardCore

// MARK: Action

@attached(accessor)
public macro Action<T, S: Store>(
    reducers: KeyPath<T, Reducer<S>>...,
    middlewares: KeyPath<T, Middleware<S>>...,
    lateReducers: KeyPath<T, Reducer<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "ActionMacro")

@attached(accessor)
public macro Action<T, S: Store>(
    _ reducers: KeyPath<T, Reducer<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "ActionMacro")

@attached(accessor)
public macro Action<T, S: Store>(
    _ middlewares: KeyPath<T, Middleware<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "ActionMacro")


// MARK: AsyncAction

@attached(accessor)
public macro Action<T, S: Store>(
    reducers: KeyPath<T, AsyncReducer<S>>...,
    middlewares: KeyPath<T, AsyncMiddleware<S>>...,
    lateReducers: KeyPath<T, AsyncReducer<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "AsyncActionMacro")

@attached(accessor)
public macro Action<T, S: Store>(
    _ reducers: KeyPath<T, AsyncReducer<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "AsyncActionMacro")

@attached(accessor)
public macro Action<T, S: Store>(
    _ middlewares: KeyPath<T, AsyncMiddleware<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "AsyncActionMacro")

