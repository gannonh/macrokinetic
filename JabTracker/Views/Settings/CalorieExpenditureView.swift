//
//  CalorieExpenditureView.swift
//  JabTracker
//
//  Calorie expenditure settings for burned calories, activity adjustment, and rollover.
//

import SwiftData
import SwiftUI

struct CalorieExpenditureView: View {
    @Query private var users: [User]

    private var user: User? {
        users.first
    }

    var body: some View {
        List {
            if let user = user {
                // Add Burned Calories
                Section {
                    Toggle(isOn: Bindable(user).addBurnedCaloriesEnabled) {
                        Text("Add burned calories")
                            .font(DesignTokens.Typography.body)
                    }
                    .disabled(!user.healthSyncEnabled)
                    .accessibilityIdentifier("add-burned-calories-toggle")
                } footer: {
                    if !user.healthSyncEnabled {
                        Text("Enable Health Sync in settings to use this feature.")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("Add burned calories back to daily targets")
                            .font(DesignTokens.Typography.caption)
                    }
                }

                // Predictive Activity Adjustment
                Section {
                    Toggle(isOn: Bindable(user).predictiveActivityEnabled) {
                        Text("Predictive Activity Adjustment")
                            .font(DesignTokens.Typography.body)
                    }
                    .disabled(!user.healthSyncEnabled)
                    .accessibilityIdentifier("predictive-activity-toggle")
                } footer: {
                    if !user.healthSyncEnabled {
                        Text("Enable Health Sync in settings to use this feature.")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("Adjust daily calorie targets based on activity trends")
                            .font(DesignTokens.Typography.caption)
                    }
                }

                // Rollover Calories
                Section {
                    Toggle(isOn: Bindable(user).rolloverCaloriesEnabled) {
                        Text("Rollover calories")
                            .font(DesignTokens.Typography.body)
                    }
                    .accessibilityIdentifier("rollover-calories-toggle")
                } footer: {
                    Text("Add up to 200 unused calories to next day's targets")
                        .font(DesignTokens.Typography.caption)
                }
            } else {
                ContentUnavailableView(
                    "No User Found",
                    systemImage: "person.slash",
                    description: Text("Please sign in or create a profile.")
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Calorie Expenditure")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("calorie-expenditure-view")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(for: User.self, configurations: config)
    let user = User(
        healthSyncEnabled: true,
        addBurnedCaloriesEnabled: true,
        rolloverCaloriesEnabled: false,
        predictiveActivityEnabled: false
    )
    container.mainContext.insert(user)

    return NavigationStack {
        CalorieExpenditureView()
            .modelContainer(container)
    }
}
