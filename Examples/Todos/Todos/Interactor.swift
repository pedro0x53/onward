//
//  Interactor.swift
//  Todos
//
//  Created by Pedro Sousa on 03/07/25.
//

import Onward
import Foundation

struct Interactor {
    static var newToDoItem: AsyncAction<ToDoStore, String, String> {
        AsyncAction { title, description in
            AsyncMiddleware { store in
                Interactor.updateTitle(store) // dispatching an Action

                print("Sleeping...")
                try? await Task.sleep(for: .seconds(3))
                print("Awake!")

                return "Middleware's context"
            } interceptBefore: { context in
                AsyncReducer(get: \.todos, set: \.todos) { todos in
                    todos + [ToDo(title: "\(title) - \(context)", description: description)]
                }
            }

            AsyncReducer(get: \.todos, set: \.todos) { todos in
                todos + [ToDo(title: "Copy of \(title)", description: description)]
            }
        }
    }

    static var toggleToDoStatus: Action<ToDo> {
        Action {
            Reducer(get: \.isCompleted, set: \.isCompleted) { status in
                return !status
            }
        }
    }

    static var updateTitle: Action<ToDoStore> {
        Action {
            Reducer(setter: \.title) {
                return UUID().uuidString
            }
        }
    }
}
