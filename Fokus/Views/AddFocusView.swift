//
//  AddFocusView.swift
//  Fokus
//
//  Created by Patrick Lanham on 09.07.25.
//

import SwiftUI

struct AddFocusView: View {
    @ObservedObject var store: FocusStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var weakness = ""
    @State private var todos: [FocusTodoModel] = [FocusTodoModel(title: "")]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Titel
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Titel")
                            .headlineStyle()
                        TextField("Titel eingeben", text: $title)
                            .padding()
                            .background(Palette.card)
                            .cornerRadius(12)
                            .foregroundColor(Palette.textPrimary)
                    }

                    // Beschreibung
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Beschreibung")
                            .headlineStyle()
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .padding(8)
                            .background(Palette.card)
                            .cornerRadius(12)
                            .foregroundColor(Palette.textPrimary)
                    }

                    // Schwächen
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Schwächen")
                            .headlineStyle()
                        TextEditor(text: $weakness)
                            .frame(height: 100)
                            .padding(8)
                            .background(Palette.card)
                            .cornerRadius(12)
                            .foregroundColor(Palette.textPrimary)
                    }

                    // Todos
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ziele")
                            .headlineStyle()
                        
                        Button {
                            addTodo()
                        } label: {
                            Label("Ziel hinzufügen", systemImage: "plus.circle.fill")
                                .foregroundColor(Palette.accent)
                        }

                        ForEach($todos) { $todo in
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundColor(todo.isCompleted ? Palette.completed : Palette.textSecondary)
                                TextField("Todo", text: $todo.title)
                                    .padding(8)
                                    .background(Palette.background)
                                    .cornerRadius(8)
                            }
                        }
                        .onDelete(perform: deleteTodo)

                       
                    }
                    .padding()
                    .background(Palette.card)
                    .cornerRadius(16)

                    // Speichern
                    Button(action: saveFocus) {
                        Text("Speichern")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(title.isEmpty ? Palette.textSecondary : Palette.accent)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .font(.headline)
                    }
                    .disabled(title.isEmpty)
                }
                .padding()
            }
            .background(Palette.background)
            .navigationTitle("Neuer Fokus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(Palette.accent)
                }
            }
        }
    }

    private func addTodo() {
        withAnimation {
            todos.append(FocusTodoModel(title: ""))
        }
    }

    private func deleteTodo(at offsets: IndexSet) {
        withAnimation {
            todos.remove(atOffsets: offsets)
        }
    }

    private func saveFocus() {
        let newFocus = FocusItemModel(
            title: title,
            description: description,
            weakness: weakness,
            todos: todos.filter { !$0.title.isEmpty },
            completionDates: [Date()]
        )
        store.addFocus(newFocus)
        dismiss()
    }
}

#Preview {
    AddFocusView(store: FocusStore())
}
