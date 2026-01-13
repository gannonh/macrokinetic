//
//  FoodSearchSheet+Sections.swift
//  JabTracker
//
//  Section views for FoodSearchSheet.
//

import OSLog
import SwiftUI

/// Logger for FoodSearchSheet sections
private let logger = Logger(
    subsystem: "com.gannonhall.JabTracker",
    category: "FoodSearchSheet+Sections"
)

// MARK: - Search Results Sections

extension FoodSearchSheet {
    @ViewBuilder
    var searchResultsSection: some View {
        List {
            // History section (foods user has logged before)
            if !viewModel.historyResults.isEmpty {
                Section {
                    ForEach(viewModel.visibleHistoryResults, id: \.name) { result in
                        searchResultRow(result)
                    }
                } header: {
                    expandableSectionHeader(
                        title: "History",
                        remainingCount: viewModel.remainingHistoryCount(),
                        isExpanded: viewModel.historyExpanded,
                        onToggle: viewModel.toggleHistoryExpanded
                    )
                }
            }

            // My Foods section (user-created foods)
            if !viewModel.customResults.isEmpty {
                Section {
                    ForEach(viewModel.visibleCustomResults, id: \.name) { result in
                        searchResultRow(result)
                    }
                } header: {
                    expandableSectionHeader(
                        title: "My Foods",
                        remainingCount: viewModel.remainingCustomCount(),
                        isExpanded: viewModel.customExpanded,
                        onToggle: viewModel.toggleCustomExpanded
                    )
                }
            }

            // Common section (USDA foods)
            if !viewModel.commonResults.isEmpty {
                Section {
                    ForEach(viewModel.visibleCommonResults, id: \.name) { result in
                        searchResultRow(result)
                    }
                } header: {
                    expandableSectionHeader(
                        title: "Common",
                        remainingCount: viewModel.remainingCommonCount(),
                        isExpanded: viewModel.commonExpanded,
                        onToggle: viewModel.toggleCommonExpanded
                    )
                }
            }

            // Branded section (Open Food Facts)
            if !viewModel.brandedResults.isEmpty {
                Section {
                    ForEach(viewModel.visibleBrandedResults, id: \.name) { result in
                        searchResultRow(result)
                    }
                } header: {
                    expandableSectionHeader(
                        title: "Branded",
                        remainingCount: viewModel.remainingBrandedCount(),
                        isExpanded: viewModel.brandedExpanded,
                        onToggle: viewModel.toggleBrandedExpanded
                    )
                }
            }
        }
        .listStyle(.plain)
    }

    /// Expandable section header with "See X More" / "See Less" button
    @ViewBuilder
    func expandableSectionHeader(
        title: String,
        remainingCount: Int,
        isExpanded: Bool,
        onToggle: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            if remainingCount > 0 {
                Button {
                    onToggle()
                } label: {
                    Text(isExpanded ? "See Less" : "See \(remainingCount) More")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("\(title.lowercased())-expand-button")
            }
        }
    }

    func searchResultRow(_ result: FoodSearchResult) -> some View {
        Button {
            selectedFood = result
            showingFoodDetail = true
        } label: {
            FoodSearchResultRow(result: result)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("food-result-\(result.name.lowercased().replacingOccurrences(of: " ", with: "-"))")
        .if(result.source == .userCreated) { view in
            view
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button("Delete", role: .destructive) {
                        if let food = findCustomFood(for: result) {
                            foodToDelete = food
                            showingDeleteConfirmation = true
                        } else {
                            logger.warning("Could not find custom food for delete: \(result.name)")
                        }
                    }
                    .accessibilityIdentifier("delete-custom-food-button")
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button("Edit") {
                        if let food = findCustomFood(for: result) {
                            editingCustomFood = food
                        } else {
                            logger.warning("Could not find custom food for edit: \(result.name)")
                        }
                    }
                    .tint(.blue)
                    .accessibilityIdentifier("edit-custom-food-button")
                }
        }
    }

    @ViewBuilder
    var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    var emptyResultsSection: some View {
        ContentUnavailableView(
            "No Results",
            systemImage: "magnifyingglass",
            description: Text("No foods found for \"\(viewModel.searchText)\"")
        )
    }

    // MARK: - Time Picker Sheet

    @ViewBuilder
    var timePickerSheet: some View {
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

    // MARK: - Header Section

    var headerSection: some View {
        HStack(spacing: 12) {
            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
            .accessibilityIdentifier("food-search-cancel-button")

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
            .accessibilityIdentifier(FoodSearchSheet.timePickerIdentifier)
            .sheet(isPresented: $showingTimePicker) {
                timePickerSheet
            }

            Spacer()

            // Macro progress indicators matching Food Log style
            HStack(spacing: 12) {
                MacroProgressBar(
                    label: "",
                    current: viewModel.consumedCalories,
                    target: viewModel.targetCalories,
                    color: DesignTokens.Colors.calories,
                    displayMode: .fraction,
                    icon: "flame.fill",
                    showRemainingBelow: true,
                    accessibilityIdentifier: "search-header-calories"
                )
                .frame(width: 80)

                MacroProgressBar(
                    label: "P",
                    current: viewModel.consumedProtein,
                    target: viewModel.targetProtein,
                    color: DesignTokens.Colors.protein,
                    displayMode: .fraction,
                    showRemainingBelow: true,
                    accessibilityIdentifier: "search-header-protein"
                )
                .frame(width: 70)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Barcode Lookup

    /// Handle a detected barcode by looking up in custom foods first, then local database
    func handleBarcodeDetected(_ barcode: String) async {
        // Prevent concurrent lookups - skip if already looking up
        guard !isLookingUpBarcode else {
            logger.debug("Skipping barcode lookup - already in progress")
            return
        }

        isLookingUpBarcode = true
        lastScannedBarcode = barcode

        // 1. Check custom foods first (user-created foods)
        do {
            if let customFood = try await customFoodService?.lookup(barcode: barcode) {
                selectedFood = customFood.toSearchResult()
                isLookingUpBarcode = false
                showingFoodDetail = true
                logger.info("Found custom food for barcode: \(barcode)")
                return
            }
        } catch {
            // Log but continue to local database lookup
            logger.error("Custom food barcode lookup failed: \(error.localizedDescription)")
        }

        // 2. Check local database (1.7M+ foods from USDA + Open Food Facts dump)
        do {
            if let result = try await foodService.lookupBarcode(barcode) {
                selectedFood = result
                isLookingUpBarcode = false
                showingFoodDetail = true
                logger.info("Found food in local database for barcode: \(barcode)")
                return
            }
        } catch {
            logger.error("Local database barcode lookup failed: \(error.localizedDescription)")
            isLookingUpBarcode = false
            return
        }

        // 3. Not found - user can create custom food
        isLookingUpBarcode = false
        barcodeNotFound = true
        logger.info("No product found for barcode: \(barcode)")
    }
}
