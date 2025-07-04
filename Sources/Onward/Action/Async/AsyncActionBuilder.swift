//
//  AsyncActionBuilder.swift
//  onward
//
//  Created by Pedro Sousa on 02/07/25.
//

@resultBuilder
public enum AsyncActionBuilder<Store> {
    public static func buildBlock(_ reducers: [AsyncActionComponent<Store>]...) -> [AsyncActionComponent<Store>] {
        reducers.flatMap { $0 }
    }

    public static func buildArray(_ components: [[AsyncActionComponent<Store>]]) -> [AsyncActionComponent<Store>] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [AsyncActionComponent<Store>]?) -> [AsyncActionComponent<Store>] {
        component ?? []
    }

    public static func buildEither(first component: [AsyncActionComponent<Store>]) -> [AsyncActionComponent<Store>] {
        component
    }

    public static func buildEither(second component: [AsyncActionComponent<Store>]) -> [AsyncActionComponent<Store>] {
        component
    }

    public static func buildExpression(_ expression: AsyncActionComponent<Store>) -> [AsyncActionComponent<Store>] {
        return [expression]
    }

    public func buildExpression(_ expression: [AsyncActionComponent<Store>]) -> [AsyncActionComponent<Store>] {
        return expression
    }
    
    public static func buildExpression<Component: AsyncActionComponentScheme>(_ component: Component) -> [AsyncActionComponent<Store>] where Component.Store == Store {
        [AsyncActionComponent(component)]
    }

    public static func buildLimitedAvailability(_ component: [AsyncActionComponent<Store>]) -> [AsyncActionComponent<Store>] {
        return component
    }
}
