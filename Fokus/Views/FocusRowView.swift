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
    
    private var completedCount: Int {
        focus.todos.filter { $0.isCompleted }.count
    }
    
    private var progress: CGFloat {
        focus.todos.isEmpty ? 0 : CGFloat(completedCount) / CGFloat(focus.todos.count)
    }
    
    private var isCompletedToday: Bool {
        focus.completionDates.contains { Calendar.current.isDateInToday($0) }
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
            VStack(alignment: .leading, spacing: 12) {
                // Titel und Status
                HStack(alignment: .top) {
                    Text(focus.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                   
                }
                
                // Mini-Kalender mit echten Datumsangaben
                HStack(spacing: 6) {
                    ForEach(last7Days, id: \.self) { date in
                        VStack(spacing: 4) {
                            Text(dayOfMonth(for: date))
                                .font(.system(size: 10))
                                .foregroundColor(date.isToday ? .blue : .secondary)
                            
                            ZStack {
                                Circle()
                                    .fill(isCompleted(on: date) ? Color.green : Color.clear)
                                    .frame(width: 22, height: 22)
                                
                                Circle()
                                    .stroke(
                                        date.isToday ? Color.blue :
                                        isCompleted(on: date) ? Color.green : Color.gray.opacity(0.3),
                                        lineWidth: date.isToday ? 1.5 : 1
                                    )
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .frame(width: 30)
                    }
                }
                .padding(.vertical, 4)
                
                // Fortschrittsbalken und Zähler
                if !focus.todos.isEmpty {
                    HStack(spacing: 8) {
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: progress == 1 ? .green : .blue))
                        
                        Text("\(completedCount)/\(focus.todos.count)")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundColor(progress == 1 ? .green : .secondary)
                    }
                }
                
                // Schwäche mit Icon
                if !focus.weakness.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(focus.weakness)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.1)))
                }
            }
            .padding(12)
            .cardStyle()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        
        .buttonStyle(PlainButtonStyle())
    }
    
    // Prüft, ob an einem bestimmten Tag abgeschlossen wurde
    private func isCompleted(on date: Date) -> Bool {
        focus.completionDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }
    
    // Gibt den Tag des Monats zurück (z.B. "15")
    private func dayOfMonth(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// Hilfs-Erweiterung für Date
extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}


    
   



// Preview mit verschiedenen Fällen
#Preview {
    let calendar = Calendar.current
    let today = Date()
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
    
    return VStack(spacing: 16) {
        FocusRowView(
            focus: .constant(FocusItemModel(
                title: "Morgenroutine",
                description: "",
                weakness: "Aufschieben",
                todos: [
                    FocusTodoModel(title: "Meditation", isCompleted: true),
                    FocusTodoModel(title: "Journaling", isCompleted: false)
                ],
                completionDates: [yesterday, twoDaysAgo]
            )),
            store: FocusStore()
        )
        
        FocusRowView(
            focus: .constant(FocusItemModel(
                title: "Lernziele",
                description: "",
                weakness: "",
                todos: Array(repeating: FocusTodoModel(title: "Task", isCompleted: true), count: 4),
                completionDates: [today, yesterday, twoDaysAgo, calendar.date(byAdding: .day, value: -3, to: today)!]
            )),
            store: FocusStore()
        )
    }
    .padding()
}
