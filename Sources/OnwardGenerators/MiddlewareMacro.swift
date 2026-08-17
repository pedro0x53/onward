import OnwardCore

/// Generates a ``Middleware`` or ``AsyncMiddleware`` stored property from a
/// function declaration.
///
/// Apply `@Middleware` to a method inside an ``Interactor`` (or any type).
/// The macro generates a peer stored property whose name is the function name
/// suffixed with `Middleware`.
///
/// The generated middleware captures the annotated function and passes the
/// store's ``Store/Proxy`` as the sole argument. To run reducers after the
/// middleware finishes, wire them via `@Action(middlewares:, lateReducers:)`.
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
///     // Async middleware — performs a network call
///     @Middleware(ToDoStore.self)
///     func fetch(_ proxy: ToDoStore.Proxy) async {
///         let items = try? await api.fetchItems()
///         proxy.dispatch(\.todosMutator, items ?? [])
///     }
///
///     // Generated peer properties (schematic):
///     //   var logMiddleware: Middleware<ToDoStore> { ... }
///     //   var fetchMiddleware: AsyncMiddleware<ToDoStore> { ... }
/// }
/// ```
///
/// - Parameters:
///   - store: The ``Store`` type whose ``Store/Proxy`` is passed to the function.
@attached(peer, names: arbitrary)
public macro Middleware<S: Store>(
    _ store: S.Type
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "MiddlewareMacro")
