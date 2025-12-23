//
//  FoodSearchSheet.swift
//  JabTracker
//
//  Enhanced food search sheet with categorized results.
//

import OSLog
import SwiftUI

/// Logger for FoodSearchSheet
private let logger = Logger(
    subsystem: "com.gannonhall.JabTracker",
    category: "FoodSearchSheet"
)

/// Full-screen food search sheet with method tabs and categorized results
struct FoodSearchSheet: View {
    // MARK: - Properties

    let user: User
    let foodService: FoodService?
    let mealLogService: MealLogService?
    let customFoodService: CustomFoodService?
    let onComplete: () -> Void

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State var viewModel: FoodSearchSheetViewModel
    @State var selectedFood: FoodSearchResult?
    @State var showingFoodDetail = false
    @State private var showingComingSoon = false
    @State private var showingTimePicker = false
    @State var editingCustomFood: Food?
    @State var foodToDelete: Food?
    @State var showingDeleteConfirmation = false
    @State private var showingDeleteError = false

    // MARK: - Static Identifiers

    static let accessibilityIdentifierValue = "food-search-sheet"
    static let searchFieldIdentifier = "food-search-field"
    static let timePickerIdentifier = "time-picker-button"

    // MARK: - Initialization

    init(
        user: User,
        foodService: FoodService?,
        mealLogService: MealLogService?,
        customFoodService: CustomFoodService? = nil,
        onComplete: @escaping () -> Void
    ) {
        self.user = user
        self.foodService = foodService
        self.mealLogService = mealLogService
        self.customFoodService = customFoodService
        self.onComplete = onComplete

        // Initialize ViewModel with services
        if let fs = foodService, let mls = mealLogService {
            self._viewModel = State(
                wrappedValue: FoodSearchSheetViewModel(
                    foodService: fs,
                    mealLogService: mls
                ))
        } else {
            // Fallback for previews - will need proper DI
            fatalError("FoodSearchSheet requires non-nil foodService and mealLogService")
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with time picker and remaining macros
                headerSection

                // Method tabs
                methodTabsSection

                // Search field
                searchFieldSection

                // Content: Recent foods or search results
                contentSection
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("food-search-cancel-button")
                }
            }
        }
        .accessibilityIdentifier(Self.accessibilityIdentifierValue)
        .sheet(isPresented: $showingFoodDetail) {
            if let food = selectedFood {
                FoodDetailSheet(
                    food: food,
                    user: user,
                    selectedMeal: MealSection.from(date: viewModel.selectedTime),
                    selectedTime: viewModel.selectedTime,
                    foodService: foodService,
                    mealLogService: mealLogService,
                    customFoodService: customFoodService
                ) {
                    onComplete()
                    dismiss()
                }
            }
        }
        .alert("Coming Soon", isPresented: $showingComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(viewModel.selectedMethod.displayName) will be available in a future update.")
        }
        .alert("Delete Custom Food?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                foodToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let food = foodToDelete {
                    Task { await deleteCustomFood(food) }
                }
            }
        } message: {
            if let food = foodToDelete {
                Text("This will permanently delete '\(food.name)' from your custom foods.")
            }
        }
        .sheet(item: $editingCustomFood) { food in
            if let customFoodService {
                CreateFoodSheet.edit(
                    food: food,
                    customFoodService: customFoodService,
                    onFoodCreated: { _ in
                        editingCustomFood = nil
                        // Refresh search results to show updated food
                        Task {
                            await viewModel.performSearch()
                        }
                    }
                )
            }
        }
        .alert("Delete Failed", isPresented: $showingDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Unable to delete the custom food. Please try again.")
        }
        .task {
            await viewModel.loadInitialData(user: user, for: Date())
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            // Time picker button
            Button {
                showingTimePicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(viewModel.selectedTime, format: .dateTime.hour().minute())
                        .font(.subheadline.weight(.medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(8)
            }
            .accessibilityIdentifier(Self.timePickerIdentifier)
            .sheet(isPresented: $showingTimePicker) {
                timePickerSheet
            }

            Spacer()

            // Remaining macros display
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(viewModel.remainingCalories)) left")
                        .font(.caption.weight(.medium))
                    Text("Calories")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 24)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(viewModel.remainingProtein))g left")
                        .font(.caption.weight(.medium))
                    Text("Protein")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Time Picker Sheet

    private var timePickerSheet: some View {
        NavigationStack {
            DatePicker(
                "Entry Time",
                selection: $viewModel.selectedTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding()
            .navigationTitle("Select Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingTimePicker = false
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.4)])
    }

    // MARK: - Method Tabs Section

    private var methodTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SearchMethod.allCases) { method in
                    methodTabButton(method)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
    }

    private func methodTabButton(_ method: SearchMethod) -> some View {
        Button {
            if method.isEnabled {
                viewModel.selectedMethod = method
            } else {
                viewModel.selectedMethod = method
                showingComingSoon = true
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: method.icon)
                    .font(.caption)
                Text(method.displayName)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                viewModel.selectedMethod == method
                    ? Color.primary.opacity(0.1)
                    : Color.clear
            )
            .foregroundColor(
                method.isEnabled ? .primary : .secondary
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        viewModel.selectedMethod == method
                            ? Color.primary.opacity(0.3)
                            : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .accessibilityIdentifier("method-tab-\(method.rawValue)")
    }

    // MARK: - Search Field Section

    private var searchFieldSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search for a food", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .accessibilityIdentifier(Self.searchFieldIdentifier)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityIdentifier("clear-search-button")
            }

            if viewModel.isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onChange(of: viewModel.searchText) { _, _ in
            // Trigger search on any input (no minimum)
            Task {
                // Small debounce
                try? await Task.sleep(nanoseconds: 200_000_000)
                await viewModel.performSearch()
            }
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        Group {
            if viewModel.searchText.isEmpty {
                recentFoodsSection
            } else if viewModel.hasResults {
                searchResultsSection
            } else if viewModel.isSearching {
                loadingSection
            } else {
                emptyResultsSection
            }
        }
    }

    // MARK: - Recent Foods Section

    private var recentFoodsSection: some View {
        List {
            if !viewModel.recentFoods.isEmpty {
                Section("Latest") {
                    ForEach(viewModel.recentFoods) { food in
                        recentFoodRow(food)
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Recent Foods",
                    systemImage: "clock",
                    description: Text("Foods you log will appear here for quick access")
                )
            }
        }
        .listStyle(.plain)
    }

    private func recentFoodRow(_ food: Food) -> some View {
        let result = food.toSearchResult()
        return Button {
            selectedFood = result
            showingFoodDetail = true
        } label: {
            FoodSearchResultRow(result: result)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom Food Helpers

    /// Look up the actual Food entity for a custom food search result
    func findCustomFood(for result: FoodSearchResult) -> Food? {
        guard let customFoodService else { return nil }
        return try? customFoodService.getCustomFood(named: result.name)
    }

    /// Delete a custom food after confirmation
    private func deleteCustomFood(_ food: Food) async {
        guard let customFoodService else { return }
        do {
            try await customFoodService.deleteCustomFood(food)
            foodToDelete = nil
            // Refresh search results to remove deleted food
            await viewModel.performSearch()
            logger.info("Deleted custom food: \(food.name)")
        } catch {
            logger.error("Failed to delete custom food '\(food.name)': \(error.localizedDescription)")
            showingDeleteError = true
        }
    }

}

// MARK: - Preview

#Preview("Food Search Sheet") {
    Text("Preview requires full app context")
}
