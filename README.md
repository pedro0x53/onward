# Onward

Onward is a composable, action-based state management library for Swift, inspired by Redux and designed to leverage Swift's type system and result builders. It enables you to build scalable, testable, and maintainable applications by structuring your state changes as actions and reducers.

## Features

- **Composable Actions**: Define actions that encapsulate state changes.
- **Reducers**: Pure functions that describe how state is transformed.
- **Reducer Queues**: Compose multiple reducers to handle complex state updates.
- **Middleware**: Intercept and enhance actions for side effects or logging.
- **Swift Result Builders**: Use result builders to compose actions and reducers in a declarative way.
- **Type Safety**: Leverages Swift generics and key paths for safe state manipulation.

## Installation

Add Onward to your `Package.swift`:

```swift
.package(url: "https://github.com/pedro0x53/onward.git", from: "0.1.0")
```

And add `Onward` as a dependency for your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "Onward", package: "onward")
    ]
)
```

## Usage

### 1. Define Your Store

```swift
import Observation
import Foundation

@Observable
class ToDoStore {
    var title: String = UUID().uuidString
    var todos: [ToDo] = []
}

@Observable
class ToDo: Identifiable {
    let id = UUID()
    var title: String
    var description: String
    var isCompleted: Bool

    init(title: String, description: String, isCompleted: Bool = false) {
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
    }
}
```

### 2. Define Actions and Reducers

```swift
import Onward

struct Interactor {
        static var newToDoItem: AsyncAction<ToDoStore, String, String> {
        AsyncAction { title, description in
            AsyncMiddleware { store in
                Interactor.updateTitle(store) // dispatching an Action

                print("Sleeping...")
                try? await Task.sleep(for: .seconds(3))
                print("Awake!")

                return "Middleware's context"
            } interceptBefore: { context in
                AsyncReducer(get: \.todos, set: \.todos) { todos in
                    todos + [ToDo(title: "\(title) - \(context)", description: description)]
                }
            }

            AsyncReducer(get: \.todos, set: \.todos) { todos in
                todos + [ToDo(title: "Copy of \(title)", description: description)]
            }
        }
    }
}

```

### 3. Dispatch Actions in Your UI

```swift
@State private var store: ToDoStore = ...

Button("Add") {
    let todoIndex = store.todos.count + 1
    Task {
        await Interactor.newToDoItem(store, args: "Title \(todoIndex)", "Description \(todoIndex)")
    }
}
```

## Example

See the full example in [`Examples/Todos`](Examples/Todos) for a working SwiftUI app using Onward.

## License

MIT 
