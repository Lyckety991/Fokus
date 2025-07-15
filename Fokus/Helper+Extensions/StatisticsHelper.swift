//
//  StatisticsHelper.swift
//  Fokus
//
//  Created by Patrick Lanham on 15.07.25.
//

import Foundation


class StatisticsHelper {
    static func calculateFocusStatistics(for focus: FocusItemModel) -> FocusStatistics {
        var stats = FocusStatistics()
        
        // Berechne Streak
        stats.streak = calculateStreak(for: focus.completionDates)
        
        // Gesamtzahl der Abschlüsse
        stats.totalCompletions = focus.completionDates.count
        
        // Wöchentliche Abschlussrate
        let weeklyCompletions = focus.completionDates.filter {
            Calendar.current.dateComponents([.day], from: $0, to: Date()).day! <= 7
        }.count
        stats.weeklyCompletionRate = Double(weeklyCompletions) / 7.0
        
        // Monatliche Abschlussrate
        let monthlyCompletions = focus.completionDates.filter {
            Calendar.current.dateComponents([.day], from: $0, to: Date()).day! <= 30
        }.count
        stats.monthlyCompletionRate = Double(monthlyCompletions) / 30.0
        
        stats.completionHistory = focus.completionDates
        return stats
    }
    
    static func calculateGlobalStatistics(for focusItems: [FocusItemModel], totalXP: Int) -> GlobalStatistics {
        var stats = GlobalStatistics()
        
        // XP und Level
        stats.totalXP = totalXP
        stats.currentLevel = 1 + (totalXP / 100)
        
        // Gesamtzahl der Abschlüsse
        let totalCompletions = focusItems.flatMap { $0.completionDates }.count
        
        // Berechne täglichen Durchschnitt
        if let firstDate = focusItems.flatMap({ $0.completionDates }).min() {
            let days = Calendar.current.dateComponents([.day], from: firstDate, to: Date()).day! + 1
            stats.dailyAverage = Double(totalCompletions) / Double(days)
        }
        
        // Fokus-Abschlussrate
        let completedFocuses = focusItems.filter { $0.completionDates.contains(where: Calendar.current.isDateInToday) }.count
        stats.focusCompletionRate = Double(completedFocuses) / Double(focusItems.count)
        
        // Globaler Streak
        stats.streak = calculateGlobalStreak(for: focusItems)
        
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
        // Finde alle Tage mit mindestens einem Abschluss
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
}
