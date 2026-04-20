/// A synchronous, pure transformation of a ``Store``'s state.
///
/// A `Reducer` reads one or more properties from a store via key paths,
/// applies a transformation, and writes the results back. The three
/// initializers cover the common patterns: read-only, write-only, and
/// read-write.
///
/// ```swift
/// // Read-write: toggle a boolean
/// Reducer(get: \.isCompleted, set: \.isCompleted) { status in
///     !status
/// }
///
/// // Write-only: reset a flag
/// Reducer(setter: \.isLoading) { false }
///
/// // Read-only: log the current value
/// Reducer(getter: \.title) { title in
///     print("Title is \(title)")
/// }
/// ```
///
/// Or generate a reducer from a plain function using the `@Reducer` macro:
///
/// ```swift
/// @Reducer(ToDo.self, get: \.isCompleted, set: \.isCompleted)
/// func toggle(_ status: Bool) -> Bool { !status }
/// ```
///
/// `Reducer` conforms to ``ActionComponentSchema``, so it can be placed
/// directly inside an ``ActionBuilder`` block.
public struct Reducer<S: Store> {
    private var _reduce: (S) -> Void

    /// Creates a read-only reducer that extracts values from the store and
    /// passes them to `work`.
    ///
    /// Use this when you need to observe state without writing back (e.g.
    /// logging, validation).
    ///
    /// - Parameters:
    ///   - keyPaths: One or more key paths to read from the store.
    ///   - work: A closure that receives the extracted values.
    public init<each Input>(getter keyPaths: repeat KeyPath<S, each Input>,
                            do work: @escaping (repeat each Input) -> Void) {
        self._reduce = { store in
            work(repeat store[keyPath: each keyPaths])
        }
    }

    /// Creates a write-only reducer that produces new values and assigns
    /// them to the store.
    ///
    /// Use this when the new state does not depend on the current state.
    ///
    /// - Parameters:
    ///   - keyPaths: One or more writable key paths to set on the store.
    ///   - work: A closure that returns the new values.
    public init<each Output>(setter keyPaths: repeat ReferenceWritableKeyPath<S, each Output>,
                             do work: @escaping () -> (repeat each Output)) {
        self._reduce = { store in
            repeat store[keyPath: each keyPaths] = each work()
        }
    }

    /// Creates a read-write reducer that reads values from the store,
    /// transforms them, and writes the results back.
    ///
    /// This is the most common form. The function's inputs are read through
    /// `get` key paths and its outputs are written through `set` key paths.
    ///
    /// - Parameters:
    ///   - getKeyPaths: Key paths to read from the store.
    ///   - setKeyPaths: Writable key paths to set on the store.
    ///   - work: A closure that transforms the input values into output values.
    public init<each Input, each Output>(get getKeyPaths: repeat KeyPath<S, each Input>,
                                         set setKeyPaths: repeat ReferenceWritableKeyPath<S, each Output>,
                                         do work: @escaping (repeat each Input) -> (repeat each Output)) {
        self._reduce = { store in
            repeat store[keyPath: each setKeyPaths] = each work(repeat store[keyPath: each getKeyPaths])
        }
    }

    /// Applies this reducer's transformation to the given store.
    public func reduce(_ store: S) {
        self._reduce(store)
    }
}

extension Reducer: ActionComponentSchema {
    /// Bridges the ``ActionComponentSchema`` conformance by forwarding to
    /// ``reduce(_:)``.
    public func run(_ store: S) {
        self.reduce(store)
    }
}
