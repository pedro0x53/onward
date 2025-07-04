//
//  AsyncReducerQueue.swift
//  onward
//
//  Created by Pedro Sousa on 02/07/25.
//

public struct AsyncReducerQueue<Store> {
    private(set) var reducers: [AsyncReducer<Store>]

    public init (_ reducers: [AsyncReducer<Store>]) {
        self.reducers = reducers
    }

    public init(@AsyncReducerBuilder<Store> _ content: () -> [AsyncReducer<Store>]) {
        self.reducers = content()
    }

    public func reduce(_ store: Store) async {
        for reducer in reducers {
            await reducer.reduce(store)
        }
    }

    public mutating func append(_ reducer: AsyncReducer<Store>) {
        reducers.append(reducer)
    }
}

extension AsyncReducerQueue: AsyncActionComponentScheme {
    public func run(_ store: Store) async {
        await self.reduce(store)
    }
}
