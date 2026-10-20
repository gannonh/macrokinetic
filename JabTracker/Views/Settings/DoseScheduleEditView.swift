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
    /// A new schedule needs an explicit Daily or Weekly choice when drug-default patterns are off.
    @State var hasChosenPattern: Bool

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

    /// Error state for validation
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

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
        // For new schedules, set pattern based on medication frequency
        let defaultPattern: SchedulePatternType
        if let existingPattern = existingSchedule?.patternType {
            defaultPattern = existingPattern
        } else if ReleasePolicy.isEnabled(.medicalCalculators), medicationProfile.medication?.frequency == .daily {
            defaultPattern = .daily
        } else {
            defaultPattern = .weekly
        }
        _selectedPattern = State(initialValue: defaultPattern)
        _hasChosenPattern = State(
            initialValue: existingSchedule != nil || ReleasePolicy.isEnabled(.medicalCalculators))

        // Parse existing schedule baseSchedule configuration if editing
        if let schedule = existingSchedule,
            let config = try? JSONDecoder().decode(ScheduleConfiguration.self, from: schedule.baseSchedule)
        {
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
            _windowMinutesBefore = State(initialValue: TimeConstants.defaultWindowMinutes)
            _windowMinutesAfter = State(initialValue: TimeConstants.defaultWindowMinutes)
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

                // Frequency stepper (only for weekly pattern)
                // Split-dose has fixed 3.5-day interval, custom has its own config
                if selectedPattern == .weekly, hasChosenPattern {
                    frequencySection
                }

                if let summary = splitSummary {
                    splitAmountsSection(summary)
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
                    .disabled(isSaving || !hasChosenPattern)
                    .accessibilityIdentifier("save-schedule-edit")
                }
            }
            .alert("Invalid Input", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

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
                Text("\(RecordedAmountInput.displayText(for: medicationProfile.currentDose)) mg")
            }
        }
    }

    /// Pattern selection picker
    private var patternSelectionSection: some View {
        Section {
            Picker("Pattern", selection: patternSelection) {
                // Show patterns based on medication frequency
                if !ReleasePolicy.isEnabled(.medicalCalculators) {
                    Text("Daily").tag(SchedulePatternType?.some(.daily))
                    Text("Weekly").tag(SchedulePatternType?.some(.weekly))
                    if existingSchedule?.patternType == .splitDose {
                        Text("Recorded Split Schedule").tag(SchedulePatternType?.some(.splitDose))
                    } else if existingSchedule?.patternType == .custom {
                        Text("Recorded Custom Schedule").tag(SchedulePatternType?.some(.custom))
                    }
                } else if medicationProfile.medication?.frequency == .daily {
                    Text("Daily").tag(SchedulePatternType?.some(.daily))
                } else {
                    // Weekly medications
                    Text("Weekly").tag(SchedulePatternType?.some(.weekly))
                    Text("Split Dose").tag(SchedulePatternType?.some(.splitDose))
                }
                // Custom pattern removed from UI
            }
            .pickerStyle(.inline)
            .accessibilityIdentifier("pattern-picker")
        } header: {
            Text("Schedule Pattern")
        } footer: {
            Text(patternFooterText)
        }
    }

    /// States the amount of one administration and the weekly total of a split schedule
    private func splitAmountsSection(_ summary: SplitDoseSummary) -> some View {
        Section {
            HStack {
                Text("Per administration")
                Spacer()
                Text("\(RecordedAmountInput.displayText(for: summary.perAdministration)) mg")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("split-per-administration")
            }
            HStack {
                Text("Administrations per week")
                Spacer()
                Text("\(summary.administrations)")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("split-administrations-per-week")
            }
            HStack {
                Text("Weekly total")
                Spacer()
                Text("\(RecordedAmountInput.displayText(for: summary.weeklyTotal)) mg")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("split-weekly-total")
            }
        } header: {
            Text("Split Amounts")
        } footer: {
            Text("The weekly total is the sum of all administrations in a week.")
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

    /// Nil until the user picks a pattern for a new schedule, so no pattern is preselected.
    private var patternSelection: Binding<SchedulePatternType?> {
        Binding(
            get: { hasChosenPattern ? selectedPattern : nil },
            set: { newValue in
                guard let newValue else { return }
                selectedPattern = newValue
                hasChosenPattern = true
            }
        )
    }

    /// Footer text for pattern selection
    private var patternFooterText: String {
        if !ReleasePolicy.isEnabled(.medicalCalculators) {
            return "Record the schedule prescribed by your clinician. This app does not recommend a dosing schedule."
        }
        switch selectedPattern {
        case .daily:
            return "Doses scheduled at the same time each day"
        case .weekly:
            return "Doses scheduled on the same day and time each week"
        case .splitDose:
            return "Divide the weekly total into two equal administrations 3.5 days apart"
        case .custom:
            return "Fully customizable schedule with specific dates and times"
        }
    }

    /// Validate user inputs before saving
    /// - Returns: Error message if validation fails, nil if all inputs are valid
    private func validateInputs() -> String? {
        // Validate day of week (1-7, Monday-Sunday)
        if selectedPattern == .weekly && (dayOfWeek < 1 || dayOfWeek > 7) {
            return "Please select a valid day of the week (1-7)"
        }

        // Validate time of day
        if timeOfDay.hour < 0 || timeOfDay.hour > 23 {
            return "Please select a valid hour (0-23)"
        }

        if timeOfDay.minute < 0 || timeOfDay.minute > 59 {
            return "Please select a valid minute (0-59)"
        }

        // Validate interval
        if interval < 1 {
            return "Interval must be at least 1 day"
        }

        // Validate adherence windows (must be positive)
        if windowMinutesBefore < 0 {
            return "Adherence window before dose must be positive"
        }

        if windowMinutesAfter < 0 {
            return "Adherence window after dose must be positive"
        }

        return nil  // All validations passed
    }

    /// Save schedule configuration
    private func saveSchedule() {
        isSaving = true
        if !ReleasePolicy.isEnabled(.medicalCalculators),
            selectedPattern == .splitDose || selectedPattern == .custom,
            existingSchedule?.patternType != selectedPattern
        {
            errorMessage = "Choose a supported prescribed schedule"
            showError = true
            isSaving = false
            return
        }

        // Validate inputs first
        if let error = validateInputs() {
            errorMessage = error
            showError = true
            isSaving = false
            return
        }

        guard let config = scheduleConfiguration else {
            errorMessage = "The recorded schedule could not be read"
            showError = true
            isSaving = false
            return
        }
        onSave(config, selectedPattern)
        isSaving = false
        dismiss()
    }

    var scheduleConfiguration: ScheduleConfiguration? {
        configuration(for: selectedPattern)
    }

    /// Administration amount, count and weekly total shown while the split pattern is selected.
    var splitSummary: SplitDoseSummary? {
        guard selectedPattern == .splitDose else { return nil }
        return configuration(for: .splitDose)?.splitSummary
    }

    func configuration(for pattern: SchedulePatternType) -> ScheduleConfiguration? {
        if !ReleasePolicy.isEnabled(.medicalCalculators),
            pattern == .splitDose || pattern == .custom
        {
            guard existingSchedule?.patternType == pattern else { return nil }
            return preservedRecordedConfiguration
        }
        let amount = medicationProfile.currentDose
        switch pattern {
        case .daily:
            return ScheduleConfiguration(
                dayOfWeek: nil,
                timeOfDay: timeOfDay,
                secondTimeOfDay: nil,
                interval: 1,
                doseAmount: amount,
                windowMinutesBefore: windowMinutesBefore,
                windowMinutesAfter: windowMinutesAfter,
                splitDoseCount: nil,
                splitIntervalMinutes: nil,
                customRecurrence: nil
            )
        case .weekly:
            return ScheduleConfiguration(
                dayOfWeek: dayOfWeek,
                timeOfDay: timeOfDay,
                secondTimeOfDay: nil,
                interval: interval,
                doseAmount: amount,
                windowMinutesBefore: windowMinutesBefore,
                windowMinutesAfter: windowMinutesAfter,
                splitDoseCount: nil,
                splitIntervalMinutes: nil,
                customRecurrence: nil
            )
        case .splitDose:
            // The profile dose is the weekly total; the schedule holds the amount of one administration.
            return .splitDose(
                weeklyTotal: medicationProfile.currentDose,
                timeOfDay: timeOfDay,
                windowMinutesBefore: windowMinutesBefore,
                windowMinutesAfter: windowMinutesAfter
            )
        case .custom:
            return ScheduleConfiguration(
                dayOfWeek: nil,
                timeOfDay: timeOfDay,
                secondTimeOfDay: nil,
                interval: interval,
                doseAmount: amount,
                windowMinutesBefore: windowMinutesBefore,
                windowMinutesAfter: windowMinutesAfter,
                splitDoseCount: nil,
                splitIntervalMinutes: nil,
                customRecurrence: nil
            )
        }
    }

    var preservedRecordedConfiguration: ScheduleConfiguration? {
        guard let existingSchedule,
            let recorded = try? JSONDecoder().decode(ScheduleConfiguration.self, from: existingSchedule.baseSchedule)
        else { return nil }
        return ScheduleConfiguration(
            dayOfWeek: recorded.dayOfWeek,
            timeOfDay: timeOfDay,
            secondTimeOfDay: recorded.secondTimeOfDay,
            interval: recorded.interval,
            doseAmount: recorded.doseAmount,
            windowMinutesBefore: windowMinutesBefore,
            windowMinutesAfter: windowMinutesAfter,
            splitDoseCount: recorded.splitDoseCount,
            splitIntervalMinutes: recorded.splitIntervalMinutes,
            customRecurrence: recorded.customRecurrence
        )
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
        secondTimeOfDay: nil,  // Not used in preview
        interval: 7,
        doseAmount: 0.25,
        windowMinutesBefore: TimeConstants.defaultWindowMinutes,
        windowMinutesAfter: TimeConstants.defaultWindowMinutes,
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
