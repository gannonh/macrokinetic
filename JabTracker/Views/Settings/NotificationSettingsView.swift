import SwiftUI
import UserNotifications

/// Comprehensive notification settings view for all reminder types.
///
/// Provides configuration for:
/// - Weigh-in reminders (daily and weekly)
/// - Food logging reminders (breakfast, lunch, snack, dinner, end of day)
/// - Medication dose reminders
/// - Notification authorization status
///
/// Settings are persisted to UserDefaults and notifications are scheduled/cancelled
/// immediately when toggles or times change.
struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // Access NotificationService from AppServices
    private var notificationService: NotificationService? {
        AppServices.shared.notificationService
    }

    // Error state
    @State private var weighInError: String?
    @State private var medicationError: String?

    // Weekday options for weekly weigh-in picker
    private let weekdayOptions = [
        (value: 1, label: "Sunday"),
        (value: 2, label: "Monday"),
        (value: 3, label: "Tuesday"),
        (value: 4, label: "Wednesday"),
        (value: 5, label: "Thursday"),
        (value: 6, label: "Friday"),
        (value: 7, label: "Saturday"),
    ]

    var body: some View {
        List {
            // Weigh-in Reminders
            weighInSection

            // Food Logging Reminders
            foodLoggingSection

            // Medication Dose Reminders
            medicationSection

            // Authorization Status
            statusSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("notification-settings-view")
    }

    // MARK: - Weigh-in Section

    private var weighInSection: some View {
        Section {
            // Daily weigh-in toggle
            Toggle(
                "Daily",
                isOn: Binding(
                    get: { notificationService?.weighInDailyEnabled ?? false },
                    set: { newValue in
                        guard let service = notificationService else { return }
                        service.weighInDailyEnabled = newValue
                        service.saveState()
                        Task {
                            do {
                                try await service.scheduleWeighInDailyReminder()
                            } catch {
                                weighInError = "Failed to schedule daily reminder: \(error.localizedDescription)"
                            }
                        }
                    }
                )
            )
            .accessibilityIdentifier("weigh-in-daily-toggle")

            if notificationService?.weighInDailyEnabled == true {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { notificationService?.weighInDailyTime ?? Date() },
                        set: { newValue in
                            guard let service = notificationService else { return }
                            service.weighInDailyTime = newValue
                            service.saveState()
                            Task {
                                do {
                                    try await service.scheduleWeighInDailyReminder()
                                } catch {
                                    weighInError = "Failed to update time: \(error.localizedDescription)"
                                }
                            }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .accessibilityIdentifier("weigh-in-daily-time-picker")
            }

            // Weekly weigh-in toggle
            Toggle(
                "Weekly",
                isOn: Binding(
                    get: { notificationService?.weighInWeeklyEnabled ?? false },
                    set: { newValue in
                        guard let service = notificationService else { return }
                        service.weighInWeeklyEnabled = newValue
                        service.saveState()
                        Task {
                            do {
                                try await service.scheduleWeighInWeeklyReminder()
                            } catch {
                                weighInError = "Failed to schedule weekly reminder: \(error.localizedDescription)"
                            }
                        }
                    }
                )
            )
            .accessibilityIdentifier("weigh-in-weekly-toggle")

            if notificationService?.weighInWeeklyEnabled == true {
                Picker(
                    "Day",
                    selection: Binding(
                        get: { notificationService?.weighInWeeklyDay ?? 2 },
                        set: { newValue in
                            guard let service = notificationService else { return }
                            service.weighInWeeklyDay = newValue
                            service.saveState()
                            Task {
                                do {
                                    try await service.scheduleWeighInWeeklyReminder()
                                } catch {
                                    weighInError = "Failed to update day: \(error.localizedDescription)"
                                }
                            }
                        }
                    )
                ) {
                    ForEach(weekdayOptions, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                .accessibilityIdentifier("weigh-in-weekly-day-picker")

                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { notificationService?.weighInWeeklyTime ?? Date() },
                        set: { newValue in
                            guard let service = notificationService else { return }
                            service.weighInWeeklyTime = newValue
                            service.saveState()
                            Task {
                                do {
                                    try await service.scheduleWeighInWeeklyReminder()
                                } catch {
                                    weighInError = "Failed to update time: \(error.localizedDescription)"
                                }
                            }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .accessibilityIdentifier("weigh-in-weekly-time-picker")
            }
        } header: {
            Text("Weigh-in Reminders")
        } footer: {
            Text("Get reminded to log your weight regularly.")
        }
        .alert("Notification Error", isPresented: .constant(weighInError != nil)) {
            Button("OK") { weighInError = nil }
        } message: {
            if let weighInError {
                Text(weighInError)
            }
        }
    }

    // MARK: - Food Logging Section

    private var foodLoggingSection: some View {
        Section {
            if let service = notificationService {
                // Breakfast reminder
                ReminderToggleRow(
                    label: "Breakfast",
                    toggleIdentifier: "breakfast-reminder-toggle",
                    timePickerIdentifier: "breakfast-time-picker",
                    isEnabled: Binding(
                        get: { service.breakfastReminderEnabled },
                        set: { service.breakfastReminderEnabled = $0 }
                    ),
                    time: Binding(
                        get: { service.breakfastReminderTime },
                        set: { service.breakfastReminderTime = $0 }
                    ),
                    onToggle: { _ in
                        service.saveState()
                        try await service.refreshFoodLoggingReminders()
                    },
                    onTimeChange: { _ in
                        service.saveState()
                        try await service.refreshFoodLoggingReminders()
                    }
                )

                // Lunch reminder
                ReminderToggleRow(
                    label: "Lunch",
                    toggleIdentifier: "lunch-reminder-toggle",
                    timePickerIdentifier: "lunch-time-picker",
                    isEnabled: Binding(
                        get: { service.lunchReminderEnabled },
                        set: { service.lunchReminderEnabled = $0 }
                    ),
                    time: Binding(
                        get: { service.lunchReminderTime },
                        set: { service.lunchReminderTime = $0 }
                    ),
                    onToggle: { _ in
                        service.saveState()
                        try await service.refreshFoodLoggingReminders()
                    },
                    onTimeChange: { _ in
                        service.saveState()
                        try await service.refreshFoodLoggingReminders()
                    }
                )

                // Snack reminder
                ReminderToggleRow(
                    label: "Snack",
                    toggleIdentifier: "snack-reminder-toggle",
                    timePickerIdentifier: "snack-time-picker",
                    isEnabled: Binding(
                        get: { service.snackReminderEnabled },
                        set: { service.snackReminderEnabled = $0 }
                    ),
                    time: Binding(
                        get: { service.snackReminderTime },
                        set: { service.snackReminderTime = $0 }
                    ),
                    onToggle: { _ in
                        service.saveState()
                        try await service.refreshFoodLoggingReminders()
                    },
                    onTimeChange: { _ in
                        service.saveState()
                        try await service.refreshFoodLoggingReminders()
                    }
                )

                // Dinner reminder
                ReminderToggleRow(
                    label: "Dinner",
                    toggleIdentifier: "dinner-reminder-toggle",
                    timePickerIdentifier: "dinner-time-picker",
                    isEnabled: Binding(
                        get: { service.dinnerReminderEnabled },
                        set: { service.dinnerReminderEnabled = $0 }
                    ),
                    time: Binding(
                        get: { service.dinnerReminderTime },
                        set: { service.dinnerReminderTime = $0 }
                    ),
                    onToggle: { _ in
                        service.saveState()
                        try await service.refreshFoodLoggingReminders()
                    },
                    onTimeChange: { _ in
                        service.saveState()
                        try await service.refreshFoodLoggingReminders()
                    }
                )

                Divider()

                // End of day reminder
                ReminderToggleRow(
                    label: "End of Day",
                    toggleIdentifier: "end-of-day-reminder-toggle",
                    timePickerIdentifier: "end-of-day-time-picker",
                    isEnabled: Binding(
                        get: { service.endOfDayReminderEnabled },
                        set: { service.endOfDayReminderEnabled = $0 }
                    ),
                    time: Binding(
                        get: { service.endOfDayReminderTime },
                        set: { service.endOfDayReminderTime = $0 }
                    ),
                    onToggle: { _ in
                        service.saveState()
                        try await service.refreshFoodLoggingReminders()
                    },
                    onTimeChange: { _ in
                        service.saveState()
                        try await service.refreshFoodLoggingReminders()
                    }
                )
            }
        } header: {
            Text("Food Logging")
        } footer: {
            if notificationService?.endOfDayReminderEnabled == true {
                Text("Get one daily reminder and log all your meals at once.")
            } else {
                Text("Get reminded to log your meals throughout the day.")
            }
        }
    }

    // MARK: - Medication Section

    private var medicationSection: some View {
        Section {
            Toggle(
                "Dose Reminders",
                isOn: Binding(
                    get: { notificationService?.notificationsEnabled ?? false },
                    set: { newValue in
                        guard let service = notificationService else { return }
                        Task {
                            do {
                                if newValue {
                                    try await service.enable()
                                } else {
                                    await service.disable()
                                }
                            } catch {
                                medicationError = "Failed to update reminder: \(error.localizedDescription)"
                            }
                        }
                    }
                )
            )
            .accessibilityIdentifier("dose-reminder-toggle")
            .alert("Notification Error", isPresented: .constant(medicationError != nil)) {
                Button("OK") { medicationError = nil }
            } message: {
                if let medicationError {
                    Text(medicationError)
                }
            }

            if notificationService?.notificationsEnabled == true,
                let service = notificationService
            {
                ReminderTimingPicker(
                    selectedMinutes: Binding(
                        get: { service.reminderMinutesBefore },
                        set: { newValue in
                            service.reminderMinutesBefore = newValue
                            service.saveState()
                            Task {
                                do {
                                    try await service.updateReminderTiming(newValue)
                                } catch {
                                    medicationError = "Failed to update timing: \(error.localizedDescription)"
                                }
                            }
                        }
                    ))
            }
        } header: {
            Text("Medication")
        } footer: {
            Text("Get reminded to take your GLP-1 medication.")
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        Section {
            if let service = notificationService {
                NotificationAuthorizationStatus(status: service.authorizationStatus)
            }
        } header: {
            Text("Status")
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
