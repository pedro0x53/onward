//
//  Store.swift
//  Todos
//
//  Created by Pedro Sousa on 03/07/25.
//

import Foundation
import Observation
import Onward

@Store @Observable
final class ToDoStore {
    var title: String = UUID().uuidString
    var todos: [ToDo] = [ToDo(title: "First", description: "First description")]

    var alertIsPresented: Bool = false
    var alert: AlertContent = .init()
}

@Store @Observable
final class ToDo: Identifiable {
    let id = UUID()
    var title: String
    var description: String
    var isCompleted: Bool

    init(title: String, description: String, isCompleted: Bool = false) {
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
    }
}

struct AlertContent {
    let title: String
    let message: String

    init(title: String = "", message: String = "") {
        self.title = title
        self.message = message
    }
}
