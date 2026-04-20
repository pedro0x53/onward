/// A class-bound type that owns all of a store's business logic — its
/// actions, reducers, and middleware.
///
/// An `Interactor` acts as the single namespace for every operation that can
/// mutate a ``Store``. Keeping business logic here, instead of inside the
/// store itself, keeps the store a plain state container and makes each piece
/// of logic independently testable.
///
/// Conforming types must be reference types (`AnyObject`) and must provide a
/// `build()` factory that creates a fresh instance. The `@Interactor` macro
/// can synthesise both requirements automatically:
///
/// ```swift
/// @Interactor
/// final class TodoInteractor {
///     var toggleCompleted: Action<ToDo> {
///         Action {
///             Reducer(get: \.isCompleted, set: \.isCompleted) { $0 ? false : true }
///         }
///     }
/// }
/// ```
///
/// Wire an interactor to a store by passing its type to the `@Store` macro:
///
/// ```swift
/// @Store(TodoInteractor.self) @Observable
/// final class TodoStore {
///     var todos: [ToDo] = []
/// }
/// ```
///
/// The store will call `build()` once during initialisation and expose the
/// resulting instance through its `interactor` property, making every action
/// reachable via key-path dispatch:
///
/// ```swift
/// store.dispatch(\.toggleCompleted, todo)
/// ```
public protocol Interactor: AnyObject {
    /// Creates and returns a new instance of the conforming interactor.
    ///
    /// The ``Store`` calls this factory once when it is first accessed,
    /// ensuring that each store owns a dedicated interactor instance.
    static func build() -> Self
}
