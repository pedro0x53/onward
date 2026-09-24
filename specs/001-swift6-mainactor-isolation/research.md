# Phase 0 Research: Swift 6 MainActor Pipeline Isolation

The spec is highly detailed and carries no open `NEEDS CLARIFICATION`. Research here
resolves the *how* — the mechanism of isolation propagation, the compiler-bug risk, and
the macro strategy — so Phase 1 can define concrete contracts.

## R1 — How `@MainActor` propagates through the pipeline

**Decision**: Annotate every public pipeline type with `@MainActor` directly:
- Protocols: `Store`, `Interactor`, `ActionComponentSchema`, `AsyncActionComponentSchema`.
- Value types: `Action`, `AsyncAction`, `Reducer`, `AsyncReducer`, `Middleware`,
  `AsyncMiddleware`, `ReducerQueue`, `AsyncReducerQueue`, `ActionComponent`,
  `AsyncActionComponent`.
- Result-builder enums: `ActionBuilder`, `AsyncActionBuilder`, `ReducerBuilder`,
  `AsyncReducerBuilder` (so `buildBlock` et al. are main-actor-isolated).
- The `public extension Store` block carrying the `dispatch(...)` overloads — annotate
  the extension `@MainActor` explicitly rather than trust propagation from the protocol.

**Rationale**: A `@MainActor` protocol makes every witness main-actor-isolated in the
conformer, which is exactly what forces (and permits) a `@MainActor` store to be passed
into the pipeline without a `Sendable` crossing. Annotating the concrete types too keeps
stored `@MainActor` closures storable and keeps the isolation obvious at the declaration
site (no "why does this compile" puzzles). It also satisfies FR-002's enumeration
literally.

**Alternatives considered**:
- *Global-actor inference only from the protocol*: fragile across extensions and nested
  types (`Proxy`), and produces confusing diagnostics. Rejected.
- *A custom global actor*: pointless indirection; the consumer target is literally the
  main actor (SwiftUI `@Observable`). Rejected — also contradicts the "only supported
  pattern is main-actor" assumption.
- *`isolated` parameters on `dispatch`*: doesn't cover stored closures or protocol
  witnesses; more surface area, same result. Rejected.

## R2 — Sync dispatch stays synchronous (FR-005 / SC-006)

**Decision**: Keep `Action.dispatch` and `ActionComponentSchema.run` non-`async`. With
both caller and callee `@MainActor`, a `@MainActor` caller invokes them with no `await`
and no suspension point; all reducer mutations complete before control returns.

**Rationale**: Isolation to an actor does not insert suspension points for calls that
are *already* on that actor. Only cross-actor calls do. A `@MainActor`→`@MainActor` call
is a plain synchronous call.

**Verification plan**: FR-010(a) test — an explicit `@MainActor func` dispatches a sync
`Action` and asserts the mutated value on the very next line.

## R3 — Async ordering + re-entrant `proxy.dispatch` (FR-006 / SC-006)

**Decision**: Leave the `for component in components(...) { await component.run(store) }`
loop as-is. Sequential `await` on a single actor preserves declaration order including
when a component suspends. `proxy.dispatch(\.someMutator, ...)` called synchronously
from inside a `Middleware` / `AsyncMiddleware` body is a `@MainActor`→`@MainActor`
synchronous call from code already on the main actor — reentrant, no `await`, no
deadlock — so the re-dispatched mutation lands before the parent action's trailing
components.

**Rationale**: Actor reentrancy for synchronous same-actor calls is not a deadlock
condition; there is no lock, and no executor hop. The existing tests
`dispatchActionWithMiddleware` / `dispatchAsyncActionWithMiddleware` already exercise
this and must keep passing unchanged.

**Verification plan**: existing middleware tests unchanged + FR-010(b) new test:
`AsyncMiddleware` does `await Task.yield()` before a trailing `AsyncReducer`; assert
final state reflects both, in order.

## R4 — Remove `Sendable` / `@Sendable` from `Action` / `AsyncAction` (FR-004 / FR-011)

**Decision**: Delete `: Sendable` from the `Action` and `AsyncAction` struct
declarations; change the stored `components` property and the `init` parameter from
`@Sendable (repeat each Argument) -> [...]` to `@MainActor (repeat each Argument) -> [...]`
(no `@Sendable`). Same treatment for `Reducer` / `AsyncReducer` `work` closures and
`Middleware` / `AsyncMiddleware` `perform` closures — `@MainActor @escaping`, never
`@Sendable`.

**Rationale**: Under whole-pipeline main-actor isolation the `Sendable` conformance is
unreachable (values never cross an isolation boundary) and is a false guarantee today
(the `@Sendable` closure can't actually capture the non-`Sendable` services users need).
Removing it lets user closures capture network clients, formatters, etc. freely (FR-003,
Acceptance Scenario 1.3).

**Grep gate**: `Sources/OnwardCore` currently has these tokens only in `Action.swift`
and `AsyncAction.swift`. After the change: zero matches for
`Sendable|@Sendable|@unchecked|nonisolated|@preconcurrency` (SC-003). `@MainActor` is
permitted and expected.

## R5 — Parameter-pack + `@MainActor` closure compiler-bug risk (FR-012)

**Finding**: On the local toolchain (Swift 6.3.1) a minimal reproduction —
`struct Foo<each Argument> { let c: @MainActor (repeat each Argument) -> [Int] }` with a
`@MainActor` call site — type-checks cleanly. The known bugs were in the Swift 6.0.x
line, which CI on the pinned tools version could still hit.

**Decision**: Follow FR-012 literally. Step 1 of implementation applies `@MainActor`
**only** to the three `Reducer` initializers (no parameter pack in the closure *type* —
the pack is in the generic signature, the stored closure is `(S) -> Void`) and proves it
with `swift build`. Then widen to the pack-carrying closures (`Action` /
`AsyncAction.init` parameter typed `(repeat each Argument) -> [...]`).

**Documented fallback**: if a target toolchain rejects `@MainActor` on a
`(repeat each Argument) -> ...` parameter, isolate the enclosing struct (`@MainActor
struct Action`) and leave that one closure parameter bare (`@escaping (repeat each
Argument) -> [ActionComponent<S>]`, no `@MainActor`). Struct-level isolation still makes
the stored property and `dispatch` main-actor-isolated; the builder closure is then
called from within an already-isolated method, so user code sees identical behavior.
Record the choice in the PR and in `README` if the fallback is taken.

## R6 — Macro-generated code under the isolated pipeline (FR-007)

**`@Store`** (`StoreMacro`, ExtensionMacro + MemberMacro):
- Generates `extension X: Store { var proxy … ; struct Proxy { … } }` and a mutator
  extension. `Store` being `@MainActor` means the conformance requires `X` to be
  main-actor-isolated.
- **Nested `Proxy` struct does not inherit the extension's isolation.** The generated
  `Proxy` has `dispatch(...)` methods that call `@MainActor` store methods, so `Proxy`
  must be emitted as `@MainActor struct Proxy`.
- Generated mutator vars return `Action<X, T>` (now `@MainActor`); they live in an
  extension of the `@MainActor` class, so they are fine, but emit them inside a
  `@MainActor`-safe context (extension of the isolated type is sufficient; no extra
  annotation needed).
- The `let interactor: I = I.build()` member runs in the class's stored-property
  initialization — `X` is `@MainActor`, `build()` is `@MainActor` (see below) → OK.

**`@Interactor`** (`InteractorMacro`): generates `private init() {}`,
`static func build() -> Self`, and `extension X: Interactor`. `Interactor` being
`@MainActor` makes `build()` a `@MainActor static` requirement; the generated body
`Self()` is fine. Requires `X` to be `@MainActor`.

**`@Reducer` / `@Middleware`** (`ReducerMacro`, `MiddlewareMacro`, PeerMacro): generate a
computed `var …Reducer: Reducer<S> { Reducer(...) { … self.foo() … } }` on the interactor.
The interactor is `@MainActor`; `Reducer` / `Middleware` are `@MainActor`; the closure is
`@MainActor`. Calling the peer method (also `@MainActor`) from inside is a plain call.
No macro change needed beyond confirming expansion compiles.

**`@Action`** (`ActionFactory`): generates `get { Action { self.xReducer; self.yMiddleware } }`.
Accessor on an interactor/store property; the enclosing type is `@MainActor`; builder
closure `@MainActor`. No change needed beyond expansion tests.

**Decision**: The only *generated-code* change required is emitting `@MainActor` on the
generated `Proxy` struct in `StoreMacro`. Everything else compiles once the annotated
class is `@MainActor` and the core protocols carry isolation. Add macro-expansion tests
(new small test target) covering `@Store` (incl. `Proxy`), `@Interactor`, `@Reducer`,
`@Middleware`, `@Action` sync + async.

**Alternatives considered**: emitting `@MainActor` on every generated member — noisy and
redundant once the class is isolated; only `Proxy` (a nested type) actually needs it.

## R7 — Macro `@MainActor` requirement + diagnostic (FR-008 / SC-005)

**Decision**: In `StoreMacro` and `InteractorMacro`, inspect the attached
`declaration.attributes` for an `AttributeSyntax` whose name is `MainActor`. If absent,
`context.diagnose` a new `OnwardMacroError.missingMainActor` with message roughly:
`"@Store requires the class to be @MainActor. Add '@MainActor' to 'X'."` (analogous text
for `@Interactor`). Still emit the members/extension so the cascade of secondary errors
is minimized, or return early — decision: emit the diagnostic and continue emitting, so
the developer sees one clear pointer plus normal conformance errors, never *only* an
opaque error buried in generated code.

**Rationale**: FR-008 SHOULD-level; assumptions allow deferral if costly, but a simple
attribute-name check is cheap. Cannot fully resolve a custom global-actor typealias that
resolves to `MainActor` — acceptable; document the limitation. The literal
`@MainActor` (and `@MainActor(unsafe)` legacy) covers the documented pattern.

**Alternatives considered**: relying on the raw Swift conformance error — fails SC-005
("not an unattributed error inside macro-generated code"). Rejected.

## R8 — Test target isolation (FR-010 / SC-002)

**Decision**: Add `@MainActor` to the test file's `ToDoInteractor`, the `ToDo` `@Store`
class, and the `OnwardTests` `@Suite` struct. `@Test` methods are already `async`;
suite-level `@MainActor` isolates all six test bodies with no body edits. Then add:
- `dispatchActionSynchronouslyFromMainActor()` — explicit `@MainActor` free function
  dispatches a sync `Action`, asserts the value immediately (FR-010a).
- `asyncMiddlewareSuspendsBeforeTrailingReducer()` — `AsyncAction` with an
  `AsyncMiddleware { _ in await Task.yield() ; proxy.dispatch(...) }` then a trailing
  `AsyncReducer`; assert ordered final state (FR-010b).

**Rationale**: FR-010 permits *only* isolation annotations on the test interactor,
store, and suite — no test-body edits — plus the two additions.

## R9 — `Examples/` build (FR-013 / SC-004)

**Finding**: `Examples/Package.swift` is a bare stub (`products: []`, no targets, no
dependency on the root package). `swift build --package-path Examples` is a successful
no-op. The real sample is an Xcode project, `Examples/Todos/`, not driven by
`swift build`.

**Decision**: Treat SC-004's "`swift build` of the `Examples/` package" as satisfied by
the stub building green. Separately, for `Examples/Todos` apply the minimum `@MainActor`
the isolated core forces on `MyStore` / `MyInteractor` (the edge-case note allows exactly
this — "not otherwise in scope for edits beyond what the isolation forces") and confirm
it compiles in Xcode. If the Todos target cannot be built in the CI environment, note it
in the PR; the SPM `Examples` package remains the SC-004 gate.

**Open item for Phase 2**: consider wiring `Examples/Package.swift` to actually depend on
the root package and build the Todos sources as a target, so `swift build` covers it for
real. Out of scope for this feature unless trivial.

## R10 — Docs (FR-009, non-deferrable)

**Decision**: Update in the same PR:
- `README.md` — state that `@Store` / `@Interactor` classes must be `@MainActor`; show it
  in the quick-start snippet; add a note that a non-`@MainActor` caller of an async
  dispatch takes on a `Sendable` requirement for the passed arguments at its call site.
- `Sources/OnwardCore/OnwardCore.docc/OnwardCore.md` — same isolation note for the core
  types; mention `Sendable` removal from `Action` / `AsyncAction`.
- `Sources/OnwardGenerators/OnwardGenerators.docc/OnwardGenerators.md` — document the new
  `@MainActor` requirement and the `missingMainActor` diagnostic.

## Summary of decisions

| # | Decision |
|---|----------|
| R1 | `@MainActor` on all pipeline protocols, value types, result-builder enums, and the `Store` dispatch extension. |
| R2 | Sync `dispatch` / `run` stay non-`async`; no suspension for `@MainActor`→`@MainActor`. |
| R3 | Async loop unchanged; reentrant synchronous `proxy.dispatch` is safe on the main actor. |
| R4 | Remove `Sendable` / `@Sendable`; closures become `@MainActor @escaping`. |
| R5 | Start with `Reducer` initializers only, build, then widen; documented struct-isolation fallback for pack closures. |
| R6 | Only generated-code change: `@MainActor struct Proxy` in `StoreMacro`; add expansion tests. |
| R7 | New `OnwardMacroError.missingMainActor`; attribute-name check in `StoreMacro` / `InteractorMacro`. |
| R8 | Suite-level `@MainActor` on test types; add two new tests. |
| R9 | `Examples` SPM stub is the SC-004 gate; minimal `@MainActor` on Todos sample. |
| R10 | README + both `.docc` catalogs updated in the same PR. |
