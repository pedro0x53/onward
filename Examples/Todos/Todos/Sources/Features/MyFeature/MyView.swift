import SwiftUI

struct ContentView: View {
    @State private var store: ToDoStore = .init()

    var body: some View {
        NavigationStack {
            List(store.todos) { todo in
                HStack {
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading) {
                        Text(todo.title)
                            .font(.headline)
                        Text(todo.description)
                            .font(.caption)
                    }
                }
                .onTapGesture {
                    todo.dispatch(\.toggleToDoStatusAction)
                }
            }
            .toolbar {
                Button("Add") {
                    store.dispatch(\.addNewToDoItem, "New Item", "New Description")
                }
            }
            .alert(store.alert.title, isPresented: $store.isAlertPresented) {
                Button("Ok") {
                    store.dispatch(\.dismissAlertDeclAction)
                }
            } message: {
                Text(store.alert.message)
            }
            .navigationTitle("ToDos")
        }
        .task {
            await store.dispatch(\.loadRemoteAction)
        }
    }
}

#Preview {
    ContentView()
}
