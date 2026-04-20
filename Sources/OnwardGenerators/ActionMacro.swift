import OnwardCore

/// Composes an ``Action`` or ``AsyncAction`` from named reducers and
/// middlewares referenced by key path.
///
/// Apply `@Action` to a stored property whose type is `Action<S>` or
/// `AsyncAction<S>`. The macro generates an accessor that builds the action
/// from the referenced components. Components run in the order:
/// **reducers → middlewares → lateReducers**.
///
/// The macro resolves to a synchronous ``Action`` or an asynchronous
/// ``AsyncAction`` depending on whether the referenced components are
/// sync (``Reducer``, ``Middleware``) or async (``AsyncReducer``,
/// ``AsyncMiddleware``). All components in a single `@Action` must share
/// the same sync/async context.
///
/// ```swift
/// // Synchronous action
/// @Action(reducers: \Self.incrementReducer,
///         middlewares: \Self.logMiddleware)
/// var incrementAction: Action<CounterStore>
///
/// // Asynchronous action
/// @Action(reducers: \Self.dismissReducer,
///         middlewares: \Self.apiMiddleware)
/// var refreshAction: AsyncAction<ToDoStore>
///
/// // Shorthand for reducers only
/// @Action(\Self.toggleReducer)
/// var toggleAction: Action<ToDo>
///
/// // Shorthand for middlewares only
/// @Action(\Self.analyticsMiddleware)
/// var trackAction: Action<ToDoStore>
/// ```

// MARK: Action

@attached(accessor)
public macro Action<T, S: Store>(
    reducers: KeyPath<T, Reducer<S>>...,
    middlewares: KeyPath<T, Middleware<S>>...,
    lateReducers: KeyPath<T, Reducer<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "ActionMacro")

@attached(accessor)
public macro Action<T, S: Store>(
    _ reducers: KeyPath<T, Reducer<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "ActionMacro")

@attached(accessor)
public macro Action<T, S: Store>(
    _ middlewares: KeyPath<T, Middleware<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "ActionMacro")


// MARK: AsyncAction

@attached(accessor)
public macro Action<T, S: Store>(
    reducers: KeyPath<T, AsyncReducer<S>>...,
    middlewares: KeyPath<T, AsyncMiddleware<S>>...,
    lateReducers: KeyPath<T, AsyncReducer<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "AsyncActionMacro")

@attached(accessor)
public macro Action<T, S: Store>(
    _ reducers: KeyPath<T, AsyncReducer<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "AsyncActionMacro")

@attached(accessor)
public macro Action<T, S: Store>(
    _ middlewares: KeyPath<T, AsyncMiddleware<S>>...
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "AsyncActionMacro")

