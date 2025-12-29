//
//  ReducerQueue.swift
//  onward
//
//  Created by Pedro Sousa on 04/07/25.
//


public struct ReducerQueue<S: Store> {
    private(set) var reducers: [Reducer<S>]

    public init (_ reducers: [Reducer<S>]) {
        self.reducers = reducers
    }

    public init(@ReducerBuilder<S> _ content: () -> [Reducer<S>]) {
        self.reducers = content()
    }

    public func reduce(_ store: S) {
        for reducer in reducers {
            reducer.reduce(store)
        }
    }

    public mutating func append(_ reducer: Reducer<S>) {
        reducers.append(reducer)
    }
}

extension ReducerQueue: ActionComponentScheme {
    public func run(_ store: S) {
        self.reduce(store)
    }
}
