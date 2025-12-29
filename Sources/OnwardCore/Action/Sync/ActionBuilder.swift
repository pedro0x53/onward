//
//  ActionBuilder.swift
//  onward
//
//  Created by Pedro Sousa on 04/07/25.
//

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
    
    public static func buildExpression<Component: ActionComponentScheme>(_ component: Component) -> [ActionComponent<S>] where Component.S == S {
        [ActionComponent(component)]
    }

    public static func buildLimitedAvailability(_ component: [ActionComponent<S>]) -> [ActionComponent<S>] {
        return component
    }
}
