# Contract: Public API Surface Change

`OnwardCore` is a library; its "contract" is the public API. This is a **breaking**
change → MAJOR version bump, called out in the PR.

## Isolation contract

Every public pipeline type is `@MainActor`-isolated:

```
@MainActor protocol Store
@MainActor protocol Interactor           // static func build() -> Self  (now @MainActor)
@MainActor protocol ActionComponentSchema
@MainActor protocol AsyncActionComponentSchema

@MainActor struct Action<S, each Argument>          // no longer : Sendable
@MainActor struct AsyncAction<S, each Argument>     // no longer : Sendable
@MainActor struct ActionComponent<S>
@MainActor struct AsyncActionComponent<S>
@MainActor struct Reducer<S>
@MainActor struct AsyncReducer<S>
@MainActor struct ReducerQueue<S>
@MainActor struct AsyncReducerQueue<S>
@MainActor struct Middleware<S>
@MainActor struct AsyncMiddleware<S>

@MainActor @resultBuilder enum ActionBuilder<S>
@MainActor @resultBuilder enum AsyncActionBuilder<S>
@MainActor @resultBuilder enum ReducerBuilder<S>
@MainActor @resultBuilder enum AsyncReducerBuilder<S>

@MainActor extension Store { func dispatch(...) ... }   // all overloads
```

## Removed

| Removed | From | Reason |
|---------|------|--------|
| `: Sendable` conformance | `Action`, `AsyncAction` | Redundant + false guarantee under main isolation (FR-004) |
| `@Sendable` on `components` | `Action.init`, `AsyncAction.init`, stored property | Becomes `@MainActor` (FR-003) |
| `@Sendable` on `work` / `perform` | `Reducer`, `AsyncReducer`, `Middleware`, `AsyncMiddleware` inits | Becomes `@MainActor`; lets closures capture non-`Sendable` deps (FR-003) |

`Sources/OnwardCore` must contain **zero** occurrences of `Sendable`, `@Sendable`,
`@unchecked`, `nonisolated`, `@preconcurrency` after the change (FR-011 / SC-003).

## Behavioral guarantees (unchanged — must be preserved)

| ID | Guarantee |
|----|-----------|
| B1 | Dispatching a sync `Action` from a `@MainActor` context applies all mutations before control returns — **no suspension point introduced** (FR-005). |
| B2 | Components of an action run in declaration order (FR-006). |
| B3 | `AsyncAction` awaits each component in order, including when a component suspends (FR-006). |
| B4 | A `Middleware` re-dispatching via `proxy.dispatch` — synchronously, on the main actor — lands its mutation before the parent action's trailing components; no `await`, no deadlock (FR-006, edge case). |
| B5 | `@Reducer` / `@Middleware` / `@Action` / `@Store` / `@Interactor` expansions stay behaviorally identical to the hand-written form (Constitution V). |

## Consumer-visible effects

| Consumer | Effect |
|----------|--------|
| `@MainActor @Observable @Store` class, `@MainActor` caller | `store.dispatch(syncAction)` and `await store.dispatch(asyncAction)` compile with zero concurrency diagnostics (SC-001). Previously failed to compile. |
| User closures in reducers/middleware capturing non-`Sendable` services | Compile without those services being `Sendable` (FR-003). |
| Non-`@MainActor` caller of an async dispatch | Now gets a `Sendable` requirement on the passed arguments **at its own call site** — expected, documented, not supported further (edge case, FR-009). |
| Off-main / actor-based stores | Not supported. Out of scope. |

## Verification

- `swift build -Xswiftc -warnings-as-errors` on a `@MainActor @Observable @Store` sample
  that dispatches both a sync and an `await`-ed async action → 0 diagnostics.
- `swift build` root package + `swift build --package-path Examples` → both succeed
  (SC-004).
- `swift test` → 8/8 (SC-002).
- grep gate → 0 matches (SC-003).
