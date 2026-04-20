/// An asynchronous, composable unit of work that mutates a ``Store``.
///
/// `AsyncAction` is the `async` counterpart of ``Action``. It bundles one
/// or more ``AsyncReducer``s and ``AsyncMiddleware``s into a single
/// awaitable dispatch. Components run sequentially, so each middleware can
/// perform asynchronous work (network calls, delays, etc.) before the next
/// component executes.
///
/// ```swift
/// var fetchAction: AsyncAction<ToDoStore> {
///     AsyncAction {
///         AsyncMiddleware { proxy in
///             let items = try await api.fetchTodos()
///             // ... use the proxy to read state safely
///         }
///         AsyncReducer(set: \.todos) { items }
///     }
/// }
/// ```
///
/// Or compose with the `@Action` macro using async component key paths:
///
/// ```swift
/// @Action(reducers: \Self.dismissReducer, middlewares: \Self.apiMiddleware)
/// var refreshAction: AsyncAction<ToDoStore>
/// ```
public struct AsyncAction<S: Store, each Argument>: Sendable {
    private let components: @Sendable (repeat each Argument) -> [AsyncActionComponent<S>]

    /// Creates an async action whose components are produced by an
    /// ``AsyncActionBuilder`` closure.
    ///
    /// - Parameter components: A result-builder closure that returns the
    ///   ordered list of ``AsyncActionComponent`` values to run on dispatch.
    public init(@AsyncActionBuilder<S> _ components: @Sendable @escaping (repeat each Argument) -> [AsyncActionComponent<S>]) {
        self.components = components
    }

    /// Dispatches this action against `store`, awaiting every component in
    /// sequence.
    ///
    /// - Parameters:
    ///   - store: The store whose state will be read and/or mutated.
    ///   - arguments: The variadic arguments forwarded to the builder closure.
    public func dispatch(_ store: S,
                         _ arguments: repeat each Argument) async {
        for component in components(repeat each arguments) {
            await component.run(store)
        }
    }

    /// Dispatches this action using Swift's `callAsFunction` syntax.
    ///
    /// Equivalent to calling ``dispatch(_:_:)``.
    public func callAsFunction(_ store: S,
                               _ arguments: repeat each Argument) async {
        await dispatch(store, repeat each arguments)
    }
}
