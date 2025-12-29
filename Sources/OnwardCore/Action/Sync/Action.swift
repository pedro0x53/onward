//
//  Action.swift
//  onward
//
//  Created by Pedro Sousa on 04/07/25.
//

public struct Action<S: Store, each Argument>: Sendable {
    private let components: @Sendable (repeat each Argument) -> [ActionComponent<S>]

    public init(@ActionBuilder<S> _ components: @Sendable @escaping (repeat each Argument) -> [ActionComponent<S>]) {
        self.components = components
    }

    public func dispatch(_ store: S,
                         args arguments: repeat each Argument) {
        for component in components(repeat each arguments) {
            component.run(store)
        }
    }

    public func callAsFunction(_ store: S,
                               args arguments: repeat each Argument) {
        dispatch(store, args: repeat each arguments)
    }
}
