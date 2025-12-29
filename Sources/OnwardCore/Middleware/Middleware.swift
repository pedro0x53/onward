//
//  Middleware.swift
//  onward
//
//  Created by Pedro Sousa on 04/07/25.
//

public struct Middleware<S: Store> {
    private let _perform: (S.Proxy) -> Void

    public init(_ perform: @escaping (S.Proxy) -> Void) {
        self._perform = perform
    }

    public func perform(_ proxy: S.Proxy) {
        _perform(proxy)
    }
}

extension Middleware: ActionComponentScheme {
    public func run(_ store: S) {
        self.perform(store.proxy)
    }
}
