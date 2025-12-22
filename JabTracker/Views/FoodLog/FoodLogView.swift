//
//  FoodLogView.swift
//  JabTracker
//
//  Today's food log with meal sections and swipe actions.
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

/// Meal section totals for headers
private struct MealTotals {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double

    static let zero = MealTotals(calories: 0, protein: 0, carbs: 0, fat: 0)

    init(from entries: [FoodEntry]) {
        self.calories = entries.reduce(0) { $0 + $1.calories }
        self.protein = entries.reduce(0) { $0 + $1.protein }
        self.carbs = entries.reduce(0) { $0 + $1.carbs }
        self.fat = entries.reduce(0) { $0 + $1.fat }
    }

    init(calories: Double, protein: Double, carbs: Double, fat: Double) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}

struct FoodLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var todayEntries: [FoodEntry]

    @State private var showingAddFood = false
    @State private var entryToDelete: FoodEntry?
    @State private var showingDeleteConfirmation = false
    @State private var editingEntry: FoodEntry?

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
            List {
                // Daily summary section
                Section {
                    dailySummaryCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                // Meal sections
                ForEach(MealSection.allCases) { section in
                    mealSection(for: section)
                }
            }
            .listStyle(.insetGrouped)
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
            .sheet(item: $editingEntry) { entry in
                EditFoodEntrySheet(
                    entry: entry,
                    mealLogService: AppServices.shared.mealLogService
                ) {
                    editingEntry = nil
                }
            }
            .alert("Delete Entry?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    entryToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        Task {
                            await deleteEntry(entry)
                        }
                    }
                }
            } message: {
                if let entry = entryToDelete {
                    Text("This will remove \(entry.foodName) from your log.")
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
        .padding(.horizontal)
        .padding(.vertical, 8)
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

    @ViewBuilder
    private func mealSection(for section: MealSection) -> some View {
        let entries = todayEntries.filter { $0.meal == section }
        let totals = entries.isEmpty ? .zero : MealTotals(from: entries)

        Section {
            if entries.isEmpty {
                Text("No items logged")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(entries, id: \.id) { entry in
                    FoodEntryCardView(entry: entry)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                entryToDelete = entry
                                showingDeleteConfirmation = true
                            }
                            .accessibilityIdentifier("delete-entry-button")
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button("Edit") {
                                editingEntry = entry
                            }
                            .tint(.blue)
                            .accessibilityIdentifier("edit-entry-button")

                            Button("Duplicate") {
                                Task {
                                    await duplicateEntry(entry)
                                }
                            }
                            .tint(.green)
                            .accessibilityIdentifier("duplicate-entry-button")
                        }
                        .accessibilityIdentifier("food-entry-row-\(entry.id.uuidString)")
                }
            }
        } header: {
            mealSectionHeader(section: section, totals: totals)
        }
    }

    private func mealSectionHeader(section: MealSection, totals: MealTotals) -> some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: section.icon)
                Text(section.displayName)
                    .font(.headline)
            }

            Spacer()

            if totals.calories > 0 {
                HStack(spacing: 8) {
                    Text("\(Int(totals.protein))P \(Int(totals.fat))F \(Int(totals.carbs))C")
                        .font(.caption)
                        .foregroundColor(.cyan)

                    HStack(spacing: 2) {
                        Text("\(Int(totals.calories))")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .textCase(nil)
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

    private func deleteEntry(_ entry: FoodEntry) async {
        guard let mealLogService = AppServices.shared.mealLogService else { return }
        do {
            try await mealLogService.deleteEntry(entry)
            entryToDelete = nil
        } catch {
            // Entry deletion failed - could show error alert if needed
        }
    }

    private func duplicateEntry(_ entry: FoodEntry) async {
        guard let mealLogService = AppServices.shared.mealLogService else { return }

        // Create a Food object from the entry data
        let food = Food(
            name: entry.foodName,
            brand: entry.foodBrand ?? "",
            caloriesPer100g: entry.caloriesPer100g,
            proteinPer100g: entry.proteinPer100g,
            carbsPer100g: entry.carbsPer100g,
            fatPer100g: entry.fatPer100g,
            fiberPer100g: entry.fiberPer100g,
            servingSize: entry.servingGrams,
            servingDescription: entry.servingDescription ?? ""
        )

        do {
            _ = try await mealLogService.logFood(
                food: food,
                servingGrams: entry.servingGrams,
                mealSection: entry.meal,
                notes: entry.notes ?? ""
            )
        } catch {
            // Duplicate failed - could show error alert if needed
        }
    }
}

#Preview {
    FoodLogView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
