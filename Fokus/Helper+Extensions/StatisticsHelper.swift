//
//  StatisticsHelper.swift
//  Fokus
//
//  Created by Patrick Lanham on 15.07.25.
//

import Foundation

// MARK: - Deep Insights Datenmodelle

/// Aggregierte Insights über Nutzerverhalten und Performance
///
/// Enthält die wichtigsten Metriken für die Deep-Analytics-Ansicht,
/// inklusive beste Woche, Lieblingsfokus und personalisierte Insights.
struct DeepInsights {
    /// Anzahl der Abschlüsse in der besten Woche
    let bestWeekCompletions: Int
    
    /// Startdatum der besten Woche (nil wenn keine Daten vorhanden)
    let bestWeekDate: Date?
    
    /// Titel des am häufigsten abgeschlossenen Fokus
    let favoriteFocus: String
    
    /// Anzahl der Abschlüsse des Lieblingsfokus
    let favoriteFocusCount: Int
    
    /// Performance-Daten gruppiert nach Wochentagen
    let weekdayPerformance: [WeekdayPerformance]
    
    /// Personalisierte Motivations- und Achievement-Insights
    let insights: [PersonalizedInsight]
    
    /// Entwicklung der Abschlüsse im Vergleich zum Vormonat
    let monthlyTrend: TrendDirection
    
    /// Durchschnittliche Anzahl an Fokus-Sessions pro Tag
    let averageSessionsPerDay: Double
}

/// Performance-Metriken für einen spezifischen Wochentag
struct WeekdayPerformance {
    /// Name des Wochentags (z.B. "Montag")
    let weekday: String
    
    /// Durchschnittliche Abschlüsse an diesem Wochentag
    let averageCompletions: Double
    
    /// Gesamtanzahl aller Abschlüsse an diesem Wochentag
    let totalCompletions: Int
    
    /// Ranking des Wochentags (1 = bester Tag)
    let rank: Int
}

/// Einzelner personalisierter Insight für den Nutzer
struct PersonalizedInsight {
    /// Emoji zur visuellen Darstellung
    let emoji: String
    
    /// Überschrift des Insights
    let title: String
    
    /// Ausführliche Nachricht mit Details
    let message: String
    
    /// Kategorie des Insights für Filterung und Styling
    let type: InsightType
}

/// Kategorien für personalisierte Insights
enum InsightType {
    case motivation  /// Motivierende Nachricht
    case warning     /// Warnung bei negativen Trends
    case tip         /// Hilfreicher Tipp zur Verbesserung
    case achievement /// Erfolg oder Meilenstein
}

/// Trend-Richtung für Vergleichsdarstellungen
enum TrendDirection {
    case up      /// Aufwärtstrend (Verbesserung)
    case down    /// Abwärtstrend (Verschlechterung)
    case stable  /// Keine signifikante Änderung
    
    /// Emoji-Repräsentation des Trends
    var emoji: String {
        switch self {
        case .up: return "📈"
        case .down: return "📉"
        case .stable: return "➡️"
        }
    }
}

// MARK: - Statistik-Helper

/// Zentrale Klasse für die Berechnung und Aggregation aller Statistiken
///
/// Diese Klasse verarbeitet Fokus-Daten und generiert verschiedene Statistik-Ansichten:
/// - Fokus-spezifische Statistiken (Streaks, Completion Rates)
/// - Globale Nutzer-Statistiken (Level, XP, Achievements)
/// - Deep Insights (Trends, Wochentag-Performance, personalisierte Insights)
///
/// Alle Methoden sind statisch und thread-safe.
class StatisticsHelper {
    
    // MARK: - Fokus-Statistiken
    
    /// Berechnet detaillierte Statistiken für einen einzelnen Fokus
    ///
    /// - Parameter focus: Das FocusItemModel für das die Statistiken berechnet werden
    /// - Returns: FocusStatistics-Objekt mit Streak, Completion Rates und History
    ///
    /// Die Methode analysiert die Completion-Dates des Fokus und berechnet:
    /// - Aktuelle Streak (aufeinanderfolgende Tage)
    /// - Wöchentliche Completion Rate (Abschlüsse der letzten 7 Tage)
    /// - Monatliche Completion Rate (Abschlüsse der letzten 30 Tage)
    static func calculateFocusStatistics(for focus: FocusItemModel) -> FocusStatistics {
        var stats = FocusStatistics()
        let calendar = Calendar.current
        let now = Date()
        
        stats.streak = calculateStreak(for: focus.completionDates)
        stats.totalCompletions = focus.completionDates.count
        
        // Wöchentliche Rate: letzte 7 Tage inkl. heute
        let weeklyCompletions = focus.completionDates.filter {
            guard let days = calendar.dateComponents([.day], from: $0, to: now).day else { return false }
            return days >= 0 && days < 7
        }.count
        stats.weeklyCompletionRate = Double(weeklyCompletions) / 7.0
        
        // Monatliche Rate: letzte 30 Tage inkl. heute
        let monthlyCompletions = focus.completionDates.filter {
            guard let days = calendar.dateComponents([.day], from: $0, to: now).day else { return false }
            return days >= 0 && days < 30
        }.count
        stats.monthlyCompletionRate = Double(monthlyCompletions) / 30.0
        
        stats.completionHistory = focus.completionDates
        return stats
    }

    
    // MARK: - Globale Statistiken
    
    /// Berechnet übergreifende Statistiken über alle Fokusse eines Nutzers
    ///
    /// - Parameters:
    ///   - focusItems: Array aller FocusItemModels des Nutzers
    ///   - totalXP: Gesamt-XP des Nutzers
    /// - Returns: GlobalStatistics-Objekt mit Level, Durchschnittswerten und Achievements
    ///
    /// Aggregiert Daten über alle Fokusse und berechnet:
    /// - Aktuelles Level basierend auf XP
    /// - Durchschnittliche tägliche Abschlüsse
    /// - Aktuelle Completion Rate (heute abgeschlossene Fokusse)
    /// - Globale Streak über alle Fokusse
    /// - Freigeschaltete Achievements
    static func calculateGlobalStatistics(for focusItems: [FocusItemModel], totalXP: Int) -> GlobalStatistics {
        var stats = GlobalStatistics()
        stats.totalXP = totalXP
        stats.currentLevel = 1 + (totalXP / 100)
        
        let allDates = focusItems.flatMap { $0.completionDates }
        let totalCompletions = allDates.count
        
        if let firstDate = allDates.min() {
            let days = Calendar.current.dateComponents([.day], from: firstDate, to: Date()).day! + 1
            stats.dailyAverage = Double(totalCompletions) / Double(days)
        }
        
        let completedFocusesToday = focusItems.filter {
            $0.completionDates.contains(where: Calendar.current.isDateInToday)
        }.count
        
        stats.focusCompletionRate = focusItems.isEmpty ? 0 : Double(completedFocusesToday) / Double(focusItems.count)
        stats.streak = calculateGlobalStreak(for: focusItems)
        
       
        stats.achievements = AchievementEngine.buildAchievements(
            totalXP: totalXP,
            streak: stats.streak,
            totalCompletions: totalCompletions,
            focusCount: focusItems.count
        )
        
        return stats
    }

    
    // MARK: - Deep Insights
    
    /// Generiert umfassende Insights über Nutzerverhalten und Performance-Muster
    ///
    /// - Parameter focusItems: Array aller FocusItemModels des Nutzers
    /// - Returns: DeepInsights-Objekt mit allen Analytics-Daten
    ///
    /// Diese Methode ist das Herzstück der Deep-Analytics und berechnet:
    /// - Beste Woche (höchste Anzahl an Abschlüssen)
    /// - Lieblingsfokus (am häufigsten abgeschlossen)
    /// - Wochentag-Performance (welche Tage sind am produktivsten)
    /// - Personalisierte Insights (Motivationen, Warnungen, Tipps)
    /// - Monatstrend (Vergleich mit Vormonat)
    /// - Durchschnittliche Sessions pro Tag
    ///
    /// Die Methode ist robust gegen leere Daten und liefert sinnvolle Fallback-Werte.
    static func calculateDeepInsights(for focusItems: [FocusItemModel]) -> DeepInsights {
        // Fallback für komplett neue Nutzer ohne Fokusse
        guard !focusItems.isEmpty else {
            return DeepInsights(
                bestWeekCompletions: 0,
                bestWeekDate: nil,
                favoriteFocus: "Noch kein Fokus",
                favoriteFocusCount: 0,
                weekdayPerformance: [],
                insights: [
                    PersonalizedInsight(
                        emoji: "🚀",
                        title: "Bereit für den Start",
                        message: "Erstelle deinen ersten Fokus und beginne deine Reise!",
                        type: .motivation
                    )
                ],
                monthlyTrend: .stable,
                averageSessionsPerDay: 0.0
            )
        }
        
        let allCompletions = focusItems.flatMap { $0.completionDates }
        
        // Fallback für Nutzer mit Fokussen aber ohne Abschlüsse
        guard !allCompletions.isEmpty else {
            return DeepInsights(
                bestWeekCompletions: 0,
                bestWeekDate: nil,
                favoriteFocus: focusItems.first?.title ?? "Unbekannt",
                favoriteFocusCount: 0,
                weekdayPerformance: [],
                insights: [
                    PersonalizedInsight(
                        emoji: "🎯",
                        title: "Zeit zu starten",
                        message: "Du hast \(focusItems.count) Fokus\(focusItems.count == 1 ? "" : "se") - Zeit für den ersten Abschluss!",
                        type: .motivation
                    )
                ],
                monthlyTrend: .stable,
                averageSessionsPerDay: 0.0
            )
        }
        
        // Normale Berechnung mit vollständigen Daten
        return DeepInsights(
            bestWeekCompletions: calculateBestWeekCompletions(from: allCompletions),
            bestWeekDate: findBestWeekDate(from: allCompletions),
            favoriteFocus: findFavoriteFocus(from: focusItems),
            favoriteFocusCount: findFavoriteFocusCount(from: focusItems),
            weekdayPerformance: calculateWeekdayPerformance(from: allCompletions),
            insights: generatePersonalizedInsights(for: focusItems),
            monthlyTrend: calculateMonthlyTrend(from: allCompletions),
            averageSessionsPerDay: calculateAverageSessionsPerDay(from: allCompletions)
        )
    }
    
    // MARK: - Beste Woche Berechnung
    
    /// Findet die Anzahl der Abschlüsse in der besten Woche
    ///
    /// - Parameter dates: Array aller Completion-Dates
    /// - Returns: Höchste Anzahl an Abschlüssen in einer einzelnen Woche
    ///
    /// - Note: Die Berechnung ist auf die letzten 365 Tage limitiert für Performance
    private static func calculateBestWeekCompletions(from dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let recentDates = dates.filter { $0 >= oneYearAgo }
        
        guard !recentDates.isEmpty else { return 0 }
        
        // Gruppiere Dates nach Wochen und zähle Abschlüsse
        var weekCounts: [Date: Int] = [:]
        
        for date in recentDates {
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start {
                weekCounts[weekStart, default: 0] += 1
            }
        }
        
        return weekCounts.values.max() ?? 0
    }
    
    /// Findet das Startdatum der besten Woche
    ///
    /// - Parameter dates: Array aller Completion-Dates
    /// - Returns: Startdatum (Montag) der Woche mit den meisten Abschlüssen
    ///
    /// - Note: Die Berechnung ist auf die letzten 365 Tage limitiert für Performance
    private static func findBestWeekDate(from dates: [Date]) -> Date? {
        guard !dates.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let recentDates = dates.filter { $0 >= oneYearAgo }
        
        guard !recentDates.isEmpty else { return nil }
        
        var weekCounts: [Date: Int] = [:]
        
        for date in recentDates {
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start {
                weekCounts[weekStart, default: 0] += 1
            }
        }
        
        return weekCounts.max { $0.value < $1.value }?.key
    }
    
    // MARK: - Lieblingsfokus
    
    /// Identifiziert den am häufigsten abgeschlossenen Fokus
    ///
    /// - Parameter focusItems: Array aller FocusItemModels
    /// - Returns: Titel des Fokus mit den meisten Abschlüssen
    private static func findFavoriteFocus(from focusItems: [FocusItemModel]) -> String {
        guard !focusItems.isEmpty else { return "Noch kein Fokus" }
        
        let favorite = focusItems.max { $0.completionDates.count < $1.completionDates.count }
        return favorite?.title ?? "Unbekannt"
    }
    
    /// Gibt die Anzahl der Abschlüsse des Lieblingsfokus zurück
    ///
    /// - Parameter focusItems: Array aller FocusItemModels
    /// - Returns: Anzahl der Abschlüsse des am häufigsten abgeschlossenen Fokus
    private static func findFavoriteFocusCount(from focusItems: [FocusItemModel]) -> Int {
        guard !focusItems.isEmpty else { return 0 }
        
        let favorite = focusItems.max { $0.completionDates.count < $1.completionDates.count }
        return favorite?.completionDates.count ?? 0
    }
    
    // MARK: - Wochentag-Performance
    
    /// Analysiert die Performance nach Wochentagen
    ///
    /// - Parameter dates: Array aller Completion-Dates
    /// - Returns: Array von WeekdayPerformance, sortiert nach Rank (beste zuerst)
    ///
    /// Berechnet für jeden Wochentag:
    /// - Gesamtanzahl der Abschlüsse
    /// - Durchschnittliche Abschlüsse pro Vorkommen des Wochentags
    /// - Ranking im Vergleich zu anderen Wochentagen
    private static func calculateWeekdayPerformance(from dates: [Date]) -> [WeekdayPerformance] {
        guard !dates.isEmpty else { return [] }
        
        let calendar = Calendar.current
        var weekdayData: [Int: [Date]] = [:]
        
        // Gruppiere Dates nach Wochentagen (1 = Sonntag, 7 = Samstag)
        for date in dates {
            let weekday = calendar.component(.weekday, from: date)
            weekdayData[weekday, default: []].append(date)
        }
        
        // Berechne Performance-Metriken
        let performances: [WeekdayPerformance] = weekdayData.map { weekday, dates in
            let weekdayName = calendar.weekdaySymbols[weekday - 1]
            let totalCompletions = dates.count
            
            // Berechne wie oft dieser Wochentag in der Zeitspanne vorkam
            let allDates = Set(dates.map { calendar.startOfDay(for: $0) })
            let uniqueDays = allDates.count
            let averageCompletions = Double(totalCompletions) / Double(max(uniqueDays, 1))
            
            return WeekdayPerformance(
                weekday: weekdayName,
                averageCompletions: averageCompletions,
                totalCompletions: totalCompletions,
                rank: 0 // Wird nachträglich gesetzt
            )
        }
        
        // Sortiere nach durchschnittlichen Abschlüssen und weise Ranks zu
        let sortedPerformances = performances.sorted { $0.averageCompletions > $1.averageCompletions }
        
        return sortedPerformances.enumerated().map { index, performance in
            WeekdayPerformance(
                weekday: performance.weekday,
                averageCompletions: performance.averageCompletions,
                totalCompletions: performance.totalCompletions,
                rank: index + 1
            )
        }
    }
    
    // MARK: - Personalisierte Insights
    
    /// Generiert personalisierte Insights basierend auf Nutzerverhalten
    ///
    /// - Parameter focusItems: Array aller FocusItemModels
    /// - Returns: Array von maximal 3 personalisierten Insights
    ///
    /// Die Insights werden dynamisch generiert basierend auf:
    /// - Aktuellem Streak-Status
    /// - Wochentag-Performance (bester/schlechtester Tag)
    /// - Lieblingsfokus
    /// - Monatstrend
    ///
    /// Die Methode priorisiert wichtige Informationen und wählt die relevantesten 3 aus.
    private static func generatePersonalizedInsights(for focusItems: [FocusItemModel]) -> [PersonalizedInsight] {
        var insights: [PersonalizedInsight] = []
        let allCompletions = focusItems.flatMap { $0.completionDates }
        
        guard !allCompletions.isEmpty else {
            return [
                PersonalizedInsight(
                    emoji: "🎯",
                    title: "Los geht's!",
                    message: "Zeit für deinen ersten Fokus-Abschluss!",
                    type: .motivation
                )
            ]
        }
        
        // Streak-basierte Insights
        let globalStreak = calculateGlobalStreak(for: focusItems)
        
        if globalStreak >= 7 {
            insights.append(PersonalizedInsight(
                emoji: "🔥",
                title: "On Fire!",
                message: "Du hast eine \(globalStreak)-Tage-Serie! Behalte den Rhythmus bei.",
                type: .achievement
            ))
        } else if globalStreak == 0 {
            insights.append(PersonalizedInsight(
                emoji: "💪",
                title: "Zeit für einen Neustart",
                message: "Starte heute eine neue Serie - du schaffst das!",
                type: .motivation
            ))
        }
        
        // Wochentag-Performance Insights
        let weekdayPerformance = calculateWeekdayPerformance(from: allCompletions)
        
        if let bestDay = weekdayPerformance.first, bestDay.totalCompletions > 3 {
            insights.append(PersonalizedInsight(
                emoji: "⭐️",
                title: "Power-Tag identifiziert",
                message: "\(bestDay.weekday) ist dein stärkster Tag mit durchschnittlich \(String(format: "%.1f", bestDay.averageCompletions)) Abschlüssen!",
                type: .tip
            ))
        }
        
        if let worstDay = weekdayPerformance.last, worstDay.totalCompletions > 0 {
            insights.append(PersonalizedInsight(
                emoji: "💡",
                title: "Verbesserungspotenzial",
                message: "\(worstDay.weekday) könnte dein Durchbruch-Tag werden - plane hier mehr ein!",
                type: .tip
            ))
        }
        
        // Trend-basierte Insights
        let trend = calculateMonthlyTrend(from: allCompletions)
        
        if trend == .up {
            insights.append(PersonalizedInsight(
                emoji: "📈",
                title: "Aufwärtstrend!",
                message: "Du hast dich diesen Monat gesteigert - großartige Entwicklung!",
                type: .achievement
            ))
        } else if trend == .down {
            insights.append(PersonalizedInsight(
                emoji: "🎯",
                title: "Zurück auf Kurs",
                message: "Deine Abschlüsse sind gesunken - Zeit für neuen Fokus!",
                type: .motivation
            ))
        }
        
        // Lieblingsfokus Insight
        let favoriteFocusCount = findFavoriteFocusCount(from: focusItems)
        let favoriteFocus = findFavoriteFocus(from: focusItems)
        
        if favoriteFocusCount > 2 {
            insights.append(PersonalizedInsight(
                emoji: "❤️",
                title: "Lieblingsfokus",
                message: "\(favoriteFocus) liegt dir besonders - \(favoriteFocusCount) Abschlüsse!",
                type: .achievement
            ))
        }
        
        // Fallback wenn keine Insights generiert wurden
        if insights.isEmpty {
            insights.append(PersonalizedInsight(
                emoji: "🎯",
                title: "Weiter so!",
                message: "Du bist auf einem guten Weg. Jeden Abschluss bringt dich deinen Zielen näher!",
                type: .motivation
            ))
        }
        
        return Array(insights.prefix(3)) // Maximal 3 Insights anzeigen
    }
    
    // MARK: - Trend-Berechnung
    
    /// Berechnet den Trend durch Vergleich des aktuellen mit dem vorherigen Monat
    ///
    /// - Parameter dates: Array aller Completion-Dates
    /// - Returns: TrendDirection (.up, .down oder .stable)
    ///
    /// Vergleicht die Anzahl der Abschlüsse im aktuellen Monat mit dem Vormonat.
    /// Bei gleicher Anzahl wird .stable zurückgegeben.
    private static func calculateMonthlyTrend(from dates: [Date]) -> TrendDirection {
        guard !dates.isEmpty else { return .stable }
        
        let calendar = Calendar.current
        let now = Date()
        
        let thisMonthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) ?? now
        
        // Abschlüsse des aktuellen Monats
        let thisMonth = dates.filter { date in
            calendar.compare(date, to: thisMonthStart, toGranularity: .day) != .orderedAscending &&
            calendar.compare(date, to: now, toGranularity: .day) != .orderedDescending
        }.count
        
        // Abschlüsse des vorherigen Monats
        let lastMonth = dates.filter { date in
            calendar.compare(date, to: lastMonthStart, toGranularity: .day) != .orderedAscending &&
            calendar.compare(date, to: thisMonthStart, toGranularity: .day) == .orderedAscending
        }.count
        
        if thisMonth > lastMonth {
            return .up
        } else if thisMonth < lastMonth {
            return .down
        } else {
            return .stable
        }
    }
    
    // MARK: - Durchschnittliche Sessions
    
    /// Berechnet die durchschnittliche Anzahl an Sessions pro Tag
    ///
    /// - Parameter dates: Array aller Completion-Dates
    /// - Returns: Durchschnittliche Sessions pro Tag seit dem ersten Abschluss
    ///
    /// Die Berechnung berücksichtigt die komplette Zeitspanne vom ersten bis zum
    /// heutigen Datum, nicht nur die Tage mit Abschlüssen.
    private static func calculateAverageSessionsPerDay(from dates: [Date]) -> Double {
        guard !dates.isEmpty, let firstDate = dates.min() else { return 0.0 }
        
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: firstDate, to: Date()).day ?? 0
        let totalDays = max(days + 1, 1) // Mindestens 1 Tag
        
        return Double(dates.count) / Double(totalDays)
    }
    
    // MARK: - Streak-Berechnungen
    
    /// Berechnet die aktuelle Streak für einen einzelnen Fokus
    ///
    /// - Parameter dates: Array der Completion-Dates eines Fokus
    /// - Returns: Anzahl aufeinanderfolgender Tage mit Abschlüssen
    ///
    /// Die Streak startet beim letzten Datum und zählt rückwärts,
    /// solange für jeden vorherigen Tag ein Abschluss existiert.
    // Gemeinsame Hilfsfunktion
    private static func calculateAnchoredStreak(from dates: [Date]) -> Int {
        let calendar = Calendar.current
        let normalizedDays = Set(dates.map { calendar.startOfDay(for: $0) })
        guard !normalizedDays.isEmpty else { return 0 }
        
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let start: Date
        if normalizedDays.contains(today) {
            start = today
        } else if normalizedDays.contains(yesterday) {
            start = yesterday
        } else {
            // Letzter Abschluss liegt weiter zurück → keine aktive Streak
            return 0
        }
        
        var streak = 0
        var probe = start
        
        while normalizedDays.contains(probe) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: probe) else { break }
            probe = prev
        }
        
        return streak
    }

    // Einzelner Fokus
    private static func calculateStreak(for dates: [Date]) -> Int {
        return calculateAnchoredStreak(from: dates)
    }

    // Globale Streak über alle Fokusse
    private static func calculateGlobalStreak(for focusItems: [FocusItemModel]) -> Int {
        let allDates = focusItems.flatMap { $0.completionDates }
        return calculateAnchoredStreak(from: allDates)
    }

    


}
