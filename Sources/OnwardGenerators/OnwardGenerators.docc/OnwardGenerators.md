# ``OnwardGenerators``

Swift macros that eliminate boilerplate when adopting the Onward framework.

## Overview

`OnwardGenerators` provides a set of attached macros that synthesize protocol conformances, stored properties, and boilerplate so you can focus on your app's logic rather than plumbing.

### `@Store` — Synthesize a state container

Apply ``Store(_:)`` to a `final class` paired with `@Observable`. The macro generates a `Proxy` nested struct (an immutable state snapshot used by middlewares), a `proxy` computed property, and a mutator ``Action`` for every stored `var`:

```swift
@Store(TodoInteractor.self) @Observable
final class TodoStore {
    var todos: [Todo] = []
    var isLoading: Bool = false
}
// Generated: TodoStore.Proxy, .proxy, .todosMutator, .isLoadingMutator
```

### `@Interactor` — Synthesize business-logic ownership

Apply ``Interactor()`` to a `final class` to generate a private `init()` and the required `build()` static factory. Declare actions as computed properties — either inline with result builders or composed with macros:

```swift
@Interactor
final class TodoInteractor {
    var addTodo: Action<TodoStore, String> {
        Action { title in
            Reducer(setter: \.todos) { /* ... */ }
        }
    }
}
```

### `@Action` — Compose actions by key path

Apply ``Action(_:reducers:middlewares:lateReducers:)`` to a stored property to wire up named reducers and middlewares without writing a result-builder closure by hand:

```swift
@Action(reducers: \Self.toggleReducer, middlewares: \Self.logMiddleware)
var toggleAction: Action<TodoStore>
```

### `@Reducer` — Generate a reducer from a function

Apply ``Reducer(_:get:set:)`` to a function to synthesize a ``Reducer`` or ``AsyncReducer`` stored property:

```swift
@Reducer(TodoStore.self, get: \.isLoading, set: \.isLoading)
func flipLoading(_ current: Bool) -> Bool { !current }
// Generated: flipLoadingReducer: Reducer<TodoStore>
```

### `@Middleware` — Generate middleware from a function

Apply ``Middleware(_:)`` to a function to synthesize a ``Middleware`` or ``AsyncMiddleware`` stored property:

```swift
@Middleware(TodoStore.self)
func log(_ proxy: TodoStore.Proxy) {
    print("Todos: \(proxy.todos.count)")
}
// Generated: logMiddleware: Middleware<TodoStore>
```

## Topics

### Stores and Interactors

- ``Store(_:)``
- ``Interactor()``

### Composing Actions

- ``Action(_:reducers:middlewares:lateReducers:)-swift.macro``

### Reducers

- ``Reducer(_:get:set:)``

### Middlewares

- ``Middleware(_:)-swift.macro``
