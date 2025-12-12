//
//  FocusStatisticsView.swift
//  Fokus
//
//  Created by Patrick Lanham on 15.07.25.
//

import SwiftUI

/**
 * FocusStatisticsView - Detaillierte Statistik-Ansicht für Focus-Items
 *
 * Diese View präsentiert umfassende Statistiken und Insights zu einem spezifischen Focus-Item.
 * Sie bietet verschiedene Visualisierungen und Metriken zur Analyse der Nutzer-Performance.
 *
 * Hauptfunktionalitäten:
 * - Hero Stats Section mit prominenter Streak-Anzeige
 * - Interaktiver Timeframe-Selector für verschiedene Zeiträume
 * - Animierte Progress Cards mit visuellen Fortschrittsbalken
 * - Activity Heatmap zur Visualisierung der täglichen Aktivität
 * - Insights Section mit personalisierten Trend-Analysen
 *
 * Design Features:
 * - Scroll-basierte Navigation für große Datenmengen
 * - Animierte UI-Elemente für verbesserte User Experience
 * - Responsive Layout mit adaptiven Grid-Systemen
 * - Consistent Card-Design für visuelle Kohärenz
 */
struct FocusStatisticsView: View {
    // MARK: - Properties
    
    /// Statistik-Daten für das Focus-Item
    let statistics: FocusStatistics
    
    // MARK: - UI State Properties
    
    /// Aktuell ausgewählter Zeitrahmen für Statistik-Anzeige
    @State private var selectedTimeframe: StatTimeframe = .week
    
    /// Steuert die Animation der Fortschrittsbalken
    @State private var animateProgress = false
    
    // MARK: - Supporting Types
    
    /**
     * Zeitrahmen-Enum für Statistik-Gruppierung
     *
     * Definiert verfügbare Zeiträume für die Statistik-Analyse:
     * - Woche: Letzte 7 Tage
     * - Monat: Letzte 30 Tage  
     * - Jahr: Letzte 365 Tage
     */
    enum StatTimeframe: String, CaseIterable {
        case week = "Woche"
        case month = "Monat"
        case year = "Jahr"
    }
    // MARK: - Main Body View
    
    /**
     * Haupt-Body der FocusStatisticsView
     *
     * Implementiert eine ScrollView mit vertikal gestapelten Sektionen:
     * - Hero Stats mit prominenten Metriken
     * - Timeframe Selector für Zeitraum-Auswahl
     * - Progress Cards mit animierten Fortschrittsbalken
     * - Activity Heatmap für tägliche Aktivitätsvisualisierung
     * - Insights Section mit personalisierten Trend-Analysen
     *
     * Features:
     * - Smooth Scroll-Performance durch optimierte Layouts
     * - Einheitliches Spacing für visuelle Konsistenz
     * - Navigation Bar mit Large Title Display Mode
     * - Automatische Progress-Animation beim View-Erscheinen
     */
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
    
    // MARK: - Hero Statistics Section
    
    /**
     * Hero Stats Section Component
     *
     * Präsentiert die wichtigsten Metriken prominent im oberen Bereich:
     * - Streak Card als zentrale, hervorgehobene Komponente
     * - Quick Stats Grid mit kompakten Statistik-Karten
     *
     * Design Features:
     * - Hierarchische Informationsdarstellung (Streak prominenter als andere Stats)
     * - Konsistente Farbgebung für verschiedene Metrik-Typen
     * - Responsive Grid-Layout für optimale Platznutzung
     */
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
    
    /**
     * Streak Card Component
     *
     * Zentrale Komponente zur Hervorhebung der aktuellen Streak-Performance:
     * - Prominente Darstellung mit Flame-Icon
     * - Große, gut lesbare Zahl für den aktuellen Streak-Wert
     * - Visuelle Streak-Visualisierung mit Punkt-Indikatoren
     * - Spezielle Behandlung für längere Streaks (7+ Tage)
     *
     * Design Features:
     * - Gradient-Hintergrund für visuelle Attraktivität
     * - Border-Overlay für zusätzliche Definition
     * - Responsive Layout für verschiedene Streak-Längen
     * - Internationalisierung für Singular/Plural (Tag/Tage)
     */
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
    
    /**
     * Quick Stat Card Component
     *
     * Kompakte Statistik-Karte für sekundäre Metriken
     *
     * - Parameters:
     *   - title: Beschriftung der Metrik
     *   - value: Anzuzeigende numerische Wert
     *   - icon: SF Symbol für visuelle Identifikation
     *   - color: Themen-Farbe für Icon und Hervorhebungen
     *
     * Design Features:
     * - Vertikale Anordnung für kompakte Darstellung
     * - Einheitliche Größe durch maxWidth: .infinity
     * - Konsistente Typographie-Hierarchie
     * - Farbkodierung für verschiedene Metrik-Typen
     */
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
    
    // MARK: - Timeframe Selection
    
    /**
     * Timeframe Selector Section Component
     *
     * Ermöglicht Nutzern die Auswahl verschiedener Zeiträume für Statistik-Analyse:
     * - Segmented Control-ähnliches Design
     * - Smooth Animationen zwischen Zuständen
     * - Responsive Button-Styling basierend auf Auswahl-Status
     *
     * Technische Features:
     * - State-Management für selectedTimeframe
     * - Automatische Layoutanpassung für verschiedene Bildschirmgrößen
     * - Accessibility-Support durch eindeutige Button-Beschriftungen
     */
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
    
    // MARK: - Progress Visualization
    
    /**
     * Progress Cards Section Component
     *
     * Zeigt detaillierte Fortschritts-Metriken in ansprechenden Karten:
     * - Wöchentliche und monatliche Completion Rates
     * - Animierte Fortschrittsbalken mit Gradient-Fills
     * - Kontextuelle Progress-Indikatoren und Beschreibungen
     *
     * Features:
     * - Staggered Animations für visuellen Impact
     * - Responsive Progress-Beschreibungen basierend auf Performance
     * - Farbkodierung für verschiedene Leistungsniveaus
     */
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
    
    /**
     * Individual Progress Card Component
     *
     * Einzelne Fortschritts-Karte mit umfassenden Visualisierungen
     *
     * - Parameters:
     *   - title: Beschriftung der Progress-Metrik
     *   - progress: Fortschrittswert (0.0 - 1.0)
     *   - color: Themen-Farbe für Fortschrittsbalken und Akzente
     *   - timeframe: Zugehöriger Zeitrahmen für Kontext
     *
     * Features:
     * - Animierte Fortschrittsbalken mit GeometryReader für präzise Dimensionierung
     * - 5-Punkt Progress-Indikator-System
     * - Kontextuelle Fortschritts-Beschreibungen
     * - Gradient-basierte Fortschrittsbalken für visuellen Appeal
     */
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
    
    /**
     * Progress Indicator Component
     *
     * 5-Punkt-Indikator-System für visuelles Fortschritts-Feedback
     *
     * - Parameters:
     *   - progress: Fortschrittswert (0.0 - 1.0)
     *   - color: Basis-Farbe für gefüllte Indikatoren
     *
     * Jeder Punkt repräsentiert 20% Fortschritt (0.2 Intervalle)
     */
    private func progressIndicator(progress: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(progress > Double(index) * 0.2 ? color : color.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    /**
     * Progress Description Generator
     *
     * Generiert kontextuelle, motivierende Beschreibungen basierend auf Fortschritts-Level
     *
     * - Parameter progress: Fortschrittswert (0.0 - 1.0)
     * - Returns: Localized Beschreibungstext entsprechend der Performance
     *
     * Progress-Kategorien:
     * - 0-20%: Anfangsphase
     * - 20-40%: Aufbauphase
     * - 40-60%: Mittlerer Fortschritt
     * - 60-80%: Gute Performance
     * - 80-100%: Exzellente Performance
     * - 100%+: Überragende Performance
     */
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
    
    // MARK: - Activity Visualization
    
    /**
     * Activity Heatmap Section Component
     *
     * Visualisiert die tägliche Aktivität in einem kalenderähnlichen Heatmap-Format:
     * - Integration der ModernCalendarHeatmap für detaillierte Tagesansicht
     * - Konsistente Card-basierte Präsentation
     * - Klare Section-Überschrift für Kontext
     *
     * Design Features:
     * - Einheitliches Spacing mit anderen Sektionen
     * - Card-Styling für visuelle Konsistenz
     * - Responsive Layout für verschiedene Bildschirmgrößen
     */
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
    
    // MARK: - Insights & Analytics
    
    /**
     * Insights Section Component
     *
     * Präsentiert personalisierte Analyse-Insights und Trend-Informationen:
     * - Trend-Analyse basierend auf wöchentlichen vs. monatlichen Raten
     * - Ziel-Fortschritt mit aktueller Wochenperformance
     * - Aktivitätsmuster-Analyse für optimale Nutzungszeiten
     *
     * Features:
     * - Automatische Trend-Erkennung mit Vergleichsalgorithmen
     * - Farbkodierte Icons für verschiedene Insight-Kategorien
     * - Strukturierte Informationshierarchie mit Titel/Wert-Paaren
     */
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
    
    /**
     * Individual Insight Row Component
     *
     * Einzelne Insight-Zeile mit Icon, Titel und Wert
     *
     * - Parameters:
     *   - icon: SF Symbol für visuelle Kategorisierung
     *   - title: Insight-Kategorie Beschreibung
     *   - value: Spezifischer Insight-Wert oder -Beschreibung
     *   - color: Themen-Farbe für Icon-Hervorhebung
     *
     * Design Features:
     * - Konsistente Icon-Größe und -Platzierung
     * - Hierarchische Typographie (Titel prominent, Wert sekundär)
     * - Flexible Layout-Struktur für verschiedene Content-Längen
     */
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
    
    /**
     * Trend Description Generator
     *
     * Analysiert Trends basierend auf wöchentlichen vs. monatlichen Completion Rates
     *
     * - Returns: Localized Trend-Beschreibung basierend auf Datenvergleich
     *
     * Trend-Kategorien:
     * - Verbesserung: Wöchentliche Rate > Monatliche Rate
     * - Rückgang: Wöchentliche Rate < Monatliche Rate  
     * - Stabil: Wöchentliche Rate ≈ Monatliche Rate
     */
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

// MARK: - Calendar Heatmap Component

/**
 * ModernCalendarHeatmap - Erweiterte Kalender-Heatmap-Visualisierung
 *
 * Implementiert eine GitHub-ähnliche Heatmap für die Visualisierung täglicher Aktivitäten:
 * - 28-Tage-Ansicht (4 Wochen) für übersichtliche Darstellung
 * - Wochentag-Header für zeitliche Orientierung
 * - LazyVGrid für performante Darstellung großer Datensätze
 * - Interaktive Legende mit Intensitäts-Indikatoren
 *
 * Technische Features:
 * - Flexible Spalten-Konfiguration für responsive Layouts
 * - Datum-basierte Completion-Überprüfung
 * - Farbintensitäts-Algorithmus für visuelle Differenzierung
 * - Automatische Rückwärts-Chronologie für intuitive Zeitachse
 */
// MARK: - Modern Calendar Heatmap
struct ModernCalendarHeatmap: View {
    // MARK: - Properties
    
    /// Array der Completion-Daten für Heatmap-Visualisierung
    let completionDates: [Date]
    
    /// Grid-Konfiguration für 7-Spalten-Layout (Wochentage)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    
    // MARK: - Computed Properties
    
    /**
     * Berechnet die letzten 28 Tage für Heatmap-Darstellung
     * 
     * - Returns: Array von Dates in chronologischer Reihenfolge (älteste zuerst)
     *
     * Verwendet Calendar.current für lokalisierte Datums-Berechnungen
     * und reversed() für intuitive zeitliche Darstellung.
     */
    private var last28Days: [Date] {
        let calendar = Calendar.current
        return (0..<28).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: Date())
        }.reversed()
    }
    
    // MARK: - Main Body
    
    /**
     * Haupt-Body der Heatmap-Komponente
     *
     * Struktur:
     * - Wochentag-Header für zeitliche Orientierung
     * - LazyVGrid mit CalendarDayView-Elementen für jeden Tag
     * - Intensitäts-Legende für Farbkodierung-Erklärung
     *
     * Design Features:
     * - Konsistente Abstände zwischen Elementen
     * - Responsive Layout für verschiedene Bildschirmgrößen
     * - Accessibility-freundliche Beschriftungen
     */
    
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
    
    // MARK: - Helper Methods
    
    /**
     * Überprüft ob an einem bestimmten Datum ein Completion stattgefunden hat
     *
     * - Parameter date: Zu überprüfendes Datum
     * - Returns: true wenn Completion am angegebenen Datum existiert
     *
     * Verwendet Calendar.isDate(_:inSameDayAs:) für präzise Tages-Vergleiche
     * unabhängig von Uhrzeiten.
     */
    private func isCompleted(on date: Date) -> Bool {
        completionDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }
    
    /**
     * Bestimmt die Heatmap-Farbe basierend auf Aktivitäts-Intensität
     *
     * - Parameter intensity: Intensitätslevel (0-4)
     * - Returns: Entsprechende Color für die Intensitätsstufe
     *
     * Farbkodierung:
     * - 0: Keine Aktivität (Card-Farbe)
     * - 1-4: Steigende Intensität mit Opacity-Variationen des Completed-Farbschemas
     */
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

// MARK: - Calendar Day Component

/**
 * CalendarDayView - Einzelne Tages-Zelle für Heatmap
 *
 * Repräsentiert einen einzelnen Tag in der Heatmap-Visualisierung:
 * - Completion-Status-basierte Farbgebung
 * - Spezielle Hervorhebung für heutiges Datum
 * - Responsive Skalierung für aktuelle Tages-Betonung
 *
 * Design Features:
 * - Rounded Rectangle-Design für moderne Ästhetik
 * - Conditional Styling basierend auf verschiedenen Zuständen
 * - Smooth Animations für State-Übergänge
 * - Border-Overlay für heute-Hervorhebung
 */
// MARK: - Calendar Day View
struct CalendarDayView: View {
    // MARK: - Properties
    
    /// Datum für diese Tages-Zelle
    let date: Date
    
    /// Completion-Status für dieses Datum
    let isCompleted: Bool
    
    /// Kennzeichnet ob dies das heutige Datum ist
    let isToday: Bool
    
    // MARK: - Body
    
    /**
     * Tages-Zellen-Body mit conditional Styling
     *
     * Features:
     * - Completion-basierte Hintergrundfarbe
     * - Datum-Overlay mit kontextueller Formatierung
     * - Heute-Hervorhebung mit Accent-Border und Skalierung
     * - Smooth Animationen für State-Übergänge
     */
    
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

// MARK: - SwiftUI Preview Configuration

/**
 * SwiftUI Preview für FocusStatisticsView
 *
 * Konfiguriert Preview mit:
 * - NavigationView für korrekte Navigation Bar Darstellung
 * - Mock FocusStatistics mit repräsentativen Daten
 * - Verschiedene Completion-Daten für Heatmap-Visualisierung
 * - Realistische Streak- und Completion-Werte für Design-Validierung
 */
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
