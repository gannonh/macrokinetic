//
//  MoreView.swift
//  JabTracker
//
//  Overflow menu containing Settings and future items.
//

import SwiftData
import SwiftUI

struct MoreView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var showingGoalWizard = false

    private var currentUser: User? {
        users.first
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
                }

                Section("Nutrition Goals") {
                    Button {
                        showingGoalWizard = true
                    } label: {
                        Label("Set Up Goals", systemImage: "target")
                    }
                    .accessibilityIdentifier("set-up-goals-button")
                }

                Section("Feature Settings") {
                    NavigationLink(destination: BodyMetricsVisibilityView()) {
                        Label("Body Metrics Visibility", systemImage: "figure.arms.open")
                    }
                    .accessibilityIdentifier("body-metrics-visibility-link")

                    NavigationLink(destination: UnitsOfMeasureView()) {
                        Label("Units of Measure", systemImage: "ruler")
                    }
                    .accessibilityIdentifier("units-of-measure-link")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingGoalWizard) {
                if let user = currentUser {
                    GoalConfigurationWizard(user: user)
                }
            }
        }
        .accessibilityIdentifier("more-view")
    }
}

#Preview {
    MoreView()
}
