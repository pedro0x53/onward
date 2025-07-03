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
            Reducer(get: \.todos, set: \.todos) { todos in
                todos + [ToDo(title: title, description: description)]
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
