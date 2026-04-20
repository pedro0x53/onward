/// An asynchronous side-effect that receives a read-only snapshot of a
/// ``Store``'s state.
///
/// `AsyncMiddleware` is the `async` counterpart of ``Middleware``. It
/// receives the store's ``Store/Proxy`` and can perform asynchronous work
/// such as network calls, file I/O, or timed delays without blocking the
/// caller.
///
/// ```swift
/// let apiMiddleware = AsyncMiddleware<ToDoStore> { proxy in
///     try? await Task.sleep(for: .seconds(1))
///     print("Refreshed with title: \(proxy.title)")
/// }
/// ```
///
/// Or with the `@Middleware` macro on an `async` function:
///
/// ```swift
/// @Middleware(ToDoStore.self)
/// func fetchData(_ proxy: ToDoStore.Proxy) async {
///     let data = try? await api.fetch()
///     // ...
/// }
/// ```
///
/// `AsyncMiddleware` conforms to ``AsyncActionComponentSchema``, so it can
/// be placed directly inside an ``AsyncActionBuilder`` block alongside
/// async reducers.
public struct AsyncMiddleware<S: Store> {
    private let _perform: (S.Proxy) async -> Void

    /// Creates an async middleware with the given closure.
    ///
    /// - Parameter perform: An `async` closure that receives the store's
    ///   proxy and performs side-effect work.
    public init(_ perform: @escaping (S.Proxy) async -> Void) {
        self._perform = perform
    }

    /// Executes the middleware's closure with the given proxy.
    func perform(_ proxy: S.Proxy) async {
        await _perform(proxy)
    }
}

extension AsyncMiddleware: AsyncActionComponentSchema {
    /// Bridges the ``AsyncActionComponentSchema`` conformance by extracting
    /// the store's proxy and forwarding it to ``perform(_:)``.
    public func run(_ store: S) async {
        await self.perform(store.proxy)
    }
}
