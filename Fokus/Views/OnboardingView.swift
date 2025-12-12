//
//  OnboardingView.swift
//  Fokus
//
//  Created by Patrick Lanham on 25.07.25.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var showPaywall = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    let pages = [
        OnboardingPage(
            title: "Willkommen bei Fokus",
            subtitle: "Deine neue App für Gewohnheitsbildung",
            description: "Entwickle gesunde Gewohnheiten, verfolge deinen Fortschritt und erreiche deine Ziele mit unserem intuitiven System.",
            imageName: "Focus.png", // Dein Logo
            backgroundColor: LinearGradient(
                colors: [Palette.accent, Palette.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        OnboardingPage(
            title: "Erfolge freischalten",
            subtitle: "Gamification macht Spaß",
            description: "Sammle XP, baue Streaks auf und schalte Achievements frei. Von 'Neuling' bis 'Fokus-Legende' - jeder Schritt zählt!",
            imageName: "trophy.fill",
            backgroundColor: LinearGradient(
                colors: [Palette.warning, Palette.warning.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        OnboardingPage(
            title: "Premium Features",
            subtitle: "Noch mehr Einblicke",
            description: "Erweiterte Statistiken, Premium-Insights und detaillierte Analytics helfen dir dabei, deine Produktivität zu optimieren.",
            imageName: "sparkles",
            backgroundColor: LinearGradient(
                colors: [Palette.purple, Palette.accent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            pages[currentPage].backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentPage)
            
            VStack {
                // Skip Button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Überspringen") {
                            completeOnboarding()
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                    }
                }
                .padding(.top)
                
                Spacer()
                
                // Main Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentPage)
                
                Spacer()
                
                // Page Control & Navigation
                VStack(spacing: 24) {
                    // Custom Page Indicators
                    HStack(spacing: 12) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.white : Color.white.opacity(0.4))
                                .frame(width: index == currentPage ? 12 : 8, height: index == currentPage ? 12 : 8)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    
                    // Navigation Button
                    Button(action: nextPage) {
                        HStack {
                            Text(currentPage == pages.count - 1 ? "Los geht's!" : "Weiter")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if currentPage < pages.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(buttonTextColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .onDisappear {
                    // Nach Paywall schließen wir auch das Onboarding
                    completeOnboarding()
                }
        }
    }
    
    // Computed property für Button-Textfarbe
    private var buttonTextColor: Color {
        switch currentPage {
        case 0: return Palette.accent
        case 1: return Palette.warning
        case 2: return Palette.purple
        default: return Palette.accent
        }
    }
    
    private func nextPage() {
        if currentPage < pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPage += 1
            }
        } else {
            // Letzter Screen -> Paywall zeigen
            showPaywall = true
        }
    }
    
    private func completeOnboarding() {
        hasSeenOnboarding = true
        dismiss()
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let backgroundColor: LinearGradient
}

// MARK: - Individual Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Image/Icon Section
            VStack(spacing: 24) {
                if page.imageName == "Focus.png" {
                    // App Logo (falls vorhanden, sonst Fallback)
                    if let uiImage = UIImage(named: "Focus.png") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                    } else {
                        // Fallback: Stylized Logo
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .backdrop(blur: 10)
                            
                            Image(systemName: "target")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                    }
                } else {
                    // System Icons für andere Pages
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .backdrop(blur: 10)
                        
                        Image(systemName: page.imageName)
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                }
            }
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: isAnimating)
            
            // Text Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
            }
            .offset(y: isAnimating ? 0 : 30)
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

// MARK: - Backdrop Effect (iOS 15+ Fallback)
extension View {
    func backdrop(blur radius: CGFloat) -> some View {
        self.background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .blur(radius: radius / 2)
                .opacity(0.6)
        )
    }
}

// MARK: - Onboarding Manager
struct OnboardingManager: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false
    let content: () -> AnyView
    
    init<Content: View>(@ViewBuilder content: @escaping () -> Content) {
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        ZStack {
            content()
            
            if !hasSeenOnboarding {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            if !hasSeenOnboarding {
                showOnboarding = true
            }
        }
    }
}

// MARK: - Integration in deine App
// Verwende es so in deiner main App:
/*
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
                        revenueCatManager.configure(withAPIKey: "DEIN_API_KEY")
                        _ = await NotificationManager.shared.requestAuthorization()
                    }
            }
        }
    }
}
*/

// MARK: - Preview
#Preview {
    OnboardingView()
        .environmentObject(RevenueCatManager.shared)
}
