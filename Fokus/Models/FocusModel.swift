//
//  FocusModel.swift
//  Fokus
//
//  Created by Patrick Lanham on 07.07.25.
//

import Foundation

// MARK: - User Progress

struct UserProgressModel {
    var totalXP: Int = 0
    var currentLevel: Int { 1 + (totalXP / 100) }
}

// MARK: - Todo Model

struct FocusTodoModel: Identifiable, Hashable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

// MARK: - Focus Item Model

struct FocusItemModel: Identifiable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var weakness: String
    var todos: [FocusTodoModel]
    var completionDates: [Date]
    
    var reminderDate: Date?
    var notificationID: String?
    var repeatsDaily: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        weakness: String,
        todos: [FocusTodoModel] = [],
        completionDates: [Date] = [],
        reminderDate: Date? = nil,
        notificationID: String? = nil,
        repeatsDaily: Bool = false
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

// MARK: - Achievement Rarity (Model)

enum AchievementRarity: String {
    case common     // Gewöhnlich
    case rare       // Selten
    case legendary  // Legendär
}

// MARK: - Achievement Metric

enum AchievementMetric {
    case xp
    case streak
    case completions
    case focusCount
}

// MARK: - Achievement Model

struct Achievement: Identifiable {
    let id = UUID()
    
    /// Titel des Erfolgs (z.B. "Gewohnheitsprofi")
    let title: String
    
    /// Kurze Beschreibung, was der Erfolg aussagt
    let description: String
    
    /// SF Symbol Name für das Icon
    let icon: String
    
    /// Fortschritt 0.0 – 1.0
    let progress: Double
    
    /// Ob der Erfolg bereits freigeschaltet ist
    let isUnlocked: Bool
    
    /// Zielwert (z.B. 75 Abschlüsse)
    let goalValue: Int
    
    /// Aktueller Wert des Users (z.B. aktuelle Abschlüsse)
    let currentValue: Int
    
    /// Seltenheit des Erfolgs
    let rarity: AchievementRarity
    
    /// Kategorie (z.B. "Abschlüsse", "Konstanz", "Erfahrung")
    let category: String
    
    /// Text, der in der Detail-View bei „Anforderung“ steht
    let requirement: String
    
    /// Text, der in der Detail-View bei „Tipp“ steht
    let tip: String
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
