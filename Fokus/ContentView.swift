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
