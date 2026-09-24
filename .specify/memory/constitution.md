<!--
Sync Impact Report
Version change: (unversioned template) → 1.0.0
Ratification: initial adoption of a populated constitution (previous file was an empty scaffold).
Modified principles:
  - [PRINCIPLE_1_NAME] → I. Reducer Purity (NON-NEGOTIABLE)
  - [PRINCIPLE_2_NAME] → II. Side Effects Isolated in Middleware
  - [PRINCIPLE_3_NAME] → III. Actions Are the Only Intent Channel
  - [PRINCIPLE_4_NAME] → IV. Dependencies Through the Volt Container
  - [PRINCIPLE_5_NAME] → V. Macro / Hand-Written Parity
Added sections:
  - Architecture Constraints (was [SECTION_2_NAME])
  - Development Workflow & Quality Gates (was [SECTION_3_NAME])
Removed sections: none
Follow-up TODOs:
  - TODO(RATIFICATION_DATE): confirm the true original adoption date; 2026-09-09 recorded as the date this populated constitution was ratified.
Templates reviewed:
  - .specify/templates/plan-template.md — Constitution Check gate references this file generically; no update required.
  - .specify/templates/spec-template.md — no constitution-specific tokens; no update required.
  - .specify/templates/tasks-template.md — no constitution-specific tokens; no update required.
-->

# Onward Constitution

Onward is a Swift Package providing a DSL for the Redux architecture: `Action` (intent
wrapper), `Middleware` (isolated side effects over a read-only `Proxy`), `Reducer`
(deterministic state transition), `Interactor` (dependency aggregation and Action
definitions), plus macros that turn ordinary methods into Reducers and Middleware. This
constitution governs how those pieces stay coherent.

## Core Principles

### I. Reducer Purity (NON-NEGOTIABLE)

Reducers MUST be pure and deterministic: same inputs produce the same output with no
observable side effects. A Reducer MUST NOT reach the `Store`, dispatch other Actions,
perform I/O, read the clock, or use randomness. It reads and writes only the `State`
values handed to it (via its bound key path / setter), never the `Store` itself.

Rationale: determinism is what makes state transitions replayable, testable without
mocks, and safe to compose in a `ReducerQueue`. Any impurity here poisons the whole
pipeline.

### II. Side Effects Isolated in Middleware

Every non-deterministic operation — API calls, file system I/O, networking, timers,
persistence, logging with external effect — MUST live in a `Middleware` or
`AsyncMiddleware`. Middleware receives an immutable `Proxy` snapshot and MUST NOT hold
or mutate `Store` state directly; it influences state only by dispatching Actions /
mutators through the `Proxy`.

Rationale: concentrating I/O in one layer keeps Reducers pure, keeps the `Store`
read-only from the outside, and gives tests a single seam to substitute fakes.

### III. Actions Are the Only Intent Channel

All state change flows through an `Action` dispatched to the `Interactor`. Views and
other callers MUST dispatch (key-path dispatch, e.g. `store.dispatch(\.addItem, …)`) and
MUST NOT mutate `Store` properties directly. The `Interactor` never stores state; it
only defines Actions and reads via `Proxy`.

Rationale: a single intent channel makes data flow traceable, refactor-safe, and
uniformly interceptable by Middleware.

### IV. Dependencies Through the Volt Container

External dependencies MUST be declared on `OnwardContainer` with `@Inward` and resolved
with `@Outward`. No singletons, no global mutable shared instances, no hidden service
locators. Every dependency MUST be overridable in tests via `OnwardContainer.charge(\.key, mock)`.

Rationale: constructor-free but explicit injection keeps Interactors independently
testable and mirrors the SwiftUI Environment model users already know.

### V. Macro / Hand-Written Parity

Macro-based declarations (`@Store`, `@Interactor`, `@Action`, `@Reducer`, `@Middleware`)
MUST be behaviorally equivalent to the inline declarative form they replace. Macros
generate boilerplate; they MUST NOT introduce semantics that cannot be expressed by
hand. Every macro MUST have expansion tests, and diagnostics MUST be actionable
(`OnwardMacroErrors`).

Rationale: users choose freely between styles; divergence between them turns macros
into a trap instead of a convenience.

## Architecture Constraints

- Layering is one-directional: `View → Store → Interactor → (Middleware → Reducer)`.
  State reads flow back only through the immutable `Proxy`.
- `OnwardCore` MUST NOT depend on any UI framework. SwiftUI/Observation usage lives in
  client code and examples, not in the core state machinery.
- Public products: `OnwardCore`, `OnwardGenerators`, `Onward` (umbrella). Macro
  implementation (`OnwardGeneratorsMacros`) is never a direct public dependency.
- The only third-party runtime dependency is `Volt` (DI). `swift-syntax` is a
  build-time-only dependency of the macro target. Adding any further dependency requires
  a constitution amendment or an explicit ADR referenced from the PR.
- Supported platforms: iOS 17+, macOS 14+, tvOS 17+, watchOS 10+, visionOS 1+, Swift
  tools 6.0. Lowering a minimum is a breaking change.
- Swift 6 strict concurrency: async paths (`AsyncAction`, `AsyncMiddleware`,
  `AsyncReducer`) MUST compile without concurrency warnings and MUST NOT rely on
  `@unchecked Sendable` shortcuts in core types.

## Development Workflow & Quality Gates

- `swift test` MUST pass on every PR. New Reducers and Middleware MUST ship with tests;
  new or changed macros MUST ship with expansion tests.
- Reducer tests assert purity (no I/O, deterministic output). Middleware tests use
  `charge`-injected fakes rather than real I/O.
- Public API changes MUST be reflected in `README.md` and the relevant `.docc` catalog
  in the same PR.
- Every PR description MUST state which principles are affected and confirm compliance,
  or justify a deviation under Governance.
- Breaking changes to any public product MUST bump the package MAJOR version and be
  called out in the PR.

## Governance

This constitution supersedes ad-hoc practice. When guidance conflicts, the constitution
wins; the fix is either to comply or to amend it.

- **Amendments**: proposed via PR that edits this file, states the rationale, and bumps
  the constitution version. At least one maintainer approval is required.
- **Versioning** (semantic):
  - MAJOR — a principle is removed or redefined in a backward-incompatible way.
  - MINOR — a new principle or section is added, or guidance is materially expanded.
  - PATCH — clarifications, wording, or non-semantic refinements.
- **Compliance review**: reviewers MUST verify PRs against the Core Principles.
  Unavoidable violations MUST be documented in the PR with scope and a remediation plan;
  undocumented violations block merge.
- **Runtime guidance**: agent- and contributor-facing working notes live in `CLAUDE.md`
  / `README.md` and MUST NOT contradict this document.

**Version**: 1.0.0 | **Ratified**: 2026-09-09 | **Last Amended**: 2026-09-09
