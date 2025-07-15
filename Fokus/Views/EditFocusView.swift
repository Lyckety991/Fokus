//
//  EditFocusView.swift
//  Fokus
//
//  Created by Patrick Lanham on 11.07.25.
//

import SwiftUI



struct EditFocusView: View {
    @Binding var focus: FocusItemModel
    @ObservedObject var store: FocusStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var weakness: String
    @State private var todos: [FocusTodoModel]
    
    init(focus: Binding<FocusItemModel>, store: FocusStore) {
        self._focus = focus
        self.store = store
        self._title = State(initialValue: focus.wrappedValue.title)
        self._description = State(initialValue: focus.wrappedValue.description)
        self._weakness = State(initialValue: focus.wrappedValue.weakness)
        self._todos = State(initialValue: focus.wrappedValue.todos)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Fokus Details").headlineStyle()) {
                    TextField("Titel", text: $title)
                        .titleStyle()
                    
                    VStack(alignment: .leading) {
                        Text("Beschreibung")
                            .bodyTextStyle()
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .background(Palette.card)
                            .cornerRadius(8)
                            .foregroundColor(Palette.textPrimary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading) {
                        Text("Schwächen")
                            .bodyTextStyle()
                        TextEditor(text: $weakness)
                            .frame(minHeight: 100)
                            .background(Palette.card)
                            .cornerRadius(8)
                            .foregroundColor(Palette.textPrimary)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Palette.background)
                
                Section(header: Text("Todos").headlineStyle()) {
                    ForEach($todos) { $todo in
                        HStack {
                            Button {
                                todo.isCompleted.toggle()
                            } label: {
                                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(todo.isCompleted ? Palette.completed : Palette.textSecondary)
                            }
                            
                            TextField("Todo-Beschreibung", text: $todo.title)
                                .bodyTextStyle()
                        }
                        .padding(8)
                        .background(Palette.card.opacity(0.5))
                        .cornerRadius(8)
                    }
                    .onDelete(perform: deleteTodo)
                    .listRowBackground(Palette.background)
                    
                    Button(action: addTodo) {
                        Label("Neues Todo hinzufügen", systemImage: "plus.circle.fill")
                            .foregroundColor(Palette.accent)
                    }
                    .listRowBackground(Palette.background)
                }
                
                Section {
                    Button(action: saveChanges) {
                        HStack {
                            Spacer()
                            Text("Änderungen speichern")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(title.isEmpty ? Palette.textSecondary : Palette.accent)
                        .cornerRadius(16)
                    }
                    .disabled(title.isEmpty)
                    .listRowBackground(Palette.background)
                }
            }
            .background(Palette.background)
            .navigationTitle("Fokus bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(Palette.accent)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
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
    
    private func saveChanges() {
        let updatedFocus = FocusItemModel(
            title: title,
            description: description,
            weakness: weakness,
            todos: todos.filter { !$0.title.isEmpty },
            completionDates: focus.completionDates
        )
        focus = updatedFocus
        store.updateFocus(updatedFocus)
    }
}
// MARK: - Preview
struct EditFocusView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var sampleFocus = FocusItemModel(
            title: "Produktivität steigern",
            description: "Täglich konzentriert arbeiten ohne Ablenkungen",
            weakness: "Social Media und häufiges Multitasking",
            todos: [
                FocusTodoModel(title: "Handy in den Flugmodus"),
                FocusTodoModel(title: "Alle Benachrichtigungen deaktivieren", isCompleted: true),
                FocusTodoModel(title: "Pomodoros einhalten")
            ],
            completionDates: [Date()]
        )
        
        // Mock Store für Preview
        class MockStore: FocusStore {
            override func updateFocus(_ focus: FocusItemModel) {
                print("Mock Update: \(focus.title)")
            }
        }
        
        var body: some View {
            EditFocusView(
                focus: $sampleFocus,
                store: MockStore()
            )
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
            .previewDisplayName("Bearbeitungsansicht")
            .previewLayout(.sizeThatFits)
    }
}
