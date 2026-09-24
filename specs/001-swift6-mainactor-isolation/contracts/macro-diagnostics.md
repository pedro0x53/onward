# Contract: Macro `@MainActor` Requirement & Diagnostic

Covers FR-007, FR-008, SC-005, Constitution V.

## Generated-code contract

| Macro | Generated code must … |
|-------|-----------------------|
| `@Store(I.self)` | Produce `extension X: Store`, `var proxy`, **`@MainActor struct Proxy`**, mutator `Action` vars, and `let interactor: I = I.build()` — all compiling with no concurrency diagnostics when `X` is `@MainActor`. |
| `@Interactor` | Produce `private init`, `static func build() -> Self`, `extension X: Interactor` — compiling when `X` is `@MainActor`. |
| `@Reducer(S.self, …)` | Produce a computed `var …Reducer: [Async]Reducer<S>` whose closure calls the peer method — compiles unchanged (interactor is `@MainActor`). |
| `@Middleware(S.self)` | Produce a computed `var …Middleware: [Async]Middleware<S>` — compiles unchanged. |
| `@Action(reducers:…, middlewares:…)` | Produce the `get` accessor building `[Async]Action { … }` — compiles unchanged. |

Only **one** new emission is required: `@MainActor` on the generated `Proxy` struct
(nested types do not inherit the enclosing extension's isolation).

The consumer must NOT have to add isolation annotations that the macro is responsible for
(FR-007). The consumer IS responsible for putting `@MainActor` on their own `@Store` /
`@Interactor` class (FR-008).

## Diagnostic contract

**Trigger**: `@Store` or `@Interactor` attached to a class whose attribute list contains
no `MainActor` attribute.

**Behavior**: emit a `DiagnosticSeverity.error` via `context.diagnose`, using a new case:

```
OnwardMacroError.missingMainActor
```

**Message** (SC-005 — must name the missing isolation, not surface an opaque
generated-code error):

- `@Store`: `"@Store requires '<ClassName>' to be @MainActor. Add '@MainActor' to the class declaration."`
- `@Interactor`: `"@Interactor requires '<ClassName>' to be @MainActor. Add '@MainActor' to the class declaration."`

(A single shared message referencing "@Store/@Interactor" is acceptable.)

**Emission policy**: emit the diagnostic AND still expand the members/extension, so the
developer sees exactly one attributed pointer at the attribute site plus normal
conformance errors — never *only* an unattributed error buried in generated code.

**Known limitation** (documented, acceptable): a custom global-actor typealias that
resolves to `MainActor` is not detected — only a literal `@MainActor` (and legacy
`@MainActor(unsafe)`) attribute. Documented in `OnwardGenerators.docc`.

**Deferral**: per spec Assumptions, the diagnostic MAY be deferred if it proves costly;
the `@MainActor` *requirement* and the documentation (FR-009) are NOT deferrable. If
deferred, `@Store` / `@Interactor` on a non-`@MainActor` class still fails to
compile — just with the raw Swift conformance error.

## Verification

- Macro-expansion test: `@Store` expansion contains `@MainActor` on `struct Proxy`.
- Macro-expansion test: `@Interactor`, `@Reducer`, `@Middleware`, `@Action` (sync +
  async) expansions compile against the isolated core.
- Macro-expansion test: `@Store` / `@Interactor` on a class with no `@MainActor` emits
  `missingMainActor` at the attribute location.
- Sample build: `@MainActor @Observable @Store(I.self) final class` + `@MainActor
  @Interactor final class` → 0 concurrency diagnostics.
