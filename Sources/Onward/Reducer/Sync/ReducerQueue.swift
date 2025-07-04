//
//  ReducerQueue.swift
//  onward
//
//  Created by Pedro Sousa on 04/07/25.
//


public struct ReducerQueue<Store> {
    private(set) var reducers: [Reducer<Store>]

    public init (_ reducers: [Reducer<Store>]) {
        self.reducers = reducers
    }

    public init(@ReducerBuilder<Store> _ content: () -> [Reducer<Store>]) {
        self.reducers = content()
    }

    public func reduce(_ store: Store) {
        for reducer in reducers {
            reducer.reduce(store)
        }
    }

    public mutating func append(_ reducer: Reducer<Store>) {
        reducers.append(reducer)
    }
}

extension ReducerQueue: ActionComponentScheme {
    public func run(_ store: Store) {
        self.reduce(store)
    }
}
