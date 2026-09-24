## Swift 6 MainActor pipeline isolation

Isolates the whole dispatch pipeline (`Store`, `Interactor`, `Action`, `AsyncAction`, reducers, queues, builders, middleware) to `@MainActor`. A `@MainActor @Observable @Store` class now dispatches sync and async actions with zero concurrency diagnostics under `-warnings-as-errors`.

### Breaking change: MAJOR version bump
- `Sendable` removed from `Action` / `AsyncAction`; stored closures are `@MainActor`, never `@Sendable`.
- `@Store` / `@Interactor` classes must be `@MainActor`. Missing it emits `missingMainActor`.
- Non-`@MainActor` callers of async `dispatch` need `Sendable` arguments at their call site.

### Macros
- Generated `Proxy` is `@MainActor`.
- New `missingMainActor` diagnostic naming the class. Known limitation: a global-actor typealias resolving to `MainActor` is not detected.

### Principle impact
- Constitution V (macro parity): macro output satisfies the isolated protocols with no consumer annotations; covered by new macro-expansion tests.
- Architecture concurrency constraint: `Sources/OnwardCore` has no `Sendable`, `@Sendable`, `@unchecked`, `nonisolated`, `@preconcurrency`.

### Tests
8 `OnwardTests` (6 existing + sync-no-suspension + async-middleware ordering) and 7 macro-expansion tests.

### Notes
- `Examples/Todos` got `@MainActor` on its Store/Interactor classes; not built in Xcode here.
- `Examples/Package.swift` has a pre-existing malformed tools-version header, so `swift build --package-path Examples` fails independent of this change.
