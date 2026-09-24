# Phase 1 Data Model: Swift 6 MainActor Pipeline Isolation

This feature adds no runtime data structures. The "entities" are the public pipeline
types and the isolation annotation each must carry. This document is the authoritative
inventory driving `tasks.md`.

## Isolation matrix — `Sources/OnwardCore`

| Type | File | Kind | Change |
|------|------|------|--------|
| `Action<S, each Argument>` | Action/Sync/Action.swift | struct | `@MainActor`; drop `: Sendable`; `components` property + `init` param `@MainActor (repeat each Argument) -> [ActionComponent<S>]` (no `@Sendable`) |
| `ActionComponentSchema` | Action/Sync/ActionComponentSchema.swift | protocol | `@MainActor` |
| `ActionComponent<S>` | Action/Sync/ActionComponentSchema.swift | struct | `@MainActor`; stored `_run: (S) -> Void` |
| `ActionBuilder<S>` | Action/Sync/ActionBuilder.swift | `@resultBuilder enum` | `@MainActor` |
| `AsyncAction<S, each Argument>` | Action/Async/AsyncAction.swift | struct | `@MainActor`; drop `: Sendable`; `components` property + `init` param `@MainActor (repeat each Argument) -> [AsyncActionComponent<S>]` (no `@Sendable`) |
| `AsyncActionComponentSchema` | Action/Async/AsyncActionComponent.swift | protocol | `@MainActor`; `func run(_:) async` |
| `AsyncActionComponent<S>` | Action/Async/AsyncActionComponent.swift | struct | `@MainActor`; stored `_run: (S) async -> Void` |
| `AsyncActionBuilder<S>` | Action/Async/AsyncActionBuilder.swift | `@resultBuilder enum` | `@MainActor` |
| `Reducer<S>` | Reducer/Sync/Reducer.swift | struct | `@MainActor`; 3 inits' `work` params `@MainActor @escaping`; `_reduce: (S) -> Void` |
| `ReducerQueue<S>` | Reducer/Sync/ReducerQueue.swift | struct | `@MainActor` (incl. `mutating append`) |
| `ReducerBuilder<S>` | Reducer/Sync/ReducerBuilder.swift | `@resultBuilder enum` | `@MainActor` |
| `AsyncReducer<S>` | Reducer/Async/AsyncReducer.swift | struct | `@MainActor`; 3 inits' `work` params `@MainActor @escaping … async`; `_reduce: (S) async -> Void` |
| `AsyncReducerQueue<S>` | Reducer/Async/AsyncReducerQueue.swift | struct | `@MainActor` |
| `AsyncReducerBuilder<S>` | Reducer/Async/AsyncReducerBuilder.swift | `@resultBuilder enum` | `@MainActor` |
| `Middleware<S>` | Middleware/Middleware.swift | struct | `@MainActor`; `init` `perform` param `@MainActor @escaping (S.Proxy) -> Void` |
| `AsyncMiddleware<S>` | Middleware/AsyncMiddleware.swift | struct | `@MainActor`; `init` `perform` param `@MainActor @escaping (S.Proxy) async -> Void` |
| `Store` | Store/Store.swift | protocol | `@MainActor` |
| `extension Store` (dispatch overloads) | Store/Store.swift | extension | `@MainActor` on the extension |
| `Interactor` | Store/Interactor.swift | protocol | `@MainActor`; `static func build() -> Self` |
| `OnwardContainer` / `Inward` / `Outward` | Container/OnwardContainer.swift | — | **no change** (Volt, out of scope) |

### Conformance extensions to keep working (no annotation beyond type-level `@MainActor`)

- `extension Reducer: ActionComponentSchema, AsyncActionComponentSchema` — `run(_:)` sync.
- `extension ReducerQueue: ActionComponentSchema`.
- `extension AsyncReducer: AsyncActionComponentSchema` — `run(_:) async`.
- `extension AsyncReducerQueue: AsyncActionComponentSchema`.
- `extension Middleware: ActionComponentSchema, AsyncActionComponentSchema`.
- `extension AsyncMiddleware: AsyncActionComponentSchema`.

## Macro layer — `Sources/OnwardGeneratorsMacros`

| Unit | File | Change |
|------|------|--------|
| `StoreMacro` generated `Proxy` | Implementations/StoreMacro.swift | Emit `@MainActor struct Proxy` (nested type does not inherit extension isolation) |
| `StoreMacro` `@MainActor` check | Implementations/StoreMacro.swift | If attached class lacks a `MainActor` attribute → `context.diagnose(.missingMainActor)`, still emit members |
| `InteractorMacro` `@MainActor` check | Implementations/InteractorMacro.swift | Same check + diagnostic |
| `OnwardMacroError.missingMainActor` | Utils/OnwardMacroErrors.swift | New case + message: `"@Store/@Interactor requires the class to be @MainActor. Add '@MainActor' to '<Name>'."` |
| `ReducerMacro` / `MiddlewareMacro` / `ActionFactory` | Implementations/… | No code change; verify expansion compiles via new tests |

Public macro declarations (`Sources/OnwardGenerators/*.swift`): no signature change
expected. Update doc comments only if wording references `Sendable`.

## Tests — `Tests/OnwardTests/OnwardTests.swift`

| Item | Change |
|------|--------|
| `ToDoInteractor`, `ToDo`, `struct OnwardTests` | Add `@MainActor` (annotations only, no body edits) |
| 6 existing `@Test` | Unchanged bodies; pass 6/6 |
| new `dispatchActionSynchronouslyFromMainActor()` | Explicit `@MainActor` function; dispatch sync `Action`; assert value on next line (FR-010a) |
| new `asyncMiddlewareSuspendsBeforeTrailingReducer()` | `AsyncAction` → `AsyncMiddleware` `await Task.yield()` + `proxy.dispatch` → trailing `AsyncReducer`; assert ordered final state (FR-010b) |

New macro-expansion test target (US3, P2): assert expansions of `@Store` (incl.
`@MainActor` on `Proxy`), `@Interactor`, `@Reducer`, `@Middleware`, `@Action` (sync +
async), and the `missingMainActor` diagnostic when `@MainActor` is omitted.

## Docs

| Surface | Change |
|---------|--------|
| `README.md` | `@Store`/`@Interactor` must be `@MainActor`; snippet updated; off-main async caller `Sendable`-at-call-site note |
| `Sources/OnwardCore/OnwardCore.docc/OnwardCore.md` | Isolation note; `Sendable` removed from `Action`/`AsyncAction` |
| `Sources/OnwardGenerators/OnwardGenerators.docc/OnwardGenerators.md` | `@MainActor` requirement + `missingMainActor` diagnostic |

## State transitions

None. No entity has lifecycle state. Dispatch ordering semantics are unchanged and
covered by `contracts/public-api.md` + `quickstart.md`.

## Validation rules (from requirements)

- **FR-011 / SC-003**: `grep -REn 'Sendable|@Sendable|@unchecked|nonisolated|@preconcurrency' Sources/OnwardCore` → 0 matches.
- **FR-005**: sync dispatch adds no suspension point (no `async` on `Action.dispatch` / `run`).
- **FR-006**: async component order preserved incl. suspension; reentrant `proxy.dispatch` visible before trailing components.
- **FR-002**: every type in the matrix above carries `@MainActor`.
- **FR-008**: `@Store` / `@Interactor` on a non-`@MainActor` class emits `missingMainActor`.
