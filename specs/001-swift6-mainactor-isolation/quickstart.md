# Quickstart: Validating MainActor Pipeline Isolation

Runnable checks that prove the feature works end-to-end. Each maps to a Success Criterion
in [spec.md](./spec.md). Run from the repo root.

## Prerequisites

- Swift toolchain matching the pinned tools version (swift-tools-6.0; a 6.3.x toolchain
  also works). `swift --version` to confirm.
- Clean tree: `swift package clean` if a prior build is stale.

## 1. Root package builds under complete concurrency (SC-001, SC-004)

```bash
swift build -Xswiftc -warnings-as-errors
```

**Expected**: `Build complete!`, zero concurrency diagnostics.

## 2. SwiftUI-style store sample compiles (SC-001)

The sample lives in the test target (or the macro-expansion sample target). It defines:

```swift
@MainActor @Observable @Store(SampleInteractor.self) final class SampleStore { var count = 0 }
@MainActor @Interactor final class SampleInteractor { /* @Reducer / @Middleware methods */ }
```

and, from a `@MainActor` context, dispatches a sync `Action` and an `await`-ed
`AsyncAction`.

```bash
swift build -Xswiftc -warnings-as-errors
```

**Expected**: compiles. See [contracts/public-api.md](./contracts/public-api.md) for the
isolation surface and [contracts/macro-diagnostics.md](./contracts/macro-diagnostics.md)
for what the macros must generate.

## 3. Test suite: 8/8 (SC-002, SC-006)

```bash
swift test
```

**Expected**: 8 tests pass.
- 6 existing tests — bodies unchanged, only `@MainActor` added to `ToDoInteractor`,
  `ToDo`, and the `@Suite` struct.
- `dispatchActionSynchronouslyFromMainActor` — asserts a sync `Action` mutates before the
  next line (FR-005 / B1).
- `asyncMiddlewareSuspendsBeforeTrailingReducer` — `AsyncMiddleware` does
  `await Task.yield()` then `proxy.dispatch`; a trailing `AsyncReducer` observes the
  effect and runs after it (FR-006 / B3, B4).

## 4. Token grep gate (SC-003)

```bash
grep -REn 'Sendable|@Sendable|@unchecked|nonisolated|@preconcurrency' Sources/OnwardCore && echo "FAIL" || echo "PASS"
```

**Expected**: `PASS` (no matches). `@MainActor` is allowed and not matched by this
pattern.

## 5. Non-`@MainActor` class diagnostic (SC-005)

A negative sample (macro-expansion test) applies `@Store` / `@Interactor` to a class
with no `@MainActor`.

**Expected**: diagnostic `missingMainActor` at the attribute site naming the missing
isolation — not an unattributed error inside generated code. (MAY be deferred per spec
Assumptions; if deferred, expect the raw Swift conformance error instead.)

## 6. Examples package builds (SC-004)

```bash
swift build --package-path Examples
```

**Expected**: succeeds. (`Examples/Package.swift` is currently a stub; the `Examples/Todos`
Xcode sample is verified separately in Xcode with minimal `@MainActor` added where the
isolated core forces it.)

## 7. Incremental-isolation checkpoint (FR-012)

The first implementation commit isolates **only** the three `Reducer` initializers:

```bash
swift build   # must be green before widening isolation to the rest of the pipeline
```

If a target toolchain rejects `@MainActor` on a `(repeat each Argument) -> …` closure
parameter, apply the documented fallback (isolate the enclosing struct, leave that
parameter bare) and note it in the PR. See [research.md](./research.md) R5.

## Done when

- Steps 1–4 and 6 pass; step 5 passes or is explicitly deferred in the PR.
- PR calls out the MAJOR version bump and the principle impact (Constitution V,
  Architecture concurrency constraint).
- `README.md` + both `.docc` catalogs updated (FR-009).
