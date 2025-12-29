//
//  ReducerMacro.swift
//  onward
//
//  Created by Pedro Sousa on 13/12/25.
//

import OnwardCore

@attached(peer, names: arbitrary)
public macro Reducer<S: Store, each Input, each Output>(
    _ store: S.Type,
    get: repeat KeyPath<S, each Input>,
    set: repeat KeyPath<S, each Output>
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "ReducerMacro")
