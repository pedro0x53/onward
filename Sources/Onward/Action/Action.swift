//
//  Action.swift
//  Onward
//
//  Created by Pedro Sousa on 28/06/25.
//

public struct Action<Store: SSoT> {
    private var components: [ActionComponent<Store>]

    public init(@ActionBuilder<Store> _ components: @escaping () -> [ActionComponent<Store>]) {
        self.components = components()
    }

    public func perform(_ store: Store) async {
        for component in components {
            await component.run(store)
        }
    }
}
