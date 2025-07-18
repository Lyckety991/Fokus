//
//  SettingsView.swift
//  Fokus
//
//  Created by Patrick Lanham on 10.07.25.
//

import SwiftUI

struct SettingsView: View {
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Darstellung
                    settingsCard(title: "Darstellung", icon: "paintbrush.fill") {
                        Toggle("Dunkler Modus", isOn: $isDarkMode)
                            .onChange(of: isDarkMode) { _, newValue in
                                updateWindowTheme(isDarkMode: newValue)
                            }
                            .tint(Palette.accent)
                            .padding(.top, 8)
                    }
                    
                    // MARK: - Support
                    settingsCard(title: "Support", icon: "envelope.fill") {
                        settingsButton(label: "Support kontaktieren", icon: "envelope.fill") {
                            openMail()
                        }
                    }
                    
                    // MARK: - Rechtliches
                    settingsCard(title: "Rechtliches", icon: "lock.shield.fill") {
                        settingsButton(label: "Datenschutz", icon: "lock.shield.fill") {
                            openURL("https://www.patrick-lanham.de/datenschutz.html")
                        }
                        settingsButton(label: "Impressum", icon: "exclamationmark.shield.fill") {
                            openURL("https://www.patrick-lanham.de/datenschutz.html")
                        }
                        settingsButton(label: "Nutzungsbedingungen", icon: "lock.document.fill") {
                            openURL("https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
                        }
                        settingsButton(label: "Über die App", icon: "chart.bar.fill") {
                            openURL("https://www.patrick-lanham.de")
                        }
                    }
                    
                    // MARK: - Version
                    settingsCard(title: "App-Version", icon: "gear") {
                        HStack {
                            Text("Version")
                                .foregroundColor(Palette.textPrimary)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundColor(Palette.textSecondary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .background(Palette.background.ignoresSafeArea())
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Components
    
    private func settingsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .headlineStyle()
            }
            content()
        }
        .padding()
        .cardStyle()
    }
    
    private func settingsButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(label)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Palette.textSecondary)
            }
            .foregroundColor(Palette.textPrimary)
        }
    }

    private func openMail() {
        let mailto = "mailto:mail@patrick-lanham.de?subject=Bug%20in%20SimpleTask&body=Beschreibe%20den%20Fehler%20hier..."
        if let url = URL(string: mailto) {
            UIApplication.shared.open(url)
        }
    }

    private func openURL(_ link: String) {
        if let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }

    private func updateWindowTheme(isDarkMode: Bool) {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first?
            .overrideUserInterfaceStyle = isDarkMode ? .dark : .light
    }
}

#Preview {
    SettingsView()
}
