//
//  Reducer.swift
//  onward
//
//  Created by Pedro Sousa on 04/07/25.
//

public struct Reducer<Store> {
    private var _reduce: (Store) -> Void

    public init (_ work: @escaping () -> Void) {
        self._reduce = { _ in
            work()
        }
    }

    public init (_ work: @escaping (Store) -> Void) {
        self._reduce = work
    }

    public init<each Input>(getter keyPaths: repeat KeyPath<Store, each Input>,
                            do work: @escaping (repeat each Input) -> Void) {
        self._reduce = { store in
            work(repeat store[keyPath: each keyPaths])
        }
    }

    public init<each Output>(setter keyPaths: repeat ReferenceWritableKeyPath<Store, each Output>,
                             do work: @escaping () -> (repeat each Output)) {
        self._reduce = { store in
            repeat store[keyPath: each keyPaths] = each work()
        }
    }

    public init<each Input, each Output>(get getKeyPaths: repeat KeyPath<Store, each Input>,
                                         set setKeyPaths: repeat ReferenceWritableKeyPath<Store, each Output>,
                                         do work: @escaping (repeat each Input) -> (repeat each Output)) {
        self._reduce = { store in
            repeat store[keyPath: each setKeyPaths] = each work(repeat store[keyPath: each getKeyPaths])
        }
    }

    public func reduce(_ store: Store) {
        self._reduce(store)
    }
}

extension Reducer: ActionComponentScheme {
    public func run(_ store: Store) {
        self.reduce(store)
    }
}
