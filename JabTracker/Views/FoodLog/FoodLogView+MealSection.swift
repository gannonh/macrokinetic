//
//  FoodLogView+MealSection.swift
//  JabTracker
//
//  Meal section UI components for FoodLogView.
//

import SwiftUI

// MARK: - Meal Section Totals

/// Meal section totals for headers
struct MealTotals {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double

    static let zero = MealTotals(calories: 0, protein: 0, carbs: 0, fat: 0)

    init(from entries: [FoodEntry]) {
        self.calories = entries.reduce(0) { $0 + $1.calories }
        self.protein = entries.reduce(0) { $0 + $1.protein }
        self.carbs = entries.reduce(0) { $0 + $1.carbs }
        self.fat = entries.reduce(0) { $0 + $1.fat }
    }

    init(calories: Double, protein: Double, carbs: Double, fat: Double) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}

// MARK: - Meal Totals View

/// Displays macro totals for a meal section header
struct MealTotalsView: View {
    let totals: MealTotals

    var body: some View {
        if totals.calories > 0 {
            HStack(spacing: 6) {
                HStack(spacing: 3) {
                    Text("\(Int(totals.protein))P")
                        .foregroundColor(DesignTokens.Colors.protein)
                    Text("\(Int(totals.fat))F")
                        .foregroundColor(DesignTokens.Colors.fat)
                    Text("\(Int(totals.carbs))C")
                        .foregroundColor(DesignTokens.Colors.carbs)
                }
                .font(.caption2)

                HStack(spacing: 2) {
                    Text("\(Int(totals.calories))")
                        .font(.caption)
                        .fontWeight(.medium)
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                }
                .foregroundColor(DesignTokens.Colors.calories)
            }
        }
    }
}

// MARK: - Empty Meal Row

/// Styled empty state row for meal sections
struct EmptyMealRow: View {
    var body: some View {
        Text("No items logged")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .cardStyle()
    }
}
