//
//  Reducer.swift
//  onward
//
//  Created by Pedro Sousa on 04/07/25.
//

public struct Reducer<S: Store> {
    private var _reduce: (S) -> Void

    public init<each Input>(getter keyPaths: repeat KeyPath<S, each Input>,
                            do work: @escaping (repeat each Input) -> Void) {
        self._reduce = { store in
            work(repeat store[keyPath: each keyPaths])
        }
    }

    public init<each Output>(setter keyPaths: repeat ReferenceWritableKeyPath<S, each Output>,
                             do work: @escaping () -> (repeat each Output)) {
        self._reduce = { store in
            repeat store[keyPath: each keyPaths] = each work()
        }
    }

    public init<each Input, each Output>(get getKeyPaths: repeat KeyPath<S, each Input>,
                                         set setKeyPaths: repeat ReferenceWritableKeyPath<S, each Output>,
                                         do work: @escaping (repeat each Input) -> (repeat each Output)) {
        self._reduce = { store in
            repeat store[keyPath: each setKeyPaths] = each work(repeat store[keyPath: each getKeyPaths])
        }
    }

    public func reduce(_ store: S) {
        self._reduce(store)
    }
}

extension Reducer: ActionComponentScheme {
    public func run(_ store: S) {
        self.reduce(store)
    }
}
