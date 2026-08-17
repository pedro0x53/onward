---
name: create-action
description: Create or convert Onward Action/AsyncAction code — inline declarative actions built from Reducer/Middleware, or the @Action macro composing named reducers/middlewares by key path. Use when asked to add an action, dispatch a state change, or wire reducers/middlewares together into something dispatchable.
---

# Create Action (Onward)

An `Action<S, Args...>` / `AsyncAction<S, Args...>` bundles one or more `Reducer`/`Middleware` (or `AsyncReducer`/`AsyncMiddleware`) steps into a single dispatchable unit. It's the top-level thing a `Store` dispatches — see `create-reducer` and `create-middleware` for the steps that go inside one.

## Core types (read-only, don't reinvent)

- `Action<S: Store, each Argument>` — `Sources/OnwardCore/Action/Sync/Action.swift`
- `AsyncAction<S: Store, each Argument>` — `Sources/OnwardCore/Action/Async/AsyncAction.swift`
- `ActionBuilder<S>` / `AsyncActionBuilder<S>` — result builders, support full control flow (`if`, `if/else`, `for…in`, `#available`)
- `ActionComponentSchema` / `AsyncActionComponentSchema` — protocols `Reducer`, `Middleware`, `ReducerQueue` (and their async counterparts) conform to, letting them mix inside a builder block
- `ActionComponent<S>` / `AsyncActionComponent<S>` — type-erased wrappers the builder uses internally; you never construct these by hand
- `@Action` macro — `Sources/OnwardGenerators/ActionMacro.swift` (6 overload decls), impl in `Sources/OnwardGeneratorsMacros/Implementations/Action/{ActionFactory,ActionMacro,AsyncActionMacro}.swift`

**Key asymmetry**: `Reducer`/`Middleware` conform to *both* `ActionComponentSchema` and `AsyncActionComponentSchema`, so sync components can be dropped straight into an `AsyncAction { }` builder block alongside `AsyncReducer`/`AsyncMiddleware`. The reverse is not true — `AsyncReducer`/`AsyncMiddleware` only conform to `AsyncActionComponentSchema`, so they cannot appear inside a plain `Action { }` block. Rule of thumb: if anything in the pipeline is async, the whole thing must be an `AsyncAction`.

`Action`/`AsyncAction` dispatch runs components **in declaration order**, whatever their kind (reducer or middleware) — there's no automatic reordering.

## Decision: which path

1. **Inline builder.** Declare a computed property (or local value) of type `Action<S, ...>`/`AsyncAction<S, ...>` and list `Reducer`/`Middleware` literals (or key-path references to existing ones) directly in the builder block. Best when the action takes dispatch-time arguments, needs control flow (`if`/`for`), or is only used once.
2. **`@Action` macro.** Attach `@Action(...)` to a `var` with an explicit `Action<S>`/`AsyncAction<S>` type annotation and **no body** — the macro synthesizes the `get { }` accessor from key paths to existing `Reducer`/`Middleware`/`AsyncReducer`/`AsyncMiddleware` properties (typically macro-generated ones from `create-reducer`/`create-middleware`). Best when the pieces already exist as named properties and you're just wiring them together, and when the action takes no dispatch-time arguments (macro-composed actions can't reference builder-closure parameters).

Match whichever style the surrounding `Interactor` already uses; don't mix inline-builder and `@Action`-macro style for actions that are conceptually similar within one file.

## Path 1 — inline builder

```swift
var toggleAction: Action<ToDo> {
    Action {
        Reducer(get: \.isCompleted, set: \.isCompleted) { status in !status }
    }
}
```

With dispatch-time arguments — the builder closure's parameters become the action's `each Argument` pack, and the property's generic type must list them in order:

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

Async, mixing an `AsyncMiddleware` side effect with `AsyncReducer` follow-ups:

```swift
var loadRemoteDeclAction: AsyncAction<ToDoStore> {
    AsyncAction {
        AsyncMiddleware { proxy in
            let remoteItems = await self.httpClient.request()
            proxy.dispatch(\.todosMutator, remoteItems)
        }

        AsyncReducer(setter: \.alert) {
            AlertContent(title: "Remote Items", message: "The remote items were loaded!")
        }

        AsyncReducer(setter: \.isAlertPresented) { true }
    }
}
```

You can also embed a `ReducerQueue<S>`/`AsyncReducerQueue<S>` value, an array of components, or use `if`/`for` control flow — the builder flattens all of it.

## Path 2 — `@Action` macro

```swift
@Action(reducers: \Self.<reducerProp>...,
        middlewares: \Self.<middlewareProp>...,
        lateReducers: \Self.<reducerProp>...)
var someAction: Action<StoreType>          // or AsyncAction<StoreType>
```

Shorthand overloads exist for the common single-kind cases:

```swift
@Action(\Self.toggleReducer)              // reducers only
var toggleToDoStatusAction: Action<ToDo>

@Action(\Self.analyticsMiddleware)        // middlewares only
var trackAction: Action<ToDoStore>
```

Rules and behavior (from `ActionFactory.makeActionDecl`):
- Target must be a `var` **without** a body/accessor — the macro attaches the `get { }` accessor. Giving it a body yourself conflicts with the macro.
- The `var`'s type annotation must be written explicitly (`Action<ToDo>`, `AsyncAction<ToDoStore>`, etc.) — the macro reads this text but does not infer or validate it beyond extracting it as a string. Get the generic arguments right yourself (macro-composed actions rarely take dispatch-time arguments — there's no closure to receive them, so leave the `each Argument` pack empty).
- Every key path's root must be either the literal enclosing type name or `Self` — a key path rooted in some unrelated type triggers `invalidAction`.
- At least one key path argument is required (`missingActionComponents` if the parens are empty, `invalidKeyPaths` if none of the arguments are key paths).
- **Execution order = the literal order you type the key paths in the attribute, not the label they sit under.** The macro concatenates *all* key-path arguments across `reducers:`/`middlewares:`/`lateReducers:` in call-site order and emits one line per key path in that order — the labels exist only to pick the correct sync/async overload and for readability, they do not regroup or reorder anything. Writing `reducers:` before `middlewares:` before `lateReducers:` (the documented convention) produces the documented "reducers → middlewares → lateReducers" order; writing them out of that order changes actual dispatch order to match what you wrote, silently.
- Sync vs async is resolved by normal Swift overload resolution against the six macro declarations in `ActionMacro.swift` — pass `Reducer<S>`/`Middleware<S>` key paths to get `Action<S>`, or `AsyncReducer<S>`/`AsyncMiddleware<S>` key paths to get `AsyncAction<S>`. Unlike the inline builder, you **cannot** mix sync and async component key paths in a single `@Action(...)` call — no overload accepts both, so pick components that are all sync or all async.

Full worked example (mixing macro-generated middleware + reducers from `create-reducer`/`create-middleware`):

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

@Reducer(ToDoStore.self, set: \.alert)
func setLoadedAlertContent() async -> AlertContent {
    AlertContent(title: "Remote Items", message: "The remote items were loaded!")
}

@Reducer(ToDoStore.self, set: \.isAlertPresented)
func diplayAlert() async -> Bool { true }
```

```swift
@Action(reducers: \Self.toDoToggleToDoStatusReducer)
var toggleToDoStatusAction: Action<ToDo>

@Reducer(ToDo.self, get: \.isCompleted, set: \.isCompleted)
func toggleToDoStatus(_ status: Bool) -> Bool { !status }
```

## Dispatching

```swift
store.dispatch(interactor.toggleAction)              // by value
store.dispatch(\.toggleAction)                        // by key path on the store
await store.dispatch(interactor.loadRemoteAction)     // async
```

Also callable directly: `action(store, args...)` (sync) or `await action(store, args...)` (async), via `callAsFunction`.

## Checklist before finishing

1. Every component in the pipeline is sync, or the whole thing is an `AsyncAction` (sync components are fine inside async; never the reverse).
2. Macro path: target `var` has an explicit `Action<...>`/`AsyncAction<...>` type annotation and no body.
3. Macro path: key paths are listed in the order they should actually run — don't rely on the `reducers:`/`middlewares:`/`lateReducers:` labels to reorder anything.
4. Macro path: all referenced key paths are homogeneously sync or homogeneously async — no mixing in one `@Action(...)` call.
5. If the action needs dispatch-time arguments, use the inline builder (Path 1) — the macro path has no way to receive them.
6. Style matches neighboring code in the same file (macro composition vs inline builder) unless the user explicitly asked to convert one to the other.
