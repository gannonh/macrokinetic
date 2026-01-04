//
//  FoodLogView.swift
//  JabTracker
//
//  Today's food log with meal sections and swipe actions.
//

import SwiftData
import SwiftUI
import os

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
    // MARK: - Properties

    // Week calendar state - bound to parent for tab bar + button
    @Binding var selectedDate: Date

    @Environment(\.modelContext) private var modelContext

    @Query private var users: [User]
    @Query(sort: \FoodEntry.loggedAt, order: .forward) private var allEntries: [FoodEntry]

    @State private var showingAddFood = false
    @State private var entryToDelete: FoodEntry?
    @State private var showingDeleteConfirmation = false
    @State private var editingEntry: FoodEntry?
    @State private var entriesGroupedByDate: [Date: Int] = [:]

    // Burned calories support
    @State private var adjustedCalorieTarget: Double = 0
    @State private var activeEnergyBurned: Double = 0
    @State private var adjustmentBreakdown: CalorieAdjustmentBreakdown?

    private let calendar = Calendar.current

    /// Get macro targets for the selected date, considering per-day distribution
    private var macroTargets: DailyMacros {
        guard let user = users.first else {
            return .zero
        }
        return user.macroTargetsForDate(selectedDate)
    }

    // MARK: - Static Properties

    private static let summaryDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "FoodLogView"
    )

    // MARK: - Initialization

    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
    }

    /// Entries for the currently selected date
    private var selectedDateEntries: [FoodEntry] {
        allEntries.filter { calendar.isDate($0.loggedAt, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationStack {
            List {
                // Week calendar navigation
                Section {
                    WeekCalendarStrip(
                        selectedDate: $selectedDate,
                        entriesGroupedByDate: entriesGroupedByDate
                    )
                    .cardListRow()
                }
                .listSectionSeparator(.hidden)

                // Calorie adjustment breakdown (only for today when adjustments exist)
                if let breakdown = adjustmentBreakdown {
                    Section {
                        CalorieAdjustmentBreakdownView(
                            breakdown: breakdown,
                            baseTarget: macroTargets.calories
                        )
                        .cardListRow()
                    }
                    .listSectionSeparator(.hidden)
                }

                // Daily summary section
                Section {
                    dailySummaryCard
                        .cardListRow()
                }
                .listSectionSeparator(.hidden)

                // Meal sections
                ForEach(MealSection.allCases) { section in
                    mealSection(for: section)
                }
            }
            .cardListStyle()
            .navigationTitle("Food Log")
            .navigationBarTitleDisplayMode(.large)
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
                    FoodSearchSheet(
                        user: currentUser,
                        foodService: AppServices.shared.foodService,
                        mealLogService: AppServices.shared.mealLogService,
                        customFoodService: AppServices.shared.customFoodService,
                        initialDate: selectedDate
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
        .task(id: selectedDate) {
            loadWeekEntries()
            await updateCalorieTarget()
            startEnergyObservation()
        }
        .onChange(of: allEntries.count) {
            loadWeekEntries()
        }
        .onChange(of: users.first?.addBurnedCaloriesEnabled) { _, _ in
            Task {
                await updateCalorieTarget()
                startEnergyObservation()
            }
        }
        .onChange(of: users.first?.healthSyncEnabled) { _, _ in
            Task {
                await updateCalorieTarget()
                startEnergyObservation()
            }
        }
        .onChange(of: users.first?.rolloverCaloriesEnabled) { _, _ in
            Task {
                await updateCalorieTarget()
            }
        }
        .onDisappear {
            MetricsService.stopActiveEnergyObservation()
        }
    }

    // MARK: - Calorie Adjustment

    /// Update the adjusted calorie target based on burned calories and rollover
    private func updateCalorieTarget() async {
        guard let user = users.first,
            let calorieAdjustmentService = AppServices.shared.calorieAdjustmentService
        else {
            adjustedCalorieTarget = 0
            adjustmentBreakdown = nil
            return
        }
        let baseTargets = user.macroTargetsForDate(selectedDate)
        adjustedCalorieTarget = await calorieAdjustmentService.getAdjustedCalorieTarget(
            for: user,
            on: selectedDate,
            baseTarget: baseTargets.calories
        )

        // Fetch breakdown for display (only show for today)
        if calendar.isDateInToday(selectedDate) {
            adjustmentBreakdown = await calorieAdjustmentService.getAdjustmentBreakdown(
                for: user,
                on: selectedDate
            )
        } else {
            adjustmentBreakdown = nil
        }
    }

    /// Start observing active energy if feature is enabled
    private func startEnergyObservation() {
        // Stop any existing observation first
        MetricsService.stopActiveEnergyObservation()

        guard let user = users.first,
            user.addBurnedCaloriesEnabled,
            user.healthSyncEnabled,
            calendar.isDateInToday(selectedDate)
        else {
            // Reset burned value when conditions aren't met
            activeEnergyBurned = 0
            return
        }

        MetricsService.startActiveEnergyObservation { energy in
            self.activeEnergyBurned = energy
            Task {
                await self.updateCalorieTarget()
            }
        }
    }

    // MARK: - Week Data Loading

    /// Load entry counts for the current week (synchronous - data already in memory)
    private func loadWeekEntries() {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return
        }

        var counts: [Date: Int] = [:]

        // Get counts for each day of the week
        for dayOffset in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekInterval.start) else {
                continue
            }
            let startOfDay = calendar.startOfDay(for: dayDate)
            let count = allEntries.filter { calendar.isDate($0.loggedAt, inSameDayAs: dayDate) }.count
            counts[startOfDay] = count
        }

        entriesGroupedByDate = counts
    }

    // MARK: - Daily Summary

    /// Title for daily summary - "Today" or formatted date
    private var summaryTitle: String {
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else {
            return Self.summaryDateFormatter.string(from: selectedDate)
        }
    }

    private var dailySummaryCard: some View {
        let totals = calculateTotals()
        let targets = macroTargets
        // Use adjusted calorie target (includes burned calories) if available
        let calorieTarget = adjustedCalorieTarget > 0 ? adjustedCalorieTarget : targets.calories

        return VStack(spacing: 12) {
            Text(summaryTitle)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("daily-summary-title")

            HStack(spacing: 20) {
                calorieColumn(
                    consumed: totals.calories,
                    target: calorieTarget,
                    showFlame: activeEnergyBurned > 0
                )
                macroColumn(
                    consumed: totals.protein,
                    target: targets.proteinGrams,
                    label: "Protein",
                    color: .blue
                )
                macroColumn(
                    consumed: totals.carbs,
                    target: targets.carbsGrams,
                    label: "Carbs",
                    color: .green
                )
                macroColumn(
                    consumed: totals.fat,
                    target: targets.fatGrams,
                    label: "Fat",
                    color: .purple
                )
            }
        }
        .padding()
        .cardStyle()
        .accessibilityIdentifier("food-log-daily-summary")
    }

    /// Calorie column with optional flame icon for burned calories
    private func calorieColumn(consumed: Double, target: Double, showFlame: Bool) -> some View {
        let remaining = target - consumed
        let isOver = remaining < 0
        let color = Color.orange

        return VStack(spacing: 4) {
            Text("\(Int(consumed.rounded()))")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(isOver ? .red : color)
            Text("Cal")
                .font(.caption)
                .foregroundColor(.secondary)
            // Show remaining/over if target is set
            if target > 0 {
                HStack(spacing: 2) {
                    Text(isOver ? "+\(Int(abs(remaining).rounded()))" : "\(Int(remaining.rounded())) left")
                        .font(.caption2)
                        .foregroundColor(isOver ? .red : .secondary)
                    if showFlame {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .accessibilityIdentifier("food-log-burned-indicator")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("food-log-calorie-column")
    }

    private func macroColumn(consumed: Double, target: Double, label: String, color: Color) -> some View {
        let remaining = target - consumed
        let isOver = remaining < 0

        return VStack(spacing: 4) {
            Text("\(Int(consumed.rounded()))")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(isOver ? .red : color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            // Show remaining/over if target is set
            if target > 0 {
                Text(isOver ? "+\(Int(abs(remaining).rounded()))" : "\(Int(remaining.rounded())) left")
                    .font(.caption2)
                    .foregroundColor(isOver ? .red : .secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Meal Sections

    @ViewBuilder
    private func mealSection(for section: MealSection) -> some View {
        let entries = selectedDateEntries.filter { $0.meal == section }
        let totals = entries.isEmpty ? .zero : MealTotals(from: entries)

        Section {
            if entries.isEmpty {
                EmptyMealRow()
                    .cardListRow()
            } else {
                ForEach(entries, id: \.id) { entry in
                    Button {
                        editingEntry = entry
                    } label: {
                        FoodEntryCardView(entry: entry)
                    }
                    .buttonStyle(.plain)
                    .cardListRow()
                    .accessibilityIdentifier("food-entry-row")
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
                }
            }
        } header: {
            mealSectionHeader(section: section, totals: totals)
                .padding(.horizontal)
        }
        .listSectionSeparator(.hidden)
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
                    HStack(spacing: 4) {
                        Text("\(Int(totals.protein))P")
                            .foregroundColor(DesignTokens.Colors.protein)
                        Text("\(Int(totals.fat))F")
                            .foregroundColor(DesignTokens.Colors.fat)
                        Text("\(Int(totals.carbs))C")
                            .foregroundColor(DesignTokens.Colors.carbs)
                    }
                    .font(.caption)

                    HStack(spacing: 2) {
                        Text("\(Int(totals.calories))")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "flame.fill")
                            .font(.caption)
                    }
                    .foregroundColor(DesignTokens.Colors.calories)
                }
            }
        }
        .textCase(nil)
    }

    // MARK: - Helpers

    private func calculateTotals() -> DailyTotals {
        DailyTotals(
            calories: selectedDateEntries.reduce(0) { $0 + $1.calories },
            protein: selectedDateEntries.reduce(0) { $0 + $1.protein },
            carbs: selectedDateEntries.reduce(0) { $0 + $1.carbs },
            fat: selectedDateEntries.reduce(0) { $0 + $1.fat }
        )
    }

    private func deleteEntry(_ entry: FoodEntry) async {
        guard let mealLogService = AppServices.shared.mealLogService else { return }
        do {
            try await mealLogService.deleteEntry(entry)
            entryToDelete = nil
        } catch {
            Self.logger.error("Failed to delete entry '\(entry.foodName)': \(error.localizedDescription)")
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
                notes: entry.notes ?? "",
                loggedAt: selectedDate
            )
        } catch {
            Self.logger.error("Failed to duplicate entry '\(entry.foodName)': \(error.localizedDescription)")
        }
    }
}

// MARK: - Empty Meal Row

/// Styled empty state row for meal sections
private struct EmptyMealRow: View {
    var body: some View {
        Text("No items logged")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .cardStyle()
    }
}

#Preview {
    FoodLogView(selectedDate: .constant(Date()))
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
