


import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var revenueCat: RevenueCatManager
    
    @State private var selectedPackage: Package?
    @State private var offerings: Offerings?
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Klarere, app-spezifische Features
    private let features = [
        "Unbegrenzte Fokusse & Gewohnheiten",
        "Detaillierte Statistiken & Diagramme",
        "Level- & XP-System ohne Limit",
        "Race Goals & Fokus-Modi",
        "CSV-Export deiner Daten",
        "Keine Werbung"
    ]
    
    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header / Close
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Palette.textSecondary)
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal)
                
                if isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Lade Pro-Optionen…")
                            .foregroundColor(Palette.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // MARK: Hero
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Palette.accent, Palette.purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 72, height: 72)
                                        .shadow(color: Palette.accent.opacity(0.4), radius: 12, x: 0, y: 6)
                                    
                                    Image(systemName: "target")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Fokus Pro")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(Palette.textPrimary)
                                
                                Text("Baue konsistente Gewohnheiten auf – mit vollen Statistiken und unbegrenzten Zielen.")
                                    .font(.subheadline)
                                    .foregroundColor(Palette.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                            }
                            .padding(.top, 8)
                            
                            // MARK: Features
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Mit Fokus Pro bekommst du:")
                                    .headlineStyle()
                                
                                ForEach(features, id: \.self) { feature in
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Palette.completed)
                                            .font(.system(size: 18))
                                        Text(feature)
                                            .foregroundColor(Palette.textPrimary)
                                        Spacer()
                                    }
                                }
                            }
                            .padding()
                            .cardStyle()
                            
                            // MARK: Angebote
                            if let offering = offerings?.current {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Wähle dein Paket:")
                                        .headlineStyle()
                                    
                                    let sortedPackages = offering.availablePackages.sorted(by: sortPackages)
                                    
                                    ForEach(sortedPackages, id: \.identifier) { package in
                                        let isRecommended = (package.packageType == .annual)
                                        
                                        PackageButton(
                                            package: package,
                                            isSelected: selectedPackage?.identifier == package.identifier,
                                            isRecommended: isRecommended,
                                            onTap: { selectedPackage = package }
                                        )
                                    }
                                }
                                .padding()
                                .cardStyle()
                            } else {
                                Text("Keine Abo-Optionen verfügbar. Bitte versuche es später erneut.")
                                    .font(.footnote)
                                    .foregroundColor(Palette.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            // MARK: Hinweise / Rechtliches
                            VStack(spacing: 6) {
                                Text("Die Zahlung wird über dein Apple-ID-Konto abgewickelt.")
                                Text("Abos verlängern sich automatisch, sofern sie nicht mindestens 24 Stunden vor Ablauf gekündigt werden.")
                                Text("Verwalte oder kündige dein Abo jederzeit in den iOS-Einstellungen unter „Apple-ID“ → „Abonnements“.")
                            }
                            .font(.caption2)
                            .foregroundColor(Palette.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    
                    // MARK: Kauf-Button
                    VStack(spacing: 8) {
                        Button(action: purchase) {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                
                                Text(buttonTitle)
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                selectedPackage != nil
                                ? LinearGradient(
                                    gradient: Gradient(colors: [Palette.accent, Palette.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    gradient: Gradient(colors: [Color.gray, Color.gray]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .disabled(selectedPackage == nil || isLoading)
                        .padding(.horizontal)
                        
                        Button(action: restorePurchase) {
                            Text("Kauf wiederherstellen")
                                .font(.footnote)
                                .foregroundColor(Palette.accent)
                        }
                        .disabled(isLoading)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .onAppear {
            loadOfferings()
        }
        .alert("Fehler", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Helper: Button-Titel
    
    private var buttonTitle: String {
        guard let package = selectedPackage else { return "Paket auswählen" }
        
        let baseName: String
        switch package.packageType {
        case .monthly:
            baseName = "Monatsabo"
        case .annual:
            baseName = "Jahresabo"
        case .lifetime:
            baseName = "Lifetime"
        default:
            baseName = package.storeProduct.localizedTitle
        }
        
        return "Fokus Pro – \(baseName) für \(package.storeProduct.localizedPriceString) freischalten"
    }
    
    // MARK: - Offerings laden
    
    private func loadOfferings() {
        isLoading = true
        
        Task {
            do {
                let fetchedOfferings = try await Purchases.shared.offerings()
                
                await MainActor.run {
                    self.offerings = fetchedOfferings
                    
                    if let currentOffering = fetchedOfferings.current {
                        let sorted = currentOffering.availablePackages.sorted(by: sortPackages)
                        self.selectedPackage = sorted.first
                    }
                    
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Fehler beim Laden der Abo-Optionen: \(error.localizedDescription)"
                    self.showingError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Paket-Sortierung (Jahr → Monat → Lifetime → Rest)
    
    private func sortPackages(_ p1: Package, _ p2: Package) -> Bool {
        func weight(for type: PackageType) -> Int {
            switch type {
            case .annual: return 0      // ganz oben, bestes Angebot
            case .monthly: return 1
            case .lifetime: return 2
            default: return 3
            }
        }
        return weight(for: p1.packageType) < weight(for: p2.packageType)
    }
    
    // MARK: - Kauf
    
    private func purchase() {
        guard let package = selectedPackage else { return }
        isLoading = true
        
        Task {
            let success = await revenueCat.purchase(package: package)
            
            await MainActor.run {
                self.isLoading = false
                
                if success {
                    dismiss()
                } else {
                    self.errorMessage = "Kauf fehlgeschlagen. Bitte versuche es erneut."
                    self.showingError = true
                }
            }
        }
    }
    
    private func restorePurchase() {
        isLoading = true
        
        Task {
            let success = await revenueCat.restorePurchases()
            
            await MainActor.run {
                self.isLoading = false
                
                if success {
                    dismiss()
                } else {
                    self.errorMessage = "Keine vorherigen Käufe gefunden."
                    self.showingError = true
                }
            }
        }
    }
}

// MARK: - Package Button Component

struct PackageButton: View {
    let package: Package
    let isSelected: Bool
    let isRecommended: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(titleText)
                            .fontWeight(.semibold)
                            .foregroundColor(Palette.textPrimary)
                        
                        if isRecommended {
                            Text("Beliebt")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Palette.accent, Palette.purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text(subtitleText)
                        .font(.footnote)
                        .foregroundColor(Palette.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(package.storeProduct.localizedPriceString)
                        .font(.headline)
                        .foregroundColor(Palette.textPrimary)
                    
                    if let discount = calculateDiscount() {
                        Text("\(discount)% sparen")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.12))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(12)
            .background(backgroundStyle)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Palette.accent : Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Texte
    
    private var titleText: String {
        switch package.packageType {
        case .monthly:
            return "Monatliches Abo"
        case .annual:
            return "Jährliches Abo"
        case .lifetime:
            return "Lifetime"
        default:
            return package.storeProduct.localizedTitle
        }
    }
    
    private var subtitleText: String {
        switch package.packageType {
        case .monthly:
            return "Flexibel, monatlich kündbar"
        case .annual:
            return "Spare im Jahrespaket"
        case .lifetime:
            return "Einmal zahlen, für immer nutzen"
        default:
            return "Voller Zugriff auf Fokus Pro"
        }
    }
    
    // MARK: - Rabatt-Badge
    
    private func calculateDiscount() -> Int? {
        switch package.packageType {
        case .annual:
            // z. B. im Vergleich zum Monatsabo – statisch, weil wir deine Preise kennen
            return 62 // bei 1,99€/Monat vs. 8,99€/Jahr ≈ 62% günstiger
        case .lifetime:
            return nil // optional
        default:
            return nil
        }
    }
    
    private var backgroundStyle: some View {
        Group {
            if isSelected {
                Palette.accent.opacity(0.1)
            } else {
                Palette.card.opacity(0.8)
            }
        }
    }
}

// Preview
struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
            .environmentObject(RevenueCatManager.shared)
            .preferredColorScheme(.dark)
    }
}
