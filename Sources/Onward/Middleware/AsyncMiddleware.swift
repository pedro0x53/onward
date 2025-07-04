//
//  AsyncMiddleware.swift
//  onward
//
//  Created by Pedro Sousa on 28/06/25.
//

public struct AsyncMiddleware<Store> {
    private let _perform: (Store) async -> Void

    public init<Context>(_ perform: @escaping (Store) async -> Context,
                         @AsyncReducerBuilder<Store> interceptBefore reducerBuilder: @escaping (Context) -> [AsyncReducer<Store>]) {
        self._perform = { store in
            await AsyncReducerQueue(reducerBuilder(perform(store))).reduce(store)
        }
    }

    public init(_ perform: @escaping (Store) async -> Void,
                @AsyncReducerBuilder<Store> interceptAfter reducerBuilder: @escaping () -> [AsyncReducer<Store>]) {
        self._perform = { store in
            await AsyncReducerQueue(reducerBuilder()).reduce(store)
            await perform(store)
        }
    }

    func perform(_ store: Store) async {
        await _perform(store)
    }
}

extension AsyncMiddleware: AsyncActionComponentScheme {
    public func run(_ store: Store) async {
        await self.perform(store)
    }
}
