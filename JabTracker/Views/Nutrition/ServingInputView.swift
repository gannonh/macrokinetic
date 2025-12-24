//
//  ServingInputView.swift
//  JabTracker
//
//  Advanced serving input with target macro calculation and unit conversion.
//

import SwiftUI

/// Input mode for serving selection
enum ServingInputMode: String, CaseIterable, Identifiable {
    case quantity  // Enter quantity directly (e.g., "1 item", "150g")
    case target  // Enter target macro to calculate quantity

    var id: String { rawValue }
}

/// Target macro for reverse calculation
enum TargetMacro: String, CaseIterable, Identifiable {
    case calories = "cal"
    case protein = "P"
    case fat = "F"
    case carbs = "C"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .calories: return "flame.fill"
        case .protein: return "p.circle.fill"
        case .fat: return "f.circle.fill"
        case .carbs: return "c.circle.fill"
        }
    }
}

/// Serving unit for quantity input
enum ServingUnit: String, CaseIterable, Identifiable {
    case grams = "g"
    case ounces = "oz"
    case item = "item"
    case pounds = "lb"

    var id: String { rawValue }

    /// Convert grams to this unit
    func fromGrams(_ grams: Double) -> Double {
        switch self {
        case .grams: return grams
        case .ounces: return grams / 28.3495
        case .item: return 1.0  // Needs item weight context
        case .pounds: return grams / 453.592
        }
    }

    /// Convert this unit to grams
    func toGrams(_ value: Double, itemGrams: Double = 100) -> Double {
        switch self {
        case .grams: return value
        case .ounces: return value * 28.3495
        case .item: return value * itemGrams
        case .pounds: return value * 453.592
        }
    }
}

/// Advanced serving input view with target macro calculation
struct ServingInputView: View {
    // MARK: - Properties

    let food: FoodSearchResult
    @Binding var quantityInGrams: Double
    let onAdd: () -> Void

    // MARK: - State

    @State private var inputMode: ServingInputMode = .quantity
    @State private var selectedUnit: ServingUnit = .item
    @State private var targetMacro: TargetMacro = .calories
    @State private var inputText: String = "1"
    @FocusState private var isInputFocused: Bool

    // MARK: - Constants

    static let accessibilityIdentifierValue = "serving-input-view"

    // MARK: - Computed Properties

    /// Item weight in grams (from food's serving options)
    private var itemGrams: Double {
        food.defaultServing.grams
    }

    /// Whether item unit is available for this food
    private var hasItemUnit: Bool {
        food.hasItemServing
    }

    /// Calculated quantity display based on input mode
    private var calculatedDisplay: String {
        guard let inputValue = Double(inputText), inputValue > 0 else {
            return "0"
        }

        if inputMode == .quantity {
            return formatQuantityDisplay(inputValue)
        } else {
            return formatTargetDisplay(inputValue)
        }
    }

    /// Right side label showing unit or converted value
    private var unitLabel: String {
        if inputMode == .quantity {
            return selectedUnit.rawValue
        } else {
            // Show calculated quantity in selected unit
            guard let inputValue = Double(inputText), inputValue > 0 else {
                return "0 \(selectedUnit.rawValue)"
            }
            let grams = calculateGramsFromTarget(inputValue)
            let unitValue = convertGramsToUnit(grams)
            return String(format: "%.2f \(selectedUnit.rawValue)", unitValue)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Input display row
            inputDisplayRow

            // Mode and unit selector
            modeAndUnitSelector

            // Numeric keypad
            numericKeypad

            // Action buttons
            actionButtons
        }
        .accessibilityIdentifier(Self.accessibilityIdentifierValue)
        .onAppear {
            initializeInput()
        }
        .onChange(of: inputText) { _, _ in
            updateQuantityInGrams()
        }
        .onChange(of: selectedUnit) { _, _ in
            updateQuantityInGrams()
        }
        .onChange(of: targetMacro) { _, _ in
            updateQuantityInGrams()
        }
    }

    // MARK: - Input Display Row

    private var inputDisplayRow: some View {
        HStack {
            // Input text field
            TextField("0", text: $inputText)
                .font(.title.weight(.semibold))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.leading)
                .focused($isInputFocused)
                .frame(maxWidth: 120)
                .accessibilityIdentifier("serving-input-field")

            Spacer()

            // Right side: unit or calculated value
            Text(unitLabel)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .cardStyle(cornerRadius: 12)
    }

    // MARK: - Mode and Unit Selector

    private var modeAndUnitSelector: some View {
        HStack(spacing: 8) {
            // Swap mode button
            Button {
                toggleMode()
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityIdentifier("swap-mode-button")

            // Target macro buttons (only shown in target mode)
            if inputMode == .target {
                ForEach(TargetMacro.allCases) { macro in
                    macroButton(macro)
                }
            } else {
                // Unit buttons (only shown in quantity mode)
                ForEach(ServingUnit.allCases) { unit in
                    if unit != .item || hasItemUnit {
                        unitButton(unit)
                    }
                }
            }
        }
    }

    private func macroButton(_ macro: TargetMacro) -> some View {
        Button {
            targetMacro = macro
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

    private func unitButton(_ unit: ServingUnit) -> some View {
        Button {
            switchUnit(to: unit)
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

    // MARK: - Numeric Keypad

    private var numericKeypad: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                keypadButton("1")
                keypadButton("2")
                keypadButton("3")
                keypadButton("/", action: { appendFraction() })
            }
            HStack(spacing: 8) {
                keypadButton("4")
                keypadButton("5")
                keypadButton("6")
                keypadButton("−", action: {})
            }
            HStack(spacing: 8) {
                keypadButton("7")
                keypadButton("8")
                keypadButton("9")
                keypadButton("⌫", action: { backspace() })
            }
            HStack(spacing: 8) {
                keypadButton(".")
                keypadButton("0")
                keypadButton("Log Foods", wide: true, action: {})
                    .disabled(true)
            }
        }
    }

    private func keypadButton(_ label: String, wide: Bool = false, action: (() -> Void)? = nil) -> some View {
        Button {
            if let action = action {
                action()
            } else {
                appendDigit(label)
            }
        } label: {
            Text(label)
                .font(.title2.weight(.medium))
                .frame(maxWidth: wide ? .infinity : nil)
                .frame(height: 50)
                .frame(minWidth: wide ? 120 : 60)
                .background(Color(.tertiarySystemFill))
                .foregroundColor(.primary)
                .cornerRadius(8)
        }
        .accessibilityIdentifier("keypad-\(label)")
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Spacer()

            Button {
                onAdd()
            } label: {
                Text("Add")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("add-button")
        }
    }

    // MARK: - Helper Methods

    private func initializeInput() {
        // Default to 1 item if available, otherwise 100g
        if hasItemUnit {
            selectedUnit = .item
            inputText = "1"
        } else {
            selectedUnit = .grams
            inputText = "100"
        }
        updateQuantityInGrams()
    }

    private func toggleMode() {
        inputMode = inputMode == .quantity ? .target : .quantity
        // Reset input when switching modes
        if inputMode == .target {
            // Default to current calories
            inputText = String(Int(calculateCaloriesForCurrentQuantity()))
        } else {
            initializeInput()
        }
    }

    private func switchUnit(to unit: ServingUnit) {
        // Convert current quantity to new unit
        let currentGrams = quantityInGrams
        selectedUnit = unit
        let newValue = convertGramsToUnit(currentGrams)
        inputText = formatValue(newValue)
    }

    private func appendDigit(_ digit: String) {
        if inputText == "0" {
            inputText = digit
        } else {
            inputText += digit
        }
    }

    private func appendFraction() {
        // For entering fractions like 1/2, 1/4
        if !inputText.contains("/") {
            inputText += "/"
        }
    }

    private func backspace() {
        if !inputText.isEmpty {
            inputText.removeLast()
        }
        if inputText.isEmpty {
            inputText = "0"
        }
    }

    private func updateQuantityInGrams() {
        guard let inputValue = parseInput(), inputValue > 0 else {
            quantityInGrams = 0
            return
        }

        if inputMode == .quantity {
            quantityInGrams = selectedUnit.toGrams(inputValue, itemGrams: itemGrams)
        } else {
            quantityInGrams = calculateGramsFromTarget(inputValue)
        }
    }

    private func parseInput() -> Double? {
        // Handle fractions like "1/2"
        if inputText.contains("/") {
            let parts = inputText.split(separator: "/")
            if parts.count == 2,
                let numerator = Double(parts[0]),
                let denominator = Double(parts[1]),
                denominator > 0
            {
                return numerator / denominator
            }
            return nil
        }
        return Double(inputText)
    }

    private func convertGramsToUnit(_ grams: Double) -> Double {
        switch selectedUnit {
        case .grams: return grams
        case .ounces: return grams / 28.3495
        case .item: return grams / itemGrams
        case .pounds: return grams / 453.592
        }
    }

    private func calculateGramsFromTarget(_ targetValue: Double) -> Double {
        // Calculate how many grams needed to hit target macro value
        let per100g: Double
        switch targetMacro {
        case .calories: per100g = food.caloriesPer100g
        case .protein: per100g = food.proteinPer100g
        case .fat: per100g = food.fatPer100g
        case .carbs: per100g = food.carbsPer100g
        }

        guard per100g > 0 else { return 0 }
        return (targetValue / per100g) * 100
    }

    private func calculateCaloriesForCurrentQuantity() -> Double {
        (food.caloriesPer100g * quantityInGrams) / 100.0
    }

    private func formatValue(_ value: Double) -> String {
        if value == Double(Int(value)) {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    private func formatQuantityDisplay(_ value: Double) -> String {
        formatValue(value)
    }

    private func formatTargetDisplay(_ value: Double) -> String {
        formatValue(value)
    }
}

// MARK: - Preview

#Preview("Serving Input View") {
    Text("Preview requires full app context")
}
