//
//  ActionComponentScheme.swift
//  onward
//
//  Created by Pedro Sousa on 04/07/25.
//

public protocol ActionComponentScheme {
    associatedtype S: Store

    func run(_ store: S)
}

public struct ActionComponent<S: Store>: ActionComponentScheme {
    private let _run: (S) -> Void

    public init<C: ActionComponentScheme>(_ component: C) where C.S == S {
        self._run = component.run
    }

    public func run(_ store: S) {
        _run(store)
    }
}
