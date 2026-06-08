/// A synchronous side-effect that receives a read-only snapshot of a
/// ``Store``'s state.
///
/// Middlewares sit between reducers inside an ``Action`` pipeline. Unlike a
/// ``Reducer`` — which reads and writes store properties directly — a
/// `Middleware` receives the store's ``Store/Proxy``, an immutable copy of
/// the current state. This makes middlewares ideal for logging, analytics,
/// validation, and other read-only work that should not mutate state.
///
/// ```swift
/// let logMiddleware = Middleware<ToDoStore> { proxy in
///     print("Current title: \(proxy.title)")
/// }
/// ```
///
/// Or with the `@Middleware` macro:
///
/// ```swift
/// @Middleware(ToDoStore.self)
/// func log(_ proxy: ToDoStore.Proxy) {
///     print("Current title: \(proxy.title)")
/// }
/// ```
///
/// `Middleware` conforms to ``ActionComponentSchema``, so it can be placed
/// directly inside an ``ActionBuilder`` block alongside reducers.
public struct Middleware<S: Store> {
    private let _perform: (S.Proxy) -> Void

    /// Creates a middleware with the given closure.
    ///
    /// - Parameter perform: A closure that receives the store's proxy and
    ///   performs synchronous side-effect work.
    public init(_ perform: @escaping (S.Proxy) -> Void) {
        self._perform = perform
    }

    /// Executes the middleware's closure with the given proxy.
    public func perform(_ proxy: S.Proxy) {
        _perform(proxy)
    }
}

extension Middleware: ActionComponentSchema, AsyncActionComponentSchema {
    /// Bridges the ``ActionComponentSchema`` and ``AsyncActionComponentSchema`` conformance by extracting the
    /// store's proxy and forwarding it to ``perform(_:)``.
    public func run(_ store: S) {
        self.perform(store.proxy)
    }
}
