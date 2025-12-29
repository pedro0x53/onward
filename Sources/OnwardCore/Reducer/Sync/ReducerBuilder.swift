//
//  ReducerBuilder.swift
//  onward
//
//  Created by Pedro Sousa on 04/07/25.
//


@resultBuilder
public enum ReducerBuilder<S: Store> {
    public static func buildBlock(_ reducers: [Reducer<S>]...) -> [Reducer<S>] {
        reducers.flatMap { $0 }
    }

    public static func buildArray(_ components: [[Reducer<S>]]) -> [Reducer<S>] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [Reducer<S>]?) -> [Reducer<S>] {
        component ?? []
    }

    public static func buildEither(first component: [Reducer<S>]) -> [Reducer<S>] {
        component
    }

    public static func buildEither(second component: [Reducer<S>]) -> [Reducer<S>] {
        component
    }

    public static func buildExpression(_ expression: Reducer<S>) -> [Reducer<S>] {
        return [expression]
    }

    public static func buildExpression(_ expression: [Reducer<S>]) -> [Reducer<S>] {
        return expression
    }

    public static func buildExpression(_ expression: ReducerQueue<S>) -> [Reducer<S>] {
        return expression.reducers
    }

    public static func buildLimitedAvailability(_ component: [Reducer<S>]) -> [Reducer<S>] {
        return component
    }
}

