//
//  FoodDetailSheet+InputSection.swift
//  JabTracker
//
//  Input section views and helpers for FoodDetailSheet.
//

import SwiftUI

// MARK: - Macro Impact Configuration

/// Data model for macro impact ring display
private struct MacroImpactData: Identifiable {
    let id = UUID()
    let progress: Double
    let label: String
    let color: Color

    var valueText: String {
        "\(Int(progress * 100))%"
    }
}

// MARK: - Impact Section

extension FoodDetailSheet {
    @ViewBuilder
    var impactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Impact on Targets")
                .font(.headline)

            HStack(spacing: 16) {
                ForEach(macroImpactData) { data in
                    CircularProgressRing(
                        progress: data.progress,
                        label: data.label,
                        valueText: data.valueText,
                        color: data.color
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    /// Data-driven array for macro impact rings
    private var macroImpactData: [MacroImpactData] {
        [
            MacroImpactData(progress: calorieImpact, label: "Calories", color: .orange),
            MacroImpactData(progress: proteinImpact, label: "Protein", color: .blue),
            MacroImpactData(progress: fatImpact, label: "Fat", color: .purple),
            MacroImpactData(progress: carbImpact, label: "Carbs", color: .green),
        ]
    }
}

// MARK: - Impact Computed Properties

extension FoodDetailSheet {
    var calorieImpact: Double {
        guard user.dailyCalorieGoal > 0 else { return 0 }
        return scaledCalories / user.dailyCalorieGoal
    }

    var proteinImpact: Double {
        guard user.dailyProteinGoal > 0 else { return 0 }
        return scaledProtein / user.dailyProteinGoal
    }

    var carbImpact: Double {
        guard user.dailyCarbGoal > 0 else { return 0 }
        return scaledCarbs / user.dailyCarbGoal
    }

    var fatImpact: Double {
        guard user.dailyFatGoal > 0 else { return 0 }
        return scaledFat / user.dailyFatGoal
    }
}

// MARK: - Scaled Macro Properties

extension FoodDetailSheet {
    var scaledProtein: Double {
        (food.proteinPer100g * quantityInGrams) / 100.0
    }

    var scaledFat: Double {
        (food.fatPer100g * quantityInGrams) / 100.0
    }
}

// MARK: - Carb Breakdown Section

extension FoodDetailSheet {
    @ViewBuilder
    var carbBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Carb Breakdown")
                .font(.headline)

            VStack(spacing: 8) {
                carbBreakdownRow(label: "Carbs", value: scaledCarbs, goal: user.dailyCarbGoal)
                carbBreakdownRow(label: "Fiber", value: scaledFiber, goal: 20.0)
                carbBreakdownRow(label: "Net (Non-fiber)", value: scaledNetCarbs, goal: nil)
                carbBreakdownRow(label: "Starch", value: 0, goal: nil)
                carbBreakdownRow(label: "Sugars", value: 0, goal: nil)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    func carbBreakdownRow(label: String, value: Double, goal: Double?) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)

            Spacer()

            if let goal = goal, goal > 0 {
                Text("\(String(format: "%.1f", value)) / \(Int(goal)) g")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(Int(value / goal * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if goal == nil {
                Text("No Target")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("\(String(format: "%.1f", value)) g")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Input Section Views

extension FoodDetailSheet {
    // MARK: - Input Display Row

    @ViewBuilder
    var inputDisplayRow: some View {
        HStack {
            if inputMode == .quantity {
                // Quantity mode: enter amount in selected unit
                TextField("0", value: $servingCount, format: .number.precision(.fractionLength(0...2)))
                    .font(.title.weight(.semibold))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 100)
                    .accessibilityIdentifier(Self.quantityInputIdentifier)

                Spacer()

                // Show unit and gram equivalent
                VStack(alignment: .trailing, spacing: 2) {
                    Text(selectedUnit.rawValue)
                        .font(.subheadline.weight(.medium))
                    if selectedUnit != .grams {
                        Text("\(Int(quantityInGrams))g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // Target mode: enter macro target
                TextField("0", value: $targetValue, format: .number.precision(.fractionLength(0...1)))
                    .font(.title.weight(.semibold))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 100)
                    .accessibilityIdentifier("target-input")

                Spacer()

                // Show calculated quantity
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(calculatedQuantityDisplay) \(selectedUnit.rawValue)")
                        .font(.subheadline.weight(.medium))
                    Text("\(Int(quantityInGrams))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Mode and Unit Selector

    @ViewBuilder
    var modeAndUnitSelector: some View {
        HStack(spacing: 8) {
            // Swap mode button
            Button {
                toggleInputMode()
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(8)
            }
            .accessibilityIdentifier("swap-mode-button")

            if inputMode == .target {
                // Macro target buttons
                ForEach(TargetMacro.allCases) { macro in
                    macroButton(macro)
                }
            } else {
                // Unit buttons
                ForEach(ServingUnit.allCases) { unit in
                    if unit != .item || food.hasItemServing {
                        unitButton(unit)
                    }
                }
            }
        }
    }

    func macroButton(_ macro: TargetMacro) -> some View {
        Button {
            switchToMacro(macro)
        } label: {
            Text(macro.displayName)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    targetMacro == macro
                        ? Color.primary.opacity(0.15)
                        : Color(.tertiarySystemFill)
                )
                .foregroundColor(.primary)
                .cornerRadius(20)
        }
        .accessibilityIdentifier("macro-button-\(macro.rawValue)")
    }

    func unitButton(_ unit: ServingUnit) -> some View {
        Button {
            switchToUnit(unit)
        } label: {
            Text(unit.rawValue)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    selectedUnit == unit
                        ? Color.primary.opacity(0.15)
                        : Color(.tertiarySystemFill)
                )
                .foregroundColor(.primary)
                .cornerRadius(20)
        }
        .accessibilityIdentifier("unit-button-\(unit.rawValue)")
    }
}

// MARK: - Input Helpers

extension FoodDetailSheet {
    func initializeServingInput() {
        // Default to 1 item if available, otherwise 100g
        if food.hasItemServing {
            selectedUnit = .item
            servingCount = 1
        } else {
            selectedUnit = .grams
            servingCount = food.servingSize > 0 ? food.servingSize : 100
        }
    }

    func toggleInputMode() {
        if inputMode == .quantity {
            // Capture current calories BEFORE switching mode
            let currentCalories = scaledCalories
            // Switch to target mode
            inputMode = .target
            targetValue = currentCalories
        } else {
            // Capture grams BEFORE switching mode
            let grams = calculateGramsFromTarget()
            // Switch to quantity mode
            inputMode = .quantity
            servingCount = quantityInSelectedUnit(from: grams)
        }
    }

    func switchToUnit(_ unit: ServingUnit) {
        // Convert current quantity to new unit
        let currentGrams = quantityInGrams
        selectedUnit = unit
        servingCount = quantityInSelectedUnit(from: currentGrams)
    }

    func switchToMacro(_ macro: TargetMacro) {
        // Calculate current grams from current target before switching
        let currentGrams = calculateGramsFromTarget()
        // Switch macro
        targetMacro = macro
        // Calculate new target value for same gram weight
        targetValue = macroValueForGrams(currentGrams, macro: macro)
    }

    func macroValueForGrams(_ grams: Double, macro: TargetMacro) -> Double {
        let per100g: Double
        switch macro {
        case .calories: per100g = food.caloriesPer100g
        case .protein: per100g = food.proteinPer100g
        case .fat: per100g = food.fatPer100g
        case .carbs: per100g = food.carbsPer100g
        }
        return (per100g * grams) / 100.0
    }
}
