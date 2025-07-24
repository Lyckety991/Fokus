//
//  PaywallView.swift
//  Fokus
//
//  Created by Patrick Lanham on 20.07.25.
//
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
    
    let features = [
        "Unbegrenzte Statistiken",
        "Fortschrittsanalyse",
        "Premium-Benachrichtigungen",
        "Exklusive Fokus-Modi",
        "Wöchentliche Berichte",
        "Keine Werbung"
    ]
    
    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Palette.textSecondary)
                    }
                }
                .padding(.top)
                
                if isLoading {
                    Spacer()
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Lade Abo-Optionen...")
                            .foregroundColor(Palette.textSecondary)
                            .padding(.top)
                    }
                    Spacer()
                } else {
                    // Hauptinhalt
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Titel
                            Text("Hole dir Fokus Pro!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Palette.textPrimary)
                                .multilineTextAlignment(.center)
                            
                            // Features
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Mit Fokus Pro bekommst du:")
                                    .headlineStyle()
                                    .padding(.bottom, 4)
                                
                                ForEach(features, id: \.self) { feature in
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Palette.completed)
                                            .font(.system(size: 20))
                                        Text(feature)
                                            .foregroundColor(Palette.textPrimary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding()
                            .cardStyle()
                            
                            // Abo-Optionen von RevenueCat
                            if let offering = offerings?.current {
                                VStack(spacing: 16) {
                                    Text("Wähle dein Abo:")
                                        .headlineStyle()
                                    
                                    ForEach(offering.availablePackages, id: \.identifier) { package in
                                        PackageButton(
                                            package: package,
                                            isSelected: selectedPackage?.identifier == package.identifier,
                                            onTap: { selectedPackage = package }
                                        )
                                    }
                                }
                                .padding()
                                .cardStyle()
                            }
                            
                            // Footer
                            VStack(spacing: 8) {
                                Text("""
                                • Zahlung wird über dein iTunes-Konto abgewickelt
                                • Abo verlängert sich automatisch, außer es wird 24h vor Ablauf gekündigt
                                • Du kannst jederzeit in den Einstellungen kündigen
                                """)
                                .font(.caption)
                                .foregroundColor(Palette.textSecondary)
                                .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Kauf-Button
                    Button(action: purchase) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(selectedPackage != nil ? "Jetzt \(selectedPackage!.storeProduct.localizedTitle) kaufen" : "Paket auswählen")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            selectedPackage != nil ?
                            LinearGradient(
                                gradient: Gradient(colors: [Palette.accent, Palette.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [Color.gray, Color.gray]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .disabled(selectedPackage == nil || isLoading)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    // Wiederherstellen-Button
                    Button(action: restorePurchase) {
                        Text("Kauf wiederherstellen")
                            .font(.footnote)
                            .foregroundColor(Palette.accent)
                    }
                    .disabled(isLoading)
                    .padding(.bottom)
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
    
    private func loadOfferings() {
        isLoading = true
        
        Task {
            do {
                let fetchedOfferings = try await Purchases.shared.offerings()
                
                await MainActor.run {
                    self.offerings = fetchedOfferings
                    
                    // Automatisch das erste Paket auswählen (normalerweise das empfohlene)
                    if let currentOffering = fetchedOfferings.current,
                       let firstPackage = currentOffering.availablePackages.first {
                        self.selectedPackage = firstPackage
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
    
    private func purchase() {
        guard let package = selectedPackage else { return }
        
        isLoading = true
        
        Task {
            let success = await revenueCat.purchase(package: package)
            
            await MainActor.run {
                self.isLoading = false
                
                if success {
                    // Erfolgreich gekauft - View schließen
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
                    // Erfolgreich wiederhergestellt
                    dismiss()
                } else {
                    self.errorMessage = "Keine vorherigen Käufe gefunden."
                    self.showingError = true
                }
            }
        }
    }
}

// MARK: - Package Button Component (Vereinfacht)
struct PackageButton: View {
    let package: Package
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            packageContent
        }
    }
    
    private var packageContent: some View {
        HStack {
            leadingContent
            Spacer()
            trailingContent
        }
        .padding()
        .background(backgroundStyle)
        .cornerRadius(12)
    }
    
    private var leadingContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(package.storeProduct.localizedTitle)
                .fontWeight(.semibold)
                .foregroundColor(Palette.textPrimary)
            
            Text(packageDescription)
                .font(.footnote)
                .foregroundColor(Palette.textSecondary)
        }
    }
    
    private var trailingContent: some View {
        VStack(alignment: .trailing, spacing: 2) {
            priceText
            
            if let discount = calculateDiscount() {
                discountBadge(discount: discount)
            }
        }
    }
    
    private var priceText: some View {
        Group {
            if let introPrice = package.storeProduct.introductoryDiscount {
                Text(introPrice.localizedPriceString)
            } else {
                Text(package.storeProduct.localizedPriceString)
            }
        }
        .font(.title3)
        .fontWeight(.bold)
        .foregroundColor(Palette.textPrimary)
    }
    
    private func discountBadge(discount: Int) -> some View {
        Text("\(discount)% sparen")
            .font(.caption)
            .foregroundColor(.green)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.1))
            .cornerRadius(4)
    }
    
    private var backgroundStyle: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Palette.accent : Color.gray.opacity(0.3), lineWidth: 2)
            
            (isSelected ? Palette.accent.opacity(0.1) : Palette.card.opacity(0.5))
        }
    }
    
    private var packageDescription: String {
        switch package.packageType {
        case .monthly:
            return "Monatliche Zahlung"
        case .annual:
            return "Jährliche Zahlung - Bestes Angebot!"
        case .lifetime:
            return "Einmalige Zahlung"
        default:
            return "Premium-Zugang"
        }
    }
    
    private func calculateDiscount() -> Int? {
        switch package.packageType {
        case .annual:
            return 58
        case .lifetime:
            return 75
        default:
            return nil
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
