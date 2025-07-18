//
//  FokusApp.swift
//  Fokus
//
//  Created by Patrick Lanham on 07.07.25.
//

import SwiftUI

@main
struct FokusApp: App {
    
    @StateObject var store = FocusStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    _ = await NotificationManager.shared.requestAuthorization()
                }
        }
    }
}

