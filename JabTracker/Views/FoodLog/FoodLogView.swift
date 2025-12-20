//
//  FoodLogView.swift
//  JabTracker
//
//  Today's food log with meal sections.
//

import SwiftData
import SwiftUI

/// Daily macro totals for the summary card
private struct DailyTotals {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

struct FoodLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var todayEntries: [FoodEntry]

    @State private var showingAddFood = false

    init() {
        // Query entries for today
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        _todayEntries = Query(
            filter: #Predicate<FoodEntry> { entry in
                entry.loggedAt >= startOfDay && entry.loggedAt < endOfDay
            },
            sort: [SortDescriptor(\FoodEntry.loggedAt, order: .forward)]
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Daily summary card
                    dailySummaryCard

                    // Meal sections
                    ForEach(MealSection.allCases) { section in
                        mealSectionView(for: section)
                    }
                }
                .padding()
            }
            .navigationTitle("Food Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddFood = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("add-food-button")
                }
            }
            .sheet(isPresented: $showingAddFood) {
                if let currentUser = users.first {
                    AddFoodSheet(
                        user: currentUser,
                        foodService: AppServices.shared.foodService,
                        mealLogService: AppServices.shared.mealLogService
                    ) {
                        showingAddFood = false
                    }
                }
            }
        }
        .accessibilityIdentifier("food-log-view")
    }

    // MARK: - Daily Summary

    private var dailySummaryCard: some View {
        let totals = calculateTotals()

        return VStack(spacing: 12) {
            Text("Today")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                macroColumn(value: totals.calories, label: "Cal", color: .orange)
                macroColumn(value: totals.protein, label: "Protein", color: .blue)
                macroColumn(value: totals.carbs, label: "Carbs", color: .green)
                macroColumn(value: totals.fat, label: "Fat", color: .purple)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func macroColumn(value: Double, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(Int(value))")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Meal Sections

    private func mealSectionView(for section: MealSection) -> some View {
        let entries = todayEntries.filter { $0.meal == section }

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: section.icon)
                    .foregroundColor(.secondary)
                Text(section.displayName)
                    .font(.headline)
                Spacer()
                Text("\(Int(entries.reduce(0) { $0 + $1.calories })) cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if entries.isEmpty {
                Text("No items logged")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(entries, id: \.id) { entry in
                    foodEntryRow(entry)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func foodEntryRow(_ entry: FoodEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.foodName)
                    .font(.subheadline)
                if let brand = entry.foodBrand, !brand.isEmpty {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(entry.calories)) cal")
                    .font(.subheadline)
                Text("\(Int(entry.servingGrams))g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func calculateTotals() -> DailyTotals {
        DailyTotals(
            calories: todayEntries.reduce(0) { $0 + $1.calories },
            protein: todayEntries.reduce(0) { $0 + $1.protein },
            carbs: todayEntries.reduce(0) { $0 + $1.carbs },
            fat: todayEntries.reduce(0) { $0 + $1.fat }
        )
    }
}

#Preview {
    FoodLogView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
