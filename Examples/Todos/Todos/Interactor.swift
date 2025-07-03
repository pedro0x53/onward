//
//  Interactor.swift
//  Todos
//
//  Created by Pedro Sousa on 03/07/25.
//

import Onward

struct Interactor {
    static var newToDoItem: Action<ToDoStore, String, String> {
        Action { title, description in
            Middleware { store in
                print("Sleeping...")
                try? await Task.sleep(for: .seconds(3))
                print("Awake!")

                return "Middleware's context"
            } before: { context in
                Reducer(get: \.todos, set: \.todos) { todos in
                    todos + [ToDo(title: "\(title) \(context)", description: description)]
                }
            }
        }
    }

    static var toggleToDoStatus: Action<ToDo> {
        Action {
            Reducer(get: \.isCompleted, set: \.isCompleted) { isCompleted in
                !isCompleted
            }
        }
    }
}
