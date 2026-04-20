/// A protocol for types that can participate as a synchronous step inside
/// an ``Action``.
///
/// Both ``Reducer`` and ``Middleware`` conform to this protocol, which is
/// what allows them to be mixed freely inside an ``ActionBuilder`` closure.
/// You can also create your own conforming types if you need custom
/// synchronous logic that doesn't fit neatly into a reducer or middleware.
public protocol ActionComponentSchema {
    /// The store type this component operates on.
    associatedtype S: Store

    /// Executes the component's logic against the given store.
    func run(_ store: S)
}

/// A type-erased wrapper around any ``ActionComponentSchema``, used as the
/// uniform element type inside ``ActionBuilder`` blocks.
///
/// You rarely create `ActionComponent` values by hand. The
/// ``ActionBuilder`` automatically wraps concrete conformances
/// (``Reducer``, ``Middleware``, ``ReducerQueue``) into this type so they
/// can coexist in a single array.
public struct ActionComponent<S: Store>: ActionComponentSchema {
    private let _run: (S) -> Void

    /// Wraps a concrete ``ActionComponentSchema`` conformance into this
    /// type-erased container.
    public init<C: ActionComponentSchema>(_ component: C) where C.S == S {
        self._run = component.run
    }

    /// Executes the underlying component's logic against `store`.
    public func run(_ store: S) {
        _run(store)
    }
}
