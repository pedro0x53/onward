/// A result builder that assembles an ordered list of ``ActionComponent``
/// values for use inside an ``Action``.
///
/// `ActionBuilder` accepts ``Reducer``, ``Middleware``, ``ReducerQueue``,
/// and any custom ``ActionComponentSchema`` conformance. It supports the
/// full set of result-builder control flow: `if`, `if/else`, `for…in`,
/// and `#available` checks.
///
/// ```swift
/// Action {
///     Reducer(get: \.count, set: \.count) { $0 + 1 }
///     Middleware { proxy in print("Count is now \(proxy.count)") }
/// }
/// ```
@resultBuilder
public enum ActionBuilder<S: Store> {
    public static func buildBlock(_ reducers: [ActionComponent<S>]...) -> [ActionComponent<S>] {
        reducers.flatMap { $0 }
    }

    public static func buildArray(_ components: [[ActionComponent<S>]]) -> [ActionComponent<S>] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [ActionComponent<S>]?) -> [ActionComponent<S>] {
        component ?? []
    }

    public static func buildEither(first component: [ActionComponent<S>]) -> [ActionComponent<S>] {
        component
    }

    public static func buildEither(second component: [ActionComponent<S>]) -> [ActionComponent<S>] {
        component
    }

    public static func buildExpression(_ expression: ActionComponent<S>) -> [ActionComponent<S>] {
        return [expression]
    }

    public func buildExpression(_ expression: [ActionComponent<S>]) -> [ActionComponent<S>] {
        return expression
    }
    
    public static func buildExpression<Component: ActionComponentSchema>(_ component: Component) -> [ActionComponent<S>] where Component.S == S {
        [ActionComponent(component)]
    }

    public static func buildLimitedAvailability(_ component: [ActionComponent<S>]) -> [ActionComponent<S>] {
        return component
    }
}
