//
//  MoreView.swift
//  JabTracker
//
//  More tab with overflow navigation, feature settings, account settings, and support.
//

import SwiftData
import SwiftUI

struct MoreView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Query private var users: [User]

    @State private var showingFoodLibrary = false

    private var currentUser: User? { users.first }

    var body: some View {
        NavigationStack {
            List {
                // Overflow Menu - items not in top-level tabs
                Section {
                    NavigationLink(destination: StrategyView()) {
                        Label("Goals & Strategy", systemImage: "target")
                    }
                    .accessibilityIdentifier("goals-strategy-row")

                    Button {
                        showingFoodLibrary = true
                    } label: {
                        Label("Food Library", systemImage: "book.closed")
                            .foregroundColor(.primary)
                    }
                    .accessibilityIdentifier("food-library-row")

                    NavigationLink(
                        destination: MedicationProfileSettingsView(
                            medicationManager: MedicationManager(
                                modelContext: DataController.shared.container.mainContext)
                        )
                    ) {
                        Label("GLP-1 Medications", systemImage: "pills")
                    }
                    .accessibilityIdentifier("medications-row")
                }

                // Feature Settings Section
                Section("Feature Settings") {
                    // Dashboard - inactive placeholder
                    Label("Dashboard", systemImage: "square.grid.2x2")
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("dashboard-settings-placeholder")

                    // Food Log - inactive placeholder
                    Label("Food Log", systemImage: "fork.knife")
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("food-log-placeholder")

                    NavigationLink(destination: BodyMetricsVisibilityView()) {
                        Label("Metrics", systemImage: "chart.bar")
                    }
                    .accessibilityIdentifier("metrics-settings-link")

                    NavigationLink(destination: UnitsOfMeasureView()) {
                        Label("Units of Measurement", systemImage: "ruler")
                    }
                    .accessibilityIdentifier("units-link")

                    NavigationLink(destination: CalorieExpenditureView()) {
                        Label("Calorie Expenditure", systemImage: "flame")
                    }
                    .accessibilityIdentifier("calorie-expenditure-row")

                    // Shortcuts & Tabs - inactive placeholder
                    Label("Shortcuts & Tabs", systemImage: "bolt.horizontal")
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("shortcuts-placeholder")
                }

                // Account Settings Section
                Section("Account Settings") {
                    NavigationLink(destination: AccountView()) {
                        Label("Profile", systemImage: "person.circle")
                    }
                    .accessibilityIdentifier("profile-link")

                    NavigationLink(destination: SubscriptionSettingsView()) {
                        Label("Subscription", systemImage: "tag")
                    }
                    .accessibilityIdentifier("subscription-row")

                    NavigationLink(destination: SecurityPrivacyView()) {
                        Label("Security & Privacy", systemImage: "lock.shield")
                    }
                    .accessibilityIdentifier("security-privacy-row")

                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notifications", systemImage: "bell")
                    }
                    .accessibilityIdentifier("notifications-row")
                }

                // Support Section
                Section("Support") {
                    // FAQ - inactive placeholder
                    Label("FAQ", systemImage: "questionmark.circle")
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("faq-placeholder")

                    // Help & Support - inactive placeholder
                    Label("Help & Support", systemImage: "lifepreserver")
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("help-support-placeholder")

                    NavigationLink(destination: GeneralSettingsView()) {
                        Label("General", systemImage: "info.circle")
                    }
                    .accessibilityIdentifier("general-link")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingFoodLibrary) {
                if let user = currentUser {
                    FoodSearchSheet(
                        user: user,
                        foodService: AppServices.shared.foodService,
                        mealLogService: AppServices.shared.mealLogService,
                        customFoodService: AppServices.shared.customFoodService,
                        initialMethod: .library,
                        onComplete: { showingFoodLibrary = false }
                    )
                }
            }
        }
        .accessibilityIdentifier("more-view")
    }
}

#Preview {
    MoreView()
        .modelContainer(DataController.preview.container)
        .environmentObject(AuthenticationManager())
}
