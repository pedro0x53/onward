//
//  ActionComponent.swift
//  redux
//
//  Created by Pedro Sousa on 02/07/25.
//

public protocol ActionComponentScheme {
    associatedtype Store

    func run(_ store: Store) async
}

public struct ActionComponent<Store>: ActionComponentScheme {
    private let _run: (Store) async -> Void

    public init<C: ActionComponentScheme>(_ component: C) where C.Store == Store {
        self._run = component.run
    }

    public func run(_ store: Store) async {
        await _run(store)
    }
}
