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

    @State private var enableReminder: Bool
    @State private var reminderDate: Date
    @State private var repeatsDaily: Bool

    init(focus: Binding<FocusItemModel>, store: FocusStore) {
        self._focus = focus
        self.store = store
        self._title = State(initialValue: focus.wrappedValue.title)
        self._description = State(initialValue: focus.wrappedValue.description)
        self._weakness = State(initialValue: focus.wrappedValue.weakness)
        self._todos = State(initialValue: focus.wrappedValue.todos)
        self._enableReminder = State(initialValue: focus.wrappedValue.reminderDate != nil)
        self._reminderDate = State(initialValue: focus.wrappedValue.reminderDate ?? Date())
        self._repeatsDaily = State(initialValue: focus.wrappedValue.repeatsDaily)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Titel")
                            .headlineStyle()
                        TextField("Titel eingeben", text: $title)
                            .padding()
                            .background(Palette.card)
                            .cornerRadius(12)
                            .foregroundColor(Palette.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Beschreibung")
                            .headlineStyle()
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Palette.card)
                            .cornerRadius(12)
                            .foregroundColor(Palette.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Schwächen")
                            .headlineStyle()
                        TextEditor(text: $weakness)
                            .frame(height: 100)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Palette.card)
                            .cornerRadius(12)
                            .foregroundColor(Palette.textPrimary)
                    }

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

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Erinnerung aktivieren", isOn: $enableReminder)
                            .toggleStyle(SwitchToggleStyle(tint: Palette.accent))

                        if enableReminder {
                            VStack(alignment: .leading, spacing: 8) {
                                DatePicker("Uhrzeit", selection: $reminderDate, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)

                                Toggle("Täglich wiederholen", isOn: $repeatsDaily)
                                    .toggleStyle(SwitchToggleStyle(tint: Palette.accent))
                            }
                            .padding()
                            .background(Palette.card.opacity(0.7))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Palette.card)
                    .cornerRadius(16)

                    Button(action: saveChanges) {
                        Text("Änderungen speichern")
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
            .navigationTitle("Fokus bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
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
        var updatedFocus = FocusItemModel(
            id: focus.id,
            title: title,
            description: description,
            weakness: weakness,
            todos: todos.filter { !$0.title.isEmpty },
            completionDates: focus.completionDates,
            reminderDate: enableReminder ? reminderDate : nil,
            notificationID: focus.notificationID,
            repeatsDaily: enableReminder ? repeatsDaily : false
        )

        focus = updatedFocus
        store.updateFocus(updatedFocus)

        Task {
            if enableReminder {
                let id = try? await NotificationManager.shared.scheduleNotification(
                    title: "Focus Reminder",
                    body: title,
                    at: reminderDate,
                    repeatsDaily: repeatsDaily
                )

                updatedFocus.notificationID = id
                store.updateNotificationSettings(
                    for: updatedFocus.id,
                    notificationID: id ?? "",
                    repeatsDaily: repeatsDaily
                )
            } else if let notificationID = updatedFocus.notificationID {
                await NotificationManager.shared.cancelNotification(withID: notificationID)
                updatedFocus.notificationID = nil
                updatedFocus.reminderDate = nil
                store.updateNotificationSettings(
                    for: updatedFocus.id,
                    notificationID: nil,
                    repeatsDaily: false
                )
            }
        }

        dismiss()
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
