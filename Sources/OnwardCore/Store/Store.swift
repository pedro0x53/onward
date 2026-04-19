//
//  Store.swift
//  onward
//
//  Created by Pedro Sousa on 12/11/25.
//

public protocol Store: AnyObject {
    associatedtype Proxy

    var proxy: Self.Proxy { get }
}

public extension Store {
    public func dispatch<each Argument>(_ action: Action<Self, repeat each Argument>,
                                        _ args: repeat each Argument) {
        action.dispatch(self, repeat each args)
    }

    public func dispatch<each Argument>(_ actionPath: KeyPath<Self, Action<Self, repeat each Argument>>,
                                        _ args: repeat each Argument) {
        self[keyPath: actionPath].dispatch(self, repeat each args)
    }

    public func dispatch<each Argument>(_ asyncAction: AsyncAction<Self, repeat each Argument>,
                                        _ args: repeat each Argument) async {
        await asyncAction.dispatch(self, repeat each args)
    }

    public func dispatch<each Argument>(_ asyncActionPath: KeyPath<Self, AsyncAction<Self, repeat each Argument>>,
                                        _ args: repeat each Argument) async {
        await self[keyPath: asyncActionPath].dispatch(self, repeat each args)
    }
}
