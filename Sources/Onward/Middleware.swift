//
//  Middleware.swift
//  Onward
//
//  Created by Pedro Sousa on 28/06/25.
//

public struct Middleware<Store> {
    private let _perform: (Store) -> Void

    init<Context>(_ perform: @escaping (Store) -> Context,
                  @ReducerBuilder<Store> before reducerBuilder: @escaping (Context) -> [Reducer<Store>]) {
        self._perform = { store in
            ReducerQueue(reducerBuilder(perform(store))).reduce(store)
        }
    }

    init(_ perform: @escaping (Store) -> Void,
         @ReducerBuilder<Store> after reducerBuilder: @escaping () -> [Reducer<Store>]) {
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
