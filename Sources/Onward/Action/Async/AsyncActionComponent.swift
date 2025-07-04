//
//  AsyncActionComponent.swift
//  onward
//
//  Created by Pedro Sousa on 02/07/25.
//

public protocol AsyncActionComponentScheme {
    associatedtype Store

    func run(_ store: Store) async
}

public struct AsyncActionComponent<Store>: AsyncActionComponentScheme {
    private let _run: (Store) async -> Void

    public init<C: AsyncActionComponentScheme>(_ component: C) where C.Store == Store {
        self._run = component.run
    }

    public func run(_ store: Store) async {
        await _run(store)
    }
}
