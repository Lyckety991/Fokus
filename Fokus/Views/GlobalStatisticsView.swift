//
//  GlobalStatisticsView.swift
//  Fokus
//
//  Created by Patrick Lanham on 15.07.25.
//

import SwiftUI

struct GlobalStatisticsView: View {
    
    @EnvironmentObject var revenueCat: RevenueCatManager
    
    @State private var showPaywall = false
    @State private var exportFile: URL?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedTimeRange: StatTimeRange = .week
    @State private var isExporting = false
    
    enum StatTimeRange: String, CaseIterable {
        case week = "Woche"
        case month = "Monat"
        case year = "Jahr"
    }
    
    // Berechne echte Deep Insights
    private var deepInsights: DeepInsights {
        StatisticsHelper.calculateDeepInsights(for: store.focusItems)
    }
    
    let statistics: GlobalStatistics
    @ObservedObject var store: FocusStore
    
   
    // Berechne Chart-Daten für gewählten Zeitraum (korrekte Kalender-Berechnung)
    private var overviewChartData: [OverviewDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        
        let (startDate, totalDays) = calculateOverviewTimeRange(calendar: calendar, endDate: endDate, timeRange: selectedTimeRange)
        
        var dataPoints: [OverviewDataPoint] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let completions = store.focusItems.reduce(0) { total, focus in
                total + focus.completionDates.filter { completionDate in
                    calendar.isDate(completionDate, inSameDayAs: currentDate)
                }.count
            }
            
            dataPoints.append(OverviewDataPoint(
                date: currentDate,
                completions: completions
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dataPoints
    }
    
    // Helper für Overview-Zeitraum-Berechnung
    private func calculateOverviewTimeRange(calendar: Calendar, endDate: Date, timeRange: StatTimeRange) -> (Date, Int) {
        switch timeRange {
        case .week:
            let startDate = calendar.date(byAdding: .day, value: -6, to: endDate)!
            return (startDate, 7)
        case .month:
            // Korrekte Monatsberechnung
            let monthStart = calendar.dateInterval(of: .month, for: endDate)?.start ?? endDate
            let daysInMonth = calendar.range(of: .day, in: .month, for: endDate)?.count ?? 30
            let startDate = calendar.date(byAdding: .day, value: -(daysInMonth - 1), to: endDate)!
            return (startDate, daysInMonth)
        case .year:
            // Jahr: 365 Tage zurück (oder aktuelles Jahr vom 1. Januar)
            let yearStart = calendar.dateInterval(of: .year, for: endDate)?.start ?? endDate
            let daysInYear = calendar.range(of: .day, in: .year, for: endDate)?.count ?? 365
            return (yearStart, daysInYear)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Section mit Level & Streak
                heroSection
                
                // Quick Stats Karten
                quickStatsSection
                
                // Activity Overview Chart
                //activityOverviewSection
                
                // Premium Deep Insights
                //deepInsightsSection
                
                // CSV Export
                exportSection
            }
            .padding()
        }
        .navigationTitle("Statistiken")
        .background(Palette.background)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        // FIX: Sheet direkt an exportFile binden
        .sheet(item: $exportFile) { fileURL in
            ActivityViewController(activityItems: [fileURL])
                .onDisappear {
                    // Reset nach dem Schließen
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isExporting = false
                    }
                }
        }
        .alert("Export", isPresented: $showingAlert) {
            Button("OK") {
                isExporting = false
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Level \(statistics.currentLevel)")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundColor(Palette.textPrimary)
                    
                    Text("\(statistics.totalXP) Fokus-Punkte")
                        .font(.title3)
                        .foregroundColor(Palette.textSecondary)
                    
                    // XP Progress Bar
                    let xpProgress = Double(statistics.totalXP % 100) / 100.0
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Nächstes Level")
                                .font(.caption)
                                .foregroundColor(Palette.textSecondary)
                            Spacer()
                            Text("\(statistics.totalXP % 100)/100 XP")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Palette.accent)
                        }
                        
                        ProgressView(value: xpProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: Palette.accent))
                            .scaleEffect(y: 2)
                    }
                }
                
                Spacer()
                
                // Streak Visualization
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Palette.warning, Palette.warning.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        VStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            Text("\(statistics.streak)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .shadow(color: Palette.warning.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Text("Tage Serie")
                        .font(.caption)
                        .foregroundColor(Palette.textSecondary)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Palette.accent.opacity(0.1), Palette.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
    
    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Übersicht")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Palette.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                QuickStatCard(
                    title: "Heute",
                    value: "\(todayCompletions())",
                    subtitle: "Abschlüsse",
                    icon: "checkmark.circle.fill",
                    color: Palette.completed,
                    trend: .up
                )
                
                QuickStatCard(
                    title: "Diese Woche",
                    value: "\(weekCompletions())",
                    subtitle: "Abschlüsse",
                    icon: "calendar.circle.fill",
                    color: Palette.accent,
                    trend: .neutral
                )
                
                QuickStatCard(
                    title: "Aktive Fokusse",
                    value: "\(store.focusItems.count)",
                    subtitle: "Bereiche",
                    icon: "target",
                    color: Palette.secondary,
                    trend: .neutral
                )
                
                QuickStatCard(
                    title: "Durchschnitt",
                    value: String(format: "%.1f", statistics.dailyAverage),
                    subtitle: "pro Tag",
                    icon: "chart.bar.fill",
                    color: Palette.purple,
                    trend: .up
                )
            }
        }
    }
    
    // MARK: - Activity Overview
    private var activityOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Aktivitätsverlauf")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Palette.textPrimary)
                
                Spacer()
                
                // Time Range Picker
                HStack(spacing: 8) {
                    ForEach(StatTimeRange.allCases, id: \.self) { range in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTimeRange = range
                            }
                        }) {
                            Text(range.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedTimeRange == range ? .white : Palette.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedTimeRange == range ? Palette.accent : Palette.textSecondary.opacity(0.1))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Mini Activity Chart
            MiniOverviewChart(data: overviewChartData, timeRange: selectedTimeRange)
                .frame(height: 100)
                .background(Palette.card)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Deep Insights (Premium)
    private var deepInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailanalyse")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Palette.textPrimary)
            
            ZStack {
                // Premium Content
                VStack(spacing: 20) {
                    // Beste/Schlechteste Performance - echte Daten
                    HStack(spacing: 16) {
                        InsightCard(
                            title: "Beste Woche",
                            value: "\(deepInsights.bestWeekCompletions)",
                            subtitle: "Abschlüsse",
                            icon: "trophy.fill",
                            color: Palette.warning
                        )
                        
                        InsightCard(
                            title: "Lieblingsfokus",
                            value: deepInsights.favoriteFocus,
                            subtitle: "\(deepInsights.favoriteFocusCount)x abgeschlossen",
                            icon: "heart.fill",
                            color: Palette.completed
                        )
                    }
                    
                    // Wochentag-Performance - echte Daten
                    if !deepInsights.weekdayPerformance.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Beste Wochentage")
                                .font(.headline)
                                .foregroundColor(Palette.textPrimary)
                            
                            RealWeekdayPerformanceView(weekdayData: deepInsights.weekdayPerformance)
                        }
                    }
                    
                    // Personalisierte Insights - echte Daten
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(deepInsights.insights.enumerated()), id: \.offset) { index, insight in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("\(insight.emoji) \(insight.title)")
                                        .font(.headline)
                                        .foregroundColor(Palette.textPrimary)
                                    
                                    Spacer()
                                    
                                    // Insight-Type Badge
                                    Text(insight.type == .achievement ? "🏆" : insight.type == .tip ? "💡" : "🚀")
                                        .font(.caption)
                                }
                                
                                Text(insight.message)
                                    .font(.body)
                                    .foregroundColor(Palette.textSecondary)
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [
                                        Palette.accent.opacity(0.1),
                                        Palette.purple.opacity(0.05)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            
                            if index < deepInsights.insights.count - 1 {
                                Divider()
                                    .opacity(0.3)
                            }
                        }
                    }
                }
                .padding(20)
                .background(Palette.card)
                .cornerRadius(16)
                
                // Apple-Style Premium Blur
                if !revenueCat.isPremium {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.1),
                                                Color.white.opacity(0.05),
                                                Color.black.opacity(0.02)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                        
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.3), Color.clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                    .frame(width: 44, height: 44)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: "lock.fill")
                                    .font(.title3)
                                    .foregroundColor(Palette.accent)
                            }
                            
                            VStack(spacing: 4) {
                                Text("Premium Insights")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Palette.textPrimary)
                                
                                Text("Detaillierte Analysen und personalisierte Tipps")
                                    .font(.caption)
                                    .foregroundColor(Palette.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .cornerRadius(16)
                    .onTapGesture {
                        showPaywall = true
                    }
                }
            }
        }
    }
    
    // MARK: - Export Section
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Datenexport")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Palette.textPrimary)
            
            Button(action: exportData) {
                HStack {
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("Exportiere...")
                            .font(.headline)
                            .fontWeight(.semibold)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline)
                        Text("CSV-Export")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: isExporting ? [Palette.textSecondary] : [Palette.accent, Palette.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isExporting)
            
            if !store.focusItems.isEmpty {
                Text("Exportiert \(store.focusItems.count) Fokusse mit allen Completion-Daten")
                    .font(.caption)
                    .foregroundColor(Palette.textSecondary)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func todayCompletions() -> Int {
        let calendar = Calendar.current
        return store.focusItems.reduce(0) { total, focus in
            total + focus.completionDates.filter { calendar.isDateInToday($0) }.count
        }
    }
    
    private func weekCompletions() -> Int {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return store.focusItems.reduce(0) { total, focus in
            total + focus.completionDates.filter { calendar.compare($0, to: weekStart, toGranularity: .day) != .orderedAscending }.count
        }
    }
    
    // MARK: - FIXED Export Function
    private func exportData() {
        guard !store.focusItems.isEmpty else {
            alertMessage = "Keine Fokus-Daten zum Exportieren vorhanden."
            showingAlert = true
            return
        }
        
        guard !isExporting else { return }
        
        isExporting = true
        
        // Background Queue für File-Operations
        DispatchQueue.global(qos: .userInitiated).async {
            let focusCSV = DataExportService.exportFocusesToCSV(focusItems: store.focusItems)
            
            guard !focusCSV.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                DispatchQueue.main.async {
                    alertMessage = "Fehler beim Generieren der CSV-Daten."
                    showingAlert = true
                    isExporting = false
                }
                return
            }
            
            let timestamp = DateFormatter().apply {
                $0.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            }.string(from: Date())
            
            let filename = "fokusse_export_\(timestamp).csv"
            
            guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                DispatchQueue.main.async {
                    alertMessage = "Dokumente-Ordner nicht gefunden."
                    showingAlert = true
                    isExporting = false
                }
                return
            }
            
            let fileURL = documentsDir.appendingPathComponent(filename)
            
            do {
                // File schreiben
                try focusCSV.write(to: fileURL, atomically: true, encoding: .utf8)
                
                // Verifizieren dass Datei existiert und lesbar ist
                guard FileManager.default.fileExists(atPath: fileURL.path),
                      let _ = try? String(contentsOf: fileURL, encoding: .utf8) else {
                    DispatchQueue.main.async {
                        alertMessage = "Datei konnte nicht erstellt werden."
                        showingAlert = true
                        isExporting = false
                    }
                    return
                }
                
                // FIX: Direkt exportFile setzen - Sheet wird automatisch angezeigt
                DispatchQueue.main.async {
                    self.exportFile = fileURL
                }
                
                print("✅ CSV-Export erfolgreich erstellt: \(fileURL.lastPathComponent)")
                
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "Fehler beim Erstellen der Datei: \(error.localizedDescription)"
                    showingAlert = true
                    isExporting = false
                }
                print("❌ Export-Fehler: \(error)")
            }
        }
    }
}

// MARK: - Extension für URL Identifiable
extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let trend: TrendDirection
    
    enum TrendDirection {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .foregroundColor(trend.color)
                    .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Palette.textPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(Palette.textSecondary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(Palette.textSecondary.opacity(0.7))
            }
        }
        .padding(16)
        .background(Palette.card)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Palette.textPrimary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Palette.textPrimary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(Palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MiniOverviewChart: View {
    let data: [OverviewDataPoint]
    let timeRange: GlobalStatisticsView.StatTimeRange
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width - 32
            let height = geometry.size.height - 16
            let maxValue = max(data.map { $0.completions }.max() ?? 1, 1)
            let barWidth = width / CGFloat(data.count)
            
            HStack(alignment: .bottom, spacing: 1) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    let barHeight = CGFloat(point.completions) / CGFloat(maxValue) * height
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: point.completions > 0
                                    ? [Palette.accent, Palette.completed]
                                    : [Palette.textSecondary.opacity(0.2)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: max(barWidth - 2, 2), height: max(barHeight, 2))
                        .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.02), value: data)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

struct RealWeekdayPerformanceView: View {
    let weekdayData: [WeekdayPerformance]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(weekdayData, id: \.weekday) { dayData in
                HStack {
                    // Rank Badge
                    ZStack {
                        Circle()
                            .fill(dayData.rank <= 3 ? Palette.accent : Palette.textSecondary.opacity(0.2))
                            .frame(width: 20, height: 20)
                        
                        Text("\(dayData.rank)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(dayData.rank <= 3 ? .white : Palette.textSecondary)
                    }
                    
                    Text(dayData.weekday)
                        .font(.caption)
                        .foregroundColor(Palette.textSecondary)
                        .frame(width: 80, alignment: .leading)
                    
                    // Progress Bar basierend auf echten Daten
                    let maxCompletions = weekdayData.map { $0.averageCompletions }.max() ?? 1
                    let progress = maxCompletions > 0 ? dayData.averageCompletions / maxCompletions : 0
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: dayData.rank <= 3 ? Palette.accent : Palette.textSecondary))
                        .scaleEffect(y: 0.8)
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.1f", dayData.averageCompletions))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Palette.textPrimary)
                        
                        Text("(\(dayData.totalCompletions))")
                            .font(.caption2)
                            .foregroundColor(Palette.textSecondary)
                    }
                    .frame(width: 35)
                }
            }
        }
    }
}

struct WeekdayPerformanceView: View {
    var body: some View {
        VStack(spacing: 8) {
            ForEach(["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"], id: \.self) { day in
                HStack {
                    Text(day)
                        .font(.caption)
                        .foregroundColor(Palette.textSecondary)
                        .frame(width: 70, alignment: .leading)
                    
                    ProgressView(value: Double.random(in: 0.3...1.0))
                        .progressViewStyle(LinearProgressViewStyle(tint: Palette.accent))
                        .scaleEffect(y: 0.8)
                    
                    Text("\(Int.random(in: 1...5))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Palette.textPrimary)
                        .frame(width: 20)
                }
            }
        }
    }
}

// MARK: - Data Models
struct OverviewDataPoint: Equatable {
    let date: Date
    let completions: Int
}

// MARK: - Activity View Controller (erweitert)
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var onComplete: () -> Void = {}
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView()
        }
        
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            if let error = error {
                print("❌ Share-Fehler: \(error)")
            } else if completed {
                print("✅ Export erfolgreich geteilt")
            }
            
            // Immer cleanup ausführen, egal ob success oder error
            DispatchQueue.main.async {
                onComplete()
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Extension für DateFormatter
extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}

#Preview {
    let testManager = RevenueCatManager()
    testManager.setPremiumStatus(false)
    
    let store = FocusStore()
    store.focusItems = [
        FocusItemModel(title: "Meditation", description: "Tägliche Meditation", weakness: "Ablenkung", completionDates: [Date()]),
        FocusItemModel(title: "Sport", description: "Joggen", weakness: "Faulheit", completionDates: [])
    ]
    
    return NavigationStack {
        GlobalStatisticsView(statistics: GlobalStatistics(), store: store)
            .environmentObject(testManager)
    }
}
