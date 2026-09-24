# ``OnwardCore``

Core protocols, types, and the dependency injection container for the Onward state-management framework.

## Overview

Onward structures your app around a strict **unidirectional data flow**. State lives in observable **Stores**, business logic lives in **Interactors**, and every mutation is expressed as a composable **Action** made of **Reducers** and **Middlewares**.

```
View ──dispatch──▶ Store ──interactor──▶ Interactor
                     │                       │
                  (state)          Actions / Reducers / Middleware
                     │                       │
                  Proxy ◀─────── (read-only snapshot)
```

`OnwardCore` provides all the building blocks. Import the umbrella module to get everything at once:

```swift
import Onward
```

### Store and Interactor

A ``Store`` is a reference-type state container whose properties drive the UI. Pair it with an ``Interactor`` that owns all business logic. The ``Store`` protocol's `dispatch` family of methods routes actions from the view into the right interactor.

### Main-actor isolation

The entire dispatch pipeline — ``Store``, ``Interactor``, ``Action``, ``AsyncAction``, ``Reducer``, ``AsyncReducer``, their queues and builders, ``Middleware`` and ``AsyncMiddleware`` — is `@MainActor`. Stored closures (reducer `work`, middleware `perform`, action components) are `@MainActor` and never `@Sendable`, so a `@MainActor @Observable` store does not need to be `Sendable`. `Sendable` was removed from ``Action`` and ``AsyncAction``. Synchronous dispatch introduces no suspension point; asynchronous dispatch preserves component order and re-entrant `proxy.dispatch` visibility. A non-`@MainActor` caller of an async `dispatch` must pass `Sendable` arguments at its own call site.

### Actions

An ``Action`` (sync) or ``AsyncAction`` (async) bundles one or more reducers and middlewares into a single dispatchable value. Components run in declaration order:
**reducers → middlewares → late reducers**.

### Reducers

A ``Reducer`` is a pure transformation: it reads one or more values from a ``Store`` via key paths, transforms them, and writes the results back. ``AsyncReducer`` is the `async` counterpart.

### Middlewares

A ``Middleware`` receives the store's read-only ``Store/Proxy`` and performs side effects — logging, analytics, validation — without mutating state. ``AsyncMiddleware`` supports `async` side effects such as network calls.

### Dependency Injection

``OnwardContainer`` is a global, thread-safe dependency registry. Declare entries with ``Inward`` in a container extension; resolve them with ``Outward`` as stored properties of an ``Interactor``.

## Topics

### The Store–Interactor Pair

- ``Store``
- ``Interactor``

### Actions

- ``Action``
- ``AsyncAction``

### Reducers

- ``Reducer``
- ``AsyncReducer``
- ``ReducerQueue``
- ``AsyncReducerQueue``

### Middlewares

- ``Middleware``
- ``AsyncMiddleware``

### Result Builders

- ``ActionBuilder``
- ``AsyncActionBuilder``
- ``ReducerBuilder``
- ``AsyncReducerBuilder``

### Action Component Protocols

- ``ActionComponentSchema``
- ``ActionComponent``
- ``AsyncActionComponentSchema``
- ``AsyncActionComponent``

### Dependency Injection

- ``OnwardContainer``
- ``Inward``
- ``Outward``
