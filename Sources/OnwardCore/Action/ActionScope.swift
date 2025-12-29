//
//  ActionScope.swift
//  onward
//
//  Created by Pedro Sousa on 28/12/25.
//

import Foundation

public enum ContextValue {
    case string(String)
    case int(Int)
    case bool(Bool)
    case double(Double)
    case float(Float)
    case list([ContextValue])
    case custom(Any)
}

public final class ActionScope<S: Store, each Argument>: Identifiable {
    public let id: UUID = .init()

    public let store: S
    public var proxy: S.Proxy { store.proxy }
    public let arguments: (repeat each Argument)
    public private(set) var context: [ContextValue] = []

    init(store: S, arguments: repeat each Argument) {
        self.store = store
        self.arguments = (repeat each arguments)
    }

    func addContex(_ context: ContextValue) {
        self.context.append(context)
    }
}
