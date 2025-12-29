//
//  AsyncMiddleware.swift
//  onward
//
//  Created by Pedro Sousa on 28/06/25.
//

public struct AsyncMiddleware<S: Store> {
    private let _perform: (S.Proxy) async -> Void

    public init(_ perform: @escaping (S.Proxy) async -> Void) {
        self._perform = perform
    }

    func perform(_ proxy: S.Proxy) async {
        await _perform(proxy)
    }
}

extension AsyncMiddleware: AsyncActionComponentScheme {
    public func run(_ store: S) async {
        await self.perform(store.proxy)
    }
}
