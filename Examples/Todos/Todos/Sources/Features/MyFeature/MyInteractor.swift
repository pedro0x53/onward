import Onward
import Foundation

@Interactor
final class MyInteractor {
    @Outward(\.httpClient) var httpClient
    @Outward(\.validator) var validator

    var addNewToDoItem: Action<ToDoStore, String, String> {
        Action { title, description in
            Middleware { proxy in
                if self.validator.validate(title) &&
                   self.validator.validate(description) {
                    let newToDo = ToDo(title: title, description: description)
                    var toDos = proxy.todos
                    toDos.append(newToDo)

                    proxy.dispatch(\.todosMutator, toDos)
                }
            }
        }
    }

    var loadRemoteDeclAction: AsyncAction<ToDoStore> {
        AsyncAction {
            AsyncMiddleware { proxy in
                let remoteItems = await self.httpClient.request()
                proxy.dispatch(\.todosMutator, remoteItems)
            }

            AsyncReducer(setter: \.alert) {
                return AlertContent(title: "Remote Items", message: "The remote items were loaded!")
            }

            AsyncReducer(setter: \.isAlertPresented) {
                return true
            }
        }
    }

    var dismissAlertDeclAction: Action<ToDoStore> {
        Action {
            Reducer(setter: \.isAlertPresented) {
                return false
            }

            Reducer(setter: \.alert) {
                return .init()
            }
        }
    }

    var toggleToDoStatusDeclAction: Action<ToDo> {
        Action {
            Reducer(get: \.isCompleted, set: \.isCompleted) { status in
                return !status
            }
        }
    }

    // MARK: Using the Onward Macros
    @Action(middlewares:  \Self.loadRemoteMiddleware,
            lateReducers: \Self.toDoStoreSetLoadedAlertContentReducer,
                          \Self.toDoStoreDiplayAlertReducer)
    var loadRemoteAction: AsyncAction<ToDoStore>

    @Middleware(ToDoStore.self)
    private func loadRemote(_ proxy: ToDoStore.Proxy) async {
        let remoteItems = await httpClient.request()
        proxy.dispatch(\.todosMutator, remoteItems)
    }

    @Reducer(ToDoStore.self, set: \.alert)
    func setLoadedAlertContent() async -> AlertContent {
        return AlertContent(title: "Remote Items", message: "The remote items were loaded!")
    }

    @Reducer(ToDoStore.self, set: \.isAlertPresented)
    func diplayAlert() async -> Bool {
        return true
    }

    @Action(reducers: \Self.toDoToggleToDoStatusReducer)
    var toggleToDoStatusAction: Action<ToDo>

    @Reducer(ToDo.self, get: \.isCompleted, set: \.isCompleted)
    func toggleToDoStatus(_ status: Bool) -> Bool {
        return !status
    }
}
