//
//  CalorieExpenditureView.swift
//  JabTracker
//
//  Calorie expenditure settings for burned calories, activity adjustment, and rollover.
//

import SwiftData
import SwiftUI

struct CalorieExpenditureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    private var user: User? {
        users.first
    }

    var body: some View {
        List {
            if let user = user {
                burnedCaloriesSection(user: user)
                predictiveActivitySection(user: user)
                rolloverCaloriesSection(user: user)
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
        .onChange(of: user?.addBurnedCaloriesEnabled) { _, _ in try? modelContext.save() }
        .onChange(of: user?.predictiveActivityEnabled) { _, _ in try? modelContext.save() }
        .onChange(of: user?.rolloverCaloriesEnabled) { _, _ in try? modelContext.save() }
    }

    // MARK: - Sections

    @ViewBuilder
    private func burnedCaloriesSection(user: User) -> some View {
        Section {
            Toggle(isOn: burnedCaloriesBinding(for: user)) {
                Text("Add burned calories")
                    .font(DesignTokens.Typography.body)
            }
            .disabled(!user.healthSyncEnabled)
            .accessibilityIdentifier("add-burned-calories-toggle")
        } footer: {
            burnedCaloriesFooter(user: user)
        }
    }

    @ViewBuilder
    private func burnedCaloriesFooter(user: User) -> some View {
        if !user.healthSyncEnabled {
            Text("Enable Health Sync in settings to use this feature.")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.danger)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("Adds today's active calories from HealthKit to your daily target.")
                Text("Cannot be used with Predictive Activity.")
                    .foregroundStyle(.secondary)
            }
            .font(DesignTokens.Typography.caption)
        }
    }

    @ViewBuilder
    private func predictiveActivitySection(user: User) -> some View {
        Section {
            Toggle(isOn: predictiveActivityBinding(for: user)) {
                Text("Predictive Activity Adjustment")
                    .font(DesignTokens.Typography.body)
            }
            .disabled(!user.healthSyncEnabled)
            .accessibilityIdentifier("predictive-activity-toggle")
        } footer: {
            predictiveActivityFooter(user: user)
        }
    }

    @ViewBuilder
    private func predictiveActivityFooter(user: User) -> some View {
        if !user.healthSyncEnabled {
            Text("Enable Health Sync in settings to use this feature.")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.danger)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("Adds your 7-day average activity to daily targets.")
                Text("Cannot be used with Add Burned Calories.")
                    .foregroundStyle(.secondary)
                if let goal = user.activeNutritionGoal {
                    Text(goalMultiplierText(for: goal.goalType))
                        .foregroundStyle(.secondary)
                }
            }
            .font(DesignTokens.Typography.caption)
        }
    }

    @ViewBuilder
    private func rolloverCaloriesSection(user: User) -> some View {
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
    }

    // MARK: - Bindings

    /// Binding for burned calories that disables predictive when enabled
    private func burnedCaloriesBinding(for user: User) -> Binding<Bool> {
        Binding(
            get: { user.addBurnedCaloriesEnabled },
            set: { newValue in
                user.addBurnedCaloriesEnabled = newValue
                if newValue {
                    user.predictiveActivityEnabled = false
                }
            }
        )
    }

    /// Binding for predictive activity that disables burned when enabled
    private func predictiveActivityBinding(for user: User) -> Binding<Bool> {
        Binding(
            get: { user.predictiveActivityEnabled },
            set: { newValue in
                user.predictiveActivityEnabled = newValue
                if newValue {
                    user.addBurnedCaloriesEnabled = false
                }
            }
        )
    }

    // MARK: - Helpers

    /// Returns descriptive text for the goal-based activity multiplier
    private func goalMultiplierText(for goalType: GoalType) -> String {
        switch goalType {
        case .weightLoss:
            return "Currently: 80% of activity (weight loss)"
        case .maintenance:
            return "Currently: 100% of activity (maintenance)"
        case .muscleGain:
            return "Currently: 120% of activity (muscle gain)"
        }
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
