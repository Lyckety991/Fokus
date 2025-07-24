//
//  AchievementView.swift
//  Fokus
//
//  Created by Patrick Lanham on 23.07.25.
//

import SwiftUI

struct AchievementView: View {
    @ObservedObject var store: FocusStore
    @State private var selectedAchievement: Achievement?
    @State private var showingAchievementDetail = false
    
    // Berechne Statistiken direkt in der View
    private var realStatistics: GlobalStatistics {
        StatisticsHelper.calculateGlobalStatistics(
            for: store.focusItems,
            totalXP: store.userProgress?.totalXP ?? 0
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    
                    achievementsSection
                }
                .padding()
            }
            .background(Palette.background)
            .navigationTitle("Erfolge")
            .sheet(isPresented: $showingAchievementDetail) {
                if let achievement = selectedAchievement {
                    AchievementDetailSheet(achievement: achievement)
                }
            }
        }
    }
    
    // MARK: - Debug Section
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🔍 Debug Info:")
                .font(.headline)
                .foregroundColor(.red)
            
            Text("Achievements: \(realStatistics.achievements.count)")
                .font(.caption)
                .foregroundColor(.red)
            
            Text("Total XP: \(realStatistics.totalXP)")
                .font(.caption)
                .foregroundColor(.red)
            
            Text("Streak: \(realStatistics.streak)")
                .font(.caption)
                .foregroundColor(.red)
            
            Text("Focus Items: \(store.focusItems.count)")
                .font(.caption)
                .foregroundColor(.red)
            
            Text("UserProgress XP: \(store.userProgress?.totalXP ?? 0)")
                .font(.caption)
                .foregroundColor(.red)
            
            // Zeige alle Achievements im Debug
            ForEach(realStatistics.achievements) { achievement in
                Text("🏆 \(achievement.title): \(Int(achievement.progress * 100))% - \(achievement.isUnlocked ? "✅" : "❌")")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Anzahl")
                    .titleStyle()
                
                Spacer()
                
                Text("\(realStatistics.achievements.filter(\.isUnlocked).count)/\(realStatistics.achievements.count)")
                    .font(.subheadline)
                    .foregroundColor(Palette.textSecondary)
            }

            if realStatistics.achievements.isEmpty {
                // Fallback
                VStack(spacing: 16) {
                    Image(systemName: "trophy.slash")
                        .font(.system(size: 50))
                        .foregroundColor(Palette.textSecondary)
                    
                    Text("Keine Erfolge gefunden")
                        .headlineStyle()
                    
                    Text("Erstelle einen Fokus und schließe ihn ab, um Erfolge freizuschalten!")
                        .bodyTextStyle()
                        .multilineTextAlignment(.center)
                    
                    // Test-Button zum Generieren von Dummy-Daten
                    Button("Test-Daten hinzufügen") {
                        addTestData()
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Palette.accent)
                    .cornerRadius(8)
                }
                .padding(40)
                .cardStyle()
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(realStatistics.achievements) { achievement in
                        AchievementRow(achievement: achievement) {
                            selectedAchievement = achievement
                            showingAchievementDetail = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Test-Daten hinzufügen
    private func addTestData() {
        // Füge Test-FocusItems hinzu
        let testFocus1 = FocusItemModel(
            title: "Meditation",
            description: "Tägliche Meditation",
            weakness: "Unruhe",
            todos: [],
            completionDates: [
                Date(),
                Date().addingTimeInterval(-86400),
                Date().addingTimeInterval(-172800)
            ]
        )
        
        let testFocus2 = FocusItemModel(
            title: "Sport",
            description: "Joggen gehen",
            weakness: "Motivation",
            todos: [],
            completionDates: [Date()]
        )
        
        store.focusItems.append(contentsOf: [testFocus1, testFocus2])
        
        // Füge Test-XP hinzu
        if store.userProgress == nil {
            store.userProgress = UserProgressModel(totalXP: 150)
        } else {
            store.userProgress = UserProgressModel(totalXP: (store.userProgress?.totalXP ?? 0) + 150)
        }
    }
}

// MARK: - Achievement Row (jetzt tappable)
struct AchievementRow: View {
    let achievement: Achievement
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Achievement Icon
                achievementIcon
                
                // Achievement Info
                achievementInfo
                
                Spacer()
                
                // Status + Arrow
                VStack {
                    statusIndicator
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Palette.textSecondary)
                }
            }
            .padding(16)
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var achievementIcon: some View {
        ZStack {
            Circle()
                .fill(achievement.isUnlocked ? Palette.completed : Palette.card)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(
                            achievement.isUnlocked ? Palette.completed : Color.gray.opacity(0.3),
                            lineWidth: 2
                        )
                )
            
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(achievement.isUnlocked ? .white : Palette.textSecondary)
        }
    }
    
    private var achievementInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(achievement.title)
                .font(.headline)
                .foregroundColor(Palette.textPrimary)

            Text(achievement.description)
                .font(.subheadline)
                .foregroundColor(Palette.textSecondary)

            // Progress Bar
            if !achievement.isUnlocked {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(achievement.progress * 100))% abgeschlossen")
                        .font(.caption)
                        .foregroundColor(Palette.textSecondary)

                    ProgressView(value: achievement.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Palette.accent))
                        .frame(height: 4)
                }
            }
        }
    }
    
    private var statusIndicator: some View {
        if achievement.isUnlocked {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Palette.completed) as? Text
        } else {
            Text("\(Int(achievement.progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Palette.accent)
        }
    }
}

// MARK: - Achievement Detail Sheet
struct AchievementDetailSheet: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss
    
    // Mapping für detaillierte Infos
    private var detailInfo: (requirement: String, tip: String, category: String) {
        switch achievement.title {
        case "Neuling":
            return (
                requirement: "Erreiche 100 XP durch das Abschließen von Fokussen",
                tip: "Jeder abgeschlossene Fokus gibt dir 25 XP. Du brauchst also 4 Abschlüsse!",
                category: "Erfahrung"
            )
        case "Erfahren":
            return (
                requirement: "Sammle insgesamt 500 XP",
                tip: "Das entspricht etwa 20 abgeschlossenen Fokussen. Bleib dran!",
                category: "Erfahrung"
            )
        case "Meister":
            return (
                requirement: "Erreiche 1000 XP - ein wahrer Meilenstein!",
                tip: "Nur die Diszipliniertesten schaffen diesen Status. Das sind 40 Fokus-Abschlüsse!",
                category: "Erfahrung"
            )
        case "Durchstarter":
            return (
                requirement: "Schließe an 3 aufeinanderfolgenden Tagen mindestens einen Fokus ab",
                tip: "Der erste Schritt zur Gewohnheitsbildung. Starte noch heute!",
                category: "Konstanz"
            )
        case "Konsequent":
            return (
                requirement: "Halte eine 7-Tage-Streak aufrecht",
                tip: "Nach einer Woche wird es zur Routine. Du schaffst das!",
                category: "Konstanz"
            )
        case "Unaufhaltsam":
            return (
                requirement: "Erstelle eine unglaubliche 30-Tage-Streak",
                tip: "Nur 5% aller Nutzer schaffen das. Werde eine Inspiration für andere!",
                category: "Konstanz"
            )
        case "Erster Schritt":
            return (
                requirement: "Schließe insgesamt 10 Fokusse ab",
                tip: "Jeder Weg beginnt mit einem ersten Schritt. Du bist auf dem richtigen Weg!",
                category: "Abschlüsse"
            )
        case "Vollprofi":
            return (
                requirement: "Erreiche 50 Fokus-Abschlüsse",
                tip: "Das zeigt wahre Hingabe. Du hast bewiesen, dass du es ernst meinst!",
                category: "Abschlüsse"
            )
        case "Multitasker":
            return (
                requirement: "Erstelle und verwalte 5 aktive Fokusse gleichzeitig",
                tip: "Balance ist der Schlüssel. Übernimm dich nicht, aber bleib vielseitig!",
                category: "Vielfalt"
            )
        default:
            return (
                requirement: "Unbekannte Anforderung",
                tip: "Bleib dran und entdecke neue Erfolge!",
                category: "Allgemein"
            )
        }
    }
    
    private var rarityInfo: (name: String, color: Color) {
        switch achievement.title {
        case "Neuling", "Erster Schritt", "Durchstarter":
            return ("Gewöhnlich", Color.gray)
        case "Erfahren", "Konsequent", "Multitasker":
            return ("Selten", Palette.accent)
        case "Vollprofi":
            return ("Episch", Palette.purple)
        case "Meister", "Unaufhaltsam":
            return ("Legendär", Palette.warning)
        default:
            return ("Gewöhnlich", Color.gray)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Achievement Icon (groß)
                    achievementIcon
                    
                    // Title & Category
                    titleSection
                    
                    // Progress Section
                    progressSection
                    
                    // Requirement Section
                    requirementSection
                    
                    // Tip Section
                    tipSection
                    
                    // Reward Section
                    rewardSection
                    
                    Spacer()
                }
                .padding(24)
            }
            .background(Palette.background)
            .navigationTitle("Erfolg")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .foregroundColor(Palette.accent)
                }
            }
        }
    }
    
    private var achievementIcon: some View {
        ZStack {
            Circle()
                .fill(achievement.isUnlocked ? rarityInfo.color : Palette.card)
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(rarityInfo.color, lineWidth: 3)
                )
                .shadow(
                    color: rarityInfo.color.opacity(0.3),
                    radius: achievement.isUnlocked ? 15 : 5
                )
            
            Image(systemName: achievement.icon)
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(achievement.isUnlocked ? .white : Palette.textSecondary)
        }
    }
    
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(achievement.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Palette.textPrimary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Text(rarityInfo.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(rarityInfo.color)
                    .clipShape(Capsule())
                
                Text(detailInfo.category)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Palette.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Palette.card)
                    .clipShape(Capsule())
            }
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Fortschritt")
                    .headlineStyle()
                Spacer()
                Text("\(Int(achievement.progress * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(rarityInfo.color)
            }
            
            ProgressView(value: achievement.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: rarityInfo.color))
                .frame(height: 8)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            if achievement.isUnlocked {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Palette.completed)
                    Text("Erfolg freigeschaltet!")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Palette.completed)
                    Spacer()
                }
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var requirementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(Palette.accent)
                Text("Anforderung")
                    .headlineStyle()
                Spacer()
            }
            
            Text(detailInfo.requirement)
                .bodyTextStyle()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .cardStyle()
    }
    
    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Palette.warning)
                Text("Tipp")
                    .headlineStyle()
                Spacer()
            }
            
            Text(detailInfo.tip)
                .bodyTextStyle()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .cardStyle()
    }
    
    private var rewardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(Palette.purple)
                Text("Belohnung")
                    .headlineStyle()
                Spacer()
            }
            
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Palette.warning)
                Text("25 XP")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Palette.textPrimary)
                Spacer()
            }
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Previews
#Preview("Mit echten Daten") {
    let store = FocusStore()
    
    // Test FocusItems erstellen (mit korrektem Initializer)
    let focus1 = FocusItemModel(
        title: "Meditation",
        description: "Tägliche Meditation",
        weakness: "Unruhe",
        todos: [],
        completionDates: [Date(), Date().addingTimeInterval(-86400)]
    )
    
    let focus2 = FocusItemModel(
        title: "Sport",
        description: "Joggen",
        weakness: "Faulheit",
        todos: [],
        completionDates: [Date()]
    )
    
    store.focusItems = [focus1, focus2]
    store.userProgress = UserProgressModel(totalXP: 150)
    
    return NavigationView {
        AchievementView(store: store)
    }
}

#Preview("Leere Daten") {
    let store = FocusStore()
    return NavigationView {
        AchievementView(store: store)
    }
}

#Preview("Viele Erfolge") {
    let store = FocusStore()
    
    // Erstelle viele Test-Completions für verschiedene Achievements
    var completionDates: [Date] = []
    for i in 0..<15 {
        completionDates.append(Date().addingTimeInterval(-Double(i * 86400)))
    }
    
    let superFocus = FocusItemModel(
        title: "Super Fokus",
        description: "Test mit vielen Abschlüssen",
        weakness: "Test",
        todos: [],
        completionDates: completionDates
    )
    
    store.focusItems = [superFocus]
    store.userProgress = UserProgressModel(totalXP: 1200) // Viel XP für alle Achievements
    
    return NavigationView {
        AchievementView(store: store)
    }
}
