//
//  GlobalStatisticsView.swift
//  Fokus
//
//  Created by Patrick Lanham on 15.07.25.
//

import SwiftUI

// MARK: - Verbesserte Globale Statistikansicht
struct GlobalStatisticsView: View {
    
    @EnvironmentObject var revenueCat: RevenueCatManager
    
    @State private var showPaywall = false
    @State private var exportFile: URL?
    @State private var showingExporter = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let statistics: GlobalStatistics
    @ObservedObject var store: FocusStore
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header mit Level und XP
                    levelHeader
                    
                    ZStack {
                        // Immer das coreStatsGrid anzeigen
                        coreStatsGrid
                            .blur(radius: 3)
                        
                        // Premium-Sperrschicht nur wenn nötig
                        if !revenueCat.isPremium {
                            ZStack {
                                // 1. Material-Blur für den gesamten Hintergrund
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.regularMaterial) // iOS 15+ Apple-Style Material
                                    .opacity(0.95)
                                
                                // 2. Schloss-Icon mit Text
                                VStack(spacing: 8) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.primary) // Dynamische Farbe
                                    
                                    Text("Statistiken nur mit Premium verfügbar")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary) // Dynamische Farbe
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                            }
                        }
                    }
                    .sheet(isPresented: $showPaywall) {
                        PaywallView()
                    }
                    .onTapGesture {
                        showPaywall = true
                    }

                    // Achievements
                    

                    // Export-Button
                    exportSection
                }
                .padding()
            }
        }
        .navigationTitle("Statistiken")
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingExporter) {
            // Nur anzeigen wenn exportFile nicht nil ist
            if let exportFile = exportFile {
                ActivityViewController(activityItems: [exportFile])
                    .onDisappear {
                        // Aufräumen nach dem Sheet
                        self.exportFile = nil
                    }
            } else {
                // Fallback für den Fall, dass etwas schief läuft
                Text("Export wird vorbereitet...")
                    .padding()
            }
        }
        .alert("Export", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var levelHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Level \(statistics.currentLevel)")
                    .font(.largeTitle)
                    .bold()
                
                Text("\(statistics.totalXP) XP")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            CircularProgressView(
                progress: Double(statistics.totalXP % 100) / 100,
                color: .blue,
                lineWidth: 10
            )
            .frame(width: 80, height: 80)
            .overlay(
                Text("\(statistics.totalXP % 100)/100")
                    .font(.headline)
            )
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(15)
    }
    
    private var coreStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "Aktuelle Serie",
                value: "\(statistics.streak)",
                subtitle: "Tage",
                icon: "flame.fill",
                color: .orange
            )
            
            StatCard(
                title: "Täglicher Schnitt",
                value: String(format: "%.1f", statistics.dailyAverage),
                subtitle: "Abschlüsse/Tag",
                icon: "chart.bar.fill",
                color: .blue
            )
            
            StatCard(
                title: "Abschlussrate",
                value: "\(Int(statistics.focusCompletionRate * 100))%",
                subtitle: "Heute abgeschlossen",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "Fokus-Punkte",
                value: "\(statistics.totalXP)",
                subtitle: "Gesamt XP",
                icon: "sparkles",
                color: .purple
            )
        }
    }
    
 
    
    private var exportSection: some View {
        VStack {
            Text("Datenexport")
                .font(.title2)
                .bold()
                .padding(.bottom, 8)
            
            Button(action: exportData) {
                Label("Daten exportieren", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            // Debug Info
            if !store.focusItems.isEmpty {
                Text("Verfügbare Fokusse: \(store.focusItems.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical)
    }
    
    private func exportData() {
        print("🔄 Export startet...")
        print("📊 Anzahl FocusItems: \(store.focusItems.count)")
        
        // Prüfe ob überhaupt Daten vorhanden sind
        guard !store.focusItems.isEmpty else {
            alertMessage = "Keine Fokus-Daten zum Exportieren vorhanden."
            showingAlert = true
            return
        }
        
        // CSV generieren
        let focusCSV = DataExportService.exportFocusesToCSV(focusItems: store.focusItems)
        
        // Prüfe ob CSV nicht leer ist
        guard !focusCSV.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              focusCSV.contains(";") else { // Mindestens Header sollte Semikolon enthalten
            alertMessage = "Fehler beim Generieren der CSV-Daten."
            showingAlert = true
            return
        }
        
        // Datei erstellen
        let timestamp = DateFormatter().apply {
            $0.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        }.string(from: Date())
        
        let filename = "fokusse_export_\(timestamp).csv"
        
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            alertMessage = "Dokumente-Ordner nicht gefunden."
            showingAlert = true
            return
        }
        
        let fileURL = documentsDir.appendingPathComponent(filename)
        
        do {
            try focusCSV.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ Datei geschrieben: \(fileURL)")
            
            // Datei-Inhalt überprüfen
            let savedContent = try String(contentsOf: fileURL)
            print("📦 Gespeicherter Inhalt:\n\(savedContent)")
            
            // FIX: Erst die Datei setzen, DANN das Sheet anzeigen
            exportFile = fileURL
            
            // Kleiner Delay um sicherzustellen, dass der State aktualisiert ist
            DispatchQueue.main.async {
                showingExporter = true
            }
            
        } catch {
            print("❌ Schreibfehler: \(error)")
            alertMessage = "Fehler beim Erstellen der Datei: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// Hilfs-View für Share Sheet
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // Bessere Konfiguration für iPad
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView() // Fallback für iPad
        }
        
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            if let error = error {
                print("❌ Share-Fehler: \(error)")
            } else if completed {
                print("✅ Export erfolgreich geteilt")
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Hilfs-Komponenten
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
            }
            
            Text(value)
                .font(.title)
                .bold()
                .padding(.vertical, 4)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .cardStyle()
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}



struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    color.opacity(0.3),
                    lineWidth: lineWidth
                )
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
        }
    }
}

// Extension für DateFormatter
extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}

#Preview {
    
    GlobalStatisticsView(statistics: GlobalStatistics(), store: FocusStore())
       
    
    
}

#Preview {
    let testManager = RevenueCatManager()
    testManager.setPremiumStatus(false) // Premium aktiv setzen
    
    let store = FocusStore()
    store.focusItems = [
        FocusItemModel(title: "Meditation", description: "Tägliche Meditation", weakness: "Ablenkung", completionDates: [Date()]),
        FocusItemModel(title: "Sport", description: "Joggen", weakness: "Faulheit", completionDates: [])
    ]
    
    return GlobalStatisticsView(statistics: GlobalStatistics(), store: store)
        .environmentObject(testManager) // ✅ Genau DEN testManager übergeben!
}


