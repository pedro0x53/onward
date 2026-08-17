---
name: create-middleware
description: Create or convert Onward Middleware/AsyncMiddleware code — inline declarative middleware, @Middleware macro on existing/new functions. Use when asked to add a middleware, wire a read-only side effect (logging, network fetch, analytics) into an Action, or macro-ify a function into a middleware.
---

# Create Middleware (Onward)

Onward has two ways to build a `Middleware<S>` / `AsyncMiddleware<S>`: inline (declarative init inside an `Action`/`AsyncAction` builder) or via the `@Middleware` peer macro (turns a plain function into a generated `...Middleware` property). Companion piece to `create-reducer` — Middleware handles read-only side effects (logging, network calls, dispatching mutations via `proxy.dispatch`), Reducer handles direct key-path read/write.

## Core types (read-only, don't reinvent)

- `Middleware<S: Store>` — `Sources/OnwardCore/Middleware/Middleware.swift`
- `AsyncMiddleware<S: Store>` — `Sources/OnwardCore/Middleware/AsyncMiddleware.swift`
- `@Middleware` macro — `Sources/OnwardGenerators/MiddlewareMacro.swift` (decl), `Sources/OnwardGeneratorsMacros/Implementations/MiddlewareMacro.swift` (impl)

No `MiddlewareBuilder`/`MiddlewareQueue` exists (unlike `Reducer`) — a middleware is a single closure over `S.Proxy`, placed directly in an `ActionBuilder`/`AsyncActionBuilder` block alongside reducers, or wired via `@Action(middlewares:)`.

Each type has exactly **one** init: `Middleware<S>(_ perform: (S.Proxy) -> Void)` / `AsyncMiddleware<S>(_ perform: (S.Proxy) async -> Void)`. Unlike `Reducer`, there's no get/set key-path plumbing — the closure receives the store's `Proxy` (read-only snapshot) directly, and mutates state by calling `proxy.dispatch(\.someMutator, newValue)`, not by returning a value.

## Decision: which path

Same three shapes as reducers — infer from what the user hands you:

1. **Existing function → macro-ify it.** Function already sits in an `Interactor` and should become a middleware without rewriting its body.
2. **New function → macro-ify it.** User wants a new named function generated as a middleware via macro.
3. **Fully inline middleware.** No named function — `Middleware { proxy in ... }` / `AsyncMiddleware { proxy in ... }` literal directly inside an `Action`/`AsyncAction` builder block.

Default to **inline** for a one-off effect used in exactly one action; default to **macro** when the function is independently meaningful/testable or the surrounding `Interactor` already uses macro style — match neighboring convention in the file.

## Path 1 & 2 — `@Middleware` macro

```swift
@Middleware(<StoreType>.self)
func <name>(_ proxy: <StoreType>.Proxy) { ... }        // sync
@Middleware(<StoreType>.self)
func <name>(_ proxy: <StoreType>.Proxy) async { ... }  // async
```

Rules the macro enforces (violate these → compiler diagnostic, not silent failure):
- Function must have **either zero parameters, or exactly one parameter whose internal (second) name is literally `proxy`** — e.g. `_ proxy: ToDoStore.Proxy`. Any other arity, or a single param not named `proxy` (even `func log(proxy: ToDoStore.Proxy)` without the `_` label — the macro checks `secondName`, so the external label must be `_` and internal name `proxy`), triggers `invalidMiddleware`.
- `async` on the function → macro emits `AsyncMiddleware<S>` instead of `Middleware<S>`, inferred from the function signature, no separate annotation.
- `static func` → generated property is also `static`.
- Generated property name: `lowercase(metatype) + Capitalize(funcName) + "Middleware"` — same pattern for both sync and async, no "Async" inserted (e.g. an async `fetch` on `ToDoStore` generates `toDoStoreFetchMiddleware`).
- Store type is the first positional arg to `@Middleware(_:)` and need not match the function's enclosing type.

`@Middleware` only ever takes the store type. To run reducers after a middleware, wire them via `@Action(middlewares:, lateReducers:)` (see working example below).

Wire the generated `...Middleware` property into an `Action`/`AsyncAction` via `@Action`:

```swift
@Action(middlewares: \Self.toDoStoreLoadRemoteMiddleware,
        lateReducers: \Self.toDoStoreSetLoadedAlertContentReducer,
                      \Self.toDoStoreDiplayAlertReducer)
var loadRemoteAction: AsyncAction<ToDoStore>

@Middleware(ToDoStore.self)
private func loadRemote(_ proxy: ToDoStore.Proxy) async {
    let remoteItems = await httpClient.request()
    proxy.dispatch(\.todosMutator, remoteItems)
}
```

**Converting an existing function**: add the `@Middleware(...)` attribute above it — don't touch the body, but rename its parameter to `proxy` (with `_` label) if it isn't already, since the macro requires that exact shape.

## Path 3 — inline middleware

Declared directly inside an `Action`/`AsyncAction` builder block, mixed freely with `Reducer`/`AsyncReducer`:

```swift
var addNewToDoItem: Action<ToDoStore, String, String> {
    Action { title, description in
        Middleware { proxy in
            if self.validator.validate(title) && self.validator.validate(description) {
                let newToDo = ToDo(title: title, description: description)
                var toDos = proxy.todos
                toDos.append(newToDo)
                proxy.dispatch(\.todosMutator, toDos)
            }
        }
    }
}
```

Async form is identical, swap `Middleware` → `AsyncMiddleware`, place inside `AsyncAction`:

```swift
AsyncAction {
    AsyncMiddleware { proxy in
        let remoteItems = await self.httpClient.request()
        proxy.dispatch(\.todosMutator, remoteItems)
    }

    AsyncReducer(setter: \.isAlertPresented) { true }
}
```

Mutation inside a middleware always goes through `proxy.dispatch(\.mutatorKeyPath, newValue)` — never assign directly to `proxy` properties (it's a read-only snapshot type; there's no writable key path access like `Reducer` gets on the store).

## Checklist before finishing

1. Confirmed the `Store` type and that any `proxy.dispatch(...)` calls target a real mutator key path on that store.
2. Macro path: parameter is either absent or named exactly `proxy` with `_` external label — check this before applying the attribute, it's the #1 way `@Middleware` silently fails to compile with a diagnostic.
3. `async` used consistently — awaited calls require `async` func + `AsyncMiddleware`/`AsyncAction` context, not `Middleware`/`Action`.
4. If late reducers are needed, wire them via `@Action(middlewares:, lateReducers:)`.
5. Generated/declared property name doesn't collide with an existing member.
6. Style matches neighboring code in the same file (macro vs inline) unless user explicitly asked to convert one to the other.
