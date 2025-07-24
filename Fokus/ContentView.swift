//
//  ContentView.swift
//  Fokus
//
//  Created by Patrick Lanham on 07.07.25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            
            FocusListView()
                .tabItem {
                    Label("Fokus", systemImage: "target")
                }
            
            AchievementView(store: FocusStore())
                .tabItem {
                    Label("Erfolge", systemImage: "trophy.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape")
                }
        }
    }
}


#Preview {
    ContentView()
}
