import OnwardCore

/// Generates a ``Middleware`` or ``AsyncMiddleware`` stored property from a
/// function declaration.
///
/// Apply `@Middleware` to a method inside an ``Interactor`` (or any type).
/// The macro generates a peer stored property whose name is the function name
/// suffixed with `Middleware` (or `AsyncMiddleware` for `async` functions).
///
/// The generated middleware captures the annotated function and passes the
/// store's ``Store/Proxy`` as the sole argument. Optionally, you can chain
/// late reducers that run after the middleware finishes.
///
/// ```swift
/// @Interactor
/// final class TodoInteractor {
///
///     // Synchronous middleware — logs without mutating
///     @Middleware(ToDoStore.self)
///     func log(_ proxy: ToDoStore.Proxy) {
///         print("Todos: \(proxy.todos.count)")
///     }
///
///     // Async middleware — performs a network call, then applies reducers
///     @Middleware(ToDoStore.self, then: \Self.showAlertReducer)
///     func fetch(_ proxy: ToDoStore.Proxy) async {
///         let items = try? await api.fetchItems()
///         proxy.dispatch(\.todosMutator, items ?? [])
///     }
///
///     // Generated peer properties (schematic):
///     //   var logMiddleware: Middleware<ToDoStore> { ... }
///     //   var fetchAsyncMiddleware: AsyncMiddleware<ToDoStore> { ... }
/// }
/// ```
///
/// - Parameters:
///   - store: The ``Store`` type whose ``Store/Proxy`` is passed to the function.
@attached(peer, names: arbitrary)
public macro Middleware<S: Store>(
    _ store: S.Type
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "MiddlewareMacro")

/// Generates a ``Middleware`` stored property from a function declaration,
/// chaining one or more ``Reducer``s to run after the middleware completes.
///
/// This overload is identical to ``Middleware(_:)`` but appends late
/// synchronous reducers to the action pipeline. The reducers are referenced
/// by key path and run in the order they are listed.
///
/// ```swift
/// @Middleware(ToDoStore.self, then: \Self.sortReducer, \Self.trimReducer)
/// func normalize(_ proxy: ToDoStore.Proxy) {
///     // ... sync side effect
/// }
/// ```
///
/// - Parameters:
///   - store: The ``Store`` type whose ``Store/Proxy`` is passed to the function.
///   - then: Key paths to ``Reducer`` values that run after this middleware.
@attached(peer, names: arbitrary)
public macro Middleware<T, S: Store>(
    _ store: S.Type,
    then: KeyPath<T, Reducer<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "MiddlewareMacro")

/// Generates an ``AsyncMiddleware`` stored property from an `async` function
/// declaration, chaining one or more ``AsyncReducer``s to run after the
/// middleware completes.
///
/// This overload is the async counterpart of ``Middleware(_:then:)-...``.
/// Use it when the late reducers are themselves async.
///
/// ```swift
/// @Middleware(ToDoStore.self, then: \Self.persistReducer)
/// func fetchAndStore(_ proxy: ToDoStore.Proxy) async {
///     let items = await api.fetch()
///     proxy.dispatch(\.todosMutator, items)
/// }
/// ```
///
/// - Parameters:
///   - store: The ``Store`` type whose ``Store/Proxy`` is passed to the function.
///   - then: Key paths to ``AsyncReducer`` values that run after this middleware.
@attached(peer, names: arbitrary)
public macro Middleware<T, S: Store>(
    _ store: S.Type,
    then: KeyPath<T, AsyncReducer<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "MiddlewareMacro")
