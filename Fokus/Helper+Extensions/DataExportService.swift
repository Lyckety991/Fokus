//
//  DataExportService.swift
//  Fokus
//
//  Created by Patrick Lanham on 15.07.25.
//

import Foundation

// MARK: - Datenexport-Service
class DataExportService {
    static func exportFocusesToCSV(focusItems: [FocusItemModel]) -> String {
        var csv = "Titel;Beschreibung;Schwäche;Anzahl Abschlüsse;Letzter Abschluss\n"
        
        for focus in focusItems {
            let title = focus.title.replacingOccurrences(of: ";", with: ",")
            let description = focus.description.replacingOccurrences(of: ";", with: ",")
            let weakness = focus.weakness.replacingOccurrences(of: ";", with: ",")
            let count = focus.completionDates.count
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            
            // FIX: Verwende das letzte Datum aus completionDates statt lastCompletionDate
            let lastCompletion = focus.completionDates.max() != nil ?
                dateFormatter.string(from: focus.completionDates.max()!) : "N/A"
            
            csv += "\(title);\(description);\(weakness);\(count);\(lastCompletion)\n"
        }
        
        print("📄 Generierte CSV:\n\(csv)") // Debug-Ausgabe
        return csv
    }
    
    static func exportCompletionsToCSV(focusItems: [FocusItemModel]) -> String {
        var csv = "Datum;Fokus;XP\n"
        
        // Sammle alle Abschlüsse
        var allCompletions: [(date: Date, focusTitle: String)] = []
        
        for focus in focusItems {
            for date in focus.completionDates {
                allCompletions.append((date, focus.title))
            }
        }
        
        // Sortiere chronologisch
        allCompletions.sort { $0.date < $1.date }
        
        // CSV generieren
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        
        for completion in allCompletions {
            let dateString = dateFormatter.string(from: completion.date)
            let title = completion.focusTitle.replacingOccurrences(of: ";", with: ",")
            csv += "\(dateString);\(title);25\n"
        }
        
        print("📄 Generierte Completions CSV:\n\(csv)") // Debug-Ausgabe
        return csv
    }
    
    static func exportToFile(csv: String, filename: String) -> URL? {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try csv.write(to: path, atomically: true, encoding: .utf8)
            print("✅ Datei geschrieben nach: \(path)")
            return path
        } catch {
            print("❌ Export fehlgeschlagen: \(error)")
            return nil
        }
    }
}
