/// A result builder that assembles an ordered list of
/// ``AsyncActionComponent`` values for use inside an ``AsyncAction``.
///
/// `AsyncActionBuilder` accepts ``AsyncReducer``, ``AsyncMiddleware``,
/// ``AsyncReducerQueue``, and any custom ``AsyncActionComponentSchema``
/// conformance. It supports the full set of result-builder control flow:
/// `if`, `if/else`, `for…in`, and `#available` checks.
///
/// ```swift
/// AsyncAction {
///     AsyncReducer(set: \.isLoading) { true }
///     AsyncMiddleware { proxy in await api.refresh() }
///     AsyncReducer(set: \.isLoading) { false }
/// }
/// ```
@resultBuilder
public enum AsyncActionBuilder<S: Store> {
    public static func buildBlock(_ reducers: [AsyncActionComponent<S>]...) -> [AsyncActionComponent<S>] {
        reducers.flatMap { $0 }
    }

    public static func buildArray(_ components: [[AsyncActionComponent<S>]]) -> [AsyncActionComponent<S>] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [AsyncActionComponent<S>]?) -> [AsyncActionComponent<S>] {
        component ?? []
    }

    public static func buildEither(first component: [AsyncActionComponent<S>]) -> [AsyncActionComponent<S>] {
        component
    }

    public static func buildEither(second component: [AsyncActionComponent<S>]) -> [AsyncActionComponent<S>] {
        component
    }

    public static func buildExpression(_ expression: AsyncActionComponent<S>) -> [AsyncActionComponent<S>] {
        return [expression]
    }

    public func buildExpression(_ expression: [AsyncActionComponent<S>]) -> [AsyncActionComponent<S>] {
        return expression
    }
    
    public static func buildExpression<Component: AsyncActionComponentSchema>(_ component: Component) -> [AsyncActionComponent<S>] where Component.S == S {
        [AsyncActionComponent(component)]
    }

    public static func buildLimitedAvailability(_ component: [AsyncActionComponent<S>]) -> [AsyncActionComponent<S>] {
        return component
    }
}
