import StoreKit
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var quickDoseViewModel = QuickDoseViewModel()
    @State private var showingQuickDoseSheet = false
    @State private var showingSuccessMessage = false
    @State private var selectedTab = "home"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag("home")

            // Empty view for Add tab - sheet presentation handled by onChange
            Color.clear
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag("add")

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag("history")

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag("analytics")

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag("settings")
        }
        .accessibilityIdentifier("main-tab-view")
        .sheet(isPresented: $showingQuickDoseSheet, content: {
            QuickDoseSheet(
                viewModel: quickDoseViewModel,
                showingSuccessMessage: $showingSuccessMessage
            )
        })
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == "add" {
                showingQuickDoseSheet = true
                // Reset tab selection to previous tab so + doesn't stay selected
                selectedTab = oldValue
            }
        }
        .onAppear {
            quickDoseViewModel.loadSmartDefaults(context: modelContext)
        }
        .overlay(alignment: .top) {
            if showingSuccessMessage {
                Text("Dose logged successfully!")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.9))
                    .cornerRadius(8)
                    .accessibilityIdentifier("dose-logged-success")
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onAppear {
                        // Auto-dismiss success message after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showingSuccessMessage = false
                            }
                        }
                    }
            }
        }
    }
}

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Dashboard")
                    .font(.largeTitle)
                    .bold()
                Text("Welcome to JabTracker")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Home")
        }
    }
}


struct HistoryView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Dose History")
                    .font(.largeTitle)
                    .bold()
                Text("Your medication tracking history")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("History")
        }
    }
}

struct AnalyticsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Analytics")
                    .font(.largeTitle)
                    .bold()
                Text("Concentration levels and insights")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Analytics")
        }
    }
}

// SettingsView moved to JabTracker/Views/Settings/SettingsView.swift

#Preview {
    ContentView()
        .modelContainer(DataController.preview.container)
}
