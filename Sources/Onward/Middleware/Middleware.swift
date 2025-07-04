//
//  Middleware.swift
//  onward
//
//  Created by Pedro Sousa on 04/07/25.
//


public struct Middleware<Store> {
    private let _perform: (Store) -> Void

    public init<Context>(_ perform: @escaping (Store) -> Context,
                         @ReducerBuilder<Store> interceptBefore reducerBuilder: @escaping (Context) -> [Reducer<Store>]) {
        self._perform = { store in
            ReducerQueue(reducerBuilder(perform(store))).reduce(store)
        }
    }

    public init(_ perform: @escaping (Store) -> Void,
                @ReducerBuilder<Store> interceptAfter reducerBuilder: @escaping () -> [Reducer<Store>]) {
        self._perform = { store in
            ReducerQueue(reducerBuilder()).reduce(store)
            perform(store)
        }
    }

    func perform(_ store: Store) {
        _perform(store)
    }
}

extension Middleware: ActionComponentScheme {
    public func run(_ store: Store) {
        self.perform(store)
    }
}
