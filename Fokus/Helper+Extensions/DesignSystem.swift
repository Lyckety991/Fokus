//
//  DesignSystem.swift
//  Fokus
//
//  Created by Patrick Lanham on 11.07.25.
//

import Foundation

import SwiftUI

// MARK: - Farbpalette
struct Palette {
    // Hintergrundfarben
    static let background = Color("Background")
    static let card = Color("Card")
    
    // Textfarben
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    
    // Akzentfarben
    static let accent = Color("Accent")
    static let secondary = Color("Secondary")
    static let progress = Color("Progress")
    static let purple = Color("Purple")
    
    // Zustandsfarben
    static let completed = Color("Completed")
    static let warning = Color.orange
}

// MARK: - Asset-Farben (für beide Modi)
extension Color {
    init(_ name: String) {
        self.init(name, bundle: .main)
    }
}

// MARK: - Designkomponenten
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Palette.card)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

struct ProgressBarModifier: ViewModifier {
    let progress: CGFloat
    
    func body(content: Content) -> some View {
        content
            .tint(
                progress == 1 ?
                Palette.completed :
                Palette.progress
            )
    }
}

// MARK: - Textstile
struct TitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(Palette.textPrimary)
    }
}

struct HeadlineModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(Palette.textPrimary)
    }
}

struct BodyTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(Palette.textSecondary)
    }
}

// MARK: - Hilfsfunktionen
extension View {
    func cardStyle() -> some View {
        self.modifier(CardModifier())
    }
    
    func progressBarStyle(progress: CGFloat) -> some View {
        self.modifier(ProgressBarModifier(progress: progress))
    }
    
    func titleStyle() -> some View {
        self.modifier(TitleModifier())
    }
    
    func headlineStyle() -> some View {
        self.modifier(HeadlineModifier())
    }
    
    func bodyTextStyle() -> some View {
        self.modifier(BodyTextModifier())
    }
}

// MARK: - GradientCircle für LevelBadge
struct GradientCircle: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark ?
                                      [Palette.accent, Palette.purple] :
                                      [.blue, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}
