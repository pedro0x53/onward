/// An ordered collection of ``AsyncReducer`` values that runs them
/// sequentially as a single ``AsyncActionComponentSchema`` step.
///
/// Use an `AsyncReducerQueue` when you want to treat a batch of async
/// reducers as one logical unit inside an ``AsyncAction``, or when you need
/// to build up a list of async reducers dynamically.
///
/// ```swift
/// var queue = AsyncReducerQueue<ToDoStore> {
///     AsyncReducer(set: \.isLoading) { true }
///     AsyncReducer(get: \.query, set: \.results) { q in await search(q) }
/// }
/// queue.append(anotherReducer)
/// ```
public struct AsyncReducerQueue<S: Store> {
    /// The underlying array of async reducers, in execution order.
    private(set) var reducers: [AsyncReducer<S>]

    /// Creates a queue from an existing array of async reducers.
    public init (_ reducers: [AsyncReducer<S>]) {
        self.reducers = reducers
    }

    /// Creates a queue using an ``AsyncReducerBuilder`` closure.
    public init(@AsyncReducerBuilder<S> _ content: () -> [AsyncReducer<S>]) {
        self.reducers = content()
    }

    /// Applies every async reducer in the queue to `store`, in order.
    public func reduce(_ store: S) async {
        for reducer in reducers {
            await reducer.reduce(store)
        }
    }

    /// Appends an async reducer to the end of the queue.
    public mutating func append(_ reducer: AsyncReducer<S>) {
        reducers.append(reducer)
    }
}

extension AsyncReducerQueue: AsyncActionComponentSchema {
    /// Bridges the ``AsyncActionComponentSchema`` conformance by forwarding
    /// to ``reduce(_:)``.
    public func run(_ store: S) async {
        await self.reduce(store)
    }
}
