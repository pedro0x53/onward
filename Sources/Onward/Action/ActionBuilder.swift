//
//  ActionBuilder.swift
//  redux
//
//  Created by Pedro Sousa on 02/07/25.
//

@resultBuilder
public enum ActionBuilder<Store: SSoT> {
    public static func buildBlock(_ reducers: [ActionComponent<Store>]...) -> [ActionComponent<Store>] {
        reducers.flatMap { $0 }
    }

    public static func buildArray(_ components: [[ActionComponent<Store>]]) -> [ActionComponent<Store>] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [ActionComponent<Store>]?) -> [ActionComponent<Store>] {
        component ?? []
    }

    public static func buildEither(first component: [ActionComponent<Store>]) -> [ActionComponent<Store>] {
        component
    }

    public static func buildEither(second component: [ActionComponent<Store>]) -> [ActionComponent<Store>] {
        component
    }

    public static func buildExpression(_ expression: ActionComponent<Store>) -> [ActionComponent<Store>] {
        return [expression]
    }

    public func buildExpression(_ expression: [ActionComponent<Store>]) -> [ActionComponent<Store>] {
        return expression
    }
    
    public static func buildExpression<Component: ActionComponentScheme>(_ component: Component) -> [ActionComponent<Store>] where Component.Store == Store {
        [ActionComponent(component)]
    }

    public static func buildLimitedAvailability(_ component: [ActionComponent<Store>]) -> [ActionComponent<Store>] {
        return component
    }
}
