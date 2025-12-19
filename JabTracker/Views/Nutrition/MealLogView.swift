//
//  MealLogView.swift
//  JabTracker
//
//  View displaying today's logged meals grouped by meal section.
//

import SwiftUI

/// View showing today's meals grouped by section
struct MealLogView: View {
    let user: User
    let mealLogService: MealLogService?
    let foodService: FoodService?

    @State private var groupedEntries: [MealSection: [FoodEntry]] = [:]
    @State private var totals: DailyNutritionTotals = .zero
    @State private var isLoading = true
    @State private var showingAddFood = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading meals...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if allEntriesEmpty {
                    emptyStateView
                } else {
                    mealsList
                }
            }
            .navigationTitle("Today's Meals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddFood = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("add-food-nav-button")
                }
            }
            .sheet(isPresented: $showingAddFood) {
                AddFoodSheet(
                    user: user,
                    foodService: foodService,
                    mealLogService: mealLogService
                ) {
                    Task {
                        await loadMeals()
                    }
                }
            }
            .task {
                await loadMeals()
            }
        }
        .accessibilityIdentifier("meal-log-view")
    }

    private var allEntriesEmpty: Bool {
        groupedEntries.values.allSatisfy { $0.isEmpty }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No meals logged today")
                .font(DesignTokens.Typography.headline)

            Text("Tap + to add your first meal")
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)

            Button {
                showingAddFood = true
            } label: {
                Label("Add Food", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("add-food-empty-button")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mealsList: some View {
        List {
            // Daily totals summary
            Section {
                dailyTotalsSummary
            }

            // Meal sections
            ForEach(MealSection.allCases) { section in
                if let entries = groupedEntries[section], !entries.isEmpty {
                    Section {
                        ForEach(entries, id: \.id) { entry in
                            FoodEntryRow(entry: entry)
                        }
                        .onDelete { indexSet in
                            Task {
                                await deleteEntries(at: indexSet, in: section)
                            }
                        }
                    } header: {
                        Label(section.displayName, systemImage: section.icon)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var dailyTotalsSummary: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Daily Progress")
                    .font(DesignTokens.Typography.headline)
                Spacer()
            }

            HStack(spacing: 16) {
                macroSummaryItem(
                    value: totals.calories,
                    goal: user.dailyCalorieGoal,
                    label: "Calories",
                    color: .orange
                )
                macroSummaryItem(
                    value: totals.protein,
                    goal: user.dailyProteinGoal,
                    label: "Protein",
                    color: .red
                )
                macroSummaryItem(
                    value: totals.carbs,
                    goal: user.dailyCarbGoal,
                    label: "Carbs",
                    color: .blue
                )
                macroSummaryItem(
                    value: totals.fat,
                    goal: user.dailyFatGoal,
                    label: "Fat",
                    color: .yellow
                )
            }
        }
        .padding(.vertical, 8)
        .accessibilityIdentifier("daily-totals-summary")
    }

    private func macroSummaryItem(value: Double, goal: Double, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(Int(value))")
                .font(DesignTokens.Typography.headline)
                .foregroundColor(value > goal ? color : .primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)

            // Progress indicator
            Circle()
                .trim(from: 0, to: min(value / max(goal, 1), 1.0))
                .stroke(color, lineWidth: 3)
                .rotationEffect(.degrees(-90))
                .frame(width: 30, height: 30)
                .background(Circle().stroke(color.opacity(0.2), lineWidth: 3))
        }
        .frame(maxWidth: .infinity)
    }

    private func loadMeals() async {
        guard let service = mealLogService else {
            isLoading = false
            return
        }

        do {
            let today = Date()
            groupedEntries = try await service.getEntriesGroupedByMeal(for: today)
            totals = try await service.getDailyTotals(for: today)
        } catch {
            // Handle error - show empty state
        }

        isLoading = false
    }

    private func deleteEntries(at indexSet: IndexSet, in section: MealSection) async {
        guard let service = mealLogService,
            let entries = groupedEntries[section]
        else { return }

        for index in indexSet {
            let entry = entries[index]
            do {
                try await service.deleteEntry(entry)
            } catch {
                // Log error
            }
        }

        await loadMeals()
    }
}

/// Row for displaying a food entry
struct FoodEntryRow: View {
    let entry: FoodEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.foodName)
                    .font(DesignTokens.Typography.body)

                HStack(spacing: 8) {
                    if let brand = entry.foodBrand, !brand.isEmpty {
                        Text(brand)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("\(Int(entry.servingGrams))g")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(entry.calories)) cal")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.orange)

                Text("\(Int(entry.protein))g protein")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("food-entry-\(entry.id)")
    }
}
