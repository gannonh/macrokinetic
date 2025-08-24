import CoreData
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag("home")

            AddDoseView()
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

struct AddDoseView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Dose")
                    .font(.largeTitle)
                    .bold()
                Button("Quick Add Dose") {
                    // TODO: Implement dose addition
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("quick-add-dose-button")
            }
            .navigationTitle("Add Dose")
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

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Settings")
                    .font(.largeTitle)
                    .bold()
                Text("App preferences and profile")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
