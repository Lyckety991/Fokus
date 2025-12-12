//
//  NotificationManager.swift
//  Fokus
//
//  Created by Patrick Lanham on 17.07.25.
//

import Foundation
import UserNotifications


enum NotificationError: Error {
    case permissionDenied
    case schedulingFailed(Error)
    case invalidDate
    case notificationsNotAuthorized
}

extension NotificationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Berechtigung für Benachrichtigungen wurde verweigert"
        case .schedulingFailed(let error):
            return "Fehler beim Planen der Benachrichtigung: \(error.localizedDescription)"
        case .invalidDate:
            return "Das angegebene Datum liegt in der Vergangenheit"
        case .notificationsNotAuthorized:
            return "Benachrichtigungen sind nicht autorisiert"
        }
    }
}

@MainActor
class NotificationManager {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    private var debugLoggingEnabled = true

    private init() {}
    
    
    func checkNotificationsEnabled() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    func getNotificationSettings() async -> UNNotificationSettings {
        return await center.notificationSettings()
    }
    
    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            log("🔔 Anfrage: \(granted ? "erlaubt" : "abgelehnt")")
            return granted
        } catch {
            log("❌ Fehler bei Anfrage: \(error.localizedDescription)")
            return false
        }
    }
  
    // MARK: - Scheduling
    func scheduleNotification(
        title: String,
        body: String,
        at date: Date,
        repeatsDaily: Bool = false
    ) async throws -> String {
        // Überprüfe Datum
        guard date > Date() else {
            throw NotificationError.invalidDate
        }
        
        // Überprüfe Berechtigung
        let isAuthorized = await checkNotificationsEnabled()
        guard isAuthorized else {
            throw NotificationError.notificationsNotAuthorized
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let calendar = Calendar.autoupdatingCurrent
        let components = calendar.dateComponents(
            repeatsDaily ? [.hour, .minute] : [.year, .month, .day, .hour, .minute],
            from: date
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: repeatsDaily
        )

        let id = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            log("✅ Erinnerung geplant (\(repeatsDaily ? "täglich" : "einmalig")) für \(date.formatted()), ID: \(id)")
            
            // Kurze Verzögerung für Debug-Ausgabe nach Verarbeitung
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 Sekunden
            await listPendingNotifications()
            return id
        } catch {
            log("❌ Fehler beim Planen: \(error.localizedDescription)")
            throw NotificationError.schedulingFailed(error)
        }
    }

    // MARK: - Cancellation
    func cancelNotification(withID id: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        log("🗑️ Notification mit ID \(id) gelöscht")
    }
    
    func cancelAllNotifications() async {
        center.removeAllPendingNotificationRequests()
        log("🧹 Alle Benachrichtigungen gelöscht")
    }
    
    // MARK: - Utility Methods
    func scheduleTestNotification() async throws -> String {
        let testDate = Date().addingTimeInterval(10) // 10 Sekunden in der Zukunft
        return try await scheduleNotification(
            title: "Test Benachrichtigung",
            body: "Dies ist eine Test-Benachrichtigung",
            at: testDate
        )
    }

    // MARK: - Debugging
    func listPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        log("📬 Ausstehende Notifications (\(requests.count)):")
        requests.forEach {
            log(" - ID: \($0.identifier), Trigger: \($0.trigger?.description ?? "Kein Trigger")")
        }
    }
    
    // MARK: - Helper
    private func log(_ message: String) {
        guard debugLoggingEnabled else { return }
        print("[NotificationManager] \(message)")
    }
}
