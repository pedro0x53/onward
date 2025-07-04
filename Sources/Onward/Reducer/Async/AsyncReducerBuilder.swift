//
//  AsyncReducerBuilder.swift
//  onward
//
//  Created by Pedro Sousa on 29/06/25.
//

@resultBuilder
public enum AsyncReducerBuilder<Store> {
    public static func buildBlock(_ reducers: [AsyncReducer<Store>]...) -> [AsyncReducer<Store>] {
        reducers.flatMap { $0 }
    }

    public static func buildArray(_ components: [[AsyncReducer<Store>]]) -> [AsyncReducer<Store>] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [AsyncReducer<Store>]?) -> [AsyncReducer<Store>] {
        component ?? []
    }

    public static func buildEither(first component: [AsyncReducer<Store>]) -> [AsyncReducer<Store>] {
        component
    }

    public static func buildEither(second component: [AsyncReducer<Store>]) -> [AsyncReducer<Store>] {
        component
    }

    public static func buildExpression(_ expression: AsyncReducer<Store>) -> [AsyncReducer<Store>] {
        return [expression]
    }

    public static func buildExpression(_ expression: [AsyncReducer<Store>]) -> [AsyncReducer<Store>] {
        return expression
    }

    public static func buildExpression(_ expression: AsyncReducerQueue<Store>) -> [AsyncReducer<Store>] {
        return expression.reducers
    }

    public static func buildLimitedAvailability(_ component: [AsyncReducer<Store>]) -> [AsyncReducer<Store>] {
        return component
    }
}

