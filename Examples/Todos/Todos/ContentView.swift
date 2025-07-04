//
//  ContentView.swift
//  Todos
//
//  Created by Pedro Sousa on 03/07/25.
//

import SwiftUI
struct ContentView: View {
    @State private var store: ToDoStore = {
        let store = ToDoStore()
        store.todos.append(ToDo(title: "First", description: "First description"))
        return store
    }()

    init() {
        self.store = store
    }

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
                    Interactor.toggleToDoStatus(todo)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let todoIndex = store.todos.count + 1
                        Task {
                            await Interactor.newToDoItem(store,
                                args: "Title \(todoIndex)", "Description \(todoIndex)"
                            )
                        }
                    }
                }
            }
            .navigationTitle(store.title)
        }
    }
}

#Preview {
    ContentView()
}
