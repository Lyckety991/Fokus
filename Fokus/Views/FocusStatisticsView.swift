//
//  FocusStatisticsView.swift
//  Fokus
//
//  Created by Patrick Lanham on 15.07.25.
//

import SwiftUI

struct FocusStatisticsView: View {
    let statistics: FocusStatistics
    
    var body: some View {
        VStack(spacing: 20) {
            // Header mit Streak
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(statistics.streak) Tage Serie")
                    .font(.headline)
                Spacer()
                Text("\(statistics.totalCompletions) Abschlüsse")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Fortschrittsbalken
            VStack(alignment: .leading) {
                Text("Wöchentliche Rate: \(Int(statistics.weeklyCompletionRate * 100))%")
                    .font(.subheadline)
                ProgressView(value: statistics.weeklyCompletionRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            
            VStack(alignment: .leading) {
                Text("Monatliche Rate: \(Int(statistics.monthlyCompletionRate * 100))%")
                    .font(.subheadline)
                ProgressView(value: statistics.monthlyCompletionRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
            }
            
            // Kalenderansicht für längeren Zeitraum
            MonthCalendarView(completionDates: statistics.completionHistory)
        }
        .padding()
        .cornerRadius(12)
        .shadow(radius: 2)
        .cardStyle()
    }
}

struct MonthCalendarView: View {
    let completionDates: [Date]
    
    var body: some View {
        VStack {
            Text("Aktivitätskalender")
                .font(.headline)
                .padding(.bottom, 8)
            
            // Vereinfachte Monatsansicht
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(1...31, id: \.self) { day in
                    let hasCompletion = completionDates.contains {
                        Calendar.current.component(.day, from: $0) == day
                    }
                    
                    Circle()
                        .fill(hasCompletion ? Color.green : Color.gray.opacity(0.2))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("\(day)")
                                .font(.system(size: 8))
                                .foregroundColor(hasCompletion ? .white : .primary)
                        )
                }
            }
        }
    }
}

#Preview {
    FocusStatisticsView(statistics: FocusStatistics())
}
