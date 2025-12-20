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
            if !viewModel.historyResults.isEmpty {
                Section("History") {
                    ForEach(viewModel.historyResults, id: \.name) { result in
                        searchResultRow(result)
                    }
                }
            }

            if !viewModel.customResults.isEmpty {
                Section("Custom") {
                    ForEach(viewModel.customResults, id: \.name) { result in
                        searchResultRow(result)
                    }
                }
            }

            if !viewModel.commonResults.isEmpty {
                Section("Common") {
                    ForEach(viewModel.commonResults, id: \.name) { result in
                        searchResultRow(result)
                    }
                }
            }

            if !viewModel.brandedResults.isEmpty {
                Section("Branded") {
                    ForEach(viewModel.brandedResults, id: \.name) { result in
                        searchResultRow(result)
                    }
                }
            }
        }
        .listStyle(.plain)
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
