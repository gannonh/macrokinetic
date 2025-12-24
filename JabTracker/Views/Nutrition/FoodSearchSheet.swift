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
    @State var showingTimePicker = false
    @State var editingCustomFood: Food?
    @State var foodToDelete: Food?
    @State var showingDeleteConfirmation = false
    @State private var showingDeleteError = false
    @State var isLookingUpBarcode = false
    @State var barcodeNotFound = false
    @State var lastScannedBarcode: String?

    // MARK: - Constants

    /// Debounce timing for search input
    private enum SearchTiming {
        static let debounceNanoseconds: UInt64 = 200_000_000
    }

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
        initialMethod: SearchMethod? = nil,
        onComplete: @escaping () -> Void
    ) {
        self.user = user
        self.foodService = foodService
        self.mealLogService = mealLogService
        self.customFoodService = customFoodService
        self.onComplete = onComplete

        // Initialize ViewModel with services
        if let fs = foodService, let mls = mealLogService {
            let vm = FoodSearchSheetViewModel(
                foodService: fs,
                mealLogService: mls
            )
            // Set initial method if provided
            if let method = initialMethod {
                vm.selectedMethod = method
            }
            self._viewModel = State(wrappedValue: vm)
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

                // Show scanner or search UI based on selected method
                if viewModel.selectedMethod == .scan {
                    ZStack {
                        BarcodeScannerContentView { barcode in
                            Task {
                                await handleBarcodeDetected(barcode)
                            }
                        }

                        // Loading overlay
                        if isLookingUpBarcode {
                            VStack {
                                ProgressView("Looking up product...")
                                    .padding()
                                    .background(.regularMaterial)
                                    .cornerRadius(12)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.3))
                        }
                    }
                } else {
                    // Search field
                    searchFieldSection

                    // Content: Recent foods or search results
                    contentSection
                }
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
        .alert("Product Not Found", isPresented: $barcodeNotFound) {
            Button("Scan Again") {
                barcodeNotFound = false
            }
            Button("Search Instead") {
                viewModel.selectedMethod = .search
                viewModel.searchText = lastScannedBarcode ?? ""
                barcodeNotFound = false
            }
        } message: {
            Text("No product found for barcode \(lastScannedBarcode ?? ""). Try scanning again or search manually.")
        }
        .task {
            await viewModel.loadInitialData(user: user, for: Date())
        }
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
                try? await Task.sleep(nanoseconds: SearchTiming.debounceNanoseconds)
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
        guard let customFoodService else {
            logger.warning("CustomFoodService unavailable for findCustomFood")
            return nil
        }
        do {
            return try customFoodService.getCustomFood(named: result.name)
        } catch {
            logger.error("Failed to find custom food '\(result.name)': \(error.localizedDescription)")
            return nil
        }
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
