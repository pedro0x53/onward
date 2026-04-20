/// A result builder that assembles an ordered list of ``AsyncReducer``
/// values for use inside an ``AsyncReducerQueue`` or an ``AsyncAction``.
///
/// `AsyncReducerBuilder` accepts individual ``AsyncReducer`` instances,
/// ``AsyncReducerQueue`` values (which are flattened automatically), and
/// arrays of async reducers. It supports the full set of result-builder
/// control flow.
///
/// ```swift
/// AsyncReducerQueue {
///     AsyncReducer(set: \.isLoading) { true }
///     AsyncReducer(get: \.query, set: \.results) { q in await search(q) }
/// }
/// ```
@resultBuilder
public enum AsyncReducerBuilder<S: Store> {
    public static func buildBlock(_ reducers: [AsyncReducer<S>]...) -> [AsyncReducer<S>] {
        reducers.flatMap { $0 }
    }

    public static func buildArray(_ components: [[AsyncReducer<S>]]) -> [AsyncReducer<S>] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [AsyncReducer<S>]?) -> [AsyncReducer<S>] {
        component ?? []
    }

    public static func buildEither(first component: [AsyncReducer<S>]) -> [AsyncReducer<S>] {
        component
    }

    public static func buildEither(second component: [AsyncReducer<S>]) -> [AsyncReducer<S>] {
        component
    }

    public static func buildExpression(_ expression: AsyncReducer<S>) -> [AsyncReducer<S>] {
        return [expression]
    }

    public static func buildExpression(_ expression: [AsyncReducer<S>]) -> [AsyncReducer<S>] {
        return expression
    }

    public static func buildExpression(_ expression: AsyncReducerQueue<S>) -> [AsyncReducer<S>] {
        return expression.reducers
    }

    public static func buildLimitedAvailability(_ component: [AsyncReducer<S>]) -> [AsyncReducer<S>] {
        return component
    }
}

