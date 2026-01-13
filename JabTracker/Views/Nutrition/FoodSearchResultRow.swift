//
//  FoodSearchResultRow.swift
//  JabTracker
//
//  A row view displaying a food search result with macros.
//

import SwiftUI

/// Row view for displaying a food search result in a list
struct FoodSearchResultRow: View {
    let result: FoodSearchResult

    var body: some View {
        HStack(spacing: 12) {
            // Source icon
            Image(systemName: result.source.iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(sourceColor)
                .frame(width: 24, height: 24)
                .accessibilityLabel(result.source.displayName)

            VStack(alignment: .leading, spacing: 4) {
                // Name and brand
                if let brand = result.brand, !brand.isEmpty {
                    Text(result.name)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(brand)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text(result.name)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }

                // Macros: Calories • P/C/F (for default serving)
                HStack(spacing: 8) {
                    Text("\(Int(result.caloriesPerServing)) cal")
                        .fontWeight(.medium)
                        .foregroundColor(DesignTokens.Colors.calories)

                    Text("•")
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Text("P:\(Int(result.proteinPerServing))")
                            .foregroundColor(DesignTokens.Colors.protein)
                        Text("C:\(Int(result.carbsPerServing))")
                            .foregroundColor(DesignTokens.Colors.carbs)
                        Text("F:\(Int(result.fatPerServing))")
                            .foregroundColor(DesignTokens.Colors.fat)
                    }
                }
                .font(DesignTokens.Typography.caption)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var sourceColor: Color {
        switch result.source {
        case .local:
            return .green  // Whole foods
        case .openFoodFacts:
            return .orange  // Packaged foods
        case .userCreated:
            return .blue  // Custom
        }
    }
}
