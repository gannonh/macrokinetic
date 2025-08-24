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
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Settings")
                            .font(DesignTokens.Typography.largeTitle)
                            .accessibilityIdentifier("design-system-large-title")
                        Text("App preferences and profile")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(.secondary)
                    }

                    // Design System Demo Section
                    DesignCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Design System Demo")
                                .font(DesignTokens.Typography.headline)
                                .accessibilityIdentifier("design-system-headline")

                            Text("Typography and Colors")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(.secondary)
                                .accessibilityIdentifier("design-system-body")

                            Text("Sample caption text")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(.secondary)
                                .accessibilityIdentifier("design-system-caption")

                            VStack(spacing: 12) {
                                PrimaryButton(title: "Primary Button") {
                                    // Demo action
                                }

                                SecondaryButton(title: "Secondary Button") {
                                    // Demo action
                                }
                            }
                        }
                    }

                    // Settings Options
                    DesignCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Preferences")
                                .font(DesignTokens.Typography.headline)

                            VStack(spacing: 8) {
                                HStack {
                                    Text("Notifications")
                                        .font(DesignTokens.Typography.body)
                                    Spacer()
                                    Toggle("", isOn: .constant(true))
                                }

                                HStack {
                                    Text("Face ID")
                                        .font(DesignTokens.Typography.body)
                                    Spacer()
                                    Toggle("", isOn: .constant(false))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
