//
//  FoodSearchView.swift
//  JabTracker
//
//  Search view for finding foods to log.
//

import SwiftUI

/// Food search view with results list
struct FoodSearchView: View {
    let foodService: FoodService?
    let onFoodSelected: (FoodSearchResult) -> Void

    @State private var searchText = ""
    @State private var results: [FoodSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Results or empty state
                if results.isEmpty && searchText.count >= 2 && !isSearching {
                    emptyStateView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if searchText.count < 2 && searchText.count > 0 {
                    minimumCharactersView
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search Foods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .accessibilityIdentifier("food-search-view")
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search foods...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .accessibilityIdentifier("food-search-field")
                .onChange(of: searchText) { _, newValue in
                    performDebouncedSearch(query: newValue)
                }

            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    results = []
                    searchTask?.cancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityIdentifier("clear-search-button")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }

    private var resultsList: some View {
        List(results, id: \.name) { result in
            Button {
                onFoodSelected(result)
                dismiss()
            } label: {
                FoodSearchResultRow(result: result)
            }
            .accessibilityIdentifier("food-result-\(result.name)")
        }
        .listStyle(.plain)
    }

    private var minimumCharactersView: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.cursor")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("Type at least 2 characters")
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No foods found")
                .font(DesignTokens.Typography.headline)
            Text("Try a different search term")
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Search Error")
                .font(DesignTokens.Typography.headline)
            Text(message)
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func performDebouncedSearch(query: String) {
        // Cancel any pending search
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Minimum 2 characters required
        guard trimmed.count >= 2 else {
            results = []
            return
        }

        // Debounce: wait 500ms before searching (per design spec)
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)  // 500ms

            guard !Task.isCancelled else { return }

            await performSearch(query: trimmed)
        }
    }

    private func performSearch(query: String) async {
        guard let service = foodService else {
            errorMessage = "Food service not available"
            return
        }

        errorMessage = nil
        isSearching = true

        // Search local first (fast ~10ms)
        var localResults: [FoodSearchResult] = []
        do {
            localResults = try await service.searchLocal(query: query, limit: 15)
        } catch {
            localResults = []
        }

        // Show local results immediately
        results = localResults

        guard !Task.isCancelled else {
            isSearching = false
            return
        }

        // Then search API and merge results (~500-1000ms)
        do {
            let apiResults = try await service.searchAPI(query: query, limit: 10)

            // Merge API results (deduplicate by name)
            var seenNames = Set(localResults.map { $0.name.lowercased() })
            for apiResult in apiResults {
                let key = apiResult.name.lowercased()
                if !seenNames.contains(key) {
                    results.append(apiResult)
                    seenNames.insert(key)
                }
            }
        } catch {
            // API errors are non-fatal, local results still showing
        }

        isSearching = false
    }
}

/// Row for displaying a food search result
struct FoodSearchResultRow: View {
    let result: FoodSearchResult

    var body: some View {
        HStack(spacing: 12) {
            // Source icon
            Image(systemName: result.source.iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(sourceColor)
                .frame(width: 24, height: 24)
                .accessibilityLabel(result.source.displayName)

            VStack(alignment: .leading, spacing: 4) {
                // Name and brand
                if let brand = result.brand, !brand.isEmpty {
                    Text(result.name)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(brand)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text(result.name)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }

                // Macros: Calories • P/C/F
                HStack(spacing: 8) {
                    Text("\(Int(result.caloriesPer100g)) cal")
                        .fontWeight(.medium)

                    Text("•")
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Text("P:\(Int(result.proteinPer100g))")
                        Text("C:\(Int(result.carbsPer100g))")
                        Text("F:\(Int(result.fatPer100g))")
                    }
                    .foregroundColor(.secondary)
                }
                .font(DesignTokens.Typography.caption)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var sourceColor: Color {
        switch result.source {
        case .local:
            return .green  // Whole foods
        case .openFoodFacts:
            return .orange  // Packaged foods
        case .userCreated:
            return .blue  // Custom
        }
    }
}
