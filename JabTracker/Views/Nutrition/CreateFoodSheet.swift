//
//  CreateFoodSheet.swift
//  JabTracker
//
//  Form for creating and editing custom foods.
//

import SwiftUI

/// Form sheet for creating or editing custom foods
struct CreateFoodSheet: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var viewModel: CreateFoodViewModel

    // MARK: - Callbacks

    let onFoodCreated: ((Food) -> Void)?

    // MARK: - Accessibility Identifiers

    static let sheetIdentifier = "create-food-sheet"
    static let foodNameInputIdentifier = "food-name-input"
    static let brandInputIdentifier = "brand-input"
    static let caloriesInputIdentifier = "calories-input"
    static let proteinInputIdentifier = "protein-input"
    static let carbsInputIdentifier = "carbs-input"
    static let fatInputIdentifier = "fat-input"
    static let fiberInputIdentifier = "fiber-input"
    static let servingSizeInputIdentifier = "serving-size-input"
    static let servingUnitPickerIdentifier = "serving-unit-picker"
    static let servingDescriptionInputIdentifier = "serving-description-input"
    static let barcodeInputIdentifier = "barcode-input"
    static let cancelButtonIdentifier = "create-food-cancel"
    static let saveButtonIdentifier = "create-food-save"

    // MARK: - Initialization

    /// Initialize for creating a new custom food
    /// - Parameters:
    ///   - customFoodService: Service for creating custom foods
    ///   - prefillFrom: Optional FoodSearchResult to prefill form fields
    ///   - onFoodCreated: Callback when food is successfully created
    init(
        customFoodService: CustomFoodService,
        prefillFrom: FoodSearchResult? = nil,
        onFoodCreated: ((Food) -> Void)? = nil
    ) {
        let vm = CreateFoodViewModel(customFoodService: customFoodService, mode: .create)
        if let prefill = prefillFrom {
            vm.prefill(from: prefill)
        }
        self._viewModel = State(wrappedValue: vm)
        self.onFoodCreated = onFoodCreated
    }

    /// Private initializer for edit mode
    private init(
        viewModel: CreateFoodViewModel,
        onFoodCreated: ((Food) -> Void)?
    ) {
        self._viewModel = State(wrappedValue: viewModel)
        self.onFoodCreated = onFoodCreated
    }

    /// Create sheet for editing an existing custom food
    /// - Parameters:
    ///   - food: The food to edit (must be a custom food)
    ///   - customFoodService: Service for updating custom foods
    ///   - onFoodCreated: Callback when food is successfully updated
    /// - Returns: CreateFoodSheet configured for editing
    static func edit(
        food: Food,
        customFoodService: CustomFoodService,
        onFoodCreated: ((Food) -> Void)? = nil
    ) -> CreateFoodSheet {
        let vm = CreateFoodViewModel(
            customFoodService: customFoodService,
            mode: .edit,
            editingFood: food
        )
        return CreateFoodSheet(
            viewModel: vm,
            onFoodCreated: onFoodCreated
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                nutritionSection
                servingSection
                barcodeSection
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier(Self.cancelButtonIdentifier)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.mode == .create ? "Save" : "Update") {
                        Task {
                            await saveFood()
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isSaving)
                    .accessibilityIdentifier(Self.saveButtonIdentifier)
                }
            }
            .overlay {
                if viewModel.isSaving {
                    savingOverlay
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier(Self.sheetIdentifier)
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        Section {
            TextField("Food Name", text: $viewModel.name)
                .textContentType(.none)
                .autocorrectionDisabled()
                .accessibilityIdentifier(Self.foodNameInputIdentifier)

            TextField("Brand (optional)", text: $viewModel.brand)
                .textContentType(.organizationName)
                .autocorrectionDisabled()
                .accessibilityIdentifier(Self.brandInputIdentifier)
        } header: {
            Text("Basic Information")
        } footer: {
            if viewModel.mode == .create && viewModel.name.isEmpty {
                Text("Give your custom food a unique name")
            }
        }
    }

    // MARK: - Nutrition Section

    private var nutritionSection: some View {
        Section {
            nutritionRow(
                label: "Calories",
                value: $viewModel.caloriesPer100g,
                unit: "kcal",
                identifier: Self.caloriesInputIdentifier
            )

            nutritionRow(
                label: "Protein",
                value: $viewModel.proteinPer100g,
                unit: "g",
                identifier: Self.proteinInputIdentifier
            )

            nutritionRow(
                label: "Carbohydrates",
                value: $viewModel.carbsPer100g,
                unit: "g",
                identifier: Self.carbsInputIdentifier
            )

            nutritionRow(
                label: "Fat",
                value: $viewModel.fatPer100g,
                unit: "g",
                identifier: Self.fatInputIdentifier
            )

            nutritionRow(
                label: "Fiber",
                value: $viewModel.fiberPer100g,
                unit: "g",
                identifier: Self.fiberInputIdentifier
            )
        } header: {
            Text("Nutrition (per 100g)")
        } footer: {
            Text("Enter nutrition values per 100 grams of this food")
        }
    }

    private func nutritionRow(
        label: String,
        value: Binding<Double>,
        unit: String,
        identifier: String
    ) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)

            Spacer()

            TextField("0", value: value, format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .accessibilityIdentifier(identifier)

            Text(unit)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
        }
    }

    // MARK: - Serving Section

    private var servingSection: some View {
        Section {
            HStack {
                Text("Default Serving Size")
                    .foregroundColor(.primary)

                Spacer()

                TextField("100", value: $viewModel.servingSize, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .accessibilityIdentifier(Self.servingSizeInputIdentifier)

                Picker("", selection: $viewModel.servingUnit) {
                    Text("g").tag("g")
                    Text("oz").tag("oz")
                    Text("ml").tag("ml")
                    Text("item").tag("item")
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 60)
                .accessibilityIdentifier(Self.servingUnitPickerIdentifier)
            }

            TextField("Serving Description (e.g., '1 cup')", text: $viewModel.servingDescription)
                .textContentType(.none)
                .autocorrectionDisabled()
                .accessibilityIdentifier(Self.servingDescriptionInputIdentifier)
        } header: {
            Text("Serving")
        } footer: {
            Text("The default serving size shown when logging this food")
        }
    }

    // MARK: - Barcode Section

    private var barcodeSection: some View {
        Section {
            TextField("Barcode (optional)", text: $viewModel.barcode)
                .keyboardType(.numberPad)
                .textContentType(.none)
                .autocorrectionDisabled()
                .accessibilityIdentifier(Self.barcodeInputIdentifier)
        } header: {
            Text("Barcode")
        } footer: {
            Text("Manually enter a barcode for quick lookup")
        }
    }

    // MARK: - Saving Overlay

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Saving...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(16)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Saving custom food")
        }
    }

    // MARK: - Actions

    private func saveFood() async {
        do {
            let food = try await viewModel.save()
            onFoodCreated?(food)
            dismiss()
        } catch {
            // Error is handled by viewModel's showingError
        }
    }
}

// MARK: - Preview

#Preview("Create Food Sheet") {
    Text("Tap to present")
        .sheet(isPresented: .constant(true)) {
            Text("Preview requires full app context")
        }
}
