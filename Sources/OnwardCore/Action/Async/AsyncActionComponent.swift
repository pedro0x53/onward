//
//  AsyncActionComponent.swift
//  onward
//
//  Created by Pedro Sousa on 02/07/25.
//

public protocol AsyncActionComponentScheme {
    associatedtype S: Store

    func run(_ store: S) async
}

public struct AsyncActionComponent<S: Store>: AsyncActionComponentScheme {
    private let _run: (S) async -> Void

    public init<C: AsyncActionComponentScheme>(_ component: C) where C.S == S {
        self._run = component.run
    }

    public func run(_ store: S) async {
        await _run(store)
    }
}
