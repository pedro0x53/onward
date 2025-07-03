//
//  ToDo.swift
//  Todos
//
//  Created by Pedro Sousa on 03/07/25.
//

import Observation
import Foundation

@Observable
class ToDo: Identifiable {
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
