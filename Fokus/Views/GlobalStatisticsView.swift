//
//  GlobalStatisticsView.swift
//  Fokus
//
//  Created by Patrick Lanham on 15.07.25.
//

import SwiftUI

struct GlobalStatisticsView: View {
    let statistics: GlobalStatistics
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Level und XP
                HStack {
                    VStack {
                        Text("Level")
                            .font(.headline)
                        Text("\(statistics.currentLevel)")
                            .font(.largeTitle)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack {
                        Text("XP")
                            .font(.headline)
                        Text("\(statistics.totalXP)")
                            .font(.largeTitle)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                
                // Streak und täglicher Durchschnitt
                HStack(spacing: 20) {
                    StatCard(
                        title: "Aktuelle Serie",
                        value: "\(statistics.streak)",
                        subtitle: "Tage",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Täglich",
                        value: String(format: "%.1f", statistics.dailyAverage),
                        subtitle: "Abschlüsse/Tag",
                        icon: "chart.bar.fill",
                        color: .blue
                    )
                }
                
                // Abschlussrate
                StatCard(
                    title: "Abschlussrate",
                    value: "\(Int(statistics.focusCompletionRate * 100))%",
                    subtitle: "Heute abgeschlossen",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                // Aktive Fokusse (würde Daten aus Store benötigen)
                // Fokus-Trends (würde historische Daten benötigen)
            }
            .padding()
        }
        .navigationTitle("Statistiken")
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            Text(value)
                .font(.title)
                .bold()
                .padding(.vertical, 4)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    GlobalStatisticsView(statistics: GlobalStatistics())
}
