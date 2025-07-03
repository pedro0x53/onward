//
//  ReducerBuilder.swift
//  redux
//
//  Created by Pedro Sousa on 29/06/25.
//

@resultBuilder
public enum ReducerBuilder<Store> {
    public static func buildBlock(_ reducers: [Reducer<Store>]...) -> [Reducer<Store>] {
        reducers.flatMap { $0 }
    }

    public static func buildArray(_ components: [[Reducer<Store>]]) -> [Reducer<Store>] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [Reducer<Store>]?) -> [Reducer<Store>] {
        component ?? []
    }

    public static func buildEither(first component: [Reducer<Store>]) -> [Reducer<Store>] {
        component
    }

    public static func buildEither(second component: [Reducer<Store>]) -> [Reducer<Store>] {
        component
    }

    public static func buildExpression(_ expression: Reducer<Store>) -> [Reducer<Store>] {
        return [expression]
    }

    public static func buildExpression(_ expression: [Reducer<Store>]) -> [Reducer<Store>] {
        return expression
    }

    public static func buildExpression(_ expression: ReducerQueue<Store>) -> [Reducer<Store>] {
        return expression.reducers
    }

    public static func buildLimitedAvailability(_ component: [Reducer<Store>]) -> [Reducer<Store>] {
        return component
    }
}

