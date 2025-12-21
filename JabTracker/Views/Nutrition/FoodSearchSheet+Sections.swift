//
//  FoodSearchSheet+Sections.swift
//  JabTracker
//
//  Section views for FoodSearchSheet.
//

import SwiftUI

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

            // Custom section (user-created foods)
            if !viewModel.customResults.isEmpty {
                Section {
                    ForEach(viewModel.visibleCustomResults, id: \.name) { result in
                        searchResultRow(result)
                    }
                } header: {
                    expandableSectionHeader(
                        title: "Custom",
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
}
