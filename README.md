# Onward

Onward is a composable, action-based state management library for Swift, inspired by Redux and built around Swift's type system, result builders, and macros. It structures state changes as actions and reducers, separating business logic from state through an explicit Interactor layer.

## Features

- **`@Store` macro**: Declares a state container and auto-generates a `Proxy` snapshot type and mutator actions for every stored property.
- **`@Interactor` macro**: Owns all business logic (actions, reducers, middleware) for a store, keeping it independently testable.
- **Composable Actions**: Inline declarative style or macro-based (`@Action`, `@Reducer`, `@Middleware`) — both first-class.
- **Middleware**: Intercept actions for side effects; read state via an immutable `Proxy` snapshot.
- **Async support**: `AsyncAction` and `AsyncMiddleware` with `await`-based dispatch.
- **Dependency injection**: `@Inward` declares dependencies on `OnwardContainer`; `@Outward` resolves them — no singletons, fully testable.
- **Key-path dispatch**: Dispatch actions via `store.dispatch(\.actionName)` for clean, refactor-safe call sites.

## Installation

Add Onward to your `Package.swift`:

```swift
.package(url: "https://github.com/pedro0x53/onward.git", from: "0.4.0")
```

Then add `Onward` as a dependency for your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "Onward", package: "onward")
    ]
)
```

## Usage

### 1. Define a Store

Use `@Store(Interactor.self)` paired with `@Observable`. The macro generates a `Proxy` snapshot type and a mutator action for each stored `var`.

Store and interactor classes **must be `@MainActor`**. The whole dispatch pipeline (`Action`, `AsyncAction`, reducers, middleware, `Store`, `Interactor`) is isolated to the main actor, so a non-`Sendable` `@Observable` store can dispatch sync and async actions with no concurrency diagnostics. `@Store` and `@Interactor` emit a `missingMainActor` error on a class that lacks `@MainActor`.

```swift
import Observation
import Onward

@MainActor
@Observable
@Store(ToDoInteractor.self)
final class ToDoStore {
    var todos: [ToDo] = []
    var isAlertPresented: Bool = false
}
```

### 2. Define an Interactor

The `@Interactor` macro generates the required `build()` factory and `init()`. Declare your actions as computed properties — either inline (declarative) or with the `@Action`, `@Reducer`, and `@Middleware` macros.

```swift
import Onward

@MainActor
@Interactor
final class ToDoInteractor {

    // Inline declarative style
    var addItem: Action<ToDoStore, String, String> {
        Action { title, description in
            Middleware { proxy in
                let newToDo = ToDo(title: title, description: description)
                var todos = proxy.todos
                todos.append(newToDo)
                proxy.dispatch(\.todosMutator, todos)
            }
        }
    }

    var loadRemote: AsyncAction<ToDoStore> {
        AsyncAction {
            AsyncMiddleware { proxy in
                let items = await self.apiClient.fetchItems()
                proxy.dispatch(\.todosMutator, items)
            }
            AsyncReducer(setter: \.isAlertPresented) { true }
        }
    }

    // Macro style — composes named reducers and middleware by key path
    @Action(middlewares: \Self.fetchMiddleware, lateReducers: \Self.showAlertReducer)
    var loadRemoteAction: AsyncAction<ToDoStore>

    @Middleware(ToDoStore.self)
    private func fetch(_ proxy: ToDoStore.Proxy) async {
        let items = await apiClient.fetchItems()
        proxy.dispatch(\.todosMutator, items)
    }

    @Reducer(ToDoStore.self, set: \.isAlertPresented)
    func showAlert() async -> Bool { true }
}
```

> **Note:** `Action` and `AsyncAction` are no longer `Sendable`, and their closures are `@MainActor` rather than `@Sendable`. Calling an async `dispatch` from a non-`@MainActor` context makes the passed arguments cross an isolation boundary, so they must be `Sendable` at that call site. This is a breaking change (major version bump).

### 3. Register and Resolve Dependencies

Declare dependencies with `@Inward` on an `OnwardContainer` extension. Resolve them anywhere with `@Outward`.

```swift
// Declaration (e.g. in Workers/APIClient.swift)
extension OnwardContainer {
    @Inward var apiClient: APIClient = DefaultAPIClient()
}

// Resolution inside an Interactor
@MainActor
@Interactor
final class ToDoInteractor {
    @Outward(\.apiClient) var apiClient: APIClient
    // ...
}
```

Override for tests using the `charge` static method:

```swift
OnwardContainer.charge(\.apiClient, MockAPIClient())
```

### 4. Dispatch Actions from the UI

Use key-path dispatch — no need to hold a direct reference to the action value.

```swift
struct ContentView: View {
    @State private var store: ToDoStore = .init()

    var body: some View {
        List(store.todos) { todo in
            Text(todo.title)
                .onTapGesture {
                    // Dispatch on a nested store
                    todo.dispatch(\.toggleCompleted)
                }
        }
        .toolbar {
            Button("Add") {
                store.dispatch(\.addItem, "New Task", "Description")
            }
        }
        .task {
            await store.dispatch(\.loadRemote)
        }
    }
}
```

## Architecture Overview

```
View  ──dispatch──▶  Store  ──interactor──▶  Interactor
                      │                         │
                   (state)               Actions / Reducers / Middleware
                      │                         │
                   Proxy ◀────────────────── (read-only snapshot)
```

- **Store** holds observable state. The `@Store` macro wires it to its interactor and generates mutator actions.
- **Interactor** owns all business logic. It never holds state; it only reads via `Proxy` and writes via dispatch.
- **Middleware** runs side effects before reducers apply. It receives an immutable `Proxy` snapshot.
- **Reducer** is a pure function that derives a new value from the current one.
- **OnwardContainer** is the dependency graph — declare entries with `@Inward` in a container extension, resolve them with `@Outward`, and override for tests with `OnwardContainer.charge(\.key, mock)`.

## Example

See the full working SwiftUI app in [`Examples/Todos`](Examples/Todos).

## License

MIT
