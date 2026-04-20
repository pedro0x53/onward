/// An asynchronous, pure transformation of a ``Store``'s state.
///
/// `AsyncReducer` is the `async` counterpart of ``Reducer``. It reads one
/// or more properties from a store via key paths, applies an asynchronous
/// transformation, and writes the results back. The three initializers
/// mirror those of ``Reducer``: read-only, write-only, and read-write.
///
/// ```swift
/// // Read-write: fetch an updated title
/// AsyncReducer(get: \.id, set: \.title) { id in
///     await api.fetchTitle(for: id)
/// }
///
/// // Write-only: compute a value asynchronously
/// AsyncReducer(setter: \.isLoading) { await checkStatus() }
/// ```
///
/// The `@Reducer` macro also generates an `AsyncReducer` when the
/// annotated function is declared `async`:
///
/// ```swift
/// @Reducer(ToDoStore.self, set: \.alertIsPresented)
/// func dismissAlert() async -> Bool { false }
/// ```
///
/// `AsyncReducer` conforms to ``AsyncActionComponentSchema``, so it can be
/// placed directly inside an ``AsyncActionBuilder`` block.
public struct AsyncReducer<S: Store> {
    private var _reduce: (S) async -> Void

    /// Creates a read-only async reducer that extracts values from the store
    /// and passes them to an `async` closure.
    ///
    /// - Parameters:
    ///   - keyPaths: One or more key paths to read from the store.
    ///   - work: An `async` closure that receives the extracted values.
    public init<each Input>(getter keyPaths: repeat KeyPath<S, each Input>,
                            do work: @escaping (repeat each Input) async -> Void) {
        self._reduce = { store in
            await work(repeat store[keyPath: each keyPaths])
        }
    }

    /// Creates a write-only async reducer that produces new values
    /// asynchronously and assigns them to the store.
    ///
    /// - Parameters:
    ///   - keyPaths: One or more writable key paths to set on the store.
    ///   - work: An `async` closure that returns the new values.
    public init<each Output>(setter keyPaths: repeat ReferenceWritableKeyPath<S, each Output>,
                             do work: @escaping () async -> (repeat each Output)) {
        self._reduce = { store in
            repeat store[keyPath: each keyPaths] = each await work()
        }
    }

    /// Creates a read-write async reducer that reads values from the store,
    /// transforms them asynchronously, and writes the results back.
    ///
    /// - Parameters:
    ///   - getKeyPaths: Key paths to read from the store.
    ///   - setKeyPaths: Writable key paths to set on the store.
    ///   - work: An `async` closure that transforms the input values into
    ///     output values.
    public init<each Input, each Output>(get getKeyPaths: repeat KeyPath<S, each Input>,
                                         set setKeyPaths: repeat ReferenceWritableKeyPath<S, each Output>,
                                         do work: @escaping (repeat each Input) async -> (repeat each Output)) {
        self._reduce = { store in
            repeat store[keyPath: each setKeyPaths] = each await work(repeat store[keyPath: each getKeyPaths])
        }
    }

    /// Applies this reducer's asynchronous transformation to the given store.
    public func reduce(_ store: S) async {
        await self._reduce(store)
    }
}

extension AsyncReducer: AsyncActionComponentSchema {
    /// Bridges the ``AsyncActionComponentSchema`` conformance by forwarding
    /// to ``reduce(_:)``.
    public func run(_ store: S) async {
        await self.reduce(store)
    }
}
