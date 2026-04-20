/// An ordered collection of ``Reducer`` values that runs them sequentially
/// as a single ``ActionComponentSchema`` step.
///
/// Use a `ReducerQueue` when you want to treat a batch of reducers as one
/// logical unit inside an ``Action``, or when you need to build up a list
/// of reducers dynamically.
///
/// ```swift
/// var queue = ReducerQueue<ToDoStore> {
///     Reducer(set: \.isLoading) { true }
///     Reducer(get: \.count, set: \.count) { $0 + 1 }
/// }
/// queue.append(anotherReducer)
/// ```
public struct ReducerQueue<S: Store> {
    /// The underlying array of reducers, in execution order.
    private(set) var reducers: [Reducer<S>]

    /// Creates a queue from an existing array of reducers.
    public init (_ reducers: [Reducer<S>]) {
        self.reducers = reducers
    }

    /// Creates a queue using a ``ReducerBuilder`` closure.
    public init(@ReducerBuilder<S> _ content: () -> [Reducer<S>]) {
        self.reducers = content()
    }

    /// Applies every reducer in the queue to `store`, in order.
    public func reduce(_ store: S) {
        for reducer in reducers {
            reducer.reduce(store)
        }
    }

    /// Appends a reducer to the end of the queue.
    public mutating func append(_ reducer: Reducer<S>) {
        reducers.append(reducer)
    }
}

extension ReducerQueue: ActionComponentSchema {
    /// Bridges the ``ActionComponentSchema`` conformance by forwarding to
    /// ``reduce(_:)``.
    public func run(_ store: S) {
        self.reduce(store)
    }
}
