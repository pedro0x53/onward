//
//  ContentView.swift
//  Todos
//
//  Created by Pedro Sousa on 03/07/25.
//

import SwiftUI
struct ContentView: View {
    @State private var store: ToDoStore

    init(store: ToDoStore = .init()) {
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
                    .onTapGesture {
                        Interactor.toggleToDoStatus.dispatch(todo)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let todoIndex = store.todos.count + 1
                        Interactor.newToDoItem.dispatch(store,
                                                        "Title \(todoIndex)",
                                                        "Desctiption \(todoIndex)")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView(store: .init())
}
