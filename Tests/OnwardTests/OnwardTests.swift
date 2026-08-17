import Testing
@testable import Onward

@Interactor
final class ToDoInteractor {}

@Store(ToDoInteractor.self)
class ToDo {
    var title: String
    var description: String
    var isCompleted: Bool

    init(title: String, description: String, isCompleted: Bool = false) {
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
    }
}

@Suite("Onward")
struct OnwardTests {
    @Test func dispatchAction() async throws {
        let todo = ToDo(title: "Test", description: "Description")

        let toggleStatusAction = Action<ToDo> {
            Reducer(get: \.isCompleted, set: \.isCompleted) { status in
                return !status
            }
        }

        toggleStatusAction.dispatch(todo)

        #expect(todo.isCompleted)
    }

    @Test func dispatchAsyncAction() async throws {
        let todo = ToDo(title: "Test", description: "Description")
        let expectedTitle = "Async Title"

        let setTitleAction = AsyncAction<ToDo, String> { title in
            AsyncReducer(setter: \.title) {
                return title
            }
        }

        await setTitleAction.dispatch(todo, expectedTitle)

        #expect(todo.title == expectedTitle)
    }

    @Test func dispatchActionMultipleReducers() async throws {
        let todo = ToDo(title: "Test", description: "Description")
        let expectedTitle = "3"

        let setTitleAction = Action<ToDo> {
            Reducer(setter: \.title) {
                return "1"
            }

            Reducer(setter: \.title) {
                return "2"
            }

            Reducer(setter: \.title) {
                return expectedTitle
            }
        }

        setTitleAction.dispatch(todo)

        #expect(todo.title == expectedTitle)
    }

    @Test func dispatchAsyncActionMultipleReducers() async throws {
        let todo = ToDo(title: "Test", description: "Description")
        let expectedTitle = "3"

        let setTitleAction = AsyncAction<ToDo> {
            AsyncReducer(setter: \.title) {
                return "1"
            }

            AsyncReducer(setter: \.title) {
                return "2"
            }

            AsyncReducer(setter: \.title) {
                return expectedTitle
            }
        }

        await setTitleAction.dispatch(todo)

        #expect(todo.title == expectedTitle)
    }

    @Test func dispatchActionWithMiddleware() async throws {
        let todo = ToDo(title: "Test", description: "Description")

        let baseTitle = "Async Title"
        let expectedContext = " - Middleware Context"
        let expectedTitle = baseTitle + expectedContext

        let action = Action<ToDo, String> { title in
            // Middleware only sees a read-only proxy, so it mutates state by
            // dispatching a mutator action rather than writing directly.
            Middleware { proxy in
                proxy.dispatch(\.titleMutator, title + expectedContext)
            }

            Middleware { proxy in
                proxy.dispatch(\.isCompletedMutator, false)
            }

            Reducer(setter: \.isCompleted) {
                return true
            }
        }

        action.dispatch(todo, baseTitle)

        #expect(todo.title == expectedTitle)
        #expect(todo.isCompleted)
    }

    @Test func dispatchAsyncActionWithMiddleware() async throws {
        let todo = ToDo(title: "Test", description: "Description")

        let baseTitle = "Async Title"
        let expectedContext = " - Async Middleware Context"
        let expectedTitle = baseTitle + expectedContext

        let asyncAction = AsyncAction<ToDo, String> { title in
            AsyncMiddleware { proxy in
                proxy.dispatch(\.titleMutator, title + expectedContext)
            }

            AsyncMiddleware { proxy in
                proxy.dispatch(\.isCompletedMutator, false)
            }

            AsyncReducer(setter: \.isCompleted) {
                return true
            }
        }

        await asyncAction.dispatch(todo, baseTitle)

        #expect(todo.title == expectedTitle)
        #expect(todo.isCompleted)
    }
}
