//
//  CalorieExpenditureView.swift
//  JabTracker
//
//  Calorie expenditure mock screen showing daily budget, activity level, and TDEE breakdown.
//

import SwiftUI

struct CalorieExpenditureView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Coming Soon Banner
                Text("Coming Soon")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                // Daily Calorie Budget Card
                DesignCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Calorie Budget")
                            .font(DesignTokens.Typography.headline)

                        Text("2,400 calories")
                            .font(.system(size: 36, weight: .bold))

                        Text("Your target daily calorie intake based on your goals")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityIdentifier("daily-budget-card")

                // Activity Level Card
                DesignCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity Level")
                            .font(DesignTokens.Typography.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            ActivityLevelRow(label: "Sedentary", isSelected: false)
                            ActivityLevelRow(label: "Lightly Active", isSelected: false)
                            ActivityLevelRow(label: "Moderately Active", isSelected: true)
                            ActivityLevelRow(label: "Very Active", isSelected: false)
                            ActivityLevelRow(label: "Extremely Active", isSelected: false)
                        }

                        Text("Affects your daily calorie calculation")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityIdentifier("activity-level-card")

                // TDEE Breakdown Card
                DesignCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Total Daily Energy Expenditure")
                            .font(DesignTokens.Typography.headline)

                        VStack(spacing: 8) {
                            TDEERow(label: "BMR", value: "1,800 cal")
                            TDEERow(label: "Activity", value: "400 cal")
                            TDEERow(label: "TEF", value: "200 cal")

                            Divider()

                            HStack {
                                Text("Total")
                                    .font(DesignTokens.Typography.body.weight(.semibold))
                                Spacer()
                                Text("2,400 cal")
                                    .font(DesignTokens.Typography.body.weight(.semibold))
                            }
                        }

                        Text("Based on your profile and activity level")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityIdentifier("tdee-breakdown-card")

                Spacer()

                // Footer notice
                Text("This feature is coming soon")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Calorie Expenditure")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("calorie-expenditure-view")
    }
}

// MARK: - Supporting Views

private struct ActivityLevelRow: View {
    let label: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .secondary)
            Text(label)
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

private struct TDEERow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(DesignTokens.Typography.body)
        }
    }
}

#Preview {
    NavigationStack {
        CalorieExpenditureView()
    }
}
