//
//  FocusDetailView.swift
//  Fokus
//
//  Created by Patrick Lanham on 09.07.25.
//  Überarbeitet: 11.11.2025
//
/// Detailansicht für einen einzelnen Fokus-Item.
/// - Zeigt Beschreibung, Schwäche, Todos und Aktivitäts-Chart.
/// - Enthält Long-Press-Abschluss inkl. XP-Feedback.
/// - Nutzt Locale-abhängige Datumsformate (de/en) und lokalisierten Kalender.
/// - Synchronisiert Änderungen über `FocusStore`.
//

import SwiftUI

// MARK: - FocusDetailView

struct FocusDetailView: View {

    // MARK: Environment & Dependencies

    @EnvironmentObject private var revenueCat: RevenueCatManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    // MARK: Models

    @Binding var focus: FocusItemModel
    @ObservedObject var store: FocusStore

    // MARK: View State

    @State private var showingEditView = false
    @State private var showCompletionAnimation = false
    @State private var xpEarned = 0
    @State private var pressProgress: CGFloat = 0.0
    @State private var showDeleteConfirmation = false
    @State private var showPaywall = false
    @State private var selectedTimeRange: TimeRange = .week

    // MARK: Types

    enum TimeRange: String, CaseIterable {
        case week
        case month

        var localizedTitle: LocalizedStringKey {
            switch self {
            case .week:  return "Woche"
            case .month: return "Monat"
            }
        }
    }

    // MARK: Locale & Calendar

    private var localizedCalendar: Calendar {
        var cal = Calendar.current
        cal.locale = locale
        return cal
    }

    // MARK: Computed

    private var isCompletedToday: Bool {
        guard let lastDate = focus.lastCompletionDate else { return false }
        return localizedCalendar.isDateInToday(lastDate)
    }

    private var chartData: [ChartDataPoint] {
        let calendar = localizedCalendar
        let endDate = Date()
        let (startDate, dataPoints) = calculateTimeRangeData(calendar: calendar, endDate: endDate, timeRange: selectedTimeRange)
        return generateChartDataPoints(calendar: calendar, startDate: startDate, endDate: endDate, totalDays: dataPoints, timeRange: selectedTimeRange)
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Info-Karten

                    VStack(spacing: 16) {
                        if !focus.description.isEmpty {
                            infoCard(title: "Beschreibung", content: focus.description, icon: "text.alignleft")
                        }

                        if !focus.weakness.isEmpty {
                            infoCard(title: "Schwäche", content: focus.weakness, icon: "exclamationmark.triangle", color: Palette.warning)
                        }

                        if let lastDate = focus.lastCompletionDate {
                            infoCard(
                                title: "Letzter Abschluss",
                                content: formatDateTime(lastDate),
                                icon: "calendar",
                                color: Palette.secondary
                            )
                        }
                    }

                    // MARK: Todos

                    if !focus.todos.isEmpty {
                        todosSection
                    }

                    // MARK: Chart + Stats

                    chartStatisticsView

                    // MARK: Abschluss

                    completionSection
                }
                .padding()
            }
            .background(Palette.background)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingEditView) {
                EditFocusView(focus: $focus, store: store)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .confirmationDialog(
                "Fokus löschen",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Löschen", role: .destructive) {
                    store.deleteFocus(focus)
                    dismiss()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Bist du sicher, dass du '\(focus.title)' löschen möchtest? Diese Aktion kann nicht rückgängig gemacht werden.")
            }
            .onChange(of: focus.todos) { _ in store.updateFocus(focus) }
            .onChange(of: focus.completionDates) { _ in store.updateFocus(focus) }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(focus.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { showingEditView = true }) {
                        Label("Bearbeiten", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(Palette.accent)
                }
            }
        }
    }

    // MARK: - Sections

    private var todosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(Palette.accent)
                Text("Ziele")
                    .titleStyle()

                Spacer()

                Text("\(focus.todos.filter { $0.isCompleted }.count)/\(focus.todos.count)")
                    .font(.headline)
                    .foregroundColor(focus.todos.allSatisfy { $0.isCompleted } ? Palette.completed : Palette.textPrimary)
            }

            LazyVStack(spacing: 12) {
                ForEach($focus.todos) { $todo in
                    todoRow(todo: $todo)
                }
            }
        }
        .padding()
        .cardStyle()
    }

    private var completionSection: some View {
        VStack(spacing: 16) {
            if showCompletionAnimation {
                completionAnimationView
            }

            LongPressButton(
                isCompletedToday: isCompletedToday,
                canComplete: !isCompletedToday,
                pressProgress: $pressProgress,
                action: {
                    showCompletionAnimation = true
                    completeFocus()
                }
            )
        }
        .padding(.top)
    }

    // MARK: - Chart Statistics View

    /// Aktivitätsverlauf inkl. Zeitraum-Picker, Streak und Kennzahlen.
    private var chartStatisticsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header + Streak
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(Palette.accent)
                    Text("Aktivitätsverlauf")
                        .titleStyle()

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(Palette.warning)
                            .font(.caption)
                        Text(streakText)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Palette.textSecondary)
                    }
                }

                // Zeitraum-Auswahl
                HStack {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTimeRange = range
                            }
                        } label: {
                            Text(range.localizedTitle)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedTimeRange == range ? .white : Palette.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedTimeRange == range ? Palette.accent : Palette.textSecondary.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
            }

            // Chart-Container mit Premium-Overlay
            ZStack {
                // Inhalt
                VStack(spacing: 16) {
                    LineChartView(data: chartData)
                        .frame(height: 120)
                        .animation(.easeInOut(duration: 0.5), value: chartData)

                    // Kennzahlen
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentPeriodLabel)
                                .font(.caption)
                                .foregroundColor(Palette.textSecondary)

                            let totalDaysInPeriod = selectedTimeRange == .week
                                ? 7
                                : (localizedCalendar.range(of: .day, in: .month, for: Date())?.count ?? 30)

                            Text("\(currentPeriodCompletions())/\(totalDaysInPeriod)")
                                .font(.headline)
                                .foregroundColor(Palette.accent)
                        }

                        Spacer()

                        VStack(spacing: 4) {
                            Text("Durchschnitt")
                                .font(.caption)
                                .foregroundColor(Palette.textSecondary)
                            Text(String(format: "%.1f", averageCompletions()))
                                .font(.headline)
                                .foregroundColor(Palette.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Gesamt")
                                .font(.caption)
                                .foregroundColor(Palette.textSecondary)
                            Text("\(focus.completionDates.count)")
                                .font(.headline)
                                .foregroundColor(Palette.completed)
                        }
                    }
                }
                .padding()

                // Premium-Gating (leichter Blur)
                if !revenueCat.isPremium {
                    PaywallOverlayView(
                        onTap: { showPaywall = true }
                    )
                }
            }
            .background(Palette.card)
            .cornerRadius(16)
            .clipped()
        }
    }

    // MARK: - Localized Strings

    private var streakText: String {
        let streak = calculateStreak()
        let isGerman = locale.language.languageCode?.identifier == "de"
        return isGerman ? "\(streak) Tage" : "\(streak) days"
    }

    private var currentPeriodLabel: LocalizedStringKey {
        selectedTimeRange == .week ? "Diese Woche" : "Dieser Monat"
    }

    // MARK: - Date/Time Formatting

    private func formatDateTime(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle
                .dateTime
                .day()
                .month(.abbreviated)
                .year()
                .hour()
                .minute()
                .locale(locale)
        )
    }

    // MARK: - Zeitfenster & Chartdaten

    private func calculateTimeRangeData(calendar: Calendar, endDate: Date, timeRange: TimeRange) -> (Date, Int) {
        switch timeRange {
        case .week:
            let startDate = calendar.date(byAdding: .day, value: -6, to: endDate)!
            return (startDate, 7)
        case .month:
            let daysInMonth = calendar.range(of: .day, in: .month, for: endDate)?.count ?? 30
            let startDate = calendar.date(byAdding: .day, value: -(daysInMonth - 1), to: endDate)!
            return (startDate, daysInMonth)
        }
    }

    private func generateChartDataPoints(calendar: Calendar, startDate: Date, endDate: Date, totalDays: Int, timeRange: TimeRange) -> [ChartDataPoint] {
        var points: [ChartDataPoint] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let completions = focus.completionDates.filter { calendar.isDate($0, inSameDayAs: currentDate) }.count

            let label: String
            let showLabel: Bool
            if timeRange == .week {
                let weekdayIndex = calendar.component(.weekday, from: currentDate) - 1
                label = calendar.shortWeekdaySymbols[weekdayIndex]
                showLabel = true
            } else {
                let dayOfMonth = calendar.component(.day, from: currentDate)
                if dayOfMonth == 1 || dayOfMonth % 7 == 0 || calendar.isDate(currentDate, inSameDayAs: endDate) {
                    label = "\(dayOfMonth)"
                    showLabel = true
                } else {
                    label = ""
                    showLabel = false
                }
            }

            points.append(.init(date: currentDate, value: completions, label: label, showLabel: showLabel))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return points
    }

    // MARK: - Statistiken

    private func calculateStreak() -> Int {
        let calendar = localizedCalendar
        let sorted = focus.completionDates.sorted(by: >)
        guard !sorted.isEmpty else { return 0 }

        var streak = 0
        var probe = Date()

        if !calendar.isDateInToday(sorted.first!) {
            probe = calendar.date(byAdding: .day, value: -1, to: probe)!
        }

        for d in sorted {
            if calendar.isDate(d, inSameDayAs: probe) {
                streak += 1
                probe = calendar.date(byAdding: .day, value: -1, to: probe)!
            } else {
                break
            }
        }
        return streak
    }

    private func currentPeriodCompletions() -> Int {
        let calendar = localizedCalendar
        let endDate = Date()
        let startDate: Date

        switch selectedTimeRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -6, to: endDate)!
        case .month:
            startDate = calendar.dateInterval(of: .month, for: endDate)?.start ?? endDate
        }

        return focus.completionDates.filter {
            calendar.compare($0, to: startDate, toGranularity: .day) != .orderedAscending
        }.count
    }

    private func averageCompletions() -> Double {
        let calendar = localizedCalendar
        let endDate = Date()
        let totalDays: Double = (selectedTimeRange == .week)
            ? 7.0
            : Double(calendar.range(of: .day, in: .month, for: endDate)?.count ?? 30)

        let completions = Double(currentPeriodCompletions())
        return completions / max(totalDays, 1.0)
    }

    // MARK: - Subviews

    private func infoCard(title: LocalizedStringKey, content: String, icon: String, color: Color = Palette.accent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .headlineStyle()
            }
            Text(content)
                .bodyTextStyle()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func todoRow(todo: Binding<FocusTodoModel>) -> some View {
        HStack {
            Button { todo.wrappedValue.isCompleted.toggle() } label: {
                Image(systemName: todo.wrappedValue.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(todo.wrappedValue.isCompleted ? Palette.completed : Palette.textSecondary)
            }

            TextField("Todo", text: todo.title)
                .bodyTextStyle()

            if todo.wrappedValue.isCompleted {
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundColor(Palette.completed)
            }
        }
        .padding()
        .background(Palette.card.opacity(0.5))
        .cornerRadius(12)
    }

    private var completionAnimationView: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Palette.accent)
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }

            Text(xpReceivedText)
                .headlineStyle()
                .padding()
                .background(Palette.completed.opacity(0.2))
                .foregroundColor(Palette.completed)
                .cornerRadius(12)
        }
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { showCompletionAnimation = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { dismiss() }
            }
        }
    }

    private var xpReceivedText: String {
        let isGerman = locale.language.languageCode?.identifier == "de"
        return isGerman ? "+\(xpEarned) XP erhalten!" : "+\(xpEarned) XP received!"
    }

    // MARK: - Abschluss-Action

    private func completeFocus() {
        let baseXP = 25
        let bonusXP = focus.todos.count * 5
        xpEarned = baseXP + bonusXP

        // Alle Todos als erledigt markieren
        for i in 0..<focus.todos.count {
            focus.todos[i].isCompleted = true
        }

        withAnimation(.spring()) { showCompletionAnimation = true }

        store.completeFocus(focus.id)
        store.updateFocus(focus)
    }

    // MARK: - Long Press Button (Nested)

    struct LongPressButton: View {
        let isCompletedToday: Bool
        let canComplete: Bool
        @Binding var pressProgress: CGFloat
        let action: () -> Void

        @State private var isPressing = false
        @State private var timer: Timer?
        @Environment(\.locale) private var locale

        var body: some View {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(backgroundFill)
                        .frame(height: 60)

                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(progressFill)
                            .frame(width: geometry.size.width * pressProgress, height: 60)
                            .animation(.linear(duration: 0.1), value: pressProgress)
                    }

                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: isCompletedToday ? "checkmark.seal.fill" : "flag.checkered")
                                .font(.title2)
                            Text(buttonText)
                                .font(.subheadline)
                        }
                        Spacer()
                    }
                    .foregroundColor(foregroundColor)
                }
                .frame(height: 60)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in handlePressStart() }
                        .onEnded { _ in handlePressEnd() }
                )
                .disabled(!canComplete)

                if canComplete {
                    Text(holdButtonText)
                        .font(.caption)
                        .foregroundColor(Palette.textSecondary)
                }
            }
        }

        private var backgroundFill: Color {
            isCompletedToday ? Palette.completed.opacity(0.2) : Palette.textSecondary.opacity(0.2)
        }

        private var progressFill: LinearGradient {
            LinearGradient(gradient: Gradient(colors: [Palette.accent, Palette.completed]), startPoint: .leading, endPoint: .trailing)
        }

        private var foregroundColor: Color {
            isCompletedToday ? Palette.completed : .white
        }

        private var buttonText: String {
            let isGerman = locale.language.languageCode?.identifier == "de"

            if isCompletedToday {
                return isGerman ? "Heute abgeschlossen" : "Completed today"
            } else if isPressing {
                return "\(Int(pressProgress * 100))%"
            } else {
                return isGerman ? "Tagesabschluss" : "Daily completion"
            }
        }

        private var holdButtonText: String {
            let isGerman = locale.language.languageCode?.identifier == "de"
            return isGerman ? "Halte den Button 2 Sekunden gedrückt" : "Hold the button for 2 seconds"
        }

        private func handlePressStart() {
            guard canComplete, !isPressing else { return }
            isPressing = true
            pressProgress = 0.0

            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                pressProgress += 0.030
                if pressProgress >= 1.0 {
                    action()
                    resetPressState()
                }
            }
        }

        private func handlePressEnd() {
            if isPressing { resetPressState() }
        }

        private func resetPressState() {
            timer?.invalidate()
            timer = nil
            withAnimation(.spring()) {
                isPressing = false
                pressProgress = 0.0
            }
        }
    }
}

// MARK: - Paywall Overlay (subtle blur)

private struct PaywallOverlayView: View {
    let onTap: () -> Void

    var body: some View {
        ZStack {
            // Dezent: thinMaterial + leichte Opacity; subtiler Lichtverlauf oben
            Rectangle()
                .fill(.thinMaterial)
                .opacity(0.98)                // <= HIER: leichter Blur/Glass
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(                       // feiner Rahmen, kaum sichtbar
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(Palette.accent)
                }

                Text("Premium")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(Palette.textPrimary.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                    )
            }
            .scaleEffect(0.9)
        }
        .contentShape(Rectangle()) // gesamte Fläche tappable
        .onTapGesture(perform: onTap)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text("Premium freischalten"))
    }
}

// MARK: - Line Chart View

struct LineChartView: View {
    let data: [ChartDataPoint]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let chartHeight = geometry.size.height - 30
            let maxValue = max(data.map { $0.value }.max() ?? 1, 1)
            let xStep = width / CGFloat(max(data.count - 1, 1))

            VStack(spacing: 0) {

                ZStack {

                    // Grid
                    VStack(spacing: 0) {
                        ForEach(0..<4, id: \.self) { i in
                            Rectangle()
                                .fill(Palette.textSecondary.opacity(0.1))
                                .frame(height: 0.5)
                            if i < 3 { Spacer() }
                        }
                    }

                    // Line
                    Path { path in
                        for (index, point) in data.enumerated() {
                            let x = CGFloat(index) * xStep
                            let y = chartHeight - (CGFloat(point.value) / CGFloat(maxValue)) * chartHeight

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(colors: [Palette.accent, Palette.completed], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )

                    // Points
                    ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                        let x = CGFloat(index) * xStep
                        let y = chartHeight - (CGFloat(point.value) / CGFloat(maxValue)) * chartHeight

                        Circle()
                            .fill(point.value > 0 ? Palette.completed : Palette.textSecondary.opacity(0.3))
                            .frame(width: point.value > 0 ? 8 : 4, height: point.value > 0 ? 8 : 4)
                            .position(x: x, y: y)
                            .shadow(color: point.value > 0 ? Palette.completed.opacity(0.3) : .clear, radius: 2)
                    }
                }
                .frame(height: chartHeight)

                // X-Achsen Labels
                HStack {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                        if point.showLabel && !point.label.isEmpty {
                            Text(point.label)
                                .font(.caption2)
                                .foregroundColor(Palette.textSecondary)
                        } else {
                            Text("").font(.caption2)
                        }
                        if index < data.count - 1 { Spacer() }
                    }
                }
                .padding(.top, 12)
                .frame(height: 18)
            }
        }
    }
}

// MARK: - Chart Data

struct ChartDataPoint: Equatable {
    let date: Date
    let value: Int
    let label: String
    let showLabel: Bool
}

// MARK: - Preview

struct FocusDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFocus = FocusItemModel(
            title: "Produktivität steigern",
            description: "Täglich konzentriert arbeiten ohne Ablenkungen",
            weakness: "Social Media",
            todos: [
                FocusTodoModel(title: "Handy in den Flugmodus"),
                FocusTodoModel(title: "Alle Benachrichtigungen deaktivieren"),
                FocusTodoModel(title: "Pomodoros einhalten", isCompleted: true)
            ],
            completionDates: [Date(), Calendar.current.date(byAdding: .day, value: -1, to: Date())!]
        )

        Group {
            FocusDetailView(focus: .constant(sampleFocus), store: FocusStore())
                .environmentObject(RevenueCatManager())
                .environment(\.locale, Locale(identifier: "de"))
                .previewDisplayName("DE")

            FocusDetailView(focus: .constant(sampleFocus), store: FocusStore())
                .environmentObject(RevenueCatManager())
                .environment(\.locale, Locale(identifier: "en"))
                .previewDisplayName("EN")
        }
    }
}
