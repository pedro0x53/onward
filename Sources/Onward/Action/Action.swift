//
//  Action.swift
//  Onward
//
//  Created by Pedro Sousa on 28/06/25.
//

public struct Action<Store, each Argument>: Sendable {
    private let components: @Sendable (repeat each Argument) -> [ActionComponent<Store>]

    public init(@ActionBuilder<Store> _ components: @Sendable @escaping (repeat each Argument) -> [ActionComponent<Store>]) {
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
