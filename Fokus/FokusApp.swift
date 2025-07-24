//
//  FokusApp.swift
//  Fokus
//
//  Created by Patrick Lanham on 07.07.25.
//

import SwiftUI
import RevenueCat

@main
struct FokusApp: App {
    
    @StateObject var store = FocusStore()
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(revenueCatManager)
                .task {
                    // RevenueCat konfigurieren
                    revenueCatManager.configure(withAPIKey: "appl_fLggwLqapgawMZbzyPuCfuwdpwg")
                    
                    // Notifications
                    _ = await NotificationManager.shared.requestAuthorization()
                }
        }
    }
}
