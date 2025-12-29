//
//  AsyncReducerQueue.swift
//  onward
//
//  Created by Pedro Sousa on 02/07/25.
//

public struct AsyncReducerQueue<S: Store> {
    private(set) var reducers: [AsyncReducer<S>]

    public init (_ reducers: [AsyncReducer<S>]) {
        self.reducers = reducers
    }

    public init(@AsyncReducerBuilder<S> _ content: () -> [AsyncReducer<S>]) {
        self.reducers = content()
    }

    public func reduce(_ store: S) async {
        for reducer in reducers {
            await reducer.reduce(store)
        }
    }

    public mutating func append(_ reducer: AsyncReducer<S>) {
        reducers.append(reducer)
    }
}

extension AsyncReducerQueue: AsyncActionComponentScheme {
    public func run(_ store: S) async {
        await self.reduce(store)
    }
}
