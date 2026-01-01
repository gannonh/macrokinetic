//
//  CalorieExpenditureView.swift
//  JabTracker
//
//  Calorie expenditure settings for burned calories, activity adjustment, and rollover.
//

import SwiftUI

struct CalorieExpenditureView: View {
    @State private var addBurnedCalories = false
    @State private var predictiveActivityAdjustment = false
    @State private var rolloverCalories = false

    var body: some View {
        List {
            // Mock notice
            Section {
                Text("This is a preview")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            }

            // Add Burned Calories
            Section {
                Toggle(isOn: $addBurnedCalories) {
                    Text("Add burned calories")
                        .font(DesignTokens.Typography.body)
                }
                .disabled(true)
                .accessibilityIdentifier("add-burned-calories-toggle")
            } footer: {
                Text("Add burned calories back to daily targets (must have Health sync enabled)")
                    .font(DesignTokens.Typography.caption)
            }

            // Predictive Activity Adjustment
            Section {
                Toggle(isOn: $predictiveActivityAdjustment) {
                    Text("Predictive Activity Adjustment")
                        .font(DesignTokens.Typography.body)
                }
                .disabled(true)
                .accessibilityIdentifier("predictive-activity-toggle")
            } footer: {
                Text("Adjust daily calorie targets based on activity trends (must have Health sync enabled)")
                    .font(DesignTokens.Typography.caption)
            }

            // Rollover Calories
            Section {
                Toggle(isOn: $rolloverCalories) {
                    Text("Rollover calories")
                        .font(DesignTokens.Typography.body)
                }
                .disabled(true)
                .accessibilityIdentifier("rollover-calories-toggle")
            } footer: {
                Text("Add up to 200 unused calories to next day's targets")
                    .font(DesignTokens.Typography.caption)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Calorie Expenditure")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("calorie-expenditure-view")
    }
}

#Preview {
    NavigationStack {
        CalorieExpenditureView()
    }
}
