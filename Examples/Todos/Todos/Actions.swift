//
//  Actions.swift
//  Todos
//
//  Created by Pedro Sousa on 03/07/25.
//

import Onward
import Foundation

struct Actions {
    @Action(reducers: \Self.toDoStoreDismissAlertReducer,
            middlewares: \Self.fakeAPICallMiddleware)
    var dismissAlertAction: AsyncAction<ToDoStore>

    @Reducer(ToDo.self, get: \.title, set: \.title)
    @Reducer(ToDoStore.self, get: \.title, set: \.title)
    private func updateTitle(_ currentTitle: String) -> String {
        currentTitle == "Old Title" ? "New Title" : "Old Title"
    }

    @Reducer(ToDo.self, get: \.isCompleted, set: \.isCompleted)
    func toggleToDoStatus(_ status: Bool) -> Bool {
        return !status
    }

    @Reducer(ToDoStore.self, set: \.alertIsPresented)
    private func dismissAlert() async -> Bool {
        return false
    }

    @Middleware(ToDoStore.self)
    private func fakeAPICall(_ proxy: ToDoStore.Proxy) async {
        print("Sleeping...")
        try? await Task.sleep(for: .seconds(3))
        print("Awake!")
    }
}
