//
//  ContentView.swift
//  Todos
//
//  Created by Pedro Sousa on 03/07/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme

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
                    withAnimation {
//                        todo.dispatch(Actions.toggleToDoStatus)
                    }
                }
            }
            .toolbar {
                Button("Add") {
//                    store.dispatch(Actions.newToDoItem,
//                                   args: "New Item", UUID().uuidString)
                }

                Button {
//                    Task { await store.dispatch(Actions.fakeAPICall) }
                } label: {
                    Image(systemName: "network")
                }
            }
            .alert(store.alert.title, isPresented: $store.alertIsPresented) {
                Button("Ok") {
//                    store.dispatch(Actions.dismissAlert)
                }
            } message: {
                Text(store.alert.message)
            }
            .navigationTitle(store.title)
        }
    }
}

#Preview {
    ContentView()
}
