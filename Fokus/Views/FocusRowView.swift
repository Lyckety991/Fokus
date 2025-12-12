//
//  FocusRowView.swift
//  Fokus
//
//  Created by Patrick Lanham on 10.07.25.
//  Überarbeitet: 11.11.2025
//

import SwiftUI

struct FocusRowView: View {
    // MARK: - Bindings & Dependencies
    @Binding var focus: FocusItemModel
    var store: FocusStore
    @Environment(\.locale) private var locale

    // MARK: - State
    @State private var showingCompleteAnimation = false
    @State private var animatingDate: Date? = nil
    @State private var pulseScale: CGFloat = 1.0

    // MARK: - Locale-aware Calendar
    private var localizedCalendar: Calendar {
        var cal = Calendar.current
        cal.locale = locale
        return cal
    }

    // MARK: - Cached DateFormatters
    private static var dayNumberFormatter = DateFormatter()
    private static var dayLabelFormatter = DateFormatter()

    // MARK: - Derived
    private var completedCount: Int {
        focus.todos.filter { $0.isCompleted }.count
    }

    private var progress: CGFloat {
        focus.todos.isEmpty ? 0 : CGFloat(completedCount) / CGFloat(focus.todos.count)
    }

    private var isCompletedToday: Bool {
        focus.completionDates.contains { localizedCalendar.isDateInToday($0) }
    }

    /// Streak-Berechnung: zusammenhängende Tage rückwärts ab heute/gestern
    private var currentStreak: Int {
        let dates = focus.completionDates.sorted(by: >)
        guard let lastDate = dates.first else { return 0 }

        let daysDiff = localizedCalendar.dateComponents([.day], from: localizedCalendar.startOfDay(for: lastDate), to: localizedCalendar.startOfDay(for: Date())).day ?? 0
        if daysDiff > 1 { return 0 }

        var streak = 1
        var current = lastDate
        for d in dates.dropFirst() {
            guard let prev = localizedCalendar.date(byAdding: .day, value: -1, to: localizedCalendar.startOfDay(for: current)),
                  localizedCalendar.isDate(d, inSameDayAs: prev)
            else { break }
            streak += 1
            current = d
        }
        return streak
    }

    /// Letzte 7 Kalendertage (inkl. heute), locale-konsistent ab Tagesbeginn
    private var last7Days: [Date] {
        let today = localizedCalendar.startOfDay(for: Date())
        return (0..<7).compactMap { localizedCalendar.date(byAdding: .day, value: -$0, to: today) }.reversed()
    }

    // MARK: - Body
    var body: some View {
        NavigationLink(destination: FocusDetailView(focus: $focus, store: store)) {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                calendarSection
               
               
            }
            .padding(16)
            .background(cardBackground)
            .overlay(cardBorder)
            .scaleEffect(showingCompleteAnimation ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: showingCompleteAnimation)
        }
        .buttonStyle(.plain)
        .onAppear {
            resetTodosIfNeeded()
        }
        .onChange(of: focus.completionDates) { newDates in
            if let latest = newDates.sorted(by: >).first,
               localizedCalendar.isDateInToday(latest) {
                triggerCompletionAnimation(for: latest)
            }
        }
    }

    // MARK: - Animation Trigger
    private func triggerCompletionAnimation(for date: Date) {
        showingCompleteAnimation = true
        animatingDate = date

        withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
            pulseScale = 1.3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.2)) {
                pulseScale = 1.0
                animatingDate = nil
                showingCompleteAnimation = false
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(focus.title)
                    .font(.headline)
                    .foregroundColor(Palette.textPrimary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                statusBadge

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
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Streak \(currentStreak)"))
                }
            }
        }
    }

    private var statusBadge: some View {
        Group {
            if isCompletedToday {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill").font(.caption)
                    Text("Erledigt").font(.caption2).fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Palette.completed)
                .clipShape(Capsule())
                .accessibilityLabel(Text("Heute erledigt"))
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.caption)
                    Text("In Arbeit").font(.caption2).fontWeight(.semibold)
                }
                .foregroundColor(Palette.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Palette.card)
                .clipShape(Capsule())
                .accessibilityLabel(Text("In Arbeit"))
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

                        // Animated Indicator
                        ZStack {
                            if shouldAnimate(date: date) {
                                Circle()
                                    .fill(Palette.completed.opacity(0.30))
                                    .frame(width: 36, height: 36)
                                    .scaleEffect(pulseScale)
                                    .opacity(pulseScale > 1.0 ? 0.5 : 0)
                                    .animation(.easeInOut(duration: 0.3), value: pulseScale)
                            }

                            Circle()
                                .fill(completionColor(for: date))
                                .frame(width: 24, height: 24)
                                .scaleEffect(shouldAnimate(date: date) ? pulseScale * 0.9 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pulseScale)

                            Circle()
                                .stroke(
                                    date.isToday ? Palette.accent : completionBorderColor(for: date),
                                    lineWidth: date.isToday ? 2 : 1
                                )
                                .frame(width: 24, height: 24)
                                .scaleEffect(shouldAnimate(date: date) ? pulseScale * 0.9 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pulseScale)

                            if isCompleted(on: date) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                                    .scaleEffect(shouldAnimate(date: date) ? pulseScale : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pulseScale)
                            }

                            // kleine Funken
                            if shouldAnimate(date: date) && pulseScale > 1.2 {
                                ForEach(0..<4, id: \.self) { index in
                                    Circle()
                                        .fill(Palette.completed)
                                        .frame(width: 3, height: 3)
                                        .offset(
                                            x: cos(CGFloat(index) * .pi / 2) * 20 * (pulseScale - 1),
                                            y: sin(CGFloat(index) * .pi / 2) * 20 * (pulseScale - 1)
                                        )
                                        .opacity(Double(max(0, 2 - pulseScale)))
                                        .animation(.easeOut(duration: 0.5), value: pulseScale)
                                }
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("\(accessibilityDayString(for: date)): \(isCompleted(on: date) ? "abgeschlossen" : "offen")"))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(12)
        .background(Palette.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Helpers (Calendar/Formatting)
    private func shouldAnimate(date: Date) -> Bool {
        guard let animatingDate = animatingDate else { return false }
        return localizedCalendar.isDate(date, inSameDayAs: animatingDate)
    }

    private func isCompleted(on date: Date) -> Bool {
        focus.completionDates.contains { localizedCalendar.isDate($0, inSameDayAs: date) }
    }

    private func completionColor(for date: Date) -> Color {
        isCompleted(on: date) ? Palette.completed : Color.clear
    }

    private func completionBorderColor(for date: Date) -> Color {
        isCompleted(on: date) ? Palette.completed : Palette.textSecondary.opacity(0.25)
    }

    private func dayOfMonth(for date: Date) -> String {
        Self.dayNumberFormatter.locale = locale
        // lokalisiert, einstellige/zweistellige Tage
        Self.dayNumberFormatter.setLocalizedDateFormatFromTemplate("d")
        return Self.dayNumberFormatter.string(from: date)
    }

    private func dayLabel(for date: Date) -> String {
        Self.dayLabelFormatter.locale = locale
        Self.dayLabelFormatter.setLocalizedDateFormatFromTemplate("E")
        let s = Self.dayLabelFormatter.string(from: date)
        return String(s.prefix(2)).uppercased()
    }

    /// Für VoiceOver ein freundlicheres Label (z. B. „Montag, 10“)
    private func accessibilityDayString(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = locale
        fmt.setLocalizedDateFormatFromTemplate("EEEE d")
        return fmt.string(from: date)
    }

    // MARK: - Optional: Progress Section
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

    // MARK: - Card Styling
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Palette.card)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Palette.textSecondary.opacity(0.12), lineWidth: 1)
    }

    // MARK: - Daily Reset Logic
    /// Setzt Todos zurück, wenn heute noch NICHT abgeschlossen wurde, aber es in der Vergangenheit Abschlüsse gab.
    private func resetTodosIfNeeded() {
        let cal = localizedCalendar

        // Falls heute bereits abgeschlossen: nichts zurücksetzen
        if focus.completionDates.contains(where: { cal.isDateInToday($0) }) { return }

        // Wurde irgendwann vor heute abgeschlossen?
        let todayStart = cal.startOfDay(for: Date())
        let hadPastCompletion = focus.completionDates.contains { $0 < todayStart }
        guard hadPastCompletion else { return }

        var changed = false
        for i in 0..<focus.todos.count {
            if focus.todos[i].isCompleted {
                focus.todos[i].isCompleted = false
                changed = true
            }
        }
        if changed { store.updateFocus(focus) }
    }
}

// MARK: - Date Convenience
extension Date {
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(self) }
}

// MARK: - Preview
#Preview {
    let store = FocusStore()

    let sampleFocus = FocusItemModel(
        title: "Meditation",
        description: "Tägliche Meditation für mehr Achtsamkeit",
        weakness: "Unruhe am Morgen",
        todos: [
            FocusTodoModel(title: "5 Min meditieren", isCompleted: true),
            FocusTodoModel(title: "Atemübung machen", isCompleted: true),
            FocusTodoModel(title: "Tagebuch schreiben", isCompleted: false)
        ],
        completionDates: [
            Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        ]
    )

    return VStack {
        FocusRowView(focus: .constant(sampleFocus), store: store)
        Spacer()
    }
    .padding()
    .background(Palette.background)
}
