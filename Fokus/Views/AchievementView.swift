//
//  AchievementView.swift
//  Fokus
//
//  Created by Patrick Lanham on 23.07.25.
//

import SwiftUI

// MARK: - Rarity Filter Enum (nur für UI-Filter)

enum AchievementRarityFilter: String, CaseIterable {
    case all = "Alle"
    case common = "Gewöhnlich"
    case rare = "Selten"
    case legendary = "Legendär"
    
    var color: Color {
        switch self {
        case .all:
            return Palette.accent
        case .common:
            return .gray
        case .rare:
            return Palette.accent
        case .legendary:
            return Palette.warning
        }
    }
    
    var icon: String {
        switch self {
        case .all:
            return "list.bullet"
        case .common:
            return "circle.fill"
        case .rare:
            return "diamond.fill"
        case .legendary:
            return "crown.fill"
        }
    }
}

// MARK: - Achievement View

struct AchievementView: View {
    @ObservedObject var store: FocusStore
    @State private var selectedAchievement: Achievement?
    @State private var selectedRarity: AchievementRarityFilter = .all
    @State private var showingFilterSheet = false
    
    // Berechne Statistiken direkt in der View
    private var realStatistics: GlobalStatistics {
        StatisticsHelper.calculateGlobalStatistics(
            for: store.focusItems,
            totalXP: store.userProgress?.totalXP ?? 0
        )
    }
    
    // Gefilterte Achievements basierend auf Seltenheit
    private var filteredAchievements: [Achievement] {
        switch selectedRarity {
        case .all:
            return realStatistics.achievements
        case .common:
            return realStatistics.achievements.filter { $0.rarity == .common }
        case .rare:
            return realStatistics.achievements.filter { $0.rarity == .rare }
        case .legendary:
            return realStatistics.achievements.filter { $0.rarity == .legendary }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    achievementsSection
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .background(Palette.background)
            .navigationTitle("Erfolge")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: selectedRarity == .all
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                            .font(.title2)
                            .foregroundColor(selectedRarity == .all
                                             ? Palette.textSecondary
                                             : selectedRarity.color)
                    }
                }
            }
            .sheet(item: $selectedAchievement) { achievement in
                AchievementDetailSheet(achievement: achievement)
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(
                    selectedRarity: $selectedRarity,
                    achievements: realStatistics.achievements
                )
            }
        }
    }
    
    // MARK: - Achievements Section
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedRarity == .all ? "Alle Erfolge" : selectedRarity.rawValue)
                        .titleStyle()
                    
                    if selectedRarity != .all {
                        Text("Gefiltert nach Seltenheit")
                            .font(.caption)
                            .foregroundColor(Palette.textSecondary)
                    }
                }
                
                Spacer()
                
                Text("\(filteredAchievements.filter(\.isUnlocked).count)/\(filteredAchievements.count)")
                    .font(.subheadline)
                    .foregroundColor(Palette.textSecondary)
            }
            
            if filteredAchievements.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(filteredAchievements) { achievement in
                        AchievementRow(achievement: achievement) {
                            selectedAchievement = achievement
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedRarity == .all ? "trophy.slash" : "sparkles")
                .font(.system(size: 50))
                .foregroundColor(Palette.textSecondary)
            
            Text(selectedRarity == .all
                 ? "Keine Erfolge gefunden"
                 : "Keine \(selectedRarity.rawValue.lowercased())en Erfolge")
                .headlineStyle()
            
            Text(selectedRarity == .all
                 ? "Erstelle einen Fokus und schließe ihn ab, um Erfolge freizuschalten!"
                 : "Arbeite weiter an deinen Zielen, um \(selectedRarity.rawValue.lowercased())e Erfolge zu erreichen!")
                .bodyTextStyle()
                .multilineTextAlignment(.center)
            
            if selectedRarity == .all {
                Button("Test-Daten hinzufügen") {
                    addTestData()
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding()
                .background(Palette.accent)
                .cornerRadius(8)
            } else {
                Button("Alle anzeigen") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedRarity = .all
                    }
                }
                .font(.subheadline)
                .foregroundColor(Palette.accent)
                .padding()
                .background(Palette.card)
                .cornerRadius(8)
            }
        }
        .padding(40)
        .cardStyle()
    }
    
    // MARK: - Test-Daten hinzufügen
    
    private func addTestData() {
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
        
        if store.userProgress == nil {
            store.userProgress = UserProgressModel(totalXP: 150)
        } else {
            store.userProgress = UserProgressModel(
                totalXP: (store.userProgress?.totalXP ?? 0) + 150
            )
        }
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Binding var selectedRarity: AchievementRarityFilter
    let achievements: [Achievement]
    @Environment(\.dismiss) private var dismiss
    
    private func getCountForRarity(_ rarity: AchievementRarityFilter) -> Int {
        switch rarity {
        case .all:
            return achievements.count
        case .common:
            return achievements.filter { $0.rarity == .common }.count
        case .rare:
            return achievements.filter { $0.rarity == .rare }.count
        case .legendary:
            return achievements.filter { $0.rarity == .legendary }.count
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.title2)
                            .foregroundColor(Palette.accent)
                        
                        Text("Filter nach Seltenheit")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Palette.textPrimary)
                        
                        Spacer()
                    }
                    
                    Text("Wähle eine Seltenheitsstufe aus, um die Erfolge zu filtern")
                        .font(.subheadline)
                        .foregroundColor(Palette.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 8)
                
                // Filter Options
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(AchievementRarityFilter.allCases, id: \.self) { rarity in
                            FilterOption(
                                rarity: rarity,
                                isSelected: selectedRarity == rarity,
                                count: getCountForRarity(rarity)
                            ) {
                                selectedRarity = rarity
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .background(Palette.background)
            .navigationTitle("")
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Filter Option

struct FilterOption: View {
    let rarity: AchievementRarityFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? rarity.color : Palette.card)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(rarity.color.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: rarity.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : rarity.color)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(rarity.rawValue)
                        .font(.headline)
                        .foregroundColor(Palette.textPrimary)
                    
                    Text("\(count) Erfolge")
                        .font(.subheadline)
                        .foregroundColor(Palette.textSecondary)
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(rarity.color)
                } else {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundColor(Palette.textSecondary.opacity(0.3))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? rarity.color.opacity(0.1) : Palette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? rarity.color.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Achievement Row

struct AchievementRow: View {
    let achievement: Achievement
    let onTap: () -> Void
    
    private var rarityColor: Color {
        switch achievement.rarity {
        case .common:
            return .gray
        case .rare:
            return Palette.accent
        case .legendary:
            return Palette.warning
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                achievementIcon
                
                // Info
                achievementInfo
                
                Spacer()
                
                // Status + Arrow
                VStack(spacing: 8) {
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
                .fill(achievement.isUnlocked ? rarityColor : Palette.card)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(
                            achievement.isUnlocked ? rarityColor : Color.gray.opacity(0.3),
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
            
            if !achievement.isUnlocked {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(achievement.progress * 100))% abgeschlossen")
                        .font(.caption)
                        .foregroundColor(Palette.textSecondary)
                    
                    ProgressView(value: achievement.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: rarityColor))
                        .frame(height: 4)
                }
            }
        }
    }
    
    private var statusIndicator: some View {
        Group {
            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(Palette.completed)
            } else {
                Text("\(Int(achievement.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(rarityColor)
            }
        }
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss
    
    private var rarityName: String {
        switch achievement.rarity {
        case .common:    return "Gewöhnlich"
        case .rare:      return "Selten"
        case .legendary: return "Legendär"
        }
    }
    
    private var rarityColor: Color {
        switch achievement.rarity {
        case .common:    return .gray
        case .rare:      return Palette.accent
        case .legendary: return Palette.warning
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    achievementIcon
                    titleSection
                    progressSection
                    requirementSection
                    tipSection
                    // rewardSection (falls du XP-Belohnungen nutzen willst)
                    
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
                .fill(achievement.isUnlocked ? rarityColor : Palette.card)
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(rarityColor, lineWidth: 3)
                )
                .shadow(
                    color: rarityColor.opacity(0.3),
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
                Text(rarityName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(rarityColor)
                    .clipShape(Capsule())
                
                Text(achievement.category)
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
                    .foregroundColor(rarityColor)
            }
            
            ProgressView(value: achievement.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: rarityColor))
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
            } else {
                HStack {
                    Text("\(achievement.currentValue)/\(achievement.goalValue)")
                        .font(.subheadline)
                        .foregroundColor(Palette.textSecondary)
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
            
            Text(achievement.requirement)
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
            
            Text(achievement.tip)
                .bodyTextStyle()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .cardStyle()
    }
    
    // Optional: falls du zusätzliche XP-Belohnungen anzeigen willst
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
                
                if achievement.isUnlocked {
                    Text("Erhalten! ✅")
                        .font(.subheadline)
                        .foregroundColor(Palette.completed)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Previews

#Preview("Mit echten Daten") {
    let store = FocusStore()
    
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
