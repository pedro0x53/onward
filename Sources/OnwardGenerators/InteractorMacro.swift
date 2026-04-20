import OnwardCore

/// Synthesizes the ``Interactor`` protocol conformance for a class.
///
/// Apply `@Interactor` to a `final class` to automatically generate:
///
/// 1. A private `init()` — prevents external instantiation and keeps
///    object creation centralised through `build()`.
/// 2. A `build()` static factory — satisfies the ``Interactor`` protocol
///    requirement so a ``Store`` can create its own interactor instance.
///
/// Declare your actions, reducers, and middleware as stored or computed
/// properties directly on the class body. Both the `@Action`, `@Reducer`,
/// and `@Middleware` macros are available inside an interactor:
///
/// ```swift
/// @Interactor
/// final class TodoInteractor {
///
///     // Declarative action using @Action with reducer and middleware key paths
///     @Action(reducers: \Self.toggleCompletedReducer)
///     var toggleCompleted: Action<ToDo>
///
///     // Inline declarative reducer
///     @Reducer(ToDo.self, get: \.isCompleted, set: \.isCompleted)
///     func toggleStatus(_ current: Bool) -> Bool { !current }
///
///     // Async middleware
///     @Middleware(TodoStore.self)
///     func syncWithServer(_ proxy: TodoStore.Proxy) async { /* ... */ }
/// }
///
/// // Generated:
/// //   private init() {}
/// //   public static func build() -> Self { Self() }
/// ```
///
/// Wire the interactor to a store using the ``Store(_:)`` macro:
///
/// ```swift
/// @Store(TodoInteractor.self) @Observable
/// final class TodoStore {
///     var todos: [ToDo] = []
/// }
/// ```
@attached(member, names: arbitrary)
@attached(extension, conformances: Interactor, names: named(build))
public macro Interactor() = #externalMacro(module: "OnwardGeneratorsMacros", type: "InteractorMacro")
