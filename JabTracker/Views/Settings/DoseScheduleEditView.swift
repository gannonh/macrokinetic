//
//  DoseScheduleEditView.swift
//  JabTracker
//
//  Full schedule editing UI for creating and modifying dose schedules.
//

import SwiftData
import SwiftUI

/// Full schedule editing UI for medication profiles
///
/// Provides form-based interface for creating new schedules or editing existing ones,
/// with support for pattern selection, frequency configuration, and reminder preferences.
struct DoseScheduleEditView: View {
    // MARK: - Properties

    /// Medication profile this schedule belongs to
    let medicationProfile: MedicationProfile

    /// Existing schedule being edited (nil if creating new)
    let existingSchedule: DoseSchedule?

    /// Callback when schedule is saved
    let onSave: (ScheduleConfiguration, SchedulePatternType) -> Void

    // MARK: - State

    /// Selected schedule pattern
    @State var selectedPattern: SchedulePatternType

    /// Day of week for weekly pattern (1-7, Monday-Sunday)
    @State private var dayOfWeek: Int

    /// Time of day for dose
    @State private var timeOfDay: TimeComponents

    /// Dose interval in days
    @State private var interval: Int

    /// Adherence window minutes before
    @State private var windowMinutesBefore: Int

    /// Adherence window minutes after
    @State private var windowMinutesAfter: Int

    /// Saving state
    @State private var isSaving: Bool = false

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Initialization

    init(
        medicationProfile: MedicationProfile,
        existingSchedule: DoseSchedule?,
        onSave: @escaping (ScheduleConfiguration, SchedulePatternType) -> Void
    ) {
        self.medicationProfile = medicationProfile
        self.existingSchedule = existingSchedule
        self.onSave = onSave

        // Initialize from existing or defaults
        _selectedPattern = State(initialValue: existingSchedule?.patternType ?? .weekly)
        
        // Parse existing schedule baseSchedule configuration if editing
        if let schedule = existingSchedule,
           let data = schedule.baseSchedule,
           let config = try? JSONDecoder().decode(ScheduleConfiguration.self, from: data) {
            // Populate fields from existing configuration
            _dayOfWeek = State(initialValue: config.dayOfWeek ?? 1)
            _timeOfDay = State(initialValue: config.timeOfDay)
            _interval = State(initialValue: config.interval)
            _windowMinutesBefore = State(initialValue: config.windowMinutesBefore)
            _windowMinutesAfter = State(initialValue: config.windowMinutesAfter)
        } else {
            // Use defaults for new schedule
            _dayOfWeek = State(initialValue: 1)  // Default: Monday
            _timeOfDay = State(initialValue: TimeComponents(hour: 8, minute: 0))  // Default: 8 AM
            _interval = State(initialValue: 7)  // Default: weekly
            _windowMinutesBefore = State(initialValue: 120)  // Default: 2 hours
            _windowMinutesAfter = State(initialValue: 120)  // Default: 2 hours
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Medication info section (read-only)
                medicationInfoSection

                // Pattern selection section
                patternSelectionSection

                // Frequency stepper (if not custom)
                if selectedPattern != .custom {
                    frequencySection
                }

                // Reminder preferences section
                reminderPreferencesSection

                // Info footer if editing
                if existingSchedule != nil {
                    infoFooterSection
                }
            }
            .navigationTitle(existingSchedule == nil ? "Create Schedule" : "Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("cancel-schedule-edit")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingSchedule == nil ? "Create" : "Save") {
                        saveSchedule()
                    }
                    .disabled(isSaving)
                    .accessibilityIdentifier("save-schedule-edit")
                }
            }
        }
    }

    // MARK: - Sections

    /// Medication information (read-only)
    private var medicationInfoSection: some View {
        Section("Medication") {
            HStack {
                Text("Type")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(medicationProfile.medicationType.capitalized)
            }

            HStack {
                Text("Brand")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(medicationProfile.brandName)
            }

            HStack {
                Text("Current Dose")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(String(format: "%.2f", medicationProfile.currentDose)) mg")
            }
        }
    }

    /// Pattern selection picker
    private var patternSelectionSection: some View {
        Section {
            Picker("Pattern", selection: $selectedPattern) {
                Text("Weekly").tag(SchedulePatternType.weekly)
                Text("Split Dose").tag(SchedulePatternType.splitDose)
                Text("Custom").tag(SchedulePatternType.custom)
            }
            .pickerStyle(.inline)
            .accessibilityIdentifier("pattern-picker")
        } header: {
            Text("Schedule Pattern")
        } footer: {
            Text(patternFooterText)
        }
    }

    /// Interval stepper (days between doses)
    private var frequencySection: some View {
        Section {
            Stepper(
                value: $interval,
                in: 1...30
            ) {
                HStack {
                    Text("Interval")
                    Spacer()
                    Text("\(interval) day\(interval == 1 ? "" : "s")")
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("interval-stepper")
        } footer: {
            Text("Days between doses")
        }
    }

    /// Adherence window preferences
    private var reminderPreferencesSection: some View {
        Section {
            Stepper(
                value: $windowMinutesBefore,
                in: 0...240,
                step: 15
            ) {
                HStack {
                    Text("Window Before")
                    Spacer()
                    Text("\(windowMinutesBefore) min")
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("window-before-stepper")

            Stepper(
                value: $windowMinutesAfter,
                in: 0...240,
                step: 15
            ) {
                HStack {
                    Text("Window After")
                    Spacer()
                    Text("\(windowMinutesAfter) min")
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("window-after-stepper")
        } header: {
            Text("Adherence Window")
        } footer: {
            Text("Time window for on-time dose adherence")
        }
    }

    /// Info footer for editing existing schedule
    private var infoFooterSection: some View {
        Section {
            EmptyView()
        } footer: {
            Text(
                "Modifying this schedule will update all future scheduled doses. "
                    + "Past doses will remain unchanged."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helper Properties

    /// Footer text for pattern selection
    private var patternFooterText: String {
        switch selectedPattern {
        case .weekly:
            return "Doses scheduled on the same day and time each week"
        case .splitDose:
            return "Multiple doses per day (e.g., morning and evening)"
        case .custom:
            return "Fully customizable schedule with specific dates and times"
        }
    }

    // MARK: - Actions

    /// Save schedule configuration
    private func saveSchedule() {
        isSaving = true

        // Build schedule configuration based on pattern
        let config: ScheduleConfiguration

        switch selectedPattern {
        case .weekly:
            config = ScheduleConfiguration(
                dayOfWeek: dayOfWeek,
                timeOfDay: timeOfDay,
                interval: interval,
                doseAmount: medicationProfile.currentDose,
                windowMinutesBefore: windowMinutesBefore,
                windowMinutesAfter: windowMinutesAfter,
                splitDoseCount: nil,
                splitIntervalMinutes: nil,
                customRecurrence: nil
            )

        case .splitDose:
            config = ScheduleConfiguration(
                dayOfWeek: nil,
                timeOfDay: timeOfDay,
                interval: 1,  // Daily for split dose
                doseAmount: medicationProfile.currentDose,
                windowMinutesBefore: windowMinutesBefore,
                windowMinutesAfter: windowMinutesAfter,
                splitDoseCount: 2,  // Default: 2 doses per day
                splitIntervalMinutes: 720,  // 12 hours apart
                customRecurrence: nil
            )

        case .custom:
            // Basic custom configuration - user will need to configure via advanced editor
            config = ScheduleConfiguration(
                dayOfWeek: nil,
                timeOfDay: timeOfDay,
                interval: interval,
                doseAmount: medicationProfile.currentDose,
                windowMinutesBefore: windowMinutesBefore,
                windowMinutesAfter: windowMinutesAfter,
                splitDoseCount: nil,
                splitIntervalMinutes: nil,
                customRecurrence: nil
            )
        }

        // Call save callback
        onSave(config, selectedPattern)

        isSaving = false
        dismiss()
    }
}

// MARK: - Previews

#Preview("Create New Schedule") {
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(
        for: MedicationProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let profile = MedicationProfile(
        brandName: "Ozempic",
        currentDose: 0.25,
        startDate: Date(),
        medicationType: "semaglutide"
    )
    context.insert(profile)

    return DoseScheduleEditView(
        medicationProfile: profile,
        existingSchedule: nil,
        onSave: { _, _ in
            print("Schedule saved")
        }
    )
    .modelContainer(container)
}

#Preview("Edit Existing Schedule") {
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(
        for: MedicationProfile.self, DoseSchedule.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let profile = MedicationProfile(
        brandName: "Ozempic",
        currentDose: 0.25,
        startDate: Date(),
        medicationType: "semaglutide"
    )
    context.insert(profile)

    let config = ScheduleConfiguration(
        dayOfWeek: 1,
        timeOfDay: TimeComponents(hour: 8, minute: 0),
        interval: 7,
        doseAmount: 0.25,
        windowMinutesBefore: 120,
        windowMinutesAfter: 120,
        splitDoseCount: nil,
        splitIntervalMinutes: nil,
        customRecurrence: nil
    )

    // swiftlint:disable:next force_try
    let jsonData = try! JSONEncoder().encode(config)

    let schedule = DoseSchedule(
        medicationProfile: profile,
        patternType: .weekly,
        baseSchedule: jsonData,
        customScheduleData: nil
    )
    schedule.isActive = true
    context.insert(schedule)

    return DoseScheduleEditView(
        medicationProfile: profile,
        existingSchedule: schedule,
        onSave: { _, _ in
            print("Schedule updated")
        }
    )
    .modelContainer(container)
}
