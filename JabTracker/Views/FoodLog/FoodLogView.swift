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
struct DailyTotals {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
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
    @State private var showingClearDayConfirmation = false
    @State private var editingEntry: FoodEntry?
    @State private var entriesGroupedByDate: [Date: Int] = [:]

    // Burned calories support
    @State private var adjustedCalorieTarget: Double = 0
    @State private var activeEnergyBurned: Double = 0
    @State private var adjustmentBreakdown: CalorieAdjustmentBreakdown?

    // Fasting day support
    @State private var isFastingDay: Bool = false

    // Copy/paste state
    @State private var showingPasteDialog = false

    private let calendar = Calendar.current

    /// Get macro targets for the selected date, considering per-day distribution
    private var macroTargets: DailyMacros {
        guard let user = users.first else {
            return .zero
        }
        return user.macroTargetsForDate(selectedDate)
    }

    // MARK: - Static Properties

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

    /// Whether the fasting toggle should be shown (only when no entries exist)
    private var shouldShowFastingToggle: Bool {
        selectedDateEntries.isEmpty
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

                // Compact swipeable macro summary
                Section {
                    let totals = calculateTotals()
                    MacroSummarySwipeCard(
                        consumedCalories: totals.calories,
                        consumedProtein: totals.protein,
                        consumedCarbs: totals.carbs,
                        consumedFat: totals.fat,
                        targetCalories: macroTargets.calories,
                        targetProtein: macroTargets.proteinGrams,
                        targetCarbs: macroTargets.carbsGrams,
                        targetFat: macroTargets.fatGrams,
                        adjustedCalorieTarget: adjustedCalorieTarget > 0
                            ? adjustedCalorieTarget
                            : macroTargets.calories,
                        adjustmentBreakdown: adjustmentBreakdown
                    )
                    .cardListRow()
                    .contentShape(Rectangle())
                    .contextMenu {
                        FoodLogCopyPasteMenu(
                            entries: selectedDateEntries,
                            section: nil,
                            selectedDate: selectedDate,
                            onPaste: { triggerPaste() },
                            onClearDay: { showingClearDayConfirmation = true }
                        )
                    }
                }
                .listSectionSeparator(.hidden)

                // Fasting toggle (only shown when no entries exist)
                if shouldShowFastingToggle {
                    Section {
                        FastingToggleCard(
                            isFasting: Binding(
                                get: { isFastingDay },
                                set: { newValue in
                                    isFastingDay = newValue
                                    saveFastingStatus(newValue)
                                }
                            )
                        )
                        .cardListRow()
                    }
                    .listSectionSeparator(.hidden)
                }

                // Meal sections
                ForEach(MealSection.allCases) { section in
                    mealSection(for: section)
                }
            }
            .cardListStyle()
            .safeAreaInset(edge: .top, spacing: 0) {
                PageHeader(title: "Food Log") {
                    HStack(spacing: 12) {
                        // Copy/Paste segmented control
                        CopyPasteSegmentedControl(
                            hasEntries: !selectedDateEntries.isEmpty,
                            hasClipboard: AppServices.shared.foodClipboardService?.hasContent == true,
                            onCopy: {
                                AppServices.shared.foodClipboardService?.copyDay(
                                    date: selectedDate,
                                    entries: selectedDateEntries
                                )
                            },
                            onPaste: {
                                triggerPaste()
                            }
                        )
                        .confirmationDialog(
                            "Paste Foods",
                            isPresented: $showingPasteDialog,
                            titleVisibility: .visible
                        ) {
                            Button("Add to Existing") {
                                Task {
                                    await performPaste(replacing: false)
                                }
                            }
                            Button("Replace Existing", role: .destructive) {
                                Task {
                                    await performPaste(replacing: true)
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            if let content = AppServices.shared.foodClipboardService?.content {
                                let itemText = content.entryCount == 1 ? "item" : "items"
                                let dateText = selectedDate.formatted(date: .abbreviated, time: .omitted)
                                Text("Paste \(content.entryCount) \(itemText) to \(dateText)?")
                            }
                        }

                        // Add button
                        Button {
                            showingAddFood = true
                        } label: {
                            Image(systemName: "plus")
                                .font(
                                    .system(
                                        size: DesignTokens.HeaderButton.iconSize,
                                        weight: DesignTokens.HeaderButton.iconWeight
                                    )
                                )
                                .foregroundColor(DesignTokens.HeaderButton.iconColor)
                                .frame(
                                    width: DesignTokens.HeaderButton.buttonSize,
                                    height: DesignTokens.HeaderButton.buttonSize
                                )
                                .background(DesignTokens.HeaderButton.backgroundColor)
                                .clipShape(Circle())
                        }
                        .frame(minWidth: 44, minHeight: 44)  // Apple HIG touch target
                        .accessibilityIdentifier("add-food-button")
                    }
                }
                .padding(.bottom, 14)
                .background(DesignTokens.Colors.groupedBackground)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddFood) {
                if let currentUser = users.first,
                    let foodService = AppServices.shared.foodService,
                    let mealLogService = AppServices.shared.mealLogService
                {
                    FoodSearchSheet(
                        user: currentUser,
                        foodService: foodService,
                        mealLogService: mealLogService,
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
            .alert("Clear All Foods?", isPresented: $showingClearDayConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear Day", role: .destructive) {
                    Task { await clearAllEntriesForDay() }
                }
            } message: {
                Text("This will remove \(selectedDateEntries.count) items from your log.")
            }
        }
        .accessibilityIdentifier("food-log-view")
        .task(id: selectedDate) {
            loadWeekEntries()
            loadFastingStatus()
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
        guard let user = users.first else {
            adjustedCalorieTarget = 0
            adjustmentBreakdown = nil
            return
        }
        guard let calorieAdjustmentService = AppServices.shared.calorieAdjustmentService else {
            Self.logger.warning("CalorieAdjustmentService unavailable - using base target")
            adjustedCalorieTarget = macroTargets.calories
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
        let entries = selectedDateEntries.filter { $0.meal == section }

        return HStack {
            HStack(spacing: 4) {
                Image(systemName: section.icon)
                    .font(.caption)
                Text(section.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.secondary)

            Spacer()

            MealTotalsView(totals: totals)
        }
        .textCase(nil)
        .contentShape(Rectangle())
        .accessibilityIdentifier("meal-section-header-\(section.rawValue)")
        .contextMenu {
            FoodLogCopyPasteMenu(
                entries: entries,
                section: section,
                selectedDate: selectedDate,
                onPaste: { triggerPaste() }
            )
        }
    }

    /// Trigger paste action - skip dialog if day is empty
    private func triggerPaste() {
        if selectedDateEntries.isEmpty {
            // Day is empty, paste directly (no need to ask add vs replace)
            Task {
                await performPaste(replacing: false)
            }
        } else {
            // Day has entries, show confirmation dialog
            showingPasteDialog = true
        }
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

    private func clearAllEntriesForDay() async {
        guard let mealLogService = AppServices.shared.mealLogService else { return }
        for entry in selectedDateEntries {
            do {
                try await mealLogService.deleteEntry(entry)
            } catch {
                Self.logger.error("Failed to delete entry '\(entry.foodName)': \(error.localizedDescription)")
            }
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

    private func performPaste(replacing: Bool) async {
        guard let clipboardService = AppServices.shared.foodClipboardService,
            let content = clipboardService.content,
            let mealLogService = AppServices.shared.mealLogService
        else {
            return
        }

        let entries: [ClipboardEntry]
        switch content {
        case .day(_, let clipboardEntries):
            entries = clipboardEntries
        case .meal(_, _, let clipboardEntries):
            entries = clipboardEntries
        }

        do {
            try await mealLogService.pasteEntries(
                entries,
                to: selectedDate,
                targetMeal: nil,  // Preserve original meal sections
                replacing: replacing
            )
        } catch {
            Self.logger.error("Failed to paste entries: \(error.localizedDescription)")
        }
    }

    // MARK: - Fasting Status

    /// Load fasting status for the selected date from the service
    private func loadFastingStatus() {
        guard let dayStatusService = AppServices.shared.dayStatusService else {
            isFastingDay = false
            return
        }
        isFastingDay = dayStatusService.isFasting(for: selectedDate)
    }

    /// Save fasting status for the selected date
    private func saveFastingStatus(_ isFasting: Bool) {
        guard let dayStatusService = AppServices.shared.dayStatusService else {
            Self.logger.warning("DayStatusService unavailable - cannot save fasting status")
            return
        }
        do {
            try dayStatusService.setFasting(for: selectedDate, isFasting: isFasting)
        } catch {
            Self.logger.error("Failed to save fasting status: \(error.localizedDescription)")
            // Revert UI state on save failure
            isFastingDay = !isFasting
        }
    }
}

#Preview {
    FoodLogView(selectedDate: .constant(Date()))
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
