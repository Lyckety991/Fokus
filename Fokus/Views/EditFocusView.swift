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
    @State private var isSaving: Bool = false

    init(focus: Binding<FocusItemModel>, store: FocusStore) {
        self._focus = focus
        self.store = store
        self._title = State(initialValue: focus.wrappedValue.title)
        self._description = State(initialValue: focus.wrappedValue.description)
        self._weakness = State(initialValue: focus.wrappedValue.weakness)
        self._todos = State(initialValue: focus.wrappedValue.todos)
        self._enableReminder = State(initialValue: focus.wrappedValue.reminderDate != nil)
        self._reminderDate = State(initialValue: focus.wrappedValue.reminderDate ?? Date())
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
                        Text("Beschreibe deinen Fokus in wenigen Sätzen.")
                            .foregroundStyle(.secondary)
                            .font(.caption)
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
                        Text("Beschreibe hier deine Schwächen, damit du sie in deiner Actionplan besser überwinden kannst.")
                            .foregroundStyle(.secondary)
                            .font(.caption)
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
                        Text("Füge hier deine Ziele hinzu um den Fokus höhher zu halten")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(Palette.card)
                    .cornerRadius(16)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Toggle("Tägliche Erinnerung", isOn: $enableReminder)
                                .toggleStyle(SwitchToggleStyle(tint: Palette.accent))
                                .disabled(isSaving)
                        }

                        if enableReminder {
                            VStack(alignment: .leading, spacing: 8) {
                                DatePicker("Uhrzeit", selection: $reminderDate, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .disabled(isSaving)

                                // Info-Text für bessere UX
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(Palette.accent)
                                        .font(.caption)
                                    Text("Erinnerung wird täglich zur eingestellten Zeit wiederholt")
                                        .font(.caption)
                                        .foregroundColor(Palette.textSecondary)
                                }
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
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Speichere...")
                            } else {
                                Text("Änderungen speichern")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(title.isEmpty || isSaving ? Palette.textSecondary : Palette.accent)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .font(.headline)
                    }
                    .disabled(title.isEmpty || isSaving)
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .background(Palette.background)
            .navigationTitle("Fokus bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(Palette.accent)
                    .disabled(isSaving)
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
        guard !isSaving else { return }
        isSaving = true
        
        Task {
            // Erstelle das Update-Objekt
            var updatedFocus = FocusItemModel(
                id: focus.id,
                title: title,
                description: description,
                weakness: weakness,
                todos: todos.filter { !$0.title.isEmpty },
                completionDates: focus.completionDates,
                reminderDate: nil,
                notificationID: focus.notificationID,
                repeatsDaily: false
            )
            
            // Handle Notifications BEFORE updating the focus
            if enableReminder {
                if let oldNotificationID = focus.notificationID {
                    print("🗑️ Lösche alte Notification: \(oldNotificationID)")
                    await NotificationManager.shared.cancelNotification(withID: oldNotificationID)
                }
                
                // Erstelle neue Notification
                do {
                    print("⏰ Erstelle neue Notification für: \(title)")
                    let newNotificationID = try await NotificationManager.shared.scheduleNotification(
                        title: "Fokus Erinnerung",
                        body: title,
                        at: reminderDate,
                        repeatsDaily: true
                    )
                    
                    // Update mit neuer Notification
                    updatedFocus.notificationID = newNotificationID
                    updatedFocus.reminderDate = reminderDate
                    updatedFocus.repeatsDaily = true
                    
                    print("✅ Neue Notification erstellt mit ID: \(newNotificationID)")
                    
                } catch {
                    print("❌ Fehler beim Erstellen der Notification: \(error)")
                    // Fallback: Speichere ohne Notification
                    updatedFocus.notificationID = nil
                    updatedFocus.reminderDate = nil
                    updatedFocus.repeatsDaily = false
                }
                
            } else {
                // Notification ausschalten - lösche bestehende
                if let existingNotificationID = focus.notificationID, !existingNotificationID.isEmpty {
                    print("🗑️ Lösche Notification (Reminder deaktiviert): \(existingNotificationID)")
                    await NotificationManager.shared.cancelNotification(withID: existingNotificationID)
                }
                
                // Setze alle notification-bezogenen Felder zurück
                updatedFocus.notificationID = nil
                updatedFocus.reminderDate = nil
                updatedFocus.repeatsDaily = false
                
                print("✅ Notification erfolgreich deaktiviert und gelöscht")
            }
            
            // Aktualisiere die lokale Referenz und den Store
            await MainActor.run {
                focus = updatedFocus
                store.updateFocus(updatedFocus)
                
                // Zusätzliche Store-Updates für Notification-Settings
                store.updateNotificationSettings(
                    for: updatedFocus.id,
                    notificationID: updatedFocus.notificationID,
                    repeatsDaily: updatedFocus.repeatsDaily
                )
                
                isSaving = false
                dismiss()
            }
        }
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
                // updateNotificationSettings wird automatisch von der Parent-Klasse aufgerufen
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
