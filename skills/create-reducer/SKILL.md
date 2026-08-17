---
name: create-reducer
description: Create or convert Onward Reducer/AsyncReducer code — inline declarative reducers, @Reducer macro on existing/new functions. Use when asked to add a reducer, wire state mutation into an Action, or macro-ify a function into a reducer.
---

# Create Reducer (Onward)

Onward has two ways to build a `Reducer<S>` / `AsyncReducer<S>`: inline (declarative init inside an `Action`/`AsyncAction` builder) or via the `@Reducer` peer macro (turns a plain function into a generated `...Reducer` property). Pick based on what user gives you.

## Core types (read-only, don't reinvent)

- `Reducer<S: Store>` — `Sources/OnwardCore/Reducer/Sync/Reducer.swift`
- `AsyncReducer<S: Store>` — `Sources/OnwardCore/Reducer/Async/AsyncReducer.swift`
- `ReducerQueue<S>` / `AsyncReducerQueue<S>` — batch reducers as one step
- `ReducerBuilder<S>` / `AsyncReducerBuilder<S>` — result builders, support control flow
- `@Reducer` macro — `Sources/OnwardGenerators/ReducerMacro.swift` (decl), `Sources/OnwardGeneratorsMacros/Implementations/ReducerMacro.swift` (impl)

`Reducer`/`AsyncReducer` each have exactly 3 inits — pick the one matching arity of what you need:

| Init | Use when | Signature shape |
|---|---|---|
| `getter:do:` | read-only (logging, validation, side effect w/o write) | `(get keyPaths) { values in ... }`, no return |
| `setter:do:` | write-only (new state doesn't depend on old) | `(set keyPaths) { () -> newValues }` |
| `get:set:do:` | read-write (most common) | `(get, set) { values in -> newValues }` |

Both sync and async variants use `repeat each` parameter packs — multiple key paths are supported natively, e.g. `Reducer(get: \.a, \.b, set: \.a, \.b) { a, b in (a+1, b+1) }`. Don't hand-roll multi-property reducers as separate single-property ones unless the user's function is genuinely single-purpose — but *do* prefer several small reducers over one big one when they're logically independent (see `Todos` example: `setLoadedAlertContent` + `diplayAlert` as two reducers instead of one setting a tuple).

## Decision: which path

Ask/infer which of these three the user wants:

1. **Existing function → macro-ify it.** User points at a function already in an `Interactor` (or any type) and wants it turned into a reducer without rewriting its body.
2. **New function → macro-ify it.** User wants a new named function (not a closure) doing the transform, generated as a reducer via macro.
3. **Fully inline reducer.** No named function — just a `Reducer { ... }` / `AsyncReducer { ... }` literal placed directly inside an `Action`/`AsyncAction` builder block, or assigned as a `Reducer<S>` stored property.

If ambiguous, default to **inline** for one-off simple state changes, and **macro** when the function is (or should be) independently testable/reusable, or when the surrounding code already uses the macro style (check neighboring code in the same `Interactor`/file first — match existing convention, don't mix styles within one type unless the user asks).

## Path 1 & 2 — `@Reducer` macro

```swift
@Reducer(<StoreType>.self, get: \.<prop>, set: \.<prop>)
func <name>(_ <param>: <Type>) -> <ReturnType> { ... }
```

Rules the macro enforces (violate these → compiler diagnostic, not silent failure):
- `get:` key path count **must equal** function parameter count, 1:1 in order.
- `set:` key path count **must equal** function return count (single value = 1, tuple = N members, each must be a plain named type — no nested generics in the tuple slot).
- At least one of `get:`/`set:` must be present (both empty → `invalidReducer` diagnostic).
- `async` on the function → macro emits `AsyncReducer<S>` instead of `Reducer<S>`; no separate annotation needed, it's inferred from the function signature.
- `static func` → generated property is also `static`.
- Generated property name: `lowercase(metatype)` + `Capitalize(funcName)` + `Reducer`, e.g. store `ToDoStore`, func `setLoadedAlertContent` → `toDoStoreSetLoadedAlertContentReducer`. Store type is the *first positional arg* to `@Reducer(_:)`, which need not match the function's own enclosing type (e.g. a reducer on `ToDo` inside a `ToDoStore`-scoped interactor).
- Zero-arg functions omit the closure param list in the generated body; the macro doesn't add unused `_` placeholders.

Wire the generated `...Reducer` property into an `Action` via `reducers:`/`lateReducers:` on `@Action`:

```swift
@Action(reducers: \Self.toDoToggleToDoStatusReducer)
var toggleToDoStatusAction: Action<ToDo>

@Reducer(ToDo.self, get: \.isCompleted, set: \.isCompleted)
func toggleToDoStatus(_ status: Bool) -> Bool { !status }
```

For async flows mixing a middleware + reducers, use `middlewares:` and `lateReducers:` together (reducers run after middleware dispatch settles):

```swift
@Action(middlewares: \Self.toDoStoreLoadRemoteMiddleware,
        lateReducers: \Self.toDoStoreSetLoadedAlertContentReducer,
                      \Self.toDoStoreDiplayAlertReducer)
var loadRemoteAction: AsyncAction<ToDoStore>
```

**Converting an existing function**: just add the `@Reducer(...)` attribute above it — don't touch the body. If its params/return don't cleanly map 1:1 to key paths (e.g. it takes unrelated helper args, or returns a type that isn't cleanly settable), the macro is the wrong tool — fall back to inline (Path 3) with a closure that captures the extra context.

## Path 3 — inline reducer

Declared directly where used, either inside an `Action`/`AsyncAction` result-builder block or as a computed property:

```swift
var dismissAlertDeclAction: Action<ToDoStore> {
    Action {
        Reducer(setter: \.isAlertPresented) { false }
        Reducer(setter: \.alert) { .init() }
    }
}
```

Prefer several `Reducer(...)` lines over one that sets unrelated properties — the builder flattens them via `ReducerBuilder` into one queue, execution order = declaration order, no perf cost to splitting. For read-write single property:

```swift
Reducer(get: \.isCompleted, set: \.isCompleted) { status in !status }
```

Use `ReducerQueue<S> { ... }` instead of a bare array when the user wants to build/append reducers dynamically (`queue.append(...)`) rather than as a fixed static list.

## Checklist before finishing

1. Confirmed the `Store` type and that `get:`/`set:` key paths actually exist and are settable (`ReferenceWritableKeyPath` requires the store property be a `var`, not `let`).
2. Function param/return arity matches key path counts exactly (macro path) — count them yourself, don't guess.
3. `async` used consistently — if the transform awaits anything, function/closure must be `async` and caller context must be an `AsyncAction`/`AsyncReducer`, not `Action`/`Reducer`.
4. Generated/declared property name doesn't collide with an existing member.
5. Style matches neighboring code in the same file (macro vs inline) unless user explicitly asked to convert one to the other.
