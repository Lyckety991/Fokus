//
//  FocusModel.swift
//  Fokus
//
//  Created by Patrick Lanham on 07.07.25.
//

import Foundation

// MARK: - Korrigierte Modelle
struct UserProgressModel {
    var totalXP: Int = 0
    var currentLevel: Int { 1 + (totalXP / 100) }
}

struct FocusTodoModel: Identifiable, Hashable {
    let id: UUID // ✅ Explizite ID
    var title: String
    var isCompleted: Bool
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

// Anpassung des Models für Completion-Historie
struct FocusItemModel: Identifiable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var weakness: String
    var todos: [FocusTodoModel]
    var completionDates: [Date]
    
    // 🔔 Reminder-Handling
    var reminderDate: Date?            // Wann erinnert werden soll
    var notificationID: String?        // Für das Löschen der Notification
    var repeatsDaily: Bool             // Ob täglich erinnert werden soll

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        weakness: String,
        todos: [FocusTodoModel] = [],
        completionDates: [Date] = [],
        reminderDate: Date? = nil,
        notificationID: String? = nil,
        repeatsDaily: Bool = false      // Default = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.weakness = weakness
        self.todos = todos
        self.completionDates = completionDates
        self.reminderDate = reminderDate
        self.notificationID = notificationID
        self.repeatsDaily = repeatsDaily
    }

    var lastCompletionDate: Date? {
        completionDates.max()
    }
}

// MARK: - Statistik-Modelle
struct FocusStatistics {
    var streak: Int = 0
    var totalCompletions: Int = 0
    var weeklyCompletionRate: Double = 0.0
    var monthlyCompletionRate: Double = 0.0
    var completionHistory: [Date] = []
}

struct GlobalStatistics {
    var totalXP: Int = 0
    var currentLevel: Int = 0
    var focusCompletionRate: Double = 0.0
    var dailyAverage: Double = 0.0
    var streak: Int = 0
    var achievements: [Achievement] = []
}

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let progress: Double
    let isUnlocked: Bool
}
