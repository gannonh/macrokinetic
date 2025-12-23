//
//  FoodDetailSheet.swift
//  JabTracker
//
//  Detailed nutrition view with macro impact and logging capability.
//

import SwiftUI

/// Detailed view of a food item with nutrition facts and logging controls
struct FoodDetailSheet: View {
    // MARK: - Properties

    let food: FoodSearchResult
    let user: User
    let selectedMeal: MealSection
    let selectedTime: Date
    let foodService: FoodService?
    let mealLogService: MealLogService?
    let customFoodService: CustomFoodService?
    let onComplete: () -> Void

    // MARK: - State

    @State var servingCount: Double = 1.0
    @State private var selectedServing: ServingOption?
    @State var meal: MealSection
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State var inputMode: ServingInputMode = .quantity
    @State var targetMacro: TargetMacro = .calories
    @State var targetValue: Double = 0
    @State var selectedUnit: ServingUnit = .item
    @State private var notes: String = ""
    @State private var showingCreateCustom = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Constants

    static let accessibilityIdentifierValue = "food-detail-sheet"
    static let quantityInputIdentifier = "quantity-input"
    static let addButtonIdentifier = "add-food-button"
    static let servingPickerIdentifier = "serving-picker"
    static let toCustomButtonIdentifier = "to-custom-button"
    static let defaultQuantity: Double = 100.0
    static let minimumQuantity: Double = 1.0
    static let maximumQuantity: Double = 2000.0

    // MARK: - Serving Options

    /// Available serving options for this food
    private var servingOptions: [ServingOption] {
        if food.servingOptions.isEmpty {
            return [ServingOption(label: "100g", grams: 100)]
        }
        return food.servingOptions
    }

    /// Default serving option (prefer item/serving over grams)
    private var defaultServing: ServingOption {
        // Prefer "item" or similar serving over raw grams
        if let itemServing = servingOptions.first(where: { !$0.label.hasSuffix("g") }) {
            return itemServing
        }
        // Otherwise use food's serving size if meaningful
        if food.servingSize > 0 && food.servingSize != 100 {
            return ServingOption(label: "\(Int(food.servingSize))g", grams: food.servingSize)
        }
        return servingOptions.first ?? ServingOption(label: "100g", grams: 100)
    }

    /// Current quantity in grams (for macro calculations)
    var quantityInGrams: Double {
        if inputMode == .target {
            return calculateGramsFromTarget()
        }
        return selectedUnit.toGrams(servingCount, itemGrams: defaultServing.grams)
    }

    /// Item weight in grams
    private var itemGrams: Double {
        defaultServing.grams
    }

    /// Calculate grams needed for target macro value
    func calculateGramsFromTarget() -> Double {
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

    /// Calculate quantity in selected unit from grams
    func quantityInSelectedUnit(from grams: Double) -> Double {
        switch selectedUnit {
        case .grams: return grams
        case .ounces: return grams / 28.3495
        case .item: return grams / itemGrams
        case .pounds: return grams / 453.592
        }
    }

    /// Display string for calculated quantity when in target mode
    var calculatedQuantityDisplay: String {
        let grams = calculateGramsFromTarget()
        let unitValue = quantityInSelectedUnit(from: grams)
        return String(format: "%.2f", unitValue)
    }

    // MARK: - Computed Properties

    /// Scaled calories based on quantity in grams
    var scaledCalories: Double {
        (food.caloriesPer100g * quantityInGrams) / 100.0
    }

    /// Scaled carbs based on quantity in grams
    var scaledCarbs: Double {
        (food.carbsPer100g * quantityInGrams) / 100.0
    }

    /// Scaled fiber based on quantity in grams
    var scaledFiber: Double {
        (food.fiberPer100g * quantityInGrams) / 100.0
    }

    /// Net carbs (carbs - fiber)
    var scaledNetCarbs: Double {
        max(0, scaledCarbs - scaledFiber)
    }

    // MARK: - Initialization

    init(
        food: FoodSearchResult,
        user: User,
        selectedMeal: MealSection,
        selectedTime: Date,
        foodService: FoodService?,
        mealLogService: MealLogService?,
        customFoodService: CustomFoodService?,
        onComplete: @escaping () -> Void
    ) {
        self.food = food
        self.user = user
        self.selectedMeal = selectedMeal
        self.selectedTime = selectedTime
        self.foodService = foodService
        self.mealLogService = mealLogService
        self.customFoodService = customFoodService
        self.onComplete = onComplete
        self._meal = State(wrappedValue: selectedMeal)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Food header
                    foodHeader

                    // Large macro display
                    macroDisplay

                    // Action buttons (non-functional placeholders)
                    actionButtons

                    // Impact on targets
                    impactSection

                    // Carb breakdown
                    carbBreakdownSection
                }
                .padding()
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                footerSection
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier(Self.accessibilityIdentifierValue)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .sheet(isPresented: $showingCreateCustom) {
            if let customFoodService {
                CreateFoodSheet(
                    customFoodService: customFoodService,
                    mealLogService: mealLogService,
                    selectedMeal: meal,
                    selectedTime: selectedTime,
                    prefillFrom: food,
                    onFoodCreated: { _ in
                        // Food was created (and possibly logged)
                        // Dismiss the detail sheet
                        dismiss()
                        onComplete()
                    }
                )
            } else {
                // Service unavailable - show error and dismiss
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Custom Foods Unavailable")
                        .font(.headline)
                    Text("Please try again later.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Dismiss") {
                        showingCreateCustom = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }

    // MARK: - Food Header

    private var foodHeader: some View {
        VStack(spacing: 4) {
            Text(food.name)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            if let brand = food.brand, !brand.isEmpty {
                Text(brand)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Macro Display

    private var macroDisplay: some View {
        VStack(spacing: 16) {
            // Large calorie number
            VStack(spacing: 4) {
                Text("\(Int(scaledCalories))")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                Text("Calories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Macro row with percentages
            HStack(spacing: 24) {
                macroItem(value: scaledProtein, label: "Protein", percentage: Int(proteinImpact * 100), color: .blue)
                macroItem(value: scaledFat, label: "Fat", percentage: Int(fatImpact * 100), color: .purple)
                macroItem(value: scaledCarbs, label: "Carbs", percentage: Int(carbImpact * 100), color: .green)
            }
        }
        .padding()
        .cardStyle()
    }

    private func macroItem(value: Double, label: String, percentage: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(Int(value))")
                .font(.title2.weight(.semibold))

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(percentage)%")
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(4)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                showingCreateCustom = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title3)
                    Text("To Custom")
                        .font(.caption)
                }
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier(Self.toCustomButtonIdentifier)

            Button {
                // Placeholder - future feature
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.title3)
                    Text("Favorite")
                        .font(.caption)
                }
            }
            .buttonStyle(.bordered)
            .disabled(true)
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 12) {
            // Input display row
            inputDisplayRow

            // Mode toggle and unit/macro selector
            modeAndUnitSelector

            // Notes field
            TextField("Add a note...", text: $notes)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("notes-input")

            // Meal picker and Add button
            HStack(spacing: 12) {
                Picker("Meal", selection: $meal) {
                    ForEach(MealSection.allCases) { section in
                        Text(section.displayName).tag(section)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(8)

                Button {
                    Task {
                        await saveFood()
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Add")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving || quantityInGrams <= 0)
                .accessibilityIdentifier(Self.addButtonIdentifier)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .onAppear {
            initializeServingInput()
        }
    }

    // MARK: - Save Action

    private func saveFood() async {
        guard let mealLogService = mealLogService, let foodService = foodService else {
            errorMessage = "Services not available"
            showingError = true
            return
        }

        isSaving = true

        do {
            // Create Food model from search result
            let foodModel = foodService.createFood(from: food)

            // Log the entry with calculated gram quantity
            _ = try await mealLogService.logFood(
                food: foodModel,
                servingGrams: quantityInGrams,
                mealSection: meal,
                notes: notes,
                loggedAt: selectedTime
            )

            // Save to recent foods
            foodService.saveRecentFood(foodModel)

            // Success - dismiss and notify
            dismiss()
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isSaving = false
    }
}

// MARK: - Preview

#Preview("Food Detail Sheet") {
    Text("Preview requires full app context")
}
