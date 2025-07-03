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

@Observable
class ToDoStore {
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
    static var newToDoItem: Action<ToDoStore, String, String> {
        Action { title, description in
            Middleware { store in
                print("Sleeping...")
                try? await Task.sleep(for: .seconds(3))
                print("Awake!")

                return "Middleware's context"
            } before: { context in
                Reducer(get: \.todos, set: \.todos) { todos in
                    todos + [ToDo(title: "\(title) \(context)", description: description)]
                }
            }
        }
    }

    static var toggleToDoStatus: Action<ToDo> {
        Action {
            Reducer(get: \.isCompleted, set: \.isCompleted) { isCompleted in
                !isCompleted
            }
        }
    }
}

```

### 3. Dispatch Actions in Your UI

```swift
import SwiftUI

struct ContentView: View {
    @State private var store: ToDoStore

    init(store: ToDoStore = .init()) {
        self.store = store
    }

    var body: some View {
        NavigationStack {
            List(store.todos) { todo in
                HStack {
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .frame(width: 24, height: 24)
                    VStack(alignment: .leading) {
                        Text(todo.title).font(.headline)
                        Text(todo.description).font(.caption)
                    }
                    .onTapGesture {
                        Task {
                            await Interactor.toggleToDoStatus(todo)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let todoIndex = store.todos.count + 1
                        Task {
                            await Interactor.newToDoItem(store, args: "Title \(todoIndex)", "Description \(todoIndex)")
                        }
                    }
                }
            }
        }
    }
}
```

## Example

See the full example in [`Examples/Todos`](Examples/Todos) for a working SwiftUI app using Onward.

## License

MIT 
