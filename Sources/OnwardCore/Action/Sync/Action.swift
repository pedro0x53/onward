/// A synchronous, composable unit of work that mutates a ``Store``.
///
/// An `Action` bundles one or more ``Reducer``s and ``Middleware``s into a
/// single dispatchable value. When dispatched, each component runs
/// sequentially in declaration order.
///
/// You can build an action declaratively with the ``ActionBuilder`` result
/// builder:
///
/// ```swift
/// var toggleAction: Action<ToDo> {
///     Action {
///         Reducer(get: \.isCompleted, set: \.isCompleted) { status in
///             !status
///         }
///     }
/// }
/// ```
///
/// Or use the `@Action` macro to compose named reducers and middlewares by
/// key path:
///
/// ```swift
/// @Action(reducers: \Self.toggleReducer, middlewares: \Self.logMiddleware)
/// var toggleAction: Action<ToDoStore>
/// ```
///
/// Actions support variadic arguments through parameter packs, so the
/// builder closure can receive external values at dispatch time.
public struct Action<S: Store, each Argument>: Sendable {
    private let components: @Sendable (repeat each Argument) -> [ActionComponent<S>]

    /// Creates an action whose components are produced by an
    /// ``ActionBuilder`` closure.
    ///
    /// - Parameter components: A result-builder closure that returns the
    ///   ordered list of ``ActionComponent`` values to run on dispatch.
    public init(@ActionBuilder<S> _ components: @Sendable @escaping (repeat each Argument) -> [ActionComponent<S>]) {
        self.components = components
    }

    /// Dispatches this action against `store`, running every component in
    /// sequence.
    ///
    /// - Parameters:
    ///   - store: The store whose state will be read and/or mutated.
    ///   - arguments: The variadic arguments forwarded to the builder closure.
    public func dispatch(_ store: S,
                         _ arguments: repeat each Argument) {
        for component in components(repeat each arguments) {
            component.run(store)
        }
    }

    /// Dispatches this action using Swift's `callAsFunction` syntax.
    ///
    /// Equivalent to calling ``dispatch(_:_:)``.
    public func callAsFunction(_ store: S,
                               _ arguments: repeat each Argument) {
        dispatch(store, repeat each arguments)
    }
}
