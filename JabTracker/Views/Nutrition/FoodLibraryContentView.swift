//
//  FoodLibraryContentView.swift
//  JabTracker
//
//  Food Library tab content showing custom foods with tabs and sort options.
//

import OSLog
import SwiftUI

/// Logger for FoodLibraryContentView
private let logger = Logger(
    subsystem: "com.gannonhall.JabTracker",
    category: "FoodLibraryContentView"
)

/// Content view for the Food Library showing custom foods
struct FoodLibraryContentView: View {
    // MARK: - Properties

    let customFoodService: CustomFoodService
    let onFoodSelected: (Food) -> Void

    @Binding var editingCustomFood: Food?
    @Binding var foodToDelete: Food?
    @Binding var showingDeleteConfirmation: Bool

    // MARK: - State

    @State private var selectedTab: LibraryTab = .foods
    @State private var selectedSort: FoodLibrarySortOption = .dateAdded
    @State private var customFoods: [Food] = []
    @State private var showingComingSoon = false
    @State private var comingSoonFeature = ""
    @State private var schedulingFood: Food?
    @State private var existingScheduleForFood: FoodSchedule?
    @State private var scheduledFoods: [FoodSchedule] = []
    @State private var selectedScheduleForEdit: FoodSchedule?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            tabBarSection

            // Tab content
            if selectedTab == .foods {
                foodsTabContent
            } else if selectedTab == .scheduled {
                scheduledTabContent
            }
        }
        .accessibilityIdentifier("food-library-content")
        .sheet(item: $schedulingFood) { food in
            if let scheduleService = AppServices.shared.foodScheduleService {
                ScheduleConfigSheet(
                    food: food,
                    scheduleService: scheduleService,
                    existingSchedule: existingScheduleForFood,
                    onComplete: {
                        Task { await loadCustomFoods() }
                    }
                )
            }
        }
        .sheet(item: $selectedScheduleForEdit) { schedule in
            if let scheduleService = AppServices.shared.foodScheduleService {
                ScheduleEditSheetWrapper(
                    schedule: schedule,
                    scheduleService: scheduleService,
                    customFoodService: customFoodService,
                    onComplete: {
                        Task { await loadScheduledFoods() }
                    }
                )
            }
        }
        .task {
            await loadCustomFoods()
            await loadScheduledFoods()
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .scheduled {
                Task { await loadScheduledFoods() }
            }
        }
        .onChange(of: editingCustomFood) { _, newValue in
            // Reload when edit sheet is dismissed (food was nil, then set, then nil again)
            if newValue == nil {
                Task {
                    await loadCustomFoods()
                }
            }
        }
        .onChange(of: showingDeleteConfirmation) { _, newValue in
            // Reload when delete confirmation is dismissed
            if !newValue {
                Task {
                    await loadCustomFoods()
                }
            }
        }
        .alert("Coming Soon", isPresented: $showingComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(comingSoonFeature) will be available in a future update.")
        }
    }

    // MARK: - Tab Bar Section

    private var tabBarSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibraryTab.allCases, id: \.rawValue) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
    }

    private func tabButton(_ tab: LibraryTab) -> some View {
        Button {
            if tab.isEnabled {
                selectedTab = tab
            } else {
                comingSoonFeature = tab.displayName
                showingComingSoon = true
            }
        } label: {
            Text(tab.displayName)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    selectedTab == tab
                        ? Color.primary.opacity(0.1)
                        : Color.clear
                )
                .foregroundColor(
                    tab.isEnabled ? .primary : .secondary
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            selectedTab == tab
                                ? Color.primary.opacity(0.3)
                                : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .accessibilityIdentifier("food-library-tab-\(tab.rawValue)")
    }

    // MARK: - Foods Tab Content

    private var foodsTabContent: some View {
        VStack(spacing: 0) {
            // Header with sort menu
            headerSection

            // Foods list
            if customFoods.isEmpty {
                emptyStateView
            } else {
                foodsList
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Foods")
                .font(.headline)

            Spacer()

            // Sort menu
            Menu {
                ForEach(FoodLibrarySortOption.allCases, id: \.rawValue) { option in
                    Button {
                        selectedSort = option
                        sortFoods()
                    } label: {
                        HStack {
                            Text(option.displayName)
                            if selectedSort == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedSort.displayName)
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(8)
            }
            .accessibilityIdentifier("food-library-sort-menu")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var foodsList: some View {
        List {
            ForEach(customFoods) { food in
                foodRow(food)
                    .accessibilityIdentifier("food-library-row-\(food.id)")
            }
        }
        .listStyle(.plain)
    }

    private func foodRow(_ food: Food) -> some View {
        Button {
            onFoodSelected(food)
        } label: {
            foodRowContent(food)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", role: .destructive) {
                foodToDelete = food
                showingDeleteConfirmation = true
            }
            .accessibilityIdentifier("delete-food-library-button")
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button("Edit") {
                editingCustomFood = food
            }
            .tint(.blue)
            .accessibilityIdentifier("edit-food-library-button")

            Button {
                Task {
                    await loadScheduleAndPresent(for: food)
                }
            } label: {
                Label("Schedule", systemImage: "calendar.badge.plus")
            }
            .tint(.purple)
            .accessibilityIdentifier("schedule-food-library-button")
        }
    }

    private func foodRowContent(_ food: Food) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                foodNameBrand(food)
                foodMacrosRow(food)
                foodServingInfo(food)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func foodNameBrand(_ food: Food) -> some View {
        if !food.brand.isEmpty {
            Text(food.name)
                .font(DesignTokens.Typography.body)
                .foregroundColor(.primary)
                .lineLimit(1)
            Text(food.brand)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        } else {
            Text(food.name)
                .font(DesignTokens.Typography.body)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
    }

    private func foodMacrosRow(_ food: Food) -> some View {
        HStack(spacing: 8) {
            Text("\(Int(food.caloriesPerServing)) cal")
                .fontWeight(.medium)
                .foregroundColor(DesignTokens.Colors.calories)
            Text("•")
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                Text("P:\(Int(food.proteinPerServing))")
                    .foregroundColor(DesignTokens.Colors.protein)
                Text("C:\(Int(food.carbsPerServing))")
                    .foregroundColor(DesignTokens.Colors.carbs)
                Text("F:\(Int(food.fatPerServing))")
                    .foregroundColor(DesignTokens.Colors.fat)
            }
        }
        .font(DesignTokens.Typography.caption)
    }

    @ViewBuilder
    private func foodServingInfo(_ food: Food) -> some View {
        if !food.servingDescription.isEmpty {
            Text(food.servingDescription)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        } else {
            Text("\(Int(food.servingSize))\(food.servingUnit)")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No custom foods yet")
                .font(DesignTokens.Typography.headline)

            Text("Create one to get started.")
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Helpers

    private func loadCustomFoods() async {
        do {
            let foods = try await customFoodService.getAllCustomFoods(limit: 1000)
            customFoods = foods
            sortFoods()
        } catch {
            logger.error("Failed to load custom foods: \(error.localizedDescription)")
            customFoods = []
        }
    }

    private func sortFoods() {
        switch selectedSort {
        case .dateAdded:
            customFoods.sort { $0.createdAt > $1.createdAt }
        case .name:
            customFoods.sort { $0.name.lowercased() < $1.name.lowercased() }
        }
    }

    private func loadScheduleAndPresent(for food: Food) async {
        guard let scheduleService = AppServices.shared.foodScheduleService else { return }
        do {
            existingScheduleForFood = try await scheduleService.getSchedule(for: food.id)
            schedulingFood = food
        } catch {
            logger.error("Failed to load schedule: \(error.localizedDescription)")
            existingScheduleForFood = nil
            schedulingFood = food
        }
    }

    private func loadScheduledFoods() async {
        guard let scheduleService = AppServices.shared.foodScheduleService else {
            scheduledFoods = []
            return
        }
        do {
            scheduledFoods = try await scheduleService.getAllActiveSchedules()
        } catch {
            logger.error("Failed to load scheduled foods: \(error.localizedDescription)")
            scheduledFoods = []
        }
    }

    private func deleteSchedule(_ schedule: FoodSchedule) async {
        guard let scheduleService = AppServices.shared.foodScheduleService else { return }
        do {
            try await scheduleService.deleteSchedule(schedule)
            await loadScheduledFoods()
        } catch {
            logger.error("Failed to delete schedule: \(error.localizedDescription)")
        }
    }

    // MARK: - Scheduled Tab Content

    private var scheduledTabContent: some View {
        VStack(spacing: 0) {
            scheduledHeaderSection

            if scheduledFoods.isEmpty {
                emptyScheduledStateView
            } else {
                scheduledFoodsList
            }
        }
    }

    private var scheduledHeaderSection: some View {
        HStack {
            Text("Scheduled Foods")
                .font(.headline)
            Spacer()
            Text("\(scheduledFoods.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var scheduledFoodsList: some View {
        List {
            ForEach(scheduledFoods) { schedule in
                scheduledFoodRow(schedule)
                    .accessibilityIdentifier("scheduled-food-row-\(schedule.id)")
            }
        }
        .listStyle(.plain)
    }

    private func scheduledFoodRow(_ schedule: FoodSchedule) -> some View {
        Button {
            selectedScheduleForEdit = schedule
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.purple)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.foodName)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if !schedule.foodBrand.isEmpty {
                        Text(schedule.foodBrand)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // Schedule summary
                    Text(scheduleSummary(for: schedule))
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    // Serving info
                    HStack(spacing: 4) {
                        Text("\(Int(schedule.servingGrams))g")
                        if !schedule.servingDescription.isEmpty {
                            Text("(\(schedule.servingDescription))")
                        }
                    }
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Stop", role: .destructive) {
                Task { await deleteSchedule(schedule) }
            }
            .accessibilityIdentifier("stop-schedule-button")
        }
    }

    private func scheduleSummary(for schedule: FoodSchedule) -> String {
        guard let config = schedule.scheduleConfig else { return "No schedule" }

        let days = config.scheduledDays.sorted { $0.rawValue < $1.rawValue }
        let meals = config.scheduledMeals.sorted { $0.rawValue < $1.rawValue }

        let dayText: String
        if days.count == 7 {
            dayText = "Every day"
        } else if days.count == 5 && !days.contains(.saturday) && !days.contains(.sunday) {
            dayText = "Weekdays"
        } else if days.count == 2 && days.contains(.saturday) && days.contains(.sunday) {
            dayText = "Weekends"
        } else {
            dayText = days.map { $0.shortName }.joined(separator: ", ")
        }

        let mealText = meals.map { $0.displayName }.joined(separator: ", ")

        return "\(dayText) - \(mealText)"
    }

    private var emptyScheduledStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No scheduled foods")
                .font(DesignTokens.Typography.headline)

            Text("Swipe a food and tap Schedule to auto-populate it in your log.")
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Schedule Edit Sheet Wrapper

/// Wrapper to load Food model before presenting ScheduleConfigSheet
private struct ScheduleEditSheetWrapper: View {
    let schedule: FoodSchedule
    let scheduleService: FoodScheduleService
    let customFoodService: CustomFoodService
    let onComplete: () -> Void

    @State private var food: Food?

    var body: some View {
        Group {
            if let food = food {
                ScheduleConfigSheet(
                    food: food,
                    scheduleService: scheduleService,
                    existingSchedule: schedule,
                    onComplete: onComplete
                )
            } else {
                ProgressView("Loading...")
                    .task {
                        await loadFood()
                    }
            }
        }
    }

    private func loadFood() async {
        // Try to find the custom food by ID
        do {
            let foods = try await customFoodService.getAllCustomFoods(limit: 1000)
            food = foods.first { $0.id == schedule.foodId }

            // If not found, create a placeholder Food from schedule data
            if food == nil {
                let placeholder = Food(
                    name: schedule.foodName,
                    brand: schedule.foodBrand,
                    source: .userCreated,
                    caloriesPer100g: schedule.caloriesPer100g,
                    proteinPer100g: schedule.proteinPer100g,
                    carbsPer100g: schedule.carbsPer100g,
                    fatPer100g: schedule.fatPer100g,
                    fiberPer100g: schedule.fiberPer100g,
                    servingSize: schedule.servingGrams,
                    servingUnit: "g",
                    servingDescription: schedule.servingDescription
                )
                placeholder.id = schedule.foodId
                food = placeholder
            }
        } catch {
            // Create placeholder from schedule data
            let placeholder = Food(
                name: schedule.foodName,
                brand: schedule.foodBrand,
                source: .userCreated,
                caloriesPer100g: schedule.caloriesPer100g,
                proteinPer100g: schedule.proteinPer100g,
                carbsPer100g: schedule.carbsPer100g,
                fatPer100g: schedule.fatPer100g,
                fiberPer100g: schedule.fiberPer100g,
                servingSize: schedule.servingGrams,
                servingUnit: "g",
                servingDescription: schedule.servingDescription
            )
            placeholder.id = schedule.foodId
            food = placeholder
        }
    }
}
