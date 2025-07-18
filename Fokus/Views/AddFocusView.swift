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

    @State private var enableReminder = false
    @State private var reminderDate = Date()
    @State private var repeatsDaily = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    titleField
                    descriptionField
                    weaknessField
                    todosSection
                    reminderSection
                    saveButton
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

    // MARK: - UI-Bausteine

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Titel").headlineStyle()
            TextField("Titel eingeben", text: $title)
                .padding()
                .background(Palette.card)
                .cornerRadius(12)
                .foregroundColor(Palette.textPrimary)
        }
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Beschreibung").headlineStyle()
            TextEditor(text: $description)
                .frame(height: 100)
                .padding(8)
                .background(Palette.card)
                .cornerRadius(12)
                .foregroundColor(Palette.textPrimary)
        }
    }

    private var weaknessField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Schwächen").headlineStyle()
            TextEditor(text: $weakness)
                .frame(height: 100)
                .padding(8)
                .background(Palette.card)
                .cornerRadius(12)
                .foregroundColor(Palette.textPrimary)
        }
    }

    private var todosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ziele").headlineStyle()

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
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Erinnerung aktivieren", isOn: $enableReminder)
                .toggleStyle(SwitchToggleStyle(tint: Palette.accent))

            if enableReminder {
                VStack(alignment: .leading, spacing: 8) {
                    DatePicker(
                        "Uhrzeit",
                        selection: $reminderDate,
                        displayedComponents: .hourAndMinute
                    )
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
    }

    private var saveButton: some View {
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

    // MARK: - Aktionen

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
        var newFocus = FocusItemModel(
            title: title,
            description: description,
            weakness: weakness,
            todos: todos.filter { !$0.title.isEmpty },
            completionDates: [],
            reminderDate: enableReminder ? reminderDate : nil,
            notificationID: nil,
            repeatsDaily: enableReminder ? repeatsDaily : false
        )

        store.addFocus(newFocus)

        if enableReminder {
            Task {
                let id = await scheduleNotification(for: newFocus)
                // Nachträglich ID setzen
                if let id = id {
                    store.updateNotificationSettings(
                        for: newFocus.id,
                        notificationID: id,
                        repeatsDaily: repeatsDaily
                    )
                }
            }
        }

        dismiss()
    }

    private func scheduleNotification(for focus: FocusItemModel) async -> String? {
        guard let reminderDate = focus.reminderDate else { return nil }

        do {
            let id = try await NotificationManager.shared.scheduleNotification(
                title: "Fokus Erinnerung",
                body: focus.title,
                at: reminderDate,
                repeatsDaily: focus.repeatsDaily ?? false
            )
            return id
        } catch {
            print("❌ Fehler beim Planen: \(error.localizedDescription)")
            return nil
        }
    }
}

#Preview {
    AddFocusView(store: FocusStore())
}
