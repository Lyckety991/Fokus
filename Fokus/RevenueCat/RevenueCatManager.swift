//
//  RevenueCatManager.swift
//  Fokus
//
//  Created by Patrick Lanham on 19.07.25
//  Überarbeitet: 11.11.2025
//

import Foundation
import RevenueCat

/// Verwaltet Premium-Status, Käufe, Wiederherstellung & Offerings via RevenueCat.
/// - Hinweis: Als @MainActor deklariert, damit @Published-Änderungen sicher auf dem Main-Thread passieren.
@MainActor
final class RevenueCatManager: NSObject, ObservableObject {

    // MARK: - Singleton / DI
    static let shared = RevenueCatManager()
    override init() { super.init() }

    // MARK: - Public State
    /// Aktiver Premium-Status (entitlement aktiv?)
    @Published private(set) var isPremium: Bool = false

    /// Offerings-Cache (z. B. für Paywall)
    @Published private(set) var offerings: Offerings?

    /// Dein Entitlement-Identifier (muss zum Dashboard passen)
    let entitlementID = "Pro"

    /// Wurde RC bereits konfiguriert?
    private var isConfigured = false

    // MARK: - Configure

    /// Initialisiert RevenueCat mit deinem API-Key. Idempotent.
    func configure(withAPIKey apiKey: String) {
        guard !isConfigured else {
            // Bereits konfiguriert: trotzdem Kundeninfos aktualisieren
            observeCustomerInfoChanges() // sicherstellen, dass Delegate sitzt
            Task { await refreshCustomerInfo() }
            return
        }

        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
        isConfigured = true

       
        Task {
            await refreshCustomerInfo()
            await loadOfferings()
        }
    }

    // MARK: - Customer Info

    /// Lädt CustomerInfo neu und aktualisiert den Premium-Status.
    func refreshCustomerInfo() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            applyPremiumStatus(from: info)
        } catch {
            debugPrint("❌ CustomerInfo laden fehlgeschlagen: \(error)")
        }
    }

    /// Beobachtet Änderungen am CustomerInfo-Objekt (redundant zum Delegate – aber unkritisch)
    private func observeCustomerInfoChanges() {
        // Moderne RC-SDKs pushen Updates über den Delegate.
        // Dieser Call schadet nicht, aber ist streng genommen nicht nötig, da wir den Delegate nutzen.
        // Belassen wir für Abwärtskompatibilität:
        Purchases.shared.getCustomerInfo { [weak self] info, _ in
            guard let self else { return }
            Task { @MainActor in
                self.applyPremiumStatus(from: info)
            }
        }
    }

    private func applyPremiumStatus(from info: CustomerInfo?) {
        let active = info?.entitlements[entitlementID]?.isActive == true
        isPremium = active
    }

    // MARK: - Offerings

    /// Lädt Offerings und cached sie lokal.
    func loadOfferings() async {
        do {
            let o = try await Purchases.shared.offerings()
            offerings = o
        } catch {
            debugPrint("❌ Offerings laden fehlgeschlagen: \(error)")
        }
    }

    // MARK: - Kauf / Restore

    /// Startet den Kauf für ein Paket. Gibt `true` zurück, wenn Premium aktiv ist.
    @discardableResult
    func purchase(package: Package) async -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: package)

            // Falls der User abbricht, wirf kein „Fehler“-Toast/State
            if result.userCancelled == true {
                // kein Fehler, nur kein Kauf
                return isPremium
            }

            applyPremiumStatus(from: result.customerInfo)
            return isPremium
        } catch let error as RevenueCat.ErrorCode {
            // RC-spezifische Fehlerauswertung (optional)
            debugPrint("❌ Kauf fehlgeschlagen (RC Error): \(error)")
            return false
        } catch {
            debugPrint("❌ Kauf fehlgeschlagen: \(error.localizedDescription)")
            return false
        }
    }

    /// Stellt Käufe wieder her. Gibt `true` zurück, wenn Premium aktiv ist.
    @discardableResult
    func restorePurchases() async -> Bool {
        do {
            let info = try await Purchases.shared.restorePurchases()
            applyPremiumStatus(from: info)
            return isPremium
        } catch {
            debugPrint("❌ Wiederherstellung fehlgeschlagen: \(error)")
            return false
        }
    }

    // MARK: - Testing / Preview

    /// Testfunktion: Premium-Status manuell setzen (z. B. für Previews).
    func setPremiumStatus(_ status: Bool) {
        isPremium = status
    }
}

// MARK: - PurchasesDelegate

extension RevenueCatManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.applyPremiumStatus(from: customerInfo)
        }
    }
}
