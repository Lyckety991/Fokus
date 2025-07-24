//
//  FocusStatisticsView.swift
//  Fokus
//
//  Created by Patrick Lanham on 15.07.25.
//

import SwiftUI

struct FocusStatisticsView: View {
    let statistics: FocusStatistics
    @State private var selectedTimeframe: StatTimeframe = .week
    @State private var animateProgress = false
    
    enum StatTimeframe: String, CaseIterable {
        case week = "Woche"
        case month = "Monat"
        case year = "Jahr"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header mit Hero Stats
                heroStatsSection
                
                // Timeframe Selector
                timeframeSelectorSection
                
                // Progress Cards
                progressCardsSection
                
                // Activity Heatmap
                activityHeatmapSection
                
                // Insights Section
                insightsSection
            }
            //.padding()
        }
        .background(Palette.background)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateProgress = true
            }
        }
    }
    
    // MARK: - Hero Stats Section
    private var heroStatsSection: some View {
        VStack(spacing: 20) {
            // Streak Card (Prominent)
            streakCard
            
            // Quick Stats Grid
            HStack(spacing: 16) {
                quickStatCard(
                    title: "Abschlüsse",
                    value: "\(statistics.totalCompletions)",
                    icon: "checkmark.circle.fill",
                    color: Palette.completed
                )
                
                quickStatCard(
                    title: "Beste Serie",
                    value: "\(statistics.streak)",
                    icon: "trophy.fill",
                    color: Palette.warning
                )
            }
        }
    }
    
    private var streakCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundColor(Palette.warning)
                
                Text("Aktuelle Serie")
                    .font(.headline)
                    .foregroundColor(Palette.textPrimary)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(statistics.streak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Palette.warning)
                    
                    Text(statistics.streak == 1 ? "Tag" : "Tage")
                        .font(.title3)
                        .foregroundColor(Palette.textSecondary)
                }
                
                Spacer()
                
                // Streak Visualization
                VStack(spacing: 4) {
                    ForEach(0..<min(statistics.streak, 7), id: \.self) { _ in
                        Circle()
                            .fill(Palette.warning)
                            .frame(width: 8, height: 8)
                    }
                    
                    if statistics.streak > 7 {
                        Text("+\(statistics.streak - 7)")
                            .font(.caption2)
                            .foregroundColor(Palette.textSecondary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Palette.warning.opacity(0.1), Palette.warning.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Palette.warning.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func quickStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Palette.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .cardStyle()
    }
    
    // MARK: - Timeframe Selector
    private var timeframeSelectorSection: some View {
        HStack {
            Text("Zeitraum")
                .font(.headline)
                .foregroundColor(Palette.textPrimary)
            
            Spacer()
            
            HStack(spacing: 8) {
                ForEach(StatTimeframe.allCases, id: \.self) { timeframe in
                    Button(timeframe.rawValue) {
                        selectedTimeframe = timeframe
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(selectedTimeframe == timeframe ? .white : Palette.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        selectedTimeframe == timeframe ?
                        Palette.accent :
                        Palette.card
                    )
                    .clipShape(Capsule())
                    .animation(.easeInOut(duration: 0.2), value: selectedTimeframe)
                }
            }
        }
    }
    
    // MARK: - Progress Cards Section
    private var progressCardsSection: some View {
        VStack(spacing: 16) {
            progressCard(
                title: "Wöchentliche Rate",
                progress: statistics.weeklyCompletionRate,
                color: Palette.accent,
                timeframe: .week
            )
            
            progressCard(
                title: "Monatliche Rate",
                progress: statistics.monthlyCompletionRate,
                color: Palette.completed,
                timeframe: .month
            )
        }
    }
    
    private func progressCard(title: String, progress: Double, color: Color, timeframe: StatTimeframe) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Palette.textPrimary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            // Progress Bar mit Animation
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.2))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: animateProgress ? geometry.size.width * CGFloat(progress) : 0,
                            height: 12
                        )
                        .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateProgress)
                }
            }
            .frame(height: 12)
            
            // Progress Indicator
            HStack {
                progressIndicator(progress: progress, color: color)
                Spacer()
                Text(progressDescription(for: progress))
                    .font(.caption)
                    .foregroundColor(Palette.textSecondary)
            }
        }
        .padding(16)
        .cardStyle()
    }
    
    private func progressIndicator(progress: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(progress > Double(index) * 0.2 ? color : color.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    private func progressDescription(for progress: Double) -> String {
        switch progress {
        case 0...0.2: return "Gerade erst gestartet"
        case 0.2...0.4: return "Auf dem richtigen Weg"
        case 0.4...0.6: return "Gute Fortschritte"
        case 0.6...0.8: return "Sehr gut dabei"
        case 0.8...1.0: return "Hervorragend!"
        default: return "Überragend!"
        }
    }
    
    // MARK: - Activity Heatmap Section
    private var activityHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aktivitätsverlauf")
                .font(.headline)
                .foregroundColor(Palette.textPrimary)
            
            ModernCalendarHeatmap(completionDates: statistics.completionHistory)
        }
        .padding(16)
        .cardStyle()
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.headline)
                .foregroundColor(Palette.textPrimary)
            
            VStack(spacing: 12) {
                insightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Trend",
                    value: trendDescription,
                    color: Palette.accent
                )
                
                insightRow(
                    icon: "target",
                    title: "Ziel-Fortschritt",
                    value: "\(Int(statistics.weeklyCompletionRate * 100))% diese Woche",
                    color: Palette.completed
                )
                
                insightRow(
                    icon: "calendar",
                    title: "Aktivste Zeit",
                    value: "Letzte 7 Tage",
                    color: Palette.purple
                )
            }
        }
        .padding(16)
        .cardStyle()
    }
    
    private func insightRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Palette.textPrimary)
                
                Text(value)
                    .font(.caption)
                    .foregroundColor(Palette.textSecondary)
            }
            
            Spacer()
        }
    }
    
    private var trendDescription: String {
        let weeklyRate = statistics.weeklyCompletionRate
        let monthlyRate = statistics.monthlyCompletionRate
        
        if weeklyRate > monthlyRate {
            return "Verbesserung in letzter Zeit"
        } else if weeklyRate < monthlyRate {
            return "Leichter Rückgang"
        } else {
            return "Stabil"
        }
    }
}

// MARK: - Modern Calendar Heatmap
struct ModernCalendarHeatmap: View {
    let completionDates: [Date]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    
    // Letzten 4 Wochen (28 Tage)
    private var last28Days: [Date] {
        let calendar = Calendar.current
        return (0..<28).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: Date())
        }.reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Weekday Headers
            HStack {
                ForEach(["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(Palette.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(last28Days, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isCompleted: isCompleted(on: date),
                        isToday: Calendar.current.isDateInToday(date)
                    )
                }
            }
            
            // Legend
            HStack {
                Text("Weniger")
                    .font(.caption2)
                    .foregroundColor(Palette.textSecondary)
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { intensity in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(heatmapColor(for: intensity))
                            .frame(width: 12, height: 12)
                    }
                }
                
                Text("Mehr")
                    .font(.caption2)
                    .foregroundColor(Palette.textSecondary)
                
                Spacer()
            }
        }
    }
    
    private func isCompleted(on date: Date) -> Bool {
        completionDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }
    
    private func heatmapColor(for intensity: Int) -> Color {
        switch intensity {
        case 0: return Palette.card
        case 1: return Palette.completed.opacity(0.3)
        case 2: return Palette.completed.opacity(0.5)
        case 3: return Palette.completed.opacity(0.7)
        case 4: return Palette.completed
        default: return Palette.completed
        }
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isCompleted: Bool
    let isToday: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(isCompleted ? Palette.completed : Palette.card)
            .frame(height: 32)
            .overlay(
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption2)
                    .fontWeight(isToday ? .bold : .medium)
                    .foregroundColor(
                        isCompleted ? .white :
                        isToday ? Palette.accent :
                        Palette.textPrimary
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        isToday ? Palette.accent : Color.clear,
                        lineWidth: isToday ? 2 : 0
                    )
            )
            .scaleEffect(isToday ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isToday)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        FocusStatisticsView(
            statistics: FocusStatistics(
                streak: 12,
                totalCompletions: 45,
                weeklyCompletionRate: 0.75,
                monthlyCompletionRate: 0.60,
                completionHistory: [
                    Date(),
                    Date().addingTimeInterval(-86400),
                    Date().addingTimeInterval(-172800),
                    Date().addingTimeInterval(-259200),
                    Date().addingTimeInterval(-345600)
                ]
            )
        )
    }
}
