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
        .cardStyle()
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
        .cardStyle()
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
                    .focused($isInputFocused)
                    .accessibilityIdentifier(Self.quantityInputIdentifier)

                Spacer()

                // Show pill option label and gram equivalent
                VStack(alignment: .trailing, spacing: 2) {
                    Text(servingDisplayLabel)
                        .font(.subheadline.weight(.medium))
                    if !isGramUnit {
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
                    .focused($isInputFocused)
                    .accessibilityIdentifier("target-input")

                Spacer()

                // Show calculated quantity
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(calculatedQuantityDisplay) \(targetModeUnitLabel)")
                        .font(.subheadline.weight(.medium))
                    Text("\(Int(quantityInGrams))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .cardStyle(cornerRadius: 12)
        .contentShape(Rectangle())
        .onTapGesture {
            isInputFocused = true
        }
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
                // Serving pill picker for quantity mode
                ServingPillPicker(
                    servingOptions: food.servingOptions,
                    defaultServingGrams: food.servingSize,
                    selectedOption: $selectedPillOption
                )
                .onChange(of: selectedPillOption) { oldValue, newValue in
                    convertServingCount(from: oldValue, to: newValue)
                }
            }
        }
    }

    /// Handle serving count when switching between pill options
    /// - Converting TO unit-only (g/oz): preserve gram amount
    /// - Selecting item-based option: reset to 1 (user wants "1 small apple", not "1.64 small apples")
    private func convertServingCount(from oldOption: ServingPillOption?, to newOption: ServingPillOption?) {
        guard let oldOption = oldOption, let newOption = newOption else { return }
        guard oldOption.id != newOption.id else { return }
        guard newOption.grams > 0 else { return }

        if newOption.isUnitOnly {
            // Switching TO g/oz: convert to preserve gram amount
            let currentGrams = servingCount * oldOption.grams
            servingCount = currentGrams / newOption.grams
        } else {
            // Switching TO item-based option: reset to 1
            // User selecting "small apple" wants 1 small apple, not a fractional amount
            servingCount = 1
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
    /// Display label for current serving (e.g., "large egg • 50g" or just "g")
    var servingDisplayLabel: String {
        guard let option = selectedPillOption else {
            return selectedUnit.rawValue
        }
        if option.isUnitOnly {
            return option.label
        }
        // For item-based, show label with grams (e.g., "large egg • 50g")
        return "\(option.label) • \(Int(option.grams))g"
    }

    /// Whether current selection is the gram unit
    var isGramUnit: Bool {
        guard let option = selectedPillOption else {
            return selectedUnit == .grams
        }
        return option.label == "g"
    }

    /// Unit label for target mode display
    var targetModeUnitLabel: String {
        guard let option = selectedPillOption else {
            return selectedUnit.rawValue
        }
        return option.label
    }

    func initializeServingInput() {
        // ServingPillPicker handles its own initialization via onAppear
        // Just set a reasonable starting count
        servingCount = 1
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
            servingCount = quantityFromGrams(grams)
        }
    }

    /// Convert grams to the current serving unit's quantity
    private func quantityFromGrams(_ grams: Double) -> Double {
        guard let option = selectedPillOption else {
            return quantityInSelectedUnit(from: grams)
        }
        guard option.grams > 0 else { return grams }
        return grams / option.grams
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
