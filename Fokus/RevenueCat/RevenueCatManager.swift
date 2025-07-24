//
//  RevenueCatManager.swift
//  Fokus
//
//  Created by Patrick Lanham on 19.07.25.
//

import Foundation
import RevenueCat

/// Singleton zur Verwaltung von Käufen, Premiumstatus und Wiederherstellungen über RevenueCat
final class RevenueCatManager: NSObject, ObservableObject {
 
    static let shared = RevenueCatManager()
    
    /// Testfunktion für Premium
    func setPremiumStatus(_ status: Bool) {
            isPremium = status
        }

    /// Gibt an, ob der Nutzer aktuell ein aktives Premium-Abo besitzt
    @Published private(set) var isPremium: Bool = false

    /// RevenueCat Entitlement Identifier (wie in deinem Dashboard benannt)
     let entitlementID = "Pro"

     override init() {}

    // MARK: - Setup

    /// Initialisiert RevenueCat mit deinem API-Key (z. B. im AppDelegate oder @main App)
    func configure(withAPIKey apiKey: String) {
        Purchases.configure(withAPIKey: apiKey)
        observeCustomerInfoChanges()
        fetchCustomerInfo()
    }

    // MARK: - Observer

    /// Beobachtet Änderungen am CustomerInfo-Objekt (z. B. bei neuen Käufen)
    private func observeCustomerInfoChanges() {
        Purchases.shared.getCustomerInfo { [weak self] info, _ in
            self?.updatePremiumStatus(from: info)
        }

        Purchases.shared.delegate = self
    }

    private func updatePremiumStatus(from info: CustomerInfo?) {
        let hasPremium = info?.entitlements[entitlementID]?.isActive == true
        DispatchQueue.main.async {
            self.isPremium = hasPremium
        }
    }

    private func fetchCustomerInfo() {
        Task {
            do {
                let info = try await Purchases.shared.customerInfo()
                updatePremiumStatus(from: info)
            } catch {
                print("❌ Fehler beim Laden von CustomerInfo: \(error)")
            }
        }
    }

    // MARK: - Kauf

    /// Startet den Kaufprozess für ein bestimmtes Offering-Paket
    func purchase(package: Package) async -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.customerInfo.entitlements[entitlementID]?.isActive == true {
                await MainActor.run { self.isPremium = true }
                return true
            }
        } catch {
            print("❌ Kauf fehlgeschlagen: \(error.localizedDescription)")
        }

        return false
    }

    /// Versucht, Käufe wiederherzustellen (z. B. nach Gerätewechsel oder Reinstallation)
    func restorePurchases() async -> Bool {
        do {
            let info = try await Purchases.shared.restorePurchases()
            updatePremiumStatus(from: info)
            return info.entitlements[entitlementID]?.isActive == true
        } catch {
            print("❌ Wiederherstellung fehlgeschlagen: \(error)")
            return false
        }
    }

    /// Holt das aktuelle Offering von RevenueCat (z. B. Monats-/Jahresabo)
    func fetchOfferings() async -> Offerings? {
        do {
            return try await Purchases.shared.offerings()
        } catch {
            print("❌ Fehler beim Laden der Offerings: \(error)")
            return nil
        }
    }
}

// MARK: - PurchasesDelegate

extension RevenueCatManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        updatePremiumStatus(from: customerInfo)
    }
}

