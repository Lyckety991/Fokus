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
            OnboardingManager {
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
}



extension UserDefaults {
    enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let onboardingCompletedDate = "onboardingCompletedDate"
        static let onboardingVersion = "onboardingVersion"
    }
}

// MARK: - Erweiterte Onboarding-Konfiguration
struct OnboardingConfiguration {
    static let currentVersion = "1.0"
    
    // Falls du später das Onboarding updatest
    static func shouldShowOnboarding() -> Bool {
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: UserDefaults.Keys.hasSeenOnboarding)
        let lastVersion = UserDefaults.standard.string(forKey: UserDefaults.Keys.onboardingVersion)
        
        return !hasSeenOnboarding || lastVersion != currentVersion
    }
    
    static func markOnboardingCompleted() {
        UserDefaults.standard.set(true, forKey: UserDefaults.Keys.hasSeenOnboarding)
        UserDefaults.standard.set(currentVersion, forKey: UserDefaults.Keys.onboardingVersion)
        UserDefaults.standard.set(Date(), forKey: UserDefaults.Keys.onboardingCompletedDate)
    }
}

// MARK: - Debug Helper (für Testing)
#if DEBUG
struct OnboardingDebugView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Onboarding Debug")
                .font(.title)
            
            Button("Reset Onboarding") {
                UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.hasSeenOnboarding)
                UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.onboardingVersion)
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Show Onboarding") {
                // Trigger für Testing
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}
#endif
