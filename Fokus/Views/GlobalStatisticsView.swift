//
//  GlobalStatisticsView.swift
//  Fokus
//
//  Created by Patrick Lanham on 15.07.25.
//

import SwiftUI

// MARK: - Verbesserte Globale Statistikansicht
struct GlobalStatisticsView: View {
    let statistics: GlobalStatistics
    @State private var exportFile: URL?
    @State private var showingExporter = false
    @ObservedObject var store: FocusStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header mit Level und XP
                levelHeader
                
                // Kernstatistiken
                coreStatsGrid
                
                // Achievements
                achievementsSection
                
                // Export-Button
                exportSection
            }
            .padding()
        }
        .navigationTitle("Statistiken")
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingExporter) {
            if let exportFile = exportFile {
                ActivityViewController(activityItems: [exportFile])
            }
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
    
    private var achievementsSection: some View {
        VStack(alignment: .leading) {
            Text("Achievements")
                .font(.title2)
                .bold()
                .padding(.bottom, 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(statistics.achievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical)
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
        }
        .padding(.vertical)
    }
    
    private func exportData() {
        let focusCSV = DataExportService.exportFocusesToCSV(focusItems: store.focusItems)
        
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return
        }
        
        let fileURL = documentsDir.appendingPathComponent("fokusse_export.csv")
        
        do {
            try focusCSV.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Inhalt prüfen
            let content = try String(contentsOf: fileURL)
            guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                print("CSV-Datei ist leer – kein Export")
                return
            }

            print("📄 Datei erstellt: \(fileURL.lastPathComponent)")
            print("📦 Inhalt:\n\(content)")

            // Zustand aktualisieren
            exportFile = fileURL
            showingExporter = true
            
        } catch {
            print("❌ Fehler beim Schreiben: \(error)")
        }
    }


}


// Hilfs-View für Share Sheet
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            // Clean up after sharing completes
            if completed, let url = activityItems.first as? URL {
                try? FileManager.default.removeItem(at: url)
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

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.yellow : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(achievement.isUnlocked ? .black : .gray)
            }
            
            Text(achievement.title)
                .font(.subheadline)
                .bold()
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .frame(width: 80)
            
            ProgressView(value: achievement.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: achievement.isUnlocked ? .green : .gray))
                .frame(width: 80)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        .opacity(achievement.isUnlocked ? 1 : 0.7)
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

#Preview {
    GlobalStatisticsView(statistics: GlobalStatistics(), store: FocusStore())
    
    
}

#Preview {
    let store = FocusStore()
    store.focusItems = [
        FocusItemModel(title: "Meditation", description: "Tägliche Meditation", weakness: "Ablenkung", completionDates: [Date()]),
        FocusItemModel(title: "Sport", description: "Joggen", weakness: "Faulheit", completionDates: [])
    ]
    return GlobalStatisticsView(statistics: GlobalStatistics(), store: store)
}


