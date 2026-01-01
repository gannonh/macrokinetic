//
//  FoodLibraryView.swift
//  JabTracker
//
//  Standalone Food Library view wrapper for accessing custom foods from More tab.
//

import SwiftUI

struct FoodLibraryView: View {
    private var customFoodService: CustomFoodService? {
        AppServices.shared.customFoodService
    }

    @State private var editingCustomFood: Food?
    @State private var foodToDelete: Food?
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteError = false

    var body: some View {
        Group {
            if let service = customFoodService {
                FoodLibraryContentView(
                    customFoodService: service,
                    onFoodSelected: { _ in
                        // Read-only browsing from More tab - no food selection action
                    },
                    editingCustomFood: $editingCustomFood,
                    foodToDelete: $foodToDelete,
                    showingDeleteConfirmation: $showingDeleteConfirmation
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("Food Library")
                        .font(DesignTokens.Typography.headline)

                    Text("Unable to load food library.")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Food Library")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Food?", isPresented: $showingDeleteConfirmation) {
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
        .alert("Delete Failed", isPresented: $showingDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Unable to delete food. Please try again.")
        }
        .sheet(item: $editingCustomFood) { food in
            if let customFoodService {
                CreateFoodSheet.edit(
                    food: food,
                    customFoodService: customFoodService,
                    onFoodCreated: { _ in
                        editingCustomFood = nil
                    }
                )
            }
        }
        .accessibilityIdentifier("food-library-view")
    }

    private func deleteCustomFood(_ food: Food) async {
        guard let service = customFoodService else { return }

        do {
            try await service.deleteCustomFood(food)
            foodToDelete = nil
        } catch {
            showingDeleteError = true
        }
    }
}

#Preview {
    NavigationStack {
        FoodLibraryView()
    }
}
