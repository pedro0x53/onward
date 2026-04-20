import OnwardCore

/// Synthesizes the ``Store`` protocol conformance for a class.
///
/// Apply `@Store` to a `final class` to automatically generate:
///
/// 1. A `Proxy` nested struct — an immutable snapshot of the store's
///    current state, used by ``Middleware`` and ``AsyncMiddleware``.
/// 2. A `proxy` computed property that creates a `Proxy` from the current
///    stored properties.
/// 3. Mutator actions — one ``Action`` per stored `var` that writes a new
///    value, acting as type-safe setters.
///
/// Pair `@Store` with `@Observable` so SwiftUI views automatically
/// re-render when store properties change.
///
/// ```swift
/// @Store @Observable
/// final class ToDoStore {
///     var title: String = ""
///     var todos: [ToDo] = []
/// }
///
/// // Generated: ToDoStore.Proxy, toDoStore.proxy,
/// //            mutator actions for title and todos
/// ```
@attached(member, names: arbitrary)
@attached(extension, conformances: Store, names: arbitrary, named(proxy), named(Proxy))
public macro Store<I: Interactor>(_ interactor: I.Type) = #externalMacro(module: "OnwardGeneratorsMacros", type: "StoreMacro")
