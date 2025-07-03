//
//  Reducer.swift
//  Onward
//
//  Created by Pedro Sousa on 28/06/25.
//

public struct Reducer<Store> {
    private var _reduce: (Store) async -> Void

    public init (_ work: @escaping () async -> Void) {
        self._reduce = { _ in
            await work()
        }
    }

    public init (_ work: @escaping (Store) async -> Void) {
        self._reduce = work
    }

    public init<each Input>(getter keyPaths: repeat KeyPath<Store, each Input>,
                            do work: @escaping (repeat each Input) async -> Void) {
        self._reduce = { store in
            await work(repeat store[keyPath: each keyPaths])
        }
    }

    public init<each Output>(setter keyPaths: repeat ReferenceWritableKeyPath<Store, each Output>,
                             do work: @escaping () async -> (repeat each Output)) {
        self._reduce = { store in
            repeat store[keyPath: each keyPaths] = each await work()
        }
    }

    public init<each Input, each Output>(get getKeyPaths: repeat KeyPath<Store, each Input>,
                                         set setKeyPaths: repeat ReferenceWritableKeyPath<Store, each Output>,
                                         do work: @escaping (repeat each Input) async -> (repeat each Output)) {
        self._reduce = { store in
            repeat store[keyPath: each setKeyPaths] = each await work(repeat store[keyPath: each getKeyPaths])
        }
    }

    public func reduce(_ store: Store) async {
        await self._reduce(store)
    }
}

extension Reducer: ActionComponentScheme {
    public func run(_ store: Store) async {
        await self.reduce(store)
    }
}
