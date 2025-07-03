//
//  Middleware.swift
//  Onward
//
//  Created by Pedro Sousa on 28/06/25.
//

public struct Middleware<Store> {
    private let _perform: (Store) async -> Void

    public init<Context>(_ perform: @escaping (Store) async -> Context,
                         @ReducerBuilder<Store> before reducerBuilder: @escaping (Context) -> [Reducer<Store>]) {
        self._perform = { store in
            await ReducerQueue(reducerBuilder(perform(store))).reduce(store)
        }
    }

    public init(_ perform: @escaping (Store) async -> Void,
                @ReducerBuilder<Store> after reducerBuilder: @escaping () -> [Reducer<Store>]) {
        self._perform = { store in
            await ReducerQueue(reducerBuilder()).reduce(store)
            await perform(store)
        }
    }

    func perform(_ store: Store) async {
        await _perform(store)
    }
}

extension Middleware: ActionComponentScheme {
    public func run(_ store: Store) async {
        await self.perform(store)
    }
}
