//
//  AsyncAction.swift
//  onward
//
//  Created by Pedro Sousa on 28/06/25.
//

public struct AsyncAction<S: Store, each Argument>: Sendable {
    private let components: @Sendable (repeat each Argument) -> [AsyncActionComponent<S>]

    public init(@AsyncActionBuilder<S> _ components: @Sendable @escaping (repeat each Argument) -> [AsyncActionComponent<S>]) {
        self.components = components
    }

    public func dispatch(_ store: S,
                         _ arguments: repeat each Argument) async {
        for component in components(repeat each arguments) {
            await component.run(store)
        }
    }

    public func callAsFunction(_ store: S,
                               _ arguments: repeat each Argument) async {
        await dispatch(store, repeat each arguments)
    }
}
