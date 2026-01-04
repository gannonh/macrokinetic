//
//  MacroSummaryConsumedPage.swift
//  JabTracker
//
//  Swipe page showing consumed macro values with progress bars.
//

import SwiftUI

/// Consumed page showing what's been eaten today with progress bars
struct MacroSummaryConsumedPage: View {
    // MARK: - Properties

    let consumedCalories: Double
    let consumedProtein: Double
    let consumedFat: Double
    let consumedCarbs: Double

    let targetCalories: Double
    let targetProtein: Double
    let targetFat: Double
    let targetCarbs: Double

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            MacroProgressBar(
                label: "",
                current: consumedCalories,
                target: targetCalories,
                color: DesignTokens.Colors.calories,
                displayMode: .fraction,
                icon: "flame.fill",
                showRemainingBelow: true,
                accessibilityIdentifier: "macro-consumed-cal"
            )

            MacroProgressBar(
                label: "P",
                current: consumedProtein,
                target: targetProtein,
                color: DesignTokens.Colors.protein,
                displayMode: .fraction,
                showRemainingBelow: true,
                accessibilityIdentifier: "macro-consumed-protein"
            )

            MacroProgressBar(
                label: "F",
                current: consumedFat,
                target: targetFat,
                color: DesignTokens.Colors.fat,
                displayMode: .fraction,
                showRemainingBelow: true,
                accessibilityIdentifier: "macro-consumed-fat"
            )

            MacroProgressBar(
                label: "C",
                current: consumedCarbs,
                target: targetCarbs,
                color: DesignTokens.Colors.carbs,
                displayMode: .fraction,
                showRemainingBelow: true,
                accessibilityIdentifier: "macro-consumed-carbs"
            )
        }
        .accessibilityIdentifier("macro-summary-consumed-page")
    }
}

// MARK: - Preview

#Preview {
    MacroSummaryConsumedPage(
        consumedCalories: 1450,
        consumedProtein: 89,
        consumedFat: 51,
        consumedCarbs: 136,
        targetCalories: 2000,
        targetProtein: 125,
        targetFat: 65,
        targetCarbs: 200
    )
    .padding()
    .background(DesignTokens.Colors.cardBackground)
    .cornerRadius(DesignTokens.CornerRadius.card)
    .padding()
}
