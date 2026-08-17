---
name: create-interactor
description: Create a new Onward Interactor, or convert an existing class into one, via the @Interactor macro. Use when asked to add business logic namespace for a Store, create an Interactor, or macro-ify a plain class into an Interactor.
---

# Create Interactor (Onward)

An `Interactor` is the class-bound namespace that owns all business logic (actions, reducers, middleware) for one or more `Store`s. Stores stay plain state containers; interactors hold everything that can mutate them. This is the container piece — the actual logic inside it is built with `create-action`, `create-reducer`, and `create-middleware`.

## Core types (read-only, don't reinvent)

- `Interactor` protocol — `Sources/OnwardCore/Store/Interactor.swift` — `AnyObject`, one requirement: `static func build() -> Self`.
- `@Interactor` macro — `Sources/OnwardGenerators/InteractorMacro.swift` (decl), `Sources/OnwardGeneratorsMacros/Implementations/InteractorMacro.swift` (impl).
- Dependency injection into an interactor: `@Outward(\.someDependency)` reading from `OnwardContainer` — `Sources/OnwardCore/Container/OnwardContainer.swift`.
- Wiring point: `@Store(YourInteractor.self)` on the class(es) the interactor drives — see `Sources/OnwardGeneratorsMacros/Implementations/StoreMacro.swift`.

## What `@Interactor` actually generates

Apply `@Interactor` to a class. It's a member + extension macro that emits, unconditionally:

```swift
private init() {}                            // member — blocks external instantiation
public static func build() -> Self {         // member
    return Self()
}
extension YourClass: Interactor {}           // conformance only, no members
```

Both `init()` and `build()` land directly on the class as members; the extension just declares the `Interactor` conformance. Both expansions diagnose `notAClass` (matching `@Store`'s check) if applied to anything other than a `class` — a `struct`/`enum` is rejected up front rather than failing later on the `AnyObject` conformance requirement.

**Gotchas the macro does not guard against:**
- **No init collision check.** The macro always injects a bare `private init() {}`. If the class already declares *any* initializer, this is a duplicate-declaration compile error. Converting an existing class means removing its custom `init` first (see conversion steps below).
- **`build()` calls the zero-arg init unconditionally.** Every stored property must therefore have a default value, or be populated through `@Outward` (which resolves at property-access time from `OnwardContainer`, not through init). There is no way to pass constructor arguments to an interactor — dependencies always go through DI, not initialization.

## Path 1 — new Interactor

```swift
@Interactor
final class TodoInteractor {
    @Outward(\.httpClient) var httpClient
    @Outward(\.validator) var validator

    // actions/reducers/middlewares — see create-action / create-reducer / create-middleware
}
```

Then wire it to whichever `Store` type(s) it should drive:

```swift
@Observable
@Store(TodoInteractor.self)
final class ToDoStore {
    var todos: [ToDo] = []
}
```

A single interactor can back **multiple** store types — actions/reducers are generic over their own `Store`, so nothing stops one interactor class from hosting `Action<ToDoStore, ...>` properties alongside `Action<ToDo, ...>` properties in the same body (see `MyInteractor` in the `Todos` example, which drives both `ToDoStore` and `ToDo`).

## Path 2 — convert an existing class

1. **Remove any existing initializer(s).** The macro adds its own `init() {}` unconditionally — a pre-existing `init` (even a matching zero-arg one) causes a duplicate-declaration error. Replace constructor-set state with property default values.
2. **Make it a `final class`** if it isn't already (matches every convention in this codebase; not mechanically enforced by the macro, but required in spirit — an interactor is never subclassed or value-typed).
3. **Move any injected dependencies to `@Outward`.** If the class currently takes dependencies through its initializer, register them on `OnwardContainer` via `@Inward` (if not already registered) and replace the init parameters with `@Outward(\.dependency) var dependency` properties instead.
4. **Add `@Interactor`** above the class declaration.
5. **Convert the class's methods into actions/reducers/middlewares** as appropriate (`create-action`, `create-reducer`, `create-middleware`) — plain methods on an interactor aren't automatically dispatchable, they need to be wrapped as `Action`/`Reducer`/`Middleware` properties (inline or macro-generated) to participate in `store.dispatch(...)`.
6. **Point a `@Store(YourInteractor.self)`** at whichever store class(es) should use it, if not already wired.

## Checklist before finishing

1. Target is a `class` (ideally `final class`) — the macro diagnoses `struct`/`enum` targets directly, but prefer `final` to match repo convention.
2. No user-written initializer remains on the class — the macro's `init() {}` would collide.
3. Every stored property either has a default value or is `@Outward`-injected — `build()` constructs with zero arguments, always.
4. At least one `@Store(_:)` elsewhere in the codebase points at this interactor type, or it's dead code.
5. Business logic lives in `Action`/`AsyncAction` properties (inline or `@Action`-composed), not bare methods that nothing dispatches.
