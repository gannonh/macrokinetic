//
//  ScheduleConfigSheet.swift
//  JabTracker
//
//  Sheet for configuring food schedules.
//

import OSLog
import SwiftUI

/// Logger for ScheduleConfigSheet
private let logger = Logger(
    subsystem: "com.gannonhall.JabTracker",
    category: "ScheduleConfigSheet"
)

/// Sheet for configuring a food schedule
struct ScheduleConfigSheet: View {
    // MARK: - Properties

    let food: Food
    let scheduleService: FoodScheduleService
    let existingSchedule: FoodSchedule?
    let onComplete: () -> Void

    // MARK: - State

    @State private var selectedDayMeals: Set<DayMealKey> = []
    @State private var servingGrams: Double = 100.0
    @State private var servingDescription: String = ""
    @State private var hasStartDate = false
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var isSaving = false
    @State private var showingDeleteConfirmation = false
    @State private var errorMessage: String?
    @State private var showingError = false

    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Properties

    private var canSave: Bool {
        !selectedDayMeals.isEmpty && servingGrams > 0
    }

    private var isEditing: Bool {
        existingSchedule != nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                foodInfoSection
                dayMealGridSection
                servingSection
                dateRangeSection

                if isEditing {
                    deleteSection
                }
            }
            .navigationTitle(isEditing ? "Edit Schedule" : "Schedule Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveSchedule() }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .confirmationDialog(
            "Delete Schedule",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await deleteSchedule() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will stop auto-populating \(food.name) in your food log.")
        }
        .onAppear {
            loadExistingSchedule()
        }
        .accessibilityIdentifier("schedule-config-sheet")
    }

    // MARK: - Sections

    private var foodInfoSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: food.isCustomFood ? "star.fill" : "leaf.fill")
                    .foregroundColor(food.isCustomFood ? .blue : .green)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name)
                        .font(.headline)
                    if !food.brand.isEmpty {
                        Text(food.brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var dayMealGridSection: some View {
        Section {
            ScheduleDayMealGrid(selectedConfigs: $selectedDayMeals)
                .padding(.vertical, 8)
        } header: {
            Text("Schedule")
        } footer: {
            Text("Select which days and meals to auto-populate this food.")
        }
    }

    private var servingSection: some View {
        Section("Serving") {
            HStack {
                Text("Amount")
                Spacer()
                TextField("Grams", value: $servingGrams, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("g")
                    .foregroundColor(.secondary)
            }
            .accessibilityIdentifier("serving-grams-input")

            TextField("Description (optional)", text: $servingDescription)
                .accessibilityIdentifier("serving-description-input")
        }
    }

    private var dateRangeSection: some View {
        Section("Date Range (Optional)") {
            Toggle("Start Date", isOn: $hasStartDate)
            if hasStartDate {
                DatePicker(
                    "Start",
                    selection: $startDate,
                    displayedComponents: .date
                )
            }

            Toggle("End Date", isOn: $hasEndDate)
            if hasEndDate {
                DatePicker(
                    "End",
                    selection: $endDate,
                    displayedComponents: .date
                )
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button("Stop Schedule", role: .destructive) {
                showingDeleteConfirmation = true
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Actions

    private func loadExistingSchedule() {
        guard let schedule = existingSchedule,
            let config = schedule.scheduleConfig
        else { return }

        // Convert ScheduleDayMealConfig to DayMealKey
        selectedDayMeals = Set(
            config.dayMealConfigs.map {
                DayMealKey(day: $0.day, meal: $0.meal)
            })
        servingGrams = schedule.servingGrams
        servingDescription = schedule.servingDescription

        if let start = schedule.startDate {
            hasStartDate = true
            startDate = start
        }
        if let end = schedule.endDate {
            hasEndDate = true
            endDate = end
        }
    }

    private func saveSchedule() async {
        isSaving = true
        defer { isSaving = false }

        // Convert DayMealKey set to ScheduleDayMealConfig array
        let configs = selectedDayMeals.map { key in
            ScheduleDayMealConfig(day: key.day, meal: key.meal)
        }
        let scheduleConfig = ScheduleConfig(dayMealConfigs: configs)

        do {
            _ = try await scheduleService.createOrUpdateSchedule(
                for: food,
                config: scheduleConfig,
                servingGrams: servingGrams,
                servingDescription: servingDescription,
                startDate: hasStartDate ? startDate : nil,
                endDate: hasEndDate ? endDate : nil
            )

            logger.info("Saved schedule for: \(food.name)")
            dismiss()
            onComplete()
        } catch {
            logger.error("Failed to save schedule: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func deleteSchedule() async {
        guard let schedule = existingSchedule else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            try await scheduleService.deleteSchedule(schedule)
            logger.info("Deleted schedule for: \(food.name)")
            dismiss()
            onComplete()
        } catch {
            logger.error("Failed to delete schedule: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview("New Schedule") {
    Text("Preview requires app context")
}
