import Foundation
import Observation
import Onward

@Observable
@Store(MyInteractor.self)
final class ToDoStore {
    var todos: [ToDo] = []
    var isAlertPresented: Bool = false
    var alert: AlertContent = .init()
}

@Observable
@Store(MyInteractor.self)
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
