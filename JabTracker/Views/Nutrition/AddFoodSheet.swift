//
//  AddFoodSheet.swift
//  JabTracker
//
//  Sheet for adding a food entry with serving size and meal selection.
//

import SwiftUI

/// Sheet for logging a food entry
struct AddFoodSheet: View {
    let user: User
    let foodService: FoodService?
    let mealLogService: MealLogService?
    let onComplete: () -> Void

    @State private var showingFoodSearch = false
    @State private var selectedFood: FoodSearchResult?
    @State private var servingGrams: Double = 100
    @State private var selectedMeal: MealSection = MealSection.from(date: Date())
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Food selection section
                Section("Food") {
                    if let food = selectedFood {
                        selectedFoodRow(food)
                    } else {
                        Button {
                            showingFoodSearch = true
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Search for food")
                            }
                        }
                        .accessibilityIdentifier("search-food-button")
                    }
                }

                // Serving size section (only show when food is selected)
                if selectedFood != nil {
                    Section("Serving Size") {
                        HStack {
                            Text("Amount")
                            Spacer()
                            TextField("Grams", value: $servingGrams, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .accessibilityIdentifier("serving-grams-field")
                            Text("g")
                                .foregroundColor(.secondary)
                        }

                        // Quick serving options
                        HStack(spacing: 12) {
                            ForEach([50, 100, 150, 200], id: \.self) { grams in
                                Button("\(grams)g") {
                                    servingGrams = Double(grams)
                                }
                                .buttonStyle(.bordered)
                                .tint(servingGrams == Double(grams) ? .blue : .gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Meal section
                    Section("Meal") {
                        Picker("Meal", selection: $selectedMeal) {
                            ForEach(MealSection.allCases) { section in
                                Label(section.displayName, systemImage: section.icon)
                                    .tag(section)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("meal-section-picker")
                    }

                    // Nutrition preview
                    Section("Nutrition") {
                        nutritionPreview
                    }

                    // Notes
                    Section("Notes (Optional)") {
                        TextField("Add notes...", text: $notes, axis: .vertical)
                            .lineLimit(3)
                            .accessibilityIdentifier("notes-field")
                    }
                }

                // Error message
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Log Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveEntry()
                        }
                    }
                    .disabled(selectedFood == nil || isSaving)
                    .accessibilityIdentifier("save-food-button")
                }
            }
            .sheet(isPresented: $showingFoodSearch) {
                FoodSearchView(foodService: foodService) { result in
                    selectedFood = result
                }
            }
        }
        .accessibilityIdentifier("add-food-sheet")
    }

    private func selectedFoodRow(_ food: FoodSearchResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(DesignTokens.Typography.body)
                if let brand = food.brand {
                    Text(brand)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                selectedFood = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .accessibilityIdentifier("selected-food-row")
    }

    @ViewBuilder
    private var nutritionPreview: some View {
        if let food = selectedFood {
            let multiplier = servingGrams / 100.0

            HStack {
                nutritionStat(label: "Calories", value: food.caloriesPer100g * multiplier, unit: "kcal")
                Divider()
                nutritionStat(label: "Protein", value: food.proteinPer100g * multiplier, unit: "g")
                Divider()
                nutritionStat(label: "Carbs", value: food.carbsPer100g * multiplier, unit: "g")
                Divider()
                nutritionStat(label: "Fat", value: food.fatPer100g * multiplier, unit: "g")
            }
            .frame(height: 50)
        }
    }

    private func nutritionStat(label: String, value: Double, unit: String) -> some View {
        VStack(spacing: 2) {
            Text("\(Int(value))")
                .font(DesignTokens.Typography.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func saveEntry() async {
        guard let food = selectedFood,
            let foodService = foodService,
            let mealLogService = mealLogService
        else {
            errorMessage = "Services not available"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            // Convert search result to Food model
            let foodModel = foodService.createFood(from: food)

            // Log the entry
            _ = try await mealLogService.logFood(
                food: foodModel,
                servingGrams: servingGrams,
                mealSection: selectedMeal,
                notes: notes
            )

            // Save food to recent
            foodService.saveRecentFood(foodModel)

            onComplete()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}
