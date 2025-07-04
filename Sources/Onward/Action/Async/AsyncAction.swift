//
//  AsyncAction.swift
//  onward
//
//  Created by Pedro Sousa on 28/06/25.
//

public struct AsyncAction<Store, each Argument>: Sendable {
    private let components: @Sendable (repeat each Argument) -> [AsyncActionComponent<Store>]

    public init(@AsyncActionBuilder<Store> _ components: @Sendable @escaping (repeat each Argument) -> [AsyncActionComponent<Store>]) {
        self.components = components
    }

    public func dispatch(_ store: Store, args arguments: repeat each Argument) async {
        for component in components(repeat each arguments) {
            await component.run(store)
        }
    }

    public func callAsFunction(_ store: Store, args arguments: repeat each Argument) async {
        await dispatch(store, args: repeat each arguments)
    }
}
