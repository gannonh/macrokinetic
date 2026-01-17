//
//  EditFoodEntrySheet.swift
//  JabTracker
//
//  Sheet for editing a logged food entry with full serving options.
//

import SwiftUI

/// Sheet for editing a logged food entry
struct EditFoodEntrySheet: View {
    // MARK: - Properties

    let entry: FoodEntry
    let mealLogService: MealLogService?
    let onDismiss: () -> Void

    // MARK: - State

    @State private var servingGrams: Double
    @State private var servingCount: Double = 1.0
    @State private var selectedUnit: ServingUnit = .grams
    @State private var selectedPillOption: ServingPillOption?
    @State private var inputMode: ServingInputMode = .quantity
    @State private var targetMacro: TargetMacro = .calories
    @State private var targetValue: Double = 0
    @State private var selectedMeal: MealSection
    @State private var loggedAt: Date
    @State private var notes: String
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(entry: FoodEntry, mealLogService: MealLogService?, onDismiss: @escaping () -> Void) {
        self.entry = entry
        self.mealLogService = mealLogService
        self.onDismiss = onDismiss
        self._servingGrams = State(wrappedValue: entry.servingGrams)
        self._selectedMeal = State(wrappedValue: entry.meal)
        self._loggedAt = State(wrappedValue: entry.loggedAt)
        self._notes = State(wrappedValue: entry.notes ?? "")
    }

    // MARK: - Computed Properties

    /// Serving options parsed from the entry's persisted JSON
    private var servingOptions: [ServingOption] {
        ServingOption.parse(from: entry.servingOptionsJSON)
    }

    /// Whether this entry has persisted serving options beyond default 100g
    private var hasPersistedServingOptions: Bool {
        let options = servingOptions
        // Has options if more than 1, or if the single option isn't just "100g"
        return options.count > 1 || (options.count == 1 && options.first?.label != "100g")
    }

    /// Item weight from serving description (if available)
    private var itemGrams: Double {
        // Try to parse from serving description like "1 item (291g)"
        if let description = entry.servingDescription {
            // Look for pattern like "(XXXg)"
            if let match = description.range(of: #"\((\d+(?:\.\d+)?)\s*g\)"#, options: .regularExpression) {
                let gramsPart = String(description[match]).dropFirst().dropLast()  // Remove ( and )
                let gramsString = gramsPart.filter { $0.isNumber || $0 == "." }
                if let grams = Double(gramsString) {
                    return grams
                }
            }
        }
        return entry.servingGrams  // Fall back to original serving
    }

    /// Whether this food has an item-based serving
    private var hasItemServing: Bool {
        guard let description = entry.servingDescription else { return false }
        return !description.isEmpty
    }

    /// Current quantity in grams for macro calculations
    private var quantityInGrams: Double {
        if inputMode == .target {
            return calculateGramsFromTarget()
        }
        if let pillOption = selectedPillOption {
            return servingCount * pillOption.grams
        }
        return selectedUnit.toGrams(servingCount, itemGrams: itemGrams)
    }

    private var scaledCalories: Double {
        (entry.caloriesPer100g / 100.0) * quantityInGrams
    }

    private var scaledProtein: Double {
        (entry.proteinPer100g / 100.0) * quantityInGrams
    }

    private var scaledCarbs: Double {
        (entry.carbsPer100g / 100.0) * quantityInGrams
    }

    private var scaledFat: Double {
        (entry.fatPer100g / 100.0) * quantityInGrams
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Food info section
                Section {
                    HStack(spacing: 12) {
                        Text(FoodEmoji.emoji(for: entry.foodName, brand: entry.foodBrand))
                            .font(.system(size: 40))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.foodName)
                                .font(.headline)
                            if let brand = entry.foodBrand, !brand.isEmpty {
                                Text(brand)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Macro preview section
                Section("Nutrition") {
                    HStack {
                        macroColumn(value: scaledCalories, label: "Cal", color: DesignTokens.Colors.calories)
                        macroColumn(value: scaledProtein, label: "Protein", color: DesignTokens.Colors.protein)
                        macroColumn(value: scaledCarbs, label: "Carbs", color: DesignTokens.Colors.carbs)
                        macroColumn(value: scaledFat, label: "Fat", color: DesignTokens.Colors.fat)
                    }
                }

                // Serving input section
                Section("Serving Size") {
                    // Input display row
                    inputDisplayRow

                    // Mode toggle and unit/macro selector
                    modeAndUnitSelector
                }

                // Date and meal section
                Section("When") {
                    DatePicker("Date & Time", selection: $loggedAt)
                        .accessibilityIdentifier("date-picker")

                    Picker("Meal", selection: $selectedMeal) {
                        ForEach(MealSection.allCases) { section in
                            Label(section.displayName, systemImage: section.icon)
                                .tag(section)
                        }
                    }
                    .accessibilityIdentifier("meal-section-picker")
                }

                // Notes section
                Section("Notes") {
                    TextField("Add a note...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityIdentifier("notes-input")
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .disabled(isSaving || quantityInGrams <= 0)
                    .accessibilityIdentifier("save-entry-button")
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .onAppear {
                initializeServingInput()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("edit-food-entry-sheet")
    }

    // MARK: - Input Display Row

    @ViewBuilder
    private var inputDisplayRow: some View {
        HStack {
            if inputMode == .quantity {
                TextField("0", value: $servingCount, format: .number.precision(.fractionLength(0...2)))
                    .font(.title.weight(.semibold))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 100)
                    .accessibilityIdentifier("quantity-input")

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(currentUnitLabel)
                        .font(.subheadline.weight(.medium))
                    if !isCurrentUnitGrams {
                        Text("\(Int(quantityInGrams))g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                TextField("0", value: $targetValue, format: .number.precision(.fractionLength(0...1)))
                    .font(.title.weight(.semibold))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 100)
                    .accessibilityIdentifier("target-input")

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(calculatedQuantityDisplay) \(currentUnitLabel)")
                        .font(.subheadline.weight(.medium))
                    Text("\(Int(quantityInGrams))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    /// Current unit label - from pill option or selected unit
    private var currentUnitLabel: String {
        if hasPersistedServingOptions, let pillOption = selectedPillOption {
            return pillOption.label
        }
        return selectedUnit.rawValue
    }

    /// Whether current unit is grams (to hide redundant gram display)
    private var isCurrentUnitGrams: Bool {
        if hasPersistedServingOptions, let pillOption = selectedPillOption {
            return pillOption.label == "g"
        }
        return selectedUnit == .grams
    }

    // MARK: - Mode and Unit Selector

    @ViewBuilder
    private var modeAndUnitSelector: some View {
        if hasPersistedServingOptions {
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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TargetMacro.allCases) { macro in
                                macroButton(macro)
                            }
                        }
                    }
                } else {
                    ServingPillPicker(
                        servingOptions: servingOptions,
                        selectedOption: $selectedPillOption
                    )
                    .onChange(of: selectedPillOption) { oldValue, newValue in
                        convertServingCount(from: oldValue, to: newValue)
                    }
                }
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
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
                        ForEach(TargetMacro.allCases) { macro in
                            macroButton(macro)
                        }
                    } else {
                        ForEach(ServingUnit.allCases) { unit in
                            if unit != .item || hasItemServing {
                                unitButton(unit)
                            }
                        }
                    }
                }
            }
        }
    }

    private func macroButton(_ macro: TargetMacro) -> some View {
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

    private func unitButton(_ unit: ServingUnit) -> some View {
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

    // MARK: - Subviews

    private func macroColumn(value: Double, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(Int(value))")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Input Helpers

    private func initializeServingInput() {
        servingGrams = entry.servingGrams

        // Match serving to best pill option:
        // 1. Option that divides evenly into current grams (exact match)
        // 2. First item-based option (approximate)
        // 3. Grams fallback
        if hasPersistedServingOptions {
            let options = servingOptions
            let pillOptions = options.map { ServingPillOption(from: $0) }

            if let bestMatch = pillOptions.first(where: { option in
                !option.isUnitOnly && option.grams > 0
                    && entry.servingGrams.truncatingRemainder(dividingBy: option.grams) < 0.1
            }) {
                selectedPillOption = bestMatch
                servingCount = entry.servingGrams / bestMatch.grams
            } else if let firstItem = pillOptions.first(where: { !$0.isUnitOnly && $0.grams > 0 }) {
                selectedPillOption = firstItem
                servingCount = entry.servingGrams / firstItem.grams
            } else {
                selectedPillOption = .grams
                servingCount = entry.servingGrams
            }
        } else if hasItemServing && itemGrams > 0 {
            selectedUnit = .item
            servingCount = entry.servingGrams / itemGrams
        } else {
            selectedUnit = .grams
            servingCount = entry.servingGrams
        }
    }

    private func toggleInputMode() {
        if inputMode == .quantity {
            let currentCalories = scaledCalories
            inputMode = .target
            targetValue = currentCalories
        } else {
            let grams = calculateGramsFromTarget()
            inputMode = .quantity
            if hasPersistedServingOptions, let option = selectedPillOption, option.grams > 0 {
                servingCount = grams / option.grams
            } else {
                servingCount = quantityInSelectedUnit(from: grams)
            }
        }
    }

    private func switchToUnit(_ unit: ServingUnit) {
        let currentGrams = quantityInGrams
        selectedUnit = unit
        servingCount = quantityInSelectedUnit(from: currentGrams)
    }

    private func switchToMacro(_ macro: TargetMacro) {
        let currentGrams = calculateGramsFromTarget()
        targetMacro = macro
        targetValue = macroValueForGrams(currentGrams, macro: macro)
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
            // Guard against invalid oldOption.grams to avoid division issues
            guard oldOption.grams > 0 else { return }
            let currentGrams = servingCount * oldOption.grams
            servingCount = currentGrams / newOption.grams
        } else {
            // Switching TO item-based option: reset to 1
            // User selecting "small apple" wants 1 small apple, not a fractional amount
            servingCount = 1
        }
    }

    private func calculateGramsFromTarget() -> Double {
        let per100g: Double
        switch targetMacro {
        case .calories: per100g = entry.caloriesPer100g
        case .protein: per100g = entry.proteinPer100g
        case .fat: per100g = entry.fatPer100g
        case .carbs: per100g = entry.carbsPer100g
        }
        guard per100g > 0 else { return 0 }
        return (targetValue / per100g) * 100
    }

    private func quantityInSelectedUnit(from grams: Double) -> Double {
        switch selectedUnit {
        case .grams: return grams
        case .ounces: return grams / 28.3495
        case .item: return grams / itemGrams
        case .pounds: return grams / 453.592
        }
    }

    private func macroValueForGrams(_ grams: Double, macro: TargetMacro) -> Double {
        let per100g: Double
        switch macro {
        case .calories: per100g = entry.caloriesPer100g
        case .protein: per100g = entry.proteinPer100g
        case .fat: per100g = entry.fatPer100g
        case .carbs: per100g = entry.carbsPer100g
        }
        return (per100g * grams) / 100.0
    }

    private var calculatedQuantityDisplay: String {
        let grams = calculateGramsFromTarget()
        if hasPersistedServingOptions, let option = selectedPillOption, option.grams > 0 {
            let unitValue = grams / option.grams
            return String(format: "%.2f", unitValue)
        }
        let unitValue = quantityInSelectedUnit(from: grams)
        return String(format: "%.2f", unitValue)
    }

    // MARK: - Actions

    private func saveChanges() async {
        guard let mealLogService = mealLogService else {
            errorMessage = "Service not available"
            showingError = true
            return
        }

        isSaving = true

        // Update the entry directly
        entry.servingGrams = quantityInGrams
        entry.meal = selectedMeal
        entry.loggedAt = loggedAt
        entry.notes = notes.isEmpty ? nil : notes

        do {
            try await mealLogService.updateEntry(
                entry,
                servingGrams: quantityInGrams,
                mealSection: selectedMeal,
                loggedAt: loggedAt,
                notes: notes.isEmpty ? nil : notes
            )
            dismiss()
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isSaving = false
    }
}

#Preview {
    EditFoodEntrySheet(
        entry: FoodEntry(
            foodName: "Chicken Breast",
            foodBrand: "Generic",
            mealSection: .lunch,
            servingGrams: 150,
            servingDescription: "1 item (150g)",
            caloriesPer100g: 165,
            proteinPer100g: 31,
            carbsPer100g: 0,
            fatPer100g: 3.6
        ),
        mealLogService: nil
    ) {}
}
