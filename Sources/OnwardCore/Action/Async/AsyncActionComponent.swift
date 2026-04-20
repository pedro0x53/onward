/// A protocol for types that can participate as an asynchronous step inside
/// an ``AsyncAction``.
///
/// Both ``AsyncReducer`` and ``AsyncMiddleware`` conform to this protocol,
/// which is what allows them to be mixed freely inside an
/// ``AsyncActionBuilder`` closure. You can also create your own conforming
/// types for custom async logic.
public protocol AsyncActionComponentSchema {
    /// The store type this component operates on.
    associatedtype S: Store

    /// Executes the component's asynchronous logic against the given store.
    func run(_ store: S) async
}

/// A type-erased wrapper around any ``AsyncActionComponentSchema``, used as
/// the uniform element type inside ``AsyncActionBuilder`` blocks.
///
/// You rarely create `AsyncActionComponent` values by hand. The
/// ``AsyncActionBuilder`` automatically wraps concrete conformances
/// (``AsyncReducer``, ``AsyncMiddleware``, ``AsyncReducerQueue``) into
/// this type so they can coexist in a single array.
public struct AsyncActionComponent<S: Store>: AsyncActionComponentSchema {
    private let _run: (S) async -> Void

    /// Wraps a concrete ``AsyncActionComponentSchema`` conformance into this
    /// type-erased container.
    public init<C: AsyncActionComponentSchema>(_ component: C) where C.S == S {
        self._run = component.run
    }

    /// Executes the underlying component's async logic against `store`.
    public func run(_ store: S) async {
        await _run(store)
    }
}
