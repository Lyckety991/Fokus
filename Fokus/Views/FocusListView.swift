//
//  FocusListView.swift
//  Fokus
//
//  Created by Patrick Lanham on 09.07.25.
//

import SwiftUI
import UniformTypeIdentifiers



struct FocusListView: View {
    
    @EnvironmentObject var revenueCat: RevenueCatManager
    
    @StateObject private var store = FocusStore()
    @State private var showAddView = false
    @State private var showingStatistics = false
    @State private var exportFile: URL?
    @State private var showingExporter = false
    
    private var globalStats: GlobalStatistics {
           StatisticsHelper.calculateGlobalStatistics(
               for: store.focusItems,
               totalXP: store.userProgress?.totalXP ?? 0
           )
       }
    
    
    var body: some View {
        NavigationStack {
           
            ScrollView {
                VStack(spacing: 20) {
                    progressCard
                    focusListSection
                }
                .padding(.vertical)
            }
            .background(Palette.background)
            .navigationTitle("Fokus")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddView = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Palette.accent)
                        Text("Add")
                            .foregroundStyle(Palette.accent)
                            .bold()
                    }
                }
            }
            .sheet(isPresented: $showAddView) {
                AddFocusView(store: store)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fortschritt")
                .headlineStyle()
                .padding(.bottom, 4)
            
            if let progress = store.userProgress {
                HStack {
                    LevelBadge(level: progress.currentLevel)
                    
                    VStack(alignment: .leading) {
                        Text("Level \(progress.currentLevel)")
                            .titleStyle()
                        
                        Text("\(progress.totalXP) XP")
                            .bodyTextStyle()
                    }
                    
                    Spacer()
                    
                    XPProgressBar(totalXP: progress.totalXP)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .cardStyle()
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .onTapGesture {
                                showingStatistics = true
                            }
        .sheet(isPresented: $showingStatistics) {
            GlobalStatisticsView(statistics: globalStats, store: FocusStore())
                .environmentObject(revenueCat)
        }
        .fileExporter(
                        isPresented: $showingExporter,
                        document: CSVFile(initialText: ""),
                        contentType: .commaSeparatedText,
                        defaultFilename: "focus_export.csv"
                    ) { result in
                        switch result {
                        case .success(let url):
                            print("Export erfolgreich: \(url)")
                        case .failure(let error):
                            print("Export fehlgeschlagen: \(error)")
                        }
                    }
    }
        
    
    private var focusListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Deine Ziele")
                    .titleStyle()
                
                Spacer()
                
                Text("\(store.focusItems.count)")
                    .padding(6)
                    .background(Palette.accent.opacity(0.2))
                    .foregroundColor(Palette.accent)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            if store.focusItems.isEmpty {
                EmptyStateView()
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(store.focusItems.indices, id: \.self) { index in
                        FocusRowView(
                            focus: $store.focusItems[index],
                            store: store
                        )
                        .padding(.horizontal)
                        .contextMenu {
                            Button(role: .destructive) {
                                store.deleteFocus(store.focusItems[index])
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
}


struct CSVFile: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var text: String
    
    init(initialText: String = "") {
        text = initialText
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}


// MARK: - LevelBadge View
private struct LevelBadge: View {
    let level: Int
    
    var body: some View {
        ZStack {
            GradientCircle()
                .frame(width: 50, height: 50)
            
            Text("\(level)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - XPProgressBar View
private struct XPProgressBar: View {
    let totalXP: Int
    
    private var progress: CGFloat {
        let remainder = totalXP % 100
        return CGFloat(remainder) / 100
    }
    
    private var nextLevelXP: Int {
        100 - (totalXP % 100)
    }
    
    var body: some View {
        VStack(alignment: .trailing) {
            Text("\(totalXP % 100)/100 XP")
                .bodyTextStyle()
            
            ProgressView(value: progress)
                .progressBarStyle(progress: progress)
                .frame(width: 120)
            
            Text("Noch \(nextLevelXP) XP bis Level \(totalXP / 100 + 2)")
                .font(.caption2)
                .bodyTextStyle()
        }
    }
}

// MARK: - EmptyStateView
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(Palette.accent)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text("Keine Fokuse gefunden")
                    .headlineStyle()
                
                Text("Erstelle deinen ersten Fokus, um deine Produktivität zu steigern")
                    .bodyTextStyle()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .cardStyle()
        .padding(.horizontal)
        .padding(.vertical, 20)
    }
}

// MARK: - FocusRowView


#Preview {
    FocusListView()
   
        .preferredColorScheme(.dark)
        .environmentObject(RevenueCatManager())
        // Test für Dark Mode
}
