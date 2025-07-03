//
//  Dispatcher.swift
//  Onward
//
//  Created by Pedro Sousa on 28/06/25.
//

protocol Interface {
    associatedtype Store
    var store: Store { get }
}
