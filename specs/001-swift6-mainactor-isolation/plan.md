# Implementation Plan: Swift 6 MainActor Pipeline Isolation

**Branch**: `001-swift6-mainactor-isolation` | **Date**: 2026-09-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-swift6-mainactor-isolation/spec.md`

## Summary

Isolate the entire Onward dispatch pipeline to the main actor so a `@MainActor`
`@Observable` store (the documented primary consumer) can dispatch synchronous and
asynchronous actions against a non-`Sendable` store with zero concurrency diagnostics
under complete checking. `Sendable` / `@Sendable` is removed from `Action` /
`AsyncAction`; stored closures (`work`, `perform`, action `components`) become
`@MainActor` and never `@Sendable`. No behavior change: sync dispatch still mutates
synchronously with no suspension point; async dispatch keeps component order and the
visibility of re-entrant `proxy.dispatch` mutations. Macros gain a `@MainActor`
requirement on the annotated class plus an actionable diagnostic. Implementation starts
from the narrowest isolation change (sync `Reducer` initializers) validated by a build,
then widens, with a documented fallback for the parameter-pack `@MainActor` closure
compiler-bug risk.

## Technical Context

**Language/Version**: Swift, package pinned to swift-tools-6.0 (complete concurrency
checking); local dev toolchain observed 6.3.1. Constitution fixes tools 6.0 — not
raised here.

**Primary Dependencies**: `Volt` (runtime DI, unchanged by this work);
`swift-syntax` 602.x (build-time only, macro target).

**Storage**: N/A (state lives in consumer `Store` reference types).

**Testing**: `swift-testing` (`import Testing`, `@Suite` / `@Test`). No XCTest.
No macro-expansion test target exists yet; US3 needs one added or a
compile-level sample equivalent.

**Target Platform**: iOS 17+, macOS 14+, tvOS 17+, watchOS 10+, visionOS 1+.

**Project Type**: Swift package — library products (`OnwardCore`, `OnwardGenerators`,
`Onward`) plus a `.macro` target (`OnwardGeneratorsMacros`). Single project.

**Performance Goals**: N/A — pure type-system / isolation change, no runtime path added
or removed. Sync dispatch must introduce zero suspension points.

**Constraints**:
- After the change `Sources/OnwardCore` MUST contain no `Sendable`, `@Sendable`,
  `@unchecked`, `nonisolated`, `@preconcurrency` tokens (FR-011 / SC-003).
- `OnwardCore` MUST NOT gain a UI-framework dependency (`@MainActor` comes from
  `_Concurrency`, allowed).
- Breaking public API change → MAJOR version bump, called out in the PR.
- Docs (`README.md` + both `.docc` catalogs) updated in the same PR (FR-009,
  non-deferrable).

**Scale/Scope**: ~17 core source files, 5 macro implementation files, 1 test file,
2 docs surfaces, `Examples/`. 6 existing tests kept + 2 new = 8.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Impact | Verdict |
|-----------|--------|---------|
| I. Reducer Purity (NON-NEGOTIABLE) | Isolation does not let a reducer touch the store, dispatch, or do I/O. Purity unchanged. | PASS |
| II. Side Effects Isolated in Middleware | Middleware still receives only `Proxy`; no new capability. | PASS |
| III. Actions Are the Only Intent Channel | Dispatch surface unchanged; re-entrant `proxy.dispatch` semantics preserved (FR-006). | PASS |
| IV. Dependencies Through Volt | Explicitly out of scope; Volt untouched. | PASS |
| V. Macro / Hand-Written Parity | Macros must produce code that satisfies the now-`@MainActor` protocols without the consumer adding annotations the macro owns (FR-007). New macro diagnostic must be actionable via `OnwardMacroError` (FR-008). Expansion tests required. | PASS (with work) |
| Architecture: async paths compile with no concurrency warnings, no `@unchecked Sendable` in core | This feature is the direct fulfilment; FR-011 enforces zero shortcut tokens. | PASS |
| Workflow: `swift test` green; public API change in README + `.docc`; PR states principle impact; breaking change → MAJOR bump | Covered by FR-009, FR-010, FR-013 and the release-process assumption. | PASS |

No violations. Complexity Tracking not required.

**Post-design re-check**: see end of Phase 1 — still PASS, no new violations.

## Project Structure

### Documentation (this feature)

```text
specs/001-swift6-mainactor-isolation/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output — type inventory + isolation matrix
├── quickstart.md        # Phase 1 output — validation scenarios (SC-001..006)
├── contracts/           # Phase 1 output
│   ├── public-api.md    # Public API surface change contract
│   └── macro-diagnostics.md  # @MainActor requirement + diagnostic contract
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code (repository root)

```text
Sources/
├── OnwardCore/
│   ├── Action/Sync/            Action.swift, ActionComponentSchema.swift, ActionBuilder.swift
│   ├── Action/Async/           AsyncAction.swift, AsyncActionComponent.swift, AsyncActionBuilder.swift
│   ├── Reducer/Sync/           Reducer.swift, ReducerQueue.swift, ReducerBuilder.swift
│   ├── Reducer/Async/          AsyncReducer.swift, AsyncReducerQueue.swift, AsyncReducerBuilder.swift
│   ├── Middleware/             Middleware.swift, AsyncMiddleware.swift
│   ├── Store/                  Store.swift, Interactor.swift
│   ├── Container/              OnwardContainer.swift          (untouched — Volt)
│   └── OnwardCore.docc/        OnwardCore.md                  (doc update)
├── OnwardGenerators/           StoreMacro.swift, ActionMacro.swift, ReducerMacro.swift,
│   │                           InteractorMacro.swift, MiddlewareMacro.swift  (macro decls)
│   └── OnwardGenerators.docc/  OnwardGenerators.md            (doc update)
├── OnwardGeneratorsMacros/
│   ├── Implementations/        StoreMacro.swift, InteractorMacro.swift, ReducerMacro.swift,
│   │                           MiddlewareMacro.swift, Action/ActionFactory.swift
│   └── Utils/                  OnwardMacroErrors.swift        (new diagnostic case)
└── Onward/                     Onward.swift                    (umbrella — likely untouched)

Tests/OnwardTests/OnwardTests.swift   (add isolation annotations + 2 new tests)
Tests/  (new)  macro-expansion target OR compile sample for US3

Examples/Package.swift                (SPM stub — no-op build)
Examples/Todos/                       (Xcode app — best-effort @MainActor where forced)

README.md                             (doc update — FR-009)
```

**Structure Decision**: Single Swift package, existing layout. All isolation edits land
in `Sources/OnwardCore`; macro edits in `Sources/OnwardGeneratorsMacros` (+ the one
public macro decl file if a signature note is needed) and `Utils/OnwardMacroErrors.swift`.
Tests stay in the single `OnwardTests` target; a small macro-expansion test target is
added for US3 (P2).

## Complexity Tracking

Not applicable — no constitution violations.
