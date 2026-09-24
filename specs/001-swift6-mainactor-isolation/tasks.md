# Tasks: Swift 6 MainActor Pipeline Isolation

**Input**: Design documents from `/specs/001-swift6-mainactor-isolation/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/public-api.md](./contracts/public-api.md), [contracts/macro-diagnostics.md](./contracts/macro-diagnostics.md), [quickstart.md](./quickstart.md)

**Tests**: Explicitly requested by the spec (FR-010, R8) — included per story.

**Organization**: Tasks are grouped by user story (US1/US2/US3 map to spec.md priorities P1/P1/P2).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1, US2, US3 — maps to spec.md user stories
- File paths are exact, repo-root-relative

---

## Phase 1: Setup

**Purpose**: Confirm the pre-change baseline before touching any source.

- [X] T001 Run `swift build -Xswiftc -warnings-as-errors` from repo root and confirm the documented failure (an `@MainActor` store `await`-dispatching an `AsyncAction` fails to compile because `Action`/`AsyncAction` are `Sendable`-constrained and the pipeline is `nonisolated`). No code changes — this is the "before" baseline for SC-001.

---

## Phase 2: Foundational (Blocking Prerequisite)

**Purpose**: FR-012's narrowest-possible-change checkpoint — apply `@MainActor` to the three `Reducer` initializers only (no parameter-pack closure yet), and prove it builds, before isolation is widened to the rest of the pipeline.

**⚠️ CRITICAL**: No further isolation work (Phase 3+) starts until this checkpoint is green.

- [X] T002 In `Sources/OnwardCore/Reducer/Sync/Reducer.swift`, add `@MainActor @escaping` to the `work` parameter of all three `Reducer` initializers only. Do not touch any other type yet (FR-012).
- [X] T003 Run `swift build` from repo root; confirm green. If the toolchain rejects `@MainActor` on a `(repeat each Argument) -> ...` closure parameter later in Phase 3, apply the documented fallback from [research.md](./research.md) R5 (isolate the enclosing struct, leave that one closure parameter bare) and note it in the PR.

**Checkpoint**: Narrowest isolation change proven. Widen to the rest of the pipeline in Phase 3.

---

## Phase 3: User Story 1 - Dispatch async actions from SwiftUI state without concurrency errors (Priority: P1) 🎯 MVP

**Goal**: A `@MainActor @Observable @Store` class can `store.dispatch(syncAction)` and `await store.dispatch(asyncAction)` against a non-`Sendable` store with zero concurrency diagnostics.

**Independent Test**: `swift build -Xswiftc -warnings-as-errors` on a `@MainActor @Observable @Store` sample dispatching a sync `Action` and an `await`-ed `AsyncAction` → 0 diagnostics.

### Implementation for User Story 1

- [X] T004 [P] [US1] In `Sources/OnwardCore/Action/Sync/Action.swift`: add `@MainActor` to `struct Action<S, each Argument>`; remove `: Sendable`; change the `components` stored property and `init` parameter from `@Sendable (repeat each Argument) -> [ActionComponent<S>]` to `@MainActor (repeat each Argument) -> [ActionComponent<S>]` (no `@Sendable`).
- [X] T005 [P] [US1] In `Sources/OnwardCore/Action/Sync/ActionComponentSchema.swift`: add `@MainActor` to `protocol ActionComponentSchema`; add `@MainActor` to `struct ActionComponent<S>` and its stored `_run: (S) -> Void`.
- [X] T006 [P] [US1] In `Sources/OnwardCore/Action/Sync/ActionBuilder.swift`: add `@MainActor` to `@resultBuilder enum ActionBuilder<S>`.
- [X] T007 [P] [US1] In `Sources/OnwardCore/Action/Async/AsyncAction.swift`: add `@MainActor` to `struct AsyncAction<S, each Argument>`; remove `: Sendable`; change the `components` stored property and `init` parameter from `@Sendable (repeat each Argument) -> [AsyncActionComponent<S>]` to `@MainActor (repeat each Argument) -> [AsyncActionComponent<S>]` (no `@Sendable`).
- [X] T008 [P] [US1] In `Sources/OnwardCore/Action/Async/AsyncActionComponent.swift`: add `@MainActor` to `protocol AsyncActionComponentSchema` (keep `func run(_:) async`); add `@MainActor` to `struct AsyncActionComponent<S>` and its stored `_run: (S) async -> Void`.
- [X] T009 [P] [US1] In `Sources/OnwardCore/Action/Async/AsyncActionBuilder.swift`: add `@MainActor` to `@resultBuilder enum AsyncActionBuilder<S>`.
- [X] T010 [US1] In `Sources/OnwardCore/Reducer/Sync/Reducer.swift` (builds on T002/T003): add `@MainActor` to `struct Reducer<S>` itself; the remaining `work` closure(s) `@MainActor @escaping`; stored `_reduce: (S) -> Void`. Keep `extension Reducer: ActionComponentSchema, AsyncActionComponentSchema` (`run(_:)` sync) compiling under the now-`@MainActor` protocols.
- [X] T011 [P] [US1] In `Sources/OnwardCore/Reducer/Sync/ReducerQueue.swift`: add `@MainActor` to `struct ReducerQueue<S>`, including `mutating func append`. Keep `extension ReducerQueue: ActionComponentSchema` compiling.
- [X] T012 [P] [US1] In `Sources/OnwardCore/Reducer/Sync/ReducerBuilder.swift`: add `@MainActor` to `@resultBuilder enum ReducerBuilder<S>`.
- [X] T013 [US1] In `Sources/OnwardCore/Reducer/Async/AsyncReducer.swift`: add `@MainActor` to `struct AsyncReducer<S>`; all 3 inits' `work` params `@MainActor @escaping ... async`; stored `_reduce: (S) async -> Void`. Keep `extension AsyncReducer: AsyncActionComponentSchema` (`run(_:) async`) compiling.
- [X] T014 [P] [US1] In `Sources/OnwardCore/Reducer/Async/AsyncReducerQueue.swift`: add `@MainActor` to `struct AsyncReducerQueue<S>`. Keep `extension AsyncReducerQueue: AsyncActionComponentSchema` compiling.
- [X] T015 [P] [US1] In `Sources/OnwardCore/Reducer/Async/AsyncReducerBuilder.swift`: add `@MainActor` to `@resultBuilder enum AsyncReducerBuilder<S>`.
- [X] T016 [P] [US1] In `Sources/OnwardCore/Middleware/Middleware.swift`: add `@MainActor` to `struct Middleware<S>`; `init` `perform` param `@MainActor @escaping (S.Proxy) -> Void` (no `@Sendable`). Keep `extension Middleware: ActionComponentSchema, AsyncActionComponentSchema` compiling.
- [X] T017 [P] [US1] In `Sources/OnwardCore/Middleware/AsyncMiddleware.swift`: add `@MainActor` to `struct AsyncMiddleware<S>`; `init` `perform` param `@MainActor @escaping (S.Proxy) async -> Void` (no `@Sendable`). Keep `extension AsyncMiddleware: AsyncActionComponentSchema` compiling.
- [X] T018 [US1] In `Sources/OnwardCore/Store/Store.swift`: add `@MainActor` to `protocol Store`; add `@MainActor` explicitly to the `public extension Store` block carrying the `dispatch(...)` overloads (do not rely on propagation).
- [X] T019 [P] [US1] In `Sources/OnwardCore/Store/Interactor.swift`: add `@MainActor` to `protocol Interactor`, including its `static func build() -> Self` requirement.
- [X] T020 [US1] Run `grep -REn 'Sendable|@Sendable|@unchecked|nonisolated|@preconcurrency' Sources/OnwardCore`; confirm zero matches (FR-011, SC-003). Depends on T004-T019.
- [X] T021 [US1] Run `swift build -Xswiftc -warnings-as-errors` from repo root; confirm `Build complete!` with zero concurrency diagnostics (SC-001). Depends on T004-T020.
- [X] T022 [US1] In `Tests/OnwardTests/OnwardTests.swift`: add `@MainActor` to `ToDoInteractor`, the `ToDo` `@Store` class, and `struct OnwardTests` (the `@Suite`) — annotations only, no test-body edits (FR-010 constraint, R8). Depends on T004-T021.
- [X] T023 [US1] Run `swift test` from repo root; confirm the existing 6 tests pass unchanged. Depends on T022.

**Checkpoint**: A `@MainActor @Observable @Store` builds and dispatches sync + async actions with zero diagnostics; existing test suite is green under isolation. User Story 1 is independently functional.

---

## Phase 4: User Story 2 - Preserved execution semantics after isolation (Priority: P1)

**Goal**: Isolation introduces no suspension point on sync dispatch, and preserves async component order including a suspending middleware and re-entrant `proxy.dispatch` visibility before trailing components.

**Independent Test**: Existing 6 tests pass unchanged, plus a new ordering test where an `AsyncMiddleware` does `await Task.yield()` before a trailing `AsyncReducer`; final state reflects both in order.

### Implementation for User Story 2

- [X] T024 [US2] In `Tests/OnwardTests/OnwardTests.swift`, add `dispatchActionSynchronouslyFromMainActor()`: an explicit `@MainActor` function dispatches a synchronous `Action` and asserts the mutated value on the very next line, proving no suspension point is introduced (FR-005, FR-010a, contract B1). Depends on T023.
- [X] T025 [US2] In `Tests/OnwardTests/OnwardTests.swift`, add `asyncMiddlewareSuspendsBeforeTrailingReducer()`: an `AsyncAction` whose `AsyncMiddleware` does `await Task.yield()` then `proxy.dispatch(...)`, followed by a trailing `AsyncReducer`; assert the final state reflects the middleware's effect and the reducer ran after it, in order (FR-006, FR-010b, contracts B3/B4). Depends on T024 (same file).
- [X] T026 [US2] Run `swift test` from repo root; confirm all 8 tests pass (6 existing + 2 new) (SC-002, SC-006). Depends on T025.

**Checkpoint**: User Stories 1 and 2 both work; ordering and re-entrancy guarantees are proven by tests, not just asserted in docs.

---

## Phase 5: User Story 3 - Macro output compiles under the isolated pipeline (Priority: P2)

**Goal**: `@Store`, `@Interactor`, `@Reducer`, `@Middleware`, `@Action`-generated code satisfies the now-`@MainActor` protocol requirements with no developer-added annotations, and a non-`@MainActor` class gets an actionable diagnostic.

**Independent Test**: Macro expansion tests + a sample `@MainActor @Store` / `@Interactor` pair build with no concurrency diagnostics; a negative sample without `@MainActor` emits `missingMainActor`.

### Implementation for User Story 3

- [X] T027 [US3] In `Sources/OnwardGeneratorsMacros/Utils/OnwardMacroErrors.swift`: add `OnwardMacroError.missingMainActor` case with message `"@Store/@Interactor requires '<ClassName>' to be @MainActor. Add '@MainActor' to the class declaration."` (contracts/macro-diagnostics.md).
- [X] T028 [US3] In `Sources/OnwardGeneratorsMacros/Implementations/StoreMacro.swift`: emit `@MainActor struct Proxy` for the generated nested `Proxy` type (nested types do not inherit the enclosing extension's isolation). Depends on T027.
- [X] T029 [US3] In `Sources/OnwardGeneratorsMacros/Implementations/StoreMacro.swift`: inspect the attached class's `declaration.attributes` for a `MainActor` (or legacy `MainActor(unsafe)`) attribute; if absent, `context.diagnose` `.missingMainActor` naming the class, and still emit the members/extension (do not fail early). Depends on T028 (same file).
- [X] T030 [P] [US3] In `Sources/OnwardGeneratorsMacros/Implementations/InteractorMacro.swift`: same `@MainActor`/`MainActor(unsafe)` attribute check; if absent, `context.diagnose` `.missingMainActor` naming the class, and still emit members. Depends on T027.
- [X] T031 [US3] Add a macro-expansion test target: wire it into `Package.swift` (new test target depending on `OnwardGeneratorsMacros` + `SwiftSyntaxMacrosTestSupport`, per plan.md's `Tests/ (new) macro-expansion target`). Depends on T029, T030.
- [X] T032 [P] [US3] Add macro-expansion test (new file under the target from T031) asserting the `@Store` expansion contains `@MainActor` on `struct Proxy`. Depends on T031.
- [X] T033 [P] [US3] Add macro-expansion test (separate new file) asserting `@Interactor`, `@Reducer`, `@Middleware`, and `@Action` (sync and async) expansions compile against the isolated core with no developer-added annotations beyond `@MainActor` on the class. Depends on T031.
- [X] T034 [P] [US3] Add macro-expansion test (separate new file) asserting `@Store` and `@Interactor` applied to a class with no `@MainActor` each emit `missingMainActor` at the attribute location. Depends on T031.
- [X] T035 [US3] Add a sample build in the macro-expansion test target: `@MainActor @Observable @Store(I.self) final class` + `@MainActor @Interactor final class`; confirm 0 concurrency diagnostics (contracts/macro-diagnostics.md verification). Depends on T032-T034.
- [X] T036 [US3] Run `swift test` (full suite including the new macro-expansion target); confirm all macro-expansion tests pass. Depends on T035.

**Checkpoint**: Macro-generated code satisfies the isolated protocols at parity with hand-written form (Constitution V); non-`@MainActor` consumers get an actionable diagnostic (SC-005).

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Docs, `Examples/`, and full quickstart validation — spans all stories.

- [X] T037 [P] Update `README.md`: state that `@Store` / `@Interactor` classes must be `@MainActor`; update the quick-start snippet accordingly; add a note that a non-`@MainActor` caller of an async dispatch takes on a `Sendable` requirement for the passed arguments at its own call site (FR-009).
- [X] T038 [P] Update `Sources/OnwardCore/OnwardCore.docc/OnwardCore.md`: add the `@MainActor` isolation note for core types; document that `Sendable` was removed from `Action` / `AsyncAction` (FR-009).
- [X] T039 [P] Update `Sources/OnwardGenerators/OnwardGenerators.docc/OnwardGenerators.md`: document the `@MainActor` requirement on `@Store` / `@Interactor` classes and the `missingMainActor` diagnostic, including the known limitation (a custom global-actor typealias resolving to `MainActor` is not detected) (FR-009).
- [ ] T040 [P] Run `swift build --package-path Examples`; confirm success (SC-004; the stub package building green satisfies this per research.md R9).
- [X] T041 [P] In `Examples/Todos`, apply the minimum `@MainActor` the isolated core forces on the sample `Store` / `Interactor` classes; confirm it compiles in Xcode. If it cannot be built in the CI environment, note that explicitly in the PR (edge case: `Examples/` source not otherwise in scope).
- [X] T042 Run the full [quickstart.md](./quickstart.md) validation (steps 1-4, 6): `swift build -Xswiftc -warnings-as-errors`, `swift test` (8/8), the grep gate, and `swift build --package-path Examples`; confirm all green. Depends on T021, T026, T036, T040.
- [X] T043 Write the PR description calling out the MAJOR version bump (breaking public API change — `Sendable` removed, `@MainActor` added) and the principle impact (Constitution V macro parity, Architecture concurrency constraint), per plan.md's constraints and the release-process assumption. Depends on T042.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup. BLOCKS all of Phase 3 (FR-012 checkpoint).
- **User Story 1 (Phase 3)**: Depends on Foundational. BLOCKS User Story 2 (tests build on the annotated test file from T022/T023) and User Story 3 (macros generate code against the now-isolated core protocols).
- **User Story 2 (Phase 4)**: Depends on User Story 1 (extends the same test file after it compiles under isolation).
- **User Story 3 (Phase 5)**: Depends on User Story 1 (isolated core protocols). Independent of User Story 2 — could run in parallel with Phase 4 if staffed separately.
- **Polish (Phase 6)**: Depends on User Stories 1-3 being complete (T042/T043 gate on all prior build/test checkpoints).

### Within Each Phase

- Phase 3: T004-T019 are per-file isolation edits (parallel where files differ); T020-T023 are sequential verification gates.
- Phase 4: T024-T025 edit the same test file sequentially; T026 verifies.
- Phase 5: T027 (new diagnostic case) before T028-T030 (macros that reference it); T031 (new test target) before T032-T035 (tests within it); T036 verifies.

### Parallel Opportunities

- Phase 3: T004, T005, T006, T007, T008, T009, T011, T012, T014, T015, T016, T017, T019 can all run in parallel (13 independent files). T010, T013, T018 touch files with a same-file predecessor or extra care (T010 continues T002/T003; T018 needs both protocol + extension in one pass) and are best done solo per file, still independent of the other parallel files.
- Phase 5: T030 can run in parallel with T028/T029 (different file). T032, T033, T034 can run in parallel once T031 lands (three separate new test files).
- Phase 6: T037, T038, T039, T040, T041 can all run in parallel (five independent files/commands).

---

## Parallel Example: User Story 1

```bash
# Launch the independent isolation edits together:
Task: "Add @MainActor to Action in Sources/OnwardCore/Action/Sync/Action.swift"
Task: "Add @MainActor to ActionComponentSchema/ActionComponent in Sources/OnwardCore/Action/Sync/ActionComponentSchema.swift"
Task: "Add @MainActor to ActionBuilder in Sources/OnwardCore/Action/Sync/ActionBuilder.swift"
Task: "Add @MainActor to AsyncAction in Sources/OnwardCore/Action/Async/AsyncAction.swift"
Task: "Add @MainActor to AsyncActionComponentSchema/AsyncActionComponent in Sources/OnwardCore/Action/Async/AsyncActionComponent.swift"
Task: "Add @MainActor to Middleware in Sources/OnwardCore/Middleware/Middleware.swift"
Task: "Add @MainActor to AsyncMiddleware in Sources/OnwardCore/Middleware/AsyncMiddleware.swift"
Task: "Add @MainActor to Interactor in Sources/OnwardCore/Store/Interactor.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (baseline confirmation).
2. Complete Phase 2: Foundational (FR-012 checkpoint — CRITICAL, blocks everything else).
3. Complete Phase 3: User Story 1.
4. **STOP and VALIDATE**: T020-T023 all green → SC-001 met, existing suite green under isolation.

### Incremental Delivery

1. Setup + Foundational → foundation ready, checkpoint proven.
2. User Story 1 → validate independently → this alone fixes the blocking defect (MVP).
3. User Story 2 → validate independently → ordering/re-entrancy guarantees proven by test.
4. User Story 3 → validate independently → macro parity restored, diagnostic in place.
5. Polish → docs, Examples, full quickstart, PR description.

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (small, sequential, fast).
2. Once the Phase 2 checkpoint is green:
   - Developer A: User Story 1 (must land first — everything else depends on it).
3. Once User Story 1's checkpoint (T023) is green:
   - Developer A or B: User Story 2 (test file follow-on).
   - Developer C: User Story 3 (macro layer) in parallel.
4. Converge on Phase 6 once all three stories are checkpointed.

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks.
- [Story] label maps task to spec.md's US1/US2/US3 for traceability.
- FR-012's Foundational checkpoint (T002/T003) is the one hard gate before any other pipeline file is touched.
- No task in Phase 3-5 may reintroduce `Sendable`, `@Sendable`, `@unchecked`, `nonisolated`, or `@preconcurrency` into `Sources/OnwardCore` (T020 is the enforcement gate).
- Commit after each task or logical group; stop at any checkpoint to validate a story independently.
