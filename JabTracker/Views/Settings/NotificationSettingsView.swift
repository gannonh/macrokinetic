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
                        Task { try? await service.scheduleWeighInDailyReminder() }
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
                            Task { try? await service.scheduleWeighInDailyReminder() }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
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
                        Task { try? await service.scheduleWeighInWeeklyReminder() }
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
                            Task { try? await service.scheduleWeighInWeeklyReminder() }
                        }
                    )
                ) {
                    ForEach(weekdayOptions, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }

                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { notificationService?.weighInWeeklyTime ?? Date() },
                        set: { newValue in
                            guard let service = notificationService else { return }
                            service.weighInWeeklyTime = newValue
                            service.saveState()
                            Task { try? await service.scheduleWeighInWeeklyReminder() }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text("Weigh-in Reminders")
        } footer: {
            Text("Get reminded to log your weight regularly.")
        }
    }

    // MARK: - Food Logging Section

    private var foodLoggingSection: some View {
        Section {
            // Breakfast reminder
            Toggle(
                "Breakfast",
                isOn: Binding(
                    get: { notificationService?.breakfastReminderEnabled ?? false },
                    set: { newValue in
                        guard let service = notificationService else { return }
                        service.breakfastReminderEnabled = newValue
                        service.saveState()
                        Task { try? await service.refreshFoodLoggingReminders() }
                    }
                )
            )
            .accessibilityIdentifier("breakfast-reminder-toggle")

            if notificationService?.breakfastReminderEnabled == true {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { notificationService?.breakfastReminderTime ?? Date() },
                        set: { newValue in
                            guard let service = notificationService else { return }
                            service.breakfastReminderTime = newValue
                            service.saveState()
                            Task { try? await service.refreshFoodLoggingReminders() }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }

            // Lunch reminder
            Toggle(
                "Lunch",
                isOn: Binding(
                    get: { notificationService?.lunchReminderEnabled ?? false },
                    set: { newValue in
                        guard let service = notificationService else { return }
                        service.lunchReminderEnabled = newValue
                        service.saveState()
                        Task { try? await service.refreshFoodLoggingReminders() }
                    }
                )
            )
            .accessibilityIdentifier("lunch-reminder-toggle")

            if notificationService?.lunchReminderEnabled == true {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { notificationService?.lunchReminderTime ?? Date() },
                        set: { newValue in
                            guard let service = notificationService else { return }
                            service.lunchReminderTime = newValue
                            service.saveState()
                            Task { try? await service.refreshFoodLoggingReminders() }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }

            // Snack reminder
            Toggle(
                "Snack",
                isOn: Binding(
                    get: { notificationService?.snackReminderEnabled ?? false },
                    set: { newValue in
                        guard let service = notificationService else { return }
                        service.snackReminderEnabled = newValue
                        service.saveState()
                        Task { try? await service.refreshFoodLoggingReminders() }
                    }
                )
            )
            .accessibilityIdentifier("snack-reminder-toggle")

            if notificationService?.snackReminderEnabled == true {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { notificationService?.snackReminderTime ?? Date() },
                        set: { newValue in
                            guard let service = notificationService else { return }
                            service.snackReminderTime = newValue
                            service.saveState()
                            Task { try? await service.refreshFoodLoggingReminders() }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }

            // Dinner reminder
            Toggle(
                "Dinner",
                isOn: Binding(
                    get: { notificationService?.dinnerReminderEnabled ?? false },
                    set: { newValue in
                        guard let service = notificationService else { return }
                        service.dinnerReminderEnabled = newValue
                        service.saveState()
                        Task { try? await service.refreshFoodLoggingReminders() }
                    }
                )
            )
            .accessibilityIdentifier("dinner-reminder-toggle")

            if notificationService?.dinnerReminderEnabled == true {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { notificationService?.dinnerReminderTime ?? Date() },
                        set: { newValue in
                            guard let service = notificationService else { return }
                            service.dinnerReminderTime = newValue
                            service.saveState()
                            Task { try? await service.refreshFoodLoggingReminders() }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }

            Divider()

            // End of day reminder
            Toggle(
                "End of Day",
                isOn: Binding(
                    get: { notificationService?.endOfDayReminderEnabled ?? false },
                    set: { newValue in
                        guard let service = notificationService else { return }
                        service.endOfDayReminderEnabled = newValue
                        service.saveState()
                        Task { try? await service.refreshFoodLoggingReminders() }
                    }
                )
            )
            .accessibilityIdentifier("end-of-day-reminder-toggle")

            if notificationService?.endOfDayReminderEnabled == true {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { notificationService?.endOfDayReminderTime ?? Date() },
                        set: { newValue in
                            guard let service = notificationService else { return }
                            service.endOfDayReminderTime = newValue
                            service.saveState()
                            Task { try? await service.refreshFoodLoggingReminders() }
                        }
                    ),
                    displayedComponents: .hourAndMinute
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
                        service.notificationsEnabled = newValue
                        service.saveState()
                        Task {
                            if newValue {
                                try? await service.enable()
                            } else {
                                await service.disable()
                            }
                        }
                    }
                )
            )
            .accessibilityIdentifier("dose-reminder-toggle")

            if notificationService?.notificationsEnabled == true,
                let service = notificationService
            {
                ReminderTimingPicker(
                    selectedMinutes: Binding(
                        get: { service.reminderMinutesBefore },
                        set: { newValue in
                            service.reminderMinutesBefore = newValue
                            service.saveState()
                            Task { try? await service.updateReminderTiming(newValue) }
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
