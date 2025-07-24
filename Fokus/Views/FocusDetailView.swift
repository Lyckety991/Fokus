//
//  FocusDetailView.swift
//  Fokus
//
//  Created by Patrick Lanham on 09.07.25.
//

import SwiftUI

struct FocusDetailView: View {
    
    @EnvironmentObject var revenueCat: RevenueCatManager
    
    
    @Binding var focus: FocusItemModel
    @ObservedObject var store: FocusStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditView = false
    @State private var showCompletionAnimation = false
    @State private var xpEarned = 0
    @State private var pressProgress: CGFloat = 0.0
    @State private var isPressing = false
    @State private var showDeleteConfirmation = false
    @State private var isCompleted = false
    
    @State private var showPaywall = false 
    
    
    private var statistics: FocusStatistics {
            StatisticsHelper.calculateFocusStatistics(for: focus)
        }
    
    
    private var isCompletedToday: Bool {
        guard let lastDate = focus.lastCompletionDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
    
    // Abschluss ist auch ohne Todos möglich
    private var canComplete: Bool {
        !isCompletedToday
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header mit Titel und Bearbeiten-Button
                   
                    
                    // Info-Karten
                    VStack(spacing: 16) {
                        if !focus.description.isEmpty {
                            infoCard(title: "Beschreibung", content: focus.description, icon: "text.alignleft")
                        }
                        
                        if !focus.weakness.isEmpty {
                            infoCard(title: "Schwäche", content: focus.weakness, icon: "exclamationmark.triangle", color: Palette.warning)
                        }
                        
                        if let lastDate = focus.lastCompletionDate {
                            infoCard(title: "Letzter Abschluss", content: lastDate.formatted(date: .abbreviated, time: .shortened), icon: "calendar", color: Palette.secondary)
                        }
                    }
                    
                    // Todos
                    if !focus.todos.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(Palette.accent)
                                Text("Ziele")
                                    .titleStyle()
                                
                                Spacer()
                                
                                Text("\(focus.todos.filter { $0.isCompleted }.count)/\(focus.todos.count)")
                                    .font(.headline)
                                    .foregroundColor(focus.todos.allSatisfy { $0.isCompleted } ? Palette.completed : Palette.textPrimary)
                            }
                            
                            LazyVStack(spacing: 12) {
                                ForEach($focus.todos) { $todo in
                                    todoRow(todo: $todo)
                                }
                            }
                        }
                        .padding()
                        .cardStyle()
                    }
                    
                    if revenueCat.isPremium {
                        FocusStatisticsView(statistics: statistics)
                        
                    } else {
                        FocusStatisticsView(statistics: statistics)
                            .blur(radius: 2.5)
                            .overlay {
                                ZStack {
                                    // Blur-Effekt im Vordergrund
                                    VisualEffectBlur(blurStyle: .systemMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .opacity(0.95)
                                    
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                        
                                        Text("Statistiken nur mit Premium verfügbar")
                                            .font(.footnote)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                        
                                        
                                    }
                                    
                                    
                                    .multilineTextAlignment(.center)
                                    .padding()
                                }
                                
                                
                            }
                            .onTapGesture {
                                showPaywall = true
                            }
                            .sheet(isPresented: $showPaywall) {
                                PaywallView()
                                    .onDisappear {
                                        // Aktualisiere UI nach Kauf
                                        if revenueCat.isPremium {
                                            // Optional: Animation auslösen
                                        }
                                    }
                            }
                    }
                    
                    
                    
                    
                    
                    
                    
                    // Abschluss-Button mit Long-Press
                    VStack(spacing: 16) {
                        if showCompletionAnimation {
                            completionAnimationView
                        }
                        
                        LongPressButton(
                            isCompletedToday: isCompletedToday,
                            canComplete: !isCompletedToday,
                            pressProgress: $pressProgress,
                            action: {
                                showCompletionAnimation = true
                                completeFocus()
                            }
                        )
                        
                    }
                    .padding(.top)
                }
                .padding()
            }
            .background(Palette.background)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingEditView) {
                EditFocusView(focus: $focus, store: store)
            }
            .confirmationDialog(
                "Fokus löschen",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Löschen", role: .destructive) {
                    store.deleteFocus(focus)
                    dismiss()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Bist du sicher, dass du '\(focus.title)' löschen möchtest? Diese Aktion kann nicht rückgängig gemacht werden.")
            }
            .onChange(of: focus.todos) { _ in
                store.updateFocus(focus)
            }
            .onChange(of: focus.completionDates) { _ in
                store.updateFocus(focus)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(focus.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            ToolbarItem(placement: .topBarTrailing) {
                
                Menu {
                    Button(action: { showingEditView = true }) {
                        Label("Bearbeiten", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(Palette.accent)
                }
                
            }
        }

        
    }
    
    // MARK: - Subviews
    
    private func infoCard(title: String, content: String, icon: String, color: Color = Palette.accent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .headlineStyle()
            }
            
            Text(content)
                .bodyTextStyle()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private func todoRow(todo: Binding<FocusTodoModel>) -> some View {
        HStack {
            Button(action: {
                todo.wrappedValue.isCompleted.toggle()
            }) {
                Image(systemName: todo.wrappedValue.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(todo.wrappedValue.isCompleted ? Palette.completed : Palette.textSecondary)
            }
            
            TextField("Todo", text: todo.title)
                .bodyTextStyle()
            
            if todo.wrappedValue.isCompleted {
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundColor(Palette.completed)
            }
        }
        .padding()
        .background(Palette.card.opacity(0.5))
        .cornerRadius(12)
    }
    
    private var completionAnimationView: some View {
        VStack {
            // Confetti Animation würde hier stehen
            ZStack {
                Circle()
                    .fill(Palette.accent)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
            
            Text("+\(xpEarned) XP erhalten!")
                .headlineStyle()
                .padding()
                .background(Palette.completed.opacity(0.2))
                .foregroundColor(Palette.completed)
                .cornerRadius(12)
        }
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showCompletionAnimation = false
                }
            }
        }
    }
    
    // MARK: - Long Press Button
    struct LongPressButton: View {
        let isCompletedToday: Bool
        let canComplete: Bool
        @Binding var pressProgress: CGFloat
        let action: () -> Void

        @State private var isPressing = false
        @State private var timer: Timer?

        var body: some View {
            VStack(spacing: 8) {
                ZStack {
                    // Hintergrund
                    RoundedRectangle(cornerRadius: 16)
                        .fill(backgroundFill)
                        .frame(height: 60)

                    // Fortschrittsbalken
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(progressFill)
                            .frame(width: geometry.size.width * pressProgress, height: 60)
                            .animation(.linear(duration: 0.1), value: pressProgress)
                    }

                    // Inhalt
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: isCompletedToday ? "checkmark.seal.fill" : "flag.checkered")
                                .font(.title2)

                            Text(buttonText)
                                .font(.subheadline)
                        }
                        Spacer()
                    }
                    .foregroundColor(foregroundColor)
                }
                .frame(height: 60)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in handlePressStart() }
                        .onEnded { _ in handlePressEnd() }
                )
                .disabled(!canComplete)

                if canComplete {
                    Text("Halte den Button 2 Sekunden gedrückt")
                        .font(.caption)
                        .foregroundColor(Palette.textSecondary)
                }
            }
        }

        // MARK: - UI-Helper
        private var backgroundFill: Color {
            isCompletedToday ? Palette.completed.opacity(0.2) : Palette.textSecondary.opacity(0.2)
        }

        private var progressFill: LinearGradient {
            LinearGradient(
                gradient: Gradient(colors: [Palette.accent, Palette.completed]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        private var foregroundColor: Color {
            isCompletedToday ? Palette.completed : .white
        }

        private var buttonText: String {
            isCompletedToday ? "Heute abgeschlossen" : (isPressing ? "\(Int(pressProgress * 100))%" : "Tagesabschluss")
        }

        // MARK: - Press Handling
        private func handlePressStart() {
            guard canComplete, !isPressing else { return }

            isPressing = true
            pressProgress = 0.0

            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                pressProgress += 0.025

                if pressProgress >= 1.0 {
                    action()
                    resetPressState()
                }
            }
        }

        private func handlePressEnd() {
            if isPressing {
                resetPressState()
            }
        }

        private func resetPressState() {
            timer?.invalidate()
            timer = nil

            withAnimation(.spring()) {
                isPressing = false
                pressProgress = 0.0
            }
        }
    }

    private func completeFocus() {
        // XP-Belohnung berechnen
        let baseXP = 25
        let bonusXP = focus.todos.count * 5
        xpEarned = baseXP + bonusXP
        
        // Animation zeigen
        withAnimation(.spring()) {
            showCompletionAnimation = true
        }
        
        // Fokus abschließen (durch den Store)
        store.completeFocus(focus.id)
        
        // Nicht die Todos hier zurücksetzen - das macht der Store
        // Nicht updateFocus aufrufen - das macht der Store
    }
}
// MARK: - Preview
struct FocusDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFocus = FocusItemModel(
            title: "Produktivität steigern",
            description: "Täglich konzentriert arbeiten ohne Ablenkungen",
            weakness: "Social Media",
            todos: [
                FocusTodoModel(title: "Handy in den Flugmodus"),
                FocusTodoModel(title: "Alle Benachrichtigungen deaktivieren"),
                FocusTodoModel(title: "Pomodoros einhalten", isCompleted: true)
            ],
            completionDates: [Date()]
        )
        
        return FocusDetailView(
            focus: .constant(sampleFocus),
            store: FocusStore()
        )
        .environmentObject(RevenueCatManager())
    }
}



