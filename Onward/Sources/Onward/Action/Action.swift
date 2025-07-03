//
//  Action.swift
//  Onward
//
//  Created by Pedro Sousa on 28/06/25.
//

public struct Action<Store, each Parameter> {
    private let components: (repeat each Parameter) -> [ActionComponent<Store>]

    public init(@ActionBuilder<Store> _ components: @escaping (repeat each Parameter) -> [ActionComponent<Store>]) {
        self.components = components
    }

    public func dispatch(_ store: Store, _ parameters: repeat each Parameter) {
        for component in components(repeat each parameters) {
            component.run(store)
        }
    }
}
