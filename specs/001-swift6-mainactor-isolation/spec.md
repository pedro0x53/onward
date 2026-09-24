# Feature Specification: Swift 6 MainActor Pipeline Isolation

**Feature Branch**: `001-swift6-mainactor-isolation`

**Created**: 2026-09-09

**Status**: Draft

**Input**: User description: "OnwardCore Swift 6 concurrency: Direction A (@MainActor pipeline). Isolate the whole Onward dispatch pipeline to @MainActor. Remove Sendable / @Sendable from Action / AsyncAction. work / perform closures become @MainActor @escaping — never @Sendable. No behavior change: sync dispatch still mutates synchronously, async dispatch keeps order."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Dispatch async actions from SwiftUI state without concurrency errors (Priority: P1)

A developer builds a SwiftUI `@Observable @Store` class (the documented primary use) and dispatches an `AsyncAction` from a view with `await store.dispatch(...)`. Today this fails to compile: the store is a non-`Sendable` reference type reachable from the main actor, and the dispatch pipeline is `nonisolated`, so the compiler refuses to send the store across the isolation boundary and the library offers no annotation to fix it.

**Why this priority**: This is the blocking defect. The package declares Swift tools 6.0 (complete concurrency checking) and documents SwiftUI `@Observable` stores as the main use case, yet that exact combination does not build once an async dispatch is introduced. Nothing else matters until this works.

**Independent Test**: Add a test target that defines a `@MainActor @Observable @Store` class, dispatches an `AsyncAction` from a `@MainActor` context with `await`, and builds under `swift build -Xswiftc -warnings-as-errors` with zero concurrency diagnostics.

**Acceptance Scenarios**:

1. **Given** a `@MainActor` store with an `AsyncAction`, **When** a `@MainActor` caller does `await store.dispatch(action)`, **Then** the code compiles with no concurrency diagnostics and the action runs.
2. **Given** a synchronous `Action`, **When** a `@MainActor` caller does `store.dispatch(action)`, **Then** state is mutated synchronously before the next line executes (no suspension introduced).
3. **Given** user closures inside a `Reducer` or `Middleware` that capture non-`Sendable` services (network clients, formatters), **When** the action is dispatched, **Then** the closures compile without requiring those services to be `Sendable`.

---

### User Story 2 - Preserved execution semantics after isolation (Priority: P1)

A developer relies on Onward's ordering guarantees: components in an action run in declaration order; a middleware that re-dispatches a mutation via `proxy.dispatch` lands before a trailing reducer; `AsyncAction` awaits each component in order. Isolating the pipeline to `@MainActor` must not change any of this.

**Why this priority**: The isolation change touches every core type. If it silently reorders or changes when mutations become visible, existing consumers break in ways not caught by a compile check.

**Independent Test**: Run the existing 6 tests unchanged plus a new ordering test where an `AsyncMiddleware` does `await Task.yield()` before a trailing `AsyncReducer`; assert final state reflects both in order.

**Acceptance Scenarios**:

1. **Given** the current test suite, **When** run against the isolated pipeline, **Then** all 6 existing tests pass with no test-body edits.
2. **Given** an `AsyncAction` whose `AsyncMiddleware` suspends (`await Task.yield()`) before a trailing `AsyncReducer`, **When** dispatched, **Then** the reducer observes the middleware's effect and runs after it.
3. **Given** a `Middleware` that re-dispatches a mutation through `proxy.dispatch` (re-entrant dispatch), **When** the parent action continues, **Then** the re-dispatched mutation is applied before the parent's trailing components.

---

### User Story 3 - Macro output compiles under the isolated pipeline (Priority: P2)

A developer uses `@Store`, `@Interactor`, `@Reducer`, `@Middleware`, `@Action`. The code these macros generate (store extensions, `Proxy` struct, generated reducer/middleware properties, interactor `build()`) must satisfy the now-`@MainActor` protocol requirements and compile without the developer adding annotations the macro could have added.

**Why this priority**: Macros are a headline feature and must stay at parity with hand-written form (constitution principle V). But this is downstream of the core types being isolated.

**Independent Test**: Build the macro expansion tests and a sample `@MainActor @Store` / `@Interactor` pair; confirm generated code compiles with no concurrency diagnostics.

**Acceptance Scenarios**:

1. **Given** a `@MainActor @Observable @Store(MyInteractor.self) final class MyStore`, **When** the project builds, **Then** the generated `Store` conformance, mutator extension, and `Proxy` struct compile with no concurrency diagnostics.
2. **Given** a `@MainActor @Interactor final class MyInteractor` using `@Reducer` / `@Middleware` methods, **When** the project builds, **Then** the generated `...Reducer` / `...Middleware` properties compile.
3. **Given** a `@Store` / `@Interactor` class that is NOT `@MainActor`, **When** the project builds, **Then** the developer receives a clear, actionable diagnostic pointing at the missing isolation (rather than an opaque compiler error deep in generated code).

---

### Edge Cases

- **Non-`@MainActor` caller of an async dispatch**: a caller outside the main actor that passes arguments to `dispatch` now gets a `Sendable` requirement on those arguments at its own call site. This is expected and correct — the spec does not attempt to support off-main callers, only to make the failure land where the caller can see and fix it.
- **Parameter-pack closure isolation**: `@MainActor` on a closure parameter typed `(repeat each Argument) -> ...` has triggered compiler bugs in the Swift 6.0.x line. The implementation must verify the narrowest form builds before applying isolation broadly, and have a documented fallback (isolate the enclosing struct, leave the parameter bare).
- **`Examples/` package**: consumes the core. It must still build against the isolated pipeline; its source is not otherwise in scope for edits beyond what the isolation forces.
- **Re-entrant dispatch on the main actor**: `proxy.dispatch` called synchronously from within a middleware already on the main actor must not deadlock or require an `await`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The entire Onward dispatch pipeline MUST be isolated to the main actor, so that a `@MainActor` consumer can dispatch synchronous and asynchronous actions against a non-`Sendable` store with no concurrency diagnostics under complete checking.
- **FR-002**: The public core types forming the pipeline — the store protocol, interactor protocol, action / async-action component schemas and components, sync and async reducers, sync and async middleware, reducer queues, actions, async actions, and every action/reducer result builder — MUST all carry main-actor isolation.
- **FR-003**: Stored closures and the closure parameters that populate them (`work`, `perform`, action `components`) MUST be main-actor-isolated and MUST NOT be `@Sendable`, so that user closures may freely capture non-`Sendable` dependencies.
- **FR-004**: `Sendable` / `@Sendable` conformance and annotations MUST be removed from `Action` and `AsyncAction` (they become redundant under main isolation and currently constitute a false guarantee).
- **FR-005**: Synchronous dispatch MUST remain synchronous — dispatching an `Action` from a main-actor context MUST apply all state mutations before control returns, introducing no suspension point.
- **FR-006**: Asynchronous dispatch MUST preserve component execution order, including the case where a component suspends, and MUST preserve the visibility of re-entrant `proxy.dispatch` mutations before a parent action's trailing components.
- **FR-007**: Code generated by `@Store`, `@Interactor`, `@Reducer`, `@Middleware`, and `@Action` MUST satisfy the main-actor protocol requirements without the consumer adding isolation annotations that the macro is responsible for.
- **FR-008**: The macros MUST require the annotated `@Store` / `@Interactor` class to be `@MainActor`, and SHOULD surface an actionable diagnostic when it is not, rather than letting a raw compiler error escape from generated code.
- **FR-009**: The DocC catalog and `README.md` MUST document that `@Store` / `@Interactor` classes must be `@MainActor`, and MUST document that a non-`@MainActor` caller of an async dispatch takes on a `Sendable` requirement for the passed arguments at its call site.
- **FR-010**: The test suite MUST keep all existing tests passing with no test-body edits (only isolation annotations added to the test interactor, store, and suite), and MUST add: (a) a test dispatching from an explicit `@MainActor` function that asserts synchronous mutation, and (b) a test of an `AsyncAction` whose `AsyncMiddleware` suspends before a trailing `AsyncReducer`, asserting order.
- **FR-011**: After the change, `Sources/OnwardCore` MUST contain no `Sendable`, `@Sendable`, `@unchecked`, `nonisolated`, or `@preconcurrency` tokens.
- **FR-012**: Implementation MUST begin with the narrowest possible isolation change (main-actor isolation on the sync reducer's initializers only) validated by a build, before applying isolation across the rest of the pipeline, and MUST have a documented fallback for the parameter-pack closure compiler-bug risk.
- **FR-013**: The `Examples/` package MUST build successfully against the isolated core.

### Out of Scope

- Off-main-actor stores, actor-based stores, or any store not isolated to the main actor.
- Any `Sendable` conformance on core types.
- Changes to Volt / dependency injection.
- Edits to `Examples/` source beyond confirming it builds.

### Key Entities

- **Dispatch pipeline**: the ordered path a dispatched intent travels — `View → Store → Interactor → (Middleware → Reducer)` — with state read back only through the immutable `Proxy`. This feature places the whole path in a single isolation domain (the main actor).
- **Store**: long-lived reference-type state container, mutated synchronously through a writable key path, non-`Sendable` by construction.
- **Proxy**: immutable snapshot handed to middleware; the only channel middleware uses to influence state (via re-dispatch).
- **Action / AsyncAction component**: a `Reducer` or `Middleware` step; components run in declaration order within an action.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A SwiftUI-style `@MainActor @Observable @Store` that dispatches both a sync `Action` and an `await`-ed `AsyncAction` builds with zero concurrency diagnostics under `swift build -Xswiftc -warnings-as-errors`. (Today: fails to compile.)
- **SC-002**: 100% of the existing 6 tests pass unchanged (annotations aside), and the 2 new tests pass — total 8/8.
- **SC-003**: A grep of `Sources/OnwardCore` for `Sendable`, `@Sendable`, `@unchecked`, `nonisolated`, `@preconcurrency` returns zero matches.
- **SC-004**: `swift build` of the root package and `swift build` of the `Examples/` package both succeed against the isolated core.
- **SC-005**: A consumer whose `@Store` / `@Interactor` class omits `@MainActor` sees a diagnostic that names the missing isolation, not an unattributed error inside macro-generated code.
- **SC-006**: Observable behavior is unchanged: in a scripted scenario, a middleware re-dispatch and a suspended async middleware both produce identical final state and ordering before and after the change.

## Assumptions

- The primary and effectively only supported consumer pattern is a main-actor-isolated store (SwiftUI `@Observable` UI state); developers wanting off-main state are out of scope and will be told so.
- `swift-syntax` remains a build-time-only dependency of the macro target; the isolation change does not add runtime dependencies.
- Supported platforms and the Swift 6.0 tools version are unchanged; lowering a minimum is explicitly a breaking change and not part of this work.
- The package version bump (this is a breaking public API change — removing `Sendable`, adding `@MainActor`) is handled by the normal release process; this spec does not prescribe the number beyond "MAJOR bump, called out in the PR".
- The macro diagnostic for a non-`@MainActor` class is desirable but MAY be deferred if it proves costly; the documentation requirement (FR-009) is not deferrable.
