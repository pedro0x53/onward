//
//  AsyncReducer.swift
//  onward
//
//  Created by Pedro Sousa on 28/06/25.
//

public struct AsyncReducer<S: Store> {
    private var _reduce: (S) async -> Void

    public init<each Input>(getter keyPaths: repeat KeyPath<S, each Input>,
                            do work: @escaping (repeat each Input) async -> Void) {
        self._reduce = { store in
            await work(repeat store[keyPath: each keyPaths])
        }
    }

    public init<each Output>(setter keyPaths: repeat ReferenceWritableKeyPath<S, each Output>,
                             do work: @escaping () async -> (repeat each Output)) {
        self._reduce = { store in
            repeat store[keyPath: each keyPaths] = each await work()
        }
    }

    public init<each Input, each Output>(get getKeyPaths: repeat KeyPath<S, each Input>,
                                         set setKeyPaths: repeat ReferenceWritableKeyPath<S, each Output>,
                                         do work: @escaping (repeat each Input) async -> (repeat each Output)) {
        self._reduce = { store in
            repeat store[keyPath: each setKeyPaths] = each await work(repeat store[keyPath: each getKeyPaths])
        }
    }

    public func reduce(_ store: S) async {
        await self._reduce(store)
    }
}

extension AsyncReducer: AsyncActionComponentScheme {
    public func run(_ store: S) async {
        await self.reduce(store)
    }
}
