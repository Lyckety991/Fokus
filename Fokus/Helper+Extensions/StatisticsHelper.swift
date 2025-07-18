//
//  StatisticsHelper.swift
//  Fokus
//
//  Created by Patrick Lanham on 15.07.25.
//

import Foundation


// MARK: - Statistik-Helfer
class StatisticsHelper {
    static func calculateFocusStatistics(for focus: FocusItemModel) -> FocusStatistics {
        var stats = FocusStatistics()
        
        stats.streak = calculateStreak(for: focus.completionDates)
        stats.totalCompletions = focus.completionDates.count
        
        // Wöchentliche Rate
        let weeklyCompletions = focus.completionDates.filter {
            Calendar.current.dateComponents([.day], from: $0, to: Date()).day! <= 7
        }.count
        stats.weeklyCompletionRate = Double(weeklyCompletions) / 7.0
        
        // Monatliche Rate
        let monthlyCompletions = focus.completionDates.filter {
            Calendar.current.dateComponents([.day], from: $0, to: Date()).day! <= 30
        }.count
        stats.monthlyCompletionRate = Double(monthlyCompletions) / 30.0
        
        stats.completionHistory = focus.completionDates
        return stats
    }
    
    static func calculateGlobalStatistics(for focusItems: [FocusItemModel], totalXP: Int) -> GlobalStatistics {
        var stats = GlobalStatistics()
        stats.totalXP = totalXP
        stats.currentLevel = 1 + (totalXP / 100)
        
        // Gesamtabschlüsse
        let totalCompletions = focusItems.flatMap { $0.completionDates }.count
        
        // Täglicher Durchschnitt
        if let firstDate = focusItems.flatMap({ $0.completionDates }).min() {
            let days = Calendar.current.dateComponents([.day], from: firstDate, to: Date()).day! + 1
            stats.dailyAverage = Double(totalCompletions) / Double(days)
        }
        
        // Aktuelle Abschlussrate
        let completedFocuses = focusItems.filter { $0.completionDates.contains(where: Calendar.current.isDateInToday) }.count
        stats.focusCompletionRate = focusItems.isEmpty ? 0 : Double(completedFocuses) / Double(focusItems.count)
        
        // Streak
        stats.streak = calculateGlobalStreak(for: focusItems)
        
        // Achievements
        stats.achievements = calculateAchievements(
            totalXP: totalXP,
            streak: stats.streak,
            totalCompletions: totalCompletions,
            focusCount: focusItems.count
        )
        
        return stats
    }
    
    private static func calculateStreak(for dates: [Date]) -> Int {
        let sortedDates = dates.sorted(by: >)
        guard let lastDate = sortedDates.first else { return 0 }
        
        var streak = 1
        var currentDate = lastDate
        
        for date in sortedDates.dropFirst() {
            guard let nextDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDate),
                  Calendar.current.isDate(date, inSameDayAs: nextDay) else { break }
            
            streak += 1
            currentDate = date
        }
        
        return streak
    }
    
    private static func calculateGlobalStreak(for focusItems: [FocusItemModel]) -> Int {
        let completionDays = Set(focusItems.flatMap { $0.completionDates }.map {
            Calendar.current.startOfDay(for: $0)
        }).sorted(by: >)
        
        guard let lastDate = completionDays.first else { return 0 }
        
        var streak = 1
        var currentDate = lastDate
        
        for date in completionDays.dropFirst() {
            guard let nextDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDate),
                  Calendar.current.isDate(date, inSameDayAs: nextDay) else { break }
            
            streak += 1
            currentDate = date
        }
        
        return streak
    }
    
    private static func calculateAchievements(
        totalXP: Int,
        streak: Int,
        totalCompletions: Int,
        focusCount: Int
    ) -> [Achievement] {
        var achievements: [Achievement] = []
        
        // XP Achievements
        achievements.append(Achievement(
            title: "Neuling",
            description: "Erreiche 100 XP",
            icon: "star.fill",
            progress: min(Double(totalXP) / 100, 1.0),
            isUnlocked: totalXP >= 100
        ))
        
        achievements.append(Achievement(
            title: "Erfahren",
            description: "Erreiche 500 XP",
            icon: "star.circle.fill",
            progress: min(Double(totalXP) / 500, 1.0),
            isUnlocked: totalXP >= 500
        ))
        
        achievements.append(Achievement(
            title: "Meister",
            description: "Erreiche 1000 XP",
            icon: "rosette",
            progress: min(Double(totalXP) / 1000, 1.0),
            isUnlocked: totalXP >= 1000
        ))
        
        // Streak Achievements
        achievements.append(Achievement(
            title: "Durchstarter",
            description: "3-Tage-Serie",
            icon: "flame",
            progress: min(Double(streak) / 3, 1.0),
            isUnlocked: streak >= 3
        ))
        
        achievements.append(Achievement(
            title: "Konsequent",
            description: "7-Tage-Serie",
            icon: "flame.fill",
            progress: min(Double(streak) / 7, 1.0),
            isUnlocked: streak >= 7
        ))
        
        achievements.append(Achievement(
            title: "Unaufhaltsam",
            description: "30-Tage-Serie",
            icon: "bolt.fill",
            progress: min(Double(streak) / 30, 1.0),
            isUnlocked: streak >= 30
        ))
        
        // Completion Achievements
        achievements.append(Achievement(
            title: "Erster Schritt",
            description: "10 Abschlüsse",
            icon: "checkmark.circle",
            progress: min(Double(totalCompletions) / 10, 1.0),
            isUnlocked: totalCompletions >= 10
        ))
        
        achievements.append(Achievement(
            title: "Vollprofi",
            description: "50 Abschlüsse",
            icon: "checkmark.circle.fill",
            progress: min(Double(totalCompletions) / 50, 1.0),
            isUnlocked: totalCompletions >= 50
        ))
        
        // Focus Achievements
        achievements.append(Achievement(
            title: "Multitasker",
            description: "5 aktive Fokusse",
            icon: "square.grid.2x2.fill",
            progress: min(Double(focusCount) / 5, 1.0),
            isUnlocked: focusCount >= 5
        ))
        
        return achievements
    }
}
