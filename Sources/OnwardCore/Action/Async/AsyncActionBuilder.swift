//
//  AsyncActionBuilder.swift
//  onward
//
//  Created by Pedro Sousa on 02/07/25.
//

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
    
    public static func buildExpression<Component: AsyncActionComponentScheme>(_ component: Component) -> [AsyncActionComponent<S>] where Component.S == S {
        [AsyncActionComponent(component)]
    }

    public static func buildLimitedAvailability(_ component: [AsyncActionComponent<S>]) -> [AsyncActionComponent<S>] {
        return component
    }
}
