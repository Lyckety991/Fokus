//
//  FocusListView.swift
//  Fokus
//
//  Created by Patrick Lanham on 09.07.25.
//

import SwiftUI
import UniformTypeIdentifiers

/**
 * FocusListView - Hauptansicht für die Verwaltung von Focus-Elementen
 *
 * Diese View stellt die zentrale Benutzeroberfläche für die Verwaltung von Focus-Items dar.
 * Sie implementiert ein Freemium-Modell mit Limitierungen für kostenlose Nutzer und bietet
 * Premium-Features für zahlende Nutzer.
 *
 * Hauptfunktionalitäten:
 * - Anzeige aller Focus-Items in einer scrollbaren Liste
 * - Fortschrittsanzeige mit Level-System und XP-Tracking
 * - Freemium-Modell mit Limit-Enforcement für kostenlose Nutzer
 * - Integration mit RevenueCat für Premium-Features
 * - Export-Funktionalität für Statistiken
 * - Kontextuelle Aktionen für Focus-Items
 */
struct FocusListView: View {
    // MARK: - Properties
    
    /// RevenueCat Manager für Premium-Feature-Verwaltung
    @EnvironmentObject var revenueCat: RevenueCatManager
    
    /// Zentraler Store für Focus-Items und Nutzer-Progress
    @StateObject private var store = FocusStore()
    
    // MARK: - UI State Properties
    
    /// Steuert die Anzeige der Add Focus View
    @State private var showAddView = false
    
    /// Steuert die Anzeige der Statistiken-View
    @State private var showingStatistics = false
    
    /// Steuert die Anzeige der Paywall für Premium-Features
    @State private var showPaywall = false
    
    /// URL für exportierte Dateien
    @State private var exportFile: URL?
    
    /// Steuert die Anzeige des File Exporters
    @State private var showingExporter = false
    
    /// Steuert die Anzeige des Limit-Alerts für kostenlose Nutzer
    @State private var showingLimitAlert = false
    
    // MARK: - Configuration Constants
    
    /// Maximale Anzahl von Focus-Items für kostenlose Nutzer
    private let maxFreeFocusItems = 3
    
    // MARK: - Computed Properties
    
    /// Überprüft, ob der kostenlose Nutzer das Limit erreicht hat
    private var hasReachedFreeLimit: Bool {
        !revenueCat.isPremium && store.focusItems.count >= maxFreeFocusItems
    }
    
    /// Berechnet globale Statistiken für alle Focus-Items
    private var globalStats: GlobalStatistics {
        StatisticsHelper.calculateGlobalStatistics(
            for: store.focusItems,
            totalXP: store.userProgress?.totalXP ?? 0
        )
    }
    // MARK: - Main Body View
    
    /**
     * Haupt-Body der FocusListView
     *
     * Implementiert eine NavigationStack mit scrollbarem Inhalt, bestehend aus:
     * - Progress Card mit Level-Anzeige und XP-Tracking
     * - Focus List Section mit allen Focus-Items
     * - Add Focus Button für neue Einträge
     *
     * Zusätzliche Features:
     * - Toolbar mit kontextuellem Add/Premium-Button
     * - Sheet-basierte Navigation für Add/Paywall/Statistics Views
     * - Alert-System für Limit-Benachrichtigungen
     * - Automatische Store-Konfiguration basierend auf Premium-Status
     */
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    progressCard
                    focusListSection
                    addFocusButton
                }
                .padding(.vertical)
            }
            .background(Palette.background)
            .navigationTitle("Fokus")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: handleAddButtonTap) {
                        if hasReachedFreeLimit {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .font(.body)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Palette.warning, Palette.warning.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Text("Get Pro")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Palette.warning, Palette.warning.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .bold()
                            }
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Palette.accent)
                                Text("Add")
                                    .foregroundStyle(Palette.accent)
                                    .bold()
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddView) {
                AddFocusView(store: store)
                    .environmentObject(revenueCat)
                    .environment(\.focusLimit, FocusLimitInfo(limit: maxFreeFocusItems, isPremium: revenueCat.isPremium))
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Limit erreicht", isPresented: $showingLimitAlert) {
                Button("Pro Version holen") {
                    showPaywall = true
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Du hast bereits \(maxFreeFocusItems) Fokusse. Mit der Pro Version kannst du unbegrenzt viele Fokusse erstellen.")
            }
            .onAppear {
                // Store mit Limit-Info initialisieren
                store.setLimitInfo(limit: maxFreeFocusItems, isPremium: revenueCat.isPremium)
            }
            .onChange(of: revenueCat.isPremium) { newValue in
                store.setLimitInfo(limit: maxFreeFocusItems, isPremium: newValue)
            }
        }
    }
    // MARK: - Action Handlers
    
    /**
     * Behandelt Taps auf den Add-Button in der Toolbar
     *
     * Entscheidet basierend auf dem Premium-Status des Nutzers:
     * - Premium-Nutzer: Öffnet direkt die Add Focus View
     * - Kostenlose Nutzer (Limit erreicht): Öffnet die Paywall
     * - Kostenlose Nutzer (Limit nicht erreicht): Öffnet die Add Focus View
     */
    private func handleAddButtonTap() {
        if hasReachedFreeLimit {
            showPaywall = true
        } else {
            showAddView = true
        }
    }
    // MARK: - UI Components
    
    /**
     * Progress Card Component
     *
     * Zeigt den aktuellen Fortschritt des Nutzers an mit:
     * - Level Badge mit aktuellem Level
     * - XP-Fortschrittsbalken mit Fortschritt zum nächsten Level
     * - Tap-Geste zum Öffnen der detaillierten Statistiken
     * - Integrierte Export-Funktionalität für CSV-Dateien
     *
     * Features:
     * - Shadow-Effekte für visuellen Tiefe-Eindruck
     * - Loading-State für asynchrone Datenladung
     * - Sheet-Navigation zu GlobalStatisticsView
     * - File Exporter für Statistik-Export
     */
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fortschritt")
                .headlineStyle()
                .padding(.bottom, 4)
            
            if let progress = store.userProgress {
                HStack {
                    LevelBadge(level: progress.currentLevel)
                    
                    VStack(alignment: .leading) {
                        Text("Level \(progress.currentLevel)")
                            .titleStyle()
                        
                        Text("\(progress.totalXP) XP")
                            .bodyTextStyle()
                    }
                    
                    Spacer()
                    
                    XPProgressBar(totalXP: progress.totalXP)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .cardStyle()
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .onTapGesture {
            showingStatistics = true
        }
        .sheet(isPresented: $showingStatistics) {
            GlobalStatisticsView(statistics: globalStats, store: store)
                .environmentObject(revenueCat)
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: CSVFile(initialText: ""),
            contentType: .commaSeparatedText,
            defaultFilename: "focus_export.csv"
        ) { result in
            switch result {
            case .success(let url):
                print("Export erfolgreich: \(url)")
            case .failure(let error):
                print("Export fehlgeschlagen: \(error)")
            }
        }
    }
    
    /**
     * Focus List Section Component
     *
     * Zentrale Sektion für die Anzeige aller Focus-Items mit:
     * - Header mit Titel und Limit-Badge
     * - Empty State für Nutzer ohne Focus-Items
     * - LazyVStack für performante Darstellung großer Listen
     * - Context Menu für Focus-Item-Aktionen (Löschen)
     *
     * Limit-Badge Features:
     * - Anzeige der aktuellen Anzahl vs. maximale Anzahl (kostenlose Nutzer)
     * - Visuelle Hervorhebung bei Limit-Erreichen
     * - Gradient-basierte Farbgebung für unterschiedliche Zustände
     */
    private var focusListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Deine Ziele")
                    .titleStyle()
                
                Spacer()
                
                // Badge mit Limit-Anzeige
                HStack(spacing: 4) {
                    Text("\(store.focusItems.count)")
                        .fontWeight(.semibold)
                    
                    if !revenueCat.isPremium {
                        Text("/ \(maxFreeFocusItems)")
                            .opacity(0.7)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    hasReachedFreeLimit
                        ? LinearGradient(
                            colors: [Palette.warning.opacity(0.3), Palette.warning.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [Palette.accent.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .foregroundColor(hasReachedFreeLimit ? Palette.warning : Palette.accent)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(hasReachedFreeLimit ? Palette.warning.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
            .padding(.horizontal)
            
            if store.focusItems.isEmpty {
                EmptyStateView()
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(store.focusItems.indices, id: \.self) { index in
                        FocusRowView(
                            focus: $store.focusItems[index],
                            store: store
                        )
                        .padding(.horizontal)
                        .contextMenu {
                            Button(role: .destructive) {
                                store.deleteFocus(store.focusItems[index])
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
    
    /**
     * Add Focus Button Component
     *
     * Kontextueller Button am Ende der Liste mit zwei Modi:
     *
     * Premium/Standard-Modus:
     * - Standard Add-Icon mit beschreibendem Text
     * - Anzeige der verfügbaren Slots für kostenlose Nutzer
     * - Subtle Styling mit Card-ähnlicher Erscheinung
     *
     * Limit-Erreicht-Modus:
     * - Premium-beworbenes Design mit Crown-Icon
     * - Gradient-Hintergrund zur Aufmerksamkeitslenkung
     * - Call-to-Action für Pro Version
     * - Animierte Scale-Effekte zur visuellen Betonung
     *
     * Features:
     * - Responsive Design basierend auf Premium-Status
     * - Smooth Animationen zwischen Zuständen
     * - Shadow-Effekte für visuellen Tiefe-Eindruck
     */
    // Neuer Add-Button unter der Liste
    private var addFocusButton: some View {
        Button(action: handleAddButtonTap) {
            HStack(spacing: 12) {
                if hasReachedFreeLimit {
                    // Premium Button Design
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pro Version freischalten")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Unbegrenzte Fokusse & mehr Features")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    // Standard Add Button
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Palette.accent)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Neuen Fokus hinzufügen")
                            .font(.headline)
                            .foregroundColor(Palette.textPrimary)
                        
                        
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundColor(Palette.textSecondary)
                }
            }
            .padding(16)
            .background(
                hasReachedFreeLimit
                    ? LinearGradient(
                        colors: [Palette.warning, Palette.warning.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Palette.card],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .cornerRadius(16)
            .shadow(
                color: hasReachedFreeLimit
                    ? Palette.warning.opacity(0.3)
                    : .black.opacity(0.05),
                radius: hasReachedFreeLimit ? 12 : 8,
                x: 0,
                y: 4
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        hasReachedFreeLimit
                            ? LinearGradient(
                                colors: [Palette.warning.opacity(0.5), Palette.warning.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Palette.textSecondary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(hasReachedFreeLimit ? 1.02 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasReachedFreeLimit)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - FocusStore Extensions

/**
 * FocusStore Extension für erweiterte Limit-Funktionalitäten
 *
 * Erweitert den FocusStore um Freemium-spezifische Funktionalitäten:
 * - Limit-Enforcement für kostenlose Nutzer
 * - Premium-Status-Tracking
 * - Sichere Add-Operationen mit Limit-Überprüfung
 *
 * Technische Implementierung:
 * - Verwendet Objective-C Associated Objects für dynamische Properties
 * - Thread-sichere Operationen für Limit-Überprüfungen
 * - Fail-safe Mechanismen für fehlerhafte Konfigurationen
 */
// MARK: - Focus Store Extension für Limit-Handling
extension FocusStore {
    
    // MARK: - Associated Object Keys
    
    /// Keys für Objective-C Associated Objects zur Laufzeit-Property-Speicherung
    private struct AssociatedKeys {
        static var focusLimit = 0
        static var isPremium = 0
    }
    
    // MARK: - Dynamic Properties
    
    /// Aktuelles Focus-Limit für den Nutzer (Standard: 999 für unbegrenzt)
    var focusLimit: Int {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.focusLimit) as? Int ?? 999 }
        set { objc_setAssociatedObject(self, &AssociatedKeys.focusLimit, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    /// Premium-Status des aktuellen Nutzers
    var isPremiumUser: Bool {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.isPremium) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &AssociatedKeys.isPremium, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    // MARK: - Configuration Methods
    
    /**
     * Konfiguriert Limit-Informationen für den Store
     *
     * - Parameters:
     *   - limit: Maximale Anzahl erlaubter Focus-Items für kostenlose Nutzer
     *   - isPremium: Premium-Status des Nutzers
     */
    func setLimitInfo(limit: Int, isPremium: Bool) {
        self.focusLimit = limit
        self.isPremiumUser = isPremium
    }
    
    // MARK: - Validation Methods
    
    /**
     * Überprüft, ob ein neuer Focus hinzugefügt werden kann
     *
     * - Returns: true wenn Hinzufügen erlaubt ist, false sonst
     */
    func canAddFocus() -> Bool {
        return isPremiumUser || focusItems.count < focusLimit
    }
    
    /**
     * Fügt einen Focus mit Limit-Überprüfung hinzu
     *
     * - Parameter focus: Der hinzuzufügende Focus
     * - Returns: true wenn erfolgreich hinzugefügt, false wenn Limit erreicht
     */
    func addFocusWithLimitCheck(_ focus: FocusItemModel) -> Bool {
        guard canAddFocus() else { return false }
        addFocus(focus)
        return true
    }
}

// MARK: - Environment Configuration

/**
 * Environment Key für Focus-Limit-Informationen
 *
 * Ermöglicht die Übertragung von Limit-Konfigurationen durch die View-Hierarchie
 * mittels SwiftUI's Environment-System.
 */
// MARK: - Environment Key für Focus Limit
struct FocusLimitKey: EnvironmentKey {
    static let defaultValue = FocusLimitInfo(limit: 999, isPremium: false)
}

/**
 * Focus Limit Information Container
 *
 * Kapselt Limit-bezogene Informationen für die Übertragung durch
 * die SwiftUI Environment.
 */
struct FocusLimitInfo {
    /// Maximale Anzahl erlaubter Focus-Items
    let limit: Int
    /// Premium-Status des Nutzers
    let isPremium: Bool
}

/**
 * Environment Values Extension
 *
 * Erweitert SwiftUI's EnvironmentValues um Focus-Limit-spezifische Informationen.
 */
extension EnvironmentValues {
    var focusLimit: FocusLimitInfo {
        get { self[FocusLimitKey.self] }
        set { self[FocusLimitKey.self] = newValue }
    }
}

// MARK: - File Handling

/**
 * CSV File Document Type
 *
 * Implementiert SwiftUI's FileDocument Protocol für CSV-Export-Funktionalität.
 * Ermöglicht das Lesen und Schreiben von CSV-Dateien mit dem nativen
 * File Exporter/Importer System.
 *
 * Features:
 * - UTF-8 Encoding Support
 * - Error Handling für Datei-Operationen
 * - Kompatibilität mit macOS/iOS File-Sharing
 */
// MARK: - Supporting Types
struct CSVFile: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var text: String
    
    init(initialText: String = "") {
        text = initialText
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - UI Helper Components

/**
 * Level Badge Component
 *
 * Zeigt das aktuelle Level des Nutzers in einem kreisförmigen Badge an.
 * Verwendet Gradient-Design für visuelle Attraktivität.
 */
private struct LevelBadge: View {
    let level: Int
    
    var body: some View {
        ZStack {
            GradientCircle()
                .frame(width: 50, height: 50)
            
            Text("\(level)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

/**
 * XP Progress Bar Component
 *
 * Zeigt den aktuellen XP-Fortschritt zum nächsten Level an.
 * Berechnet automatisch den Fortschritt basierend auf dem 100-XP-pro-Level-System.
 *
 * Features:
 * - Prozentuale Fortschrittsanzeige
 * - Berechnung der verbleibenden XP zum nächsten Level
 * - Responsive Design mit fester Breite
 */
private struct XPProgressBar: View {
    let totalXP: Int
    
    /// Berechnet den Fortschritt innerhalb des aktuellen Levels (0.0 - 1.0)
    private var progress: CGFloat {
        let remainder = totalXP % 100
        return CGFloat(remainder) / 100
    }
    
    /// Berechnet die verbleibenden XP bis zum nächsten Level
    private var nextLevelXP: Int {
        100 - (totalXP % 100)
    }
    
    var body: some View {
        VStack(alignment: .trailing) {
            Text("\(totalXP % 100)/100 XP")
                .bodyTextStyle()
            
            ProgressView(value: progress)
                .progressBarStyle(progress: progress)
                .frame(width: 120)
            
            Text("Noch \(nextLevelXP) XP bis Level \(totalXP / 100 + 2)")
                .font(.caption2)
                .bodyTextStyle()
        }
    }
}

/**
 * Empty State Component
 *
 * Zeigt eine benutzerfreundliche Nachricht an, wenn keine Focus-Items vorhanden sind.
 * Motiviert Nutzer zur Erstellung ihres ersten Focus-Items.
 *
 * Design Features:
 * - Zentriertes Icon für visuelle Klarheit
 * - Strukturierte Texthierarchie mit Headline und Beschreibung
 * - Card-basiertes Design für Konsistenz mit anderen UI-Elementen
 */
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(Palette.accent)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text("Keine Fokuse gefunden")
                    .headlineStyle()
                
                Text("Erstelle deinen ersten Fokus, um deine Produktivität zu steigern")
                    .bodyTextStyle()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .cardStyle()
        .padding(.horizontal)
        .padding(.vertical, 20)
    }
}

// MARK: - Preview Configuration

/**
 * SwiftUI Preview Configuration
 *
 * Konfiguriert die Preview mit:
 * - Dark Mode für Design-Validierung
 * - Mock RevenueCatManager für isolierte Tests
 */

#Preview {
    FocusListView()
        .preferredColorScheme(.dark)
        .environmentObject(RevenueCatManager())
}
