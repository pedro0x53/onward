---
name: dependency-injection
description: Register and resolve dependencies in Onward via @Inward/@Outward and OnwardContainer, built on the Volt package. Use when asked to add a dependency, inject a service into an Interactor, register something in the container, or override a dependency for tests.
---

# Dependency Injection (Onward / Volt)

Onward's DI is a thin, app-scoped skin over the [Volt](https://github.com/pedro0x53/volt.git) package's generic container primitives (`Charger`/`Charge`/`Discharge`). If something here doesn't cover your case — custom containers, the raw `Charger`/`Discharge` API, thread-safety internals — read Volt's source directly; it's small (5 files under `Sources/Volt`).

## Core types (read-only, don't reinvent)

- `OnwardContainer` — `Sources/OnwardCore/Container/OnwardContainer.swift` — the single app-level container: `@Charger public final class OnwardContainer {}`.
- `@Inward` — macro alias for Volt's `@Charge`, used to **register** a dependency on `OnwardContainer`.
- `Outward<Value>` — typealias for Volt's `Discharge<OnwardContainer, Value>`, used to **resolve** a dependency wherever it's needed.
- Volt internals backing all of this: `Charger()` macro, `ChargerSchema` protocol, `Charge()` macro, `Discharge` property wrapper, `BatteryCell` — all in the Volt package, not vendored into Onward.

## Registering a dependency — `@Inward`

Extend `OnwardContainer` and annotate a stored `var` with `@Inward`. Both an explicit type annotation and a default value are required (that's a Volt `@Charge` requirement, not optional sugar):

```swift
extension OnwardContainer {
    @Inward var apiClient: APIClient = DefaultAPIClient()
    @Inward var analyticsService: Analytics = FirebaseAnalytics()
}
```

The default value is what gets returned until something overrides it — there's no "unregistered dependency" crash path, just the default.

## Resolving a dependency — `@Outward`

Use `@Outward(\.keyPath)` wherever the dependency is needed — typically as a stored property on an `Interactor` (see `create-interactor`):

```swift
@Interactor
final class TodoInteractor {
    @Outward(\.apiClient) var apiClient
    @Outward(\.analyticsService) var analytics
}
```

`Outward` reads from `OnwardContainer` **on every access**, not once at init — so a mid-session override (see below) is picked up immediately by anything holding an `@Outward` property, no re-injection needed. This is also why an `Interactor`'s zero-arg `build()` works fine with injected dependencies (see `create-interactor`'s "no init collision" gotcha) — dependencies never flow through the initializer.

Because `Outward<Value> = Discharge<OnwardContainer, Value>` carries a convenience init bound to `OnwardContainer`, you write `@Outward(\.apiClient)` directly. Raw Volt usage with a custom container needs the type spelled out: `@Discharge(AppContainer.self, \.apiClient)`.

## Overriding for tests — the container is a static namespace, not a singleton instance

`ChargerSchema` requires `init()`, but don't be misled by that into thinking `OnwardContainer` has instance state you mutate through a shared instance. Each `@Inward`/`@Charge` dependency is backed by a private `BatteryCell` whose storage is a `static var`, and all reads/writes go through **static** subscript/methods on the container type — `Self()` in Volt's implementation is a throwaway handle used only to satisfy the subscript's `self` requirement, not a stored singleton. Concretely, override and inspect like this:

```swift
// Override (e.g. in test setUp)
OnwardContainer.charge(\.apiClient, MockAPIClient())

// Inspect the current value
let client = OnwardContainer.discharge(\.apiClient)
```

**Don't use `OnwardContainer.shared.apiClient = MockAPIClient()`** — despite appearing in this repo's doc comments (`OnwardContainer.swift`), no `.shared` static property exists anywhere in Onward or Volt. It won't compile. Reach for `OnwardContainer.charge(_:_:)` instead — it's the real, static, thread-safe (barrier-protected) override mechanism `ChargerSchema` provides.

## Checklist before finishing

1. New dependency: `@Inward var name: ConcreteOrProtocolType = defaultInstance` on an `OnwardContainer` extension — both type annotation and default value present.
2. Consuming it: `@Outward(\.name)` as a stored property, typically on an `Interactor`.
3. Test overrides use `OnwardContainer.charge(\.name, mockValue)`, never a `.shared` accessor.
4. For anything beyond registering/resolving/overriding on `OnwardContainer` — custom containers, subscript internals, thread-safety guarantees — check the [Volt repository](https://github.com/pedro0x53/volt.git) rather than guessing from Onward's usage alone.
