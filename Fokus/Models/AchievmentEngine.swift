//
//  AchievmentEngine.swift
//  Fokus
//
//  Created by Patrick Lanham on 16.11.25.
//

import Foundation




/// Statische Definition einer Achievement-Vorlage
private struct AchievementDefinition {
    let title: String
    let description: String
    let icon: String
    let rarity: AchievementRarity
    let category: String
    let requirement: String
    let tip: String
    let metric: AchievementMetric
    let goalValue: Int
}

enum AchievementEngine {
    
    // Alle Erfolge an EINER Stelle definiert
    private static let definitions: [AchievementDefinition] = [
        // 8 Gewöhnliche
        .init(
            title: "Erster Schritt",
            description: "Schließe deine erste Fokus-Session ab.",
            icon: "checkmark.seal",
            rarity: .common,
            category: "Abschlüsse",
            requirement: "Schließe 1 Fokus-Session ab.",
            tip: "Starte mit einem kleinen Ziel, um direkt ins Tun zu kommen.",
            metric: .completions,
            goalValue: 1
        ),
        .init(
            title: "Dranbleiben",
            description: "Erreiche 5 Abschlüsse – du kommst ins Rollen.",
            icon: "checkmark.circle",
            rarity: .common,
            category: "Abschlüsse",
            requirement: "Erreiche 5 Abschlüsse.",
            tip: "Plane feste Zeitfenster am Tag, in denen du deine Fokusse erledigst.",
            metric: .completions,
            goalValue: 5
        ),
        .init(
            title: "In Bewegung",
            description: "10 Abschlüsse – deine ersten Routinen entstehen.",
            icon: "figure.walk",
            rarity: .common,
            category: "Abschlüsse",
            requirement: "Erreiche 10 Abschlüsse.",
            tip: "Wiederhole lieber kleine Schritte täglich als große Aktionen einmalig.",
            metric: .completions,
            goalValue: 10
        ),
        .init(
            title: "Level Up",
            description: "Erreiche 100 XP und steigere dein Fokus-Level.",
            icon: "star",
            rarity: .common,
            category: "Erfahrung",
            requirement: "Sammle 100 XP.",
            tip: "Jeder Abschluss bringt XP – bleib einfach konstant dran.",
            metric: .xp,
            goalValue: 100
        ),
        .init(
            title: "Mini-Serie",
            description: "Halte eine 2-Tage-Serie.",
            icon: "flame",
            rarity: .common,
            category: "Konstanz",
            requirement: "Halte eine 2-Tage-Streak.",
            tip: "Lege dir abends schon zurecht, was du am nächsten Tag erledigst.",
            metric: .streak,
            goalValue: 2
        ),
        .init(
            title: "Im Tritt",
            description: "Halte eine 3-Tage-Serie – du kommst in den Rhythmus.",
            icon: "flame.fill",
            rarity: .common,
            category: "Konstanz",
            requirement: "Halte eine 3-Tage-Streak.",
            tip: "Nutze Erinnerungen, um deine Serie nicht aus Versehen zu unterbrechen.",
            metric: .streak,
            goalValue: 3
        ),
        .init(
            title: "Klar fokussiert",
            description: "Verwalte mindestens 3 aktive Fokusse.",
            icon: "circle.grid.2x2",
            rarity: .common,
            category: "Vielfalt",
            requirement: "Lege mindestens 3 aktive Fokusse an.",
            tip: "Wähle Fokusse für verschiedene Lebensbereiche (z. B. Gesundheit, Arbeit, Lernen).",
            metric: .focusCount,
            goalValue: 3
        ),
        .init(
            title: "Struktur geschaffen",
            description: "Verwalte 5 aktive Fokusse – deine Ziele sind klar strukturiert.",
            icon: "square.grid.2x2",
            rarity: .common,
            category: "Vielfalt",
            requirement: "Lege mindestens 5 aktive Fokusse an.",
            tip: "Achte darauf, dass jeder Fokus klar und konkret formuliert ist.",
            metric: .focusCount,
            goalValue: 5
        ),
        
        // 5 Seltene
        .init(
            title: "Routinebauer",
            description: "30 Abschlüsse – deine Gewohnheiten werden stabil.",
            icon: "checkmark.circle.fill",
            rarity: .rare,
            category: "Abschlüsse",
            requirement: "Erreiche 30 Abschlüsse.",
            tip: "Feiere Zwischenschritte – das hält deine Motivation hoch.",
            metric: .completions,
            goalValue: 30
        ),
        .init(
            title: "Gewohnheitsprofi",
            description: "75 Abschlüsse – Fokus ist fester Teil deines Alltags.",
            icon: "medal.fill",
            rarity: .rare,
            category: "Abschlüsse",
            requirement: "Erreiche 75 Abschlüsse.",
            tip: "Nutze deine stärksten Wochentage, um mehrere Fokusse zu erledigen.",
            metric: .completions,
            goalValue: 75
        ),
        .init(
            title: "Im Rhythmus",
            description: "Halte eine 7-Tage-Serie – eine komplette Woche Fokus.",
            icon: "flame.circle.fill",
            rarity: .rare,
            category: "Konstanz",
            requirement: "Halte eine 7-Tage-Streak.",
            tip: "Plane an schwierigen Tagen kleinere, schneller erreichbare Fokusse ein.",
            metric: .streak,
            goalValue: 7
        ),
        .init(
            title: "Erfahrungsträger",
            description: "750 XP – du bleibst konstant an deinen Zielen dran.",
            icon: "star.circle.fill",
            rarity: .rare,
            category: "Erfahrung",
            requirement: "Sammle 750 XP.",
            tip: "Nutze Fokus-Zeiten ohne Ablenkungen, um deine XP schneller zu steigern.",
            metric: .xp,
            goalValue: 750
        ),
        .init(
            title: "Multitasker",
            description: "Verwalte 7 aktive Fokusse parallel.",
            icon: "rectangle.3.group",
            rarity: .rare,
            category: "Vielfalt",
            requirement: "Lege mindestens 7 aktive Fokusse an.",
            tip: "Überprüfe regelmäßig, ob alle Fokusse noch relevant für dich sind.",
            metric: .focusCount,
            goalValue: 7
        ),
        
        // 3 Legendäre
        .init(
            title: "Langstreckenläufer",
            description: "150 Abschlüsse – du spielst langfristig.",
            icon: "crown.fill",
            rarity: .legendary,
            category: "Abschlüsse",
            requirement: "Erreiche 150 Abschlüsse.",
            tip: "Du spielst das Langzeitspiel – bleib bei deiner Struktur, sie funktioniert.",
            metric: .completions,
            goalValue: 150
        ),
        .init(
            title: "Unaufhaltsam",
            description: "30 Tage in Folge – eine legendäre Streak.",
            icon: "bolt.fill",
            rarity: .legendary,
            category: "Konstanz",
            requirement: "Halte eine 30-Tage-Streak.",
            tip: "Lege dir für schwierige Tage extrem kleine, aber machbare Fokusse zurecht.",
            metric: .streak,
            goalValue: 30
        ),
        .init(
            title: "Fokus-Meister",
            description: "1500 XP – du gehörst zu den Top-Nutzer:innen.",
            icon: "rosette",
            rarity: .legendary,
            category: "Erfahrung",
            requirement: "Sammle 1500 XP.",
            tip: "Nutze deine Erfahrung, um dir ambitionierte, aber realistische Ziele zu setzen.",
            metric: .xp,
            goalValue: 1500
        )
    ]
    
    /// Baut aus den Definitionen konkrete Achievements mit Progress
    static func buildAchievements(
        totalXP: Int,
        streak: Int,
        totalCompletions: Int,
        focusCount: Int
    ) -> [Achievement] {
        
        func currentValue(for metric: AchievementMetric) -> Int {
            switch metric {
            case .xp:           return totalXP
            case .streak:       return streak
            case .completions:  return totalCompletions
            case .focusCount:   return focusCount
            }
        }
        
        return definitions.map { def in
            let current = currentValue(for: def.metric)
            let progress = min(max(Double(current) / Double(def.goalValue), 0.0), 1.0)
            
            return Achievement(
                title: def.title,
                description: def.description,
                icon: def.icon,
                progress: progress,
                isUnlocked: current >= def.goalValue,
                goalValue: def.goalValue,
                currentValue: current,
                rarity: def.rarity,
                category: def.category,
                requirement: def.requirement,
                tip: def.tip
            )
        }
    }
}
