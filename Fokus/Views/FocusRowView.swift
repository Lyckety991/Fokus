//
//  FocusRowView.swift
//  Fokus
//
//  Created by Patrick Lanham on 10.07.25.
//

import SwiftUI

struct FocusRowView: View {
    @Binding var focus: FocusItemModel
    var store: FocusStore
    @State private var showingCompleteAnimation = false
    
    private var completedCount: Int {
        focus.todos.filter { $0.isCompleted }.count
    }
    
    private var progress: CGFloat {
        focus.todos.isEmpty ? 0 : CGFloat(completedCount) / CGFloat(focus.todos.count)
    }
    
    private var isCompletedToday: Bool {
        focus.completionDates.contains { Calendar.current.isDateInToday($0) }
    }
    
    private var canCompleteToday: Bool {
        !isCompletedToday && (!focus.todos.isEmpty ? progress == 1.0 : true)
    }
    
    // Streak-Berechnung für diesen Fokus
    private var currentStreak: Int {
        let sortedDates = focus.completionDates.sorted(by: >)
        guard let lastDate = sortedDates.first else { return 0 }
        
        // Wenn letzter Abschluss nicht heute oder gestern war, ist Streak 0
        let daysDifference = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        if daysDifference > 1 { return 0 }
        
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
    
    // Kalenderdaten für die letzten 7 Tage
    private var last7Days: [Date] {
        let calendar = Calendar.current
        return (0..<7).map { offset in
            calendar.date(byAdding: .day, value: -offset, to: Date())!
        }.reversed()
    }
    
    var body: some View {
        NavigationLink(destination: FocusDetailView(focus: $focus, store: store)) {
            VStack(alignment: .leading, spacing: 16) {
                // Header mit Titel und Quick Actions
                headerSection
                
                // Mini-Kalender
                calendarSection
                
                // Progress und Status
                progressSection
                
                // Schwäche (falls vorhanden)
                if !focus.weakness.isEmpty {
                    weaknessSection
                }
                
                // Quick Complete Button (falls möglich)
                if canCompleteToday {
                    quickCompleteButton
                }
            }
            .padding(16)
            .background(cardBackground)
            .overlay(cardBorder)
            .scaleEffect(showingCompleteAnimation ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: showingCompleteAnimation)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(focus.title)
                    .font(.headline)
                    .foregroundColor(Palette.textPrimary)
                    .lineLimit(2)
                
                if !focus.description.isEmpty {
                    Text(focus.description)
                        .font(.subheadline)
                        .foregroundColor(Palette.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Status Badge
                statusBadge
                
                // Streak Info
                if currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(Palette.warning)
                        Text("\(currentStreak)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Palette.warning)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Palette.warning.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    private var statusBadge: some View {
        Group {
            if isCompletedToday {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                    Text("Erledigt")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Palette.completed)
                .clipShape(Capsule())
            } else if canCompleteToday {
                HStack(spacing: 4) {
                    Image(systemName: "circle")
                        .font(.caption)
                    Text("Bereit")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Palette.accent)
                .clipShape(Capsule())
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("In Arbeit")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(Palette.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Palette.card)
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Letzte 7 Tage")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Palette.textSecondary)
            
            HStack(spacing: 8) {
                ForEach(last7Days, id: \.self) { date in
                    VStack(spacing: 6) {
                        Text(dayLabel(for: date))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(date.isToday ? Palette.accent : Palette.textSecondary)
                        
                        Text(dayOfMonth(for: date))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(date.isToday ? Palette.accent : Palette.textPrimary)
                        
                        ZStack {
                            Circle()
                                .fill(completionColor(for: date))
                                .frame(width: 24, height: 24)
                            
                            Circle()
                                .stroke(
                                    date.isToday ? Palette.accent : completionBorderColor(for: date),
                                    lineWidth: date.isToday ? 2 : 1
                                )
                                .frame(width: 24, height: 24)
                            
                            if isCompleted(on: date) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(12)
        .background(Palette.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 8) {
            if !focus.todos.isEmpty {
                HStack {
                    Text("Fortschritt")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Palette.textPrimary)
                    
                    Spacer()
                    
                    Text("\(completedCount)/\(focus.todos.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(progress == 1 ? Palette.completed : Palette.accent)
                        .monospacedDigit()
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: progress == 1 ? Palette.completed : Palette.accent))
                    .frame(height: 6)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                
                if progress == 1 && !isCompletedToday {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(Palette.warning)
                            .font(.caption)
                        Text("Alle Ziele erreicht! Bereit zum Abschließen.")
                            .font(.caption)
                            .foregroundColor(Palette.completed)
                            .fontWeight(.medium)
                    }
                    .padding(.top, 4)
                }
            } else {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(Palette.textSecondary)
                    Text("Keine Ziele definiert")
                        .font(.subheadline)
                        .foregroundColor(Palette.textSecondary)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Weakness Section
    private var weaknessSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(Palette.warning)
            
            Text("Schwäche: \(focus.weakness)")
                .font(.caption)
                .foregroundColor(Palette.textPrimary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Palette.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Quick Complete Button
    private var quickCompleteButton: some View {
        Button(action: completeToday) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.headline)
                Text("Heute abschließen")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("+25 XP")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [Palette.completed, Palette.completed.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Views
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Palette.card)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                isCompletedToday ? Palette.completed :
                canCompleteToday ? Palette.accent :
                Color.gray.opacity(0.2),
                lineWidth: isCompletedToday || canCompleteToday ? 2 : 1
            )
    }
    
    // MARK: - Helper Methods
    private func completeToday() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showingCompleteAnimation = true
            store.completeFocus(focus.id)
            
            // Reset Animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingCompleteAnimation = false
            }
        }
    }
    
    private func isCompleted(on date: Date) -> Bool {
        focus.completionDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }
    
    private func dayOfMonth(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(2)).uppercased()
    }
    
    private func completionColor(for date: Date) -> Color {
        if isCompleted(on: date) {
            return Palette.completed
        } else if date.isToday && canCompleteToday {
            return Palette.accent.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private func completionBorderColor(for date: Date) -> Color {
        if isCompleted(on: date) {
            return Palette.completed
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Extensions
extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
}

// MARK: - Preview
#Preview {
    let store = FocusStore()
    
    @State var sampleFocus = FocusItemModel(
        title: "Meditation",
        description: "Tägliche Meditation für mehr Achtsamkeit",
        weakness: "Unruhe am Morgen",
        todos: [
            FocusTodoModel(title: "5 Min meditieren", isCompleted: true),
            FocusTodoModel(title: "Atemübung machen", isCompleted: true),
            FocusTodoModel(title: "Tagebuch schreiben", isCompleted: false)
        ],
        completionDates: [
            Date().addingTimeInterval(-86400 * 2), // Vor 2 Tagen
            Date().addingTimeInterval(-86400 * 1), // Gestern
        ]
    )
    
    return VStack {
        FocusRowView(focus: $sampleFocus, store: store)
        
        Spacer()
    }
    .padding()
    .background(Palette.background)
}
