//
//  Store.swift
//  Todos
//
//  Created by Pedro Sousa on 03/07/25.
//

import Observation
import Foundation

@Observable
class ToDoStore {
    var title: String = UUID().uuidString
    var todos: [ToDo] = []
}
