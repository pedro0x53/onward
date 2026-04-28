import OnwardCore

/// Generates a ``Reducer`` or ``AsyncReducer`` stored property from a function
/// declaration.
///
/// Apply `@Reducer` to a method inside an ``Interactor`` (or any type). The
/// macro reads the function's return type and `async` modifier to decide
/// whether to produce a synchronous ``Reducer`` or an asynchronous
/// ``AsyncReducer``. The generated property name is the function name
/// suffixed with `Reducer`.
///
/// Specify which store properties to read (`get:`) and which to write
/// (`set:`). At dispatch time the macro extracts the `get` values, passes
/// them to the function, and writes the return values back via the `set`
/// key paths — exactly like calling one of ``Reducer``'s `init(get:set:do:)`
/// overloads.
///
/// ```swift
/// @Interactor
/// final class TodoInteractor {
///
///     // Sync read-write reducer
///     @Reducer(ToDo.self, get: \.isCompleted, set: \.isCompleted)
///     func toggle(_ current: Bool) -> Bool { !current }
///
///     // Async write-only reducer (no get: key paths)
///     @Reducer(ToDoStore.self, set: \.isAlertPresented)
///     func dismissAlert() async -> Bool { false }
///
///     // Generated peer properties (schematic):
///     //   var toggleReducer: Reducer<ToDo> { ... }
///     //   var dismissAlertReducer: AsyncReducer<ToDoStore> { ... }
/// }
/// ```
///
/// - Parameters:
///   - store: The ``Store`` type this reducer operates on.
///   - get: Key paths to read from the store and pass as inputs to the function.
///   - set: Writable key paths on the store to assign with the function's return values.
@attached(peer, names: arbitrary)
public macro Reducer<S: Store, each Input, each Output>(
    _ store: S.Type,
    get: repeat KeyPath<S, each Input>,
    set: repeat KeyPath<S, each Output>
) = #externalMacro(module: "OnwardGeneratorsMacros", type: "ReducerMacro")
