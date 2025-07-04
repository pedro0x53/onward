//
//  ActionComponentScheme.swift
//  onward
//
//  Created by Pedro Sousa on 04/07/25.
//

public protocol ActionComponentScheme {
    associatedtype Store

    func run(_ store: Store)
}

public struct ActionComponent<Store>: ActionComponentScheme {
    private let _run: (Store) -> Void

    public init<C: ActionComponentScheme>(_ component: C) where C.Store == Store {
        self._run = component.run
    }

    public func run(_ store: Store) {
        _run(store)
    }
}
