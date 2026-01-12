//
//  ReminderPreferencesView.swift
//  JabTracker
//
//  Reminder configuration component for onboarding schedule setup
//

import SwiftUI

/// Component for configuring dose reminder preferences
///
/// Allows users to set reminder timing and enable multiple reminders.
/// Integrates with NotificationService for actual notification scheduling.
struct ReminderPreferencesView: View {
    @Binding var reminderMinutes: Int
    @Binding var enableMultiple: Bool

    // Optional parameters for showing calculated notification time
    var schedulePattern: SchedulePatternType?
    var doseTime: Date?
    var firstDoseTime: Date?
    var secondDoseTime: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reminders")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 16) {
                // Reminder timing picker
                HStack {
                    Text("Notify me")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Spacer()

                    Picker("Minutes Before", selection: $reminderMinutes) {
                        Text("15 min before").tag(15)
                        Text("30 min before").tag(30)
                        Text("1 hour before").tag(60)
                        Text("2 hours before").tag(120)
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("reminder-time-picker")
                    .accessibilityLabel("Reminder time")
                    .accessibilityValue(reminderTimeDescription)
                }

                Divider()

                // Multiple reminders toggle
                Toggle(isOn: $enableMultiple) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Send multiple reminders")
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Text("Get reminded again if you haven't logged your dose")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityLabel("Enable multiple reminders")
                .accessibilityHint("Sends additional reminders if dose is not logged")

                // Calculated notification time display
                if let notificationTimeText = calculatedNotificationTimeText {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notification Time")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(notificationTimeText)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .accessibilityIdentifier("calculated-notification-time")
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.cardBackground)
        )
    }

    /// Human-readable description of reminder time
    private var reminderTimeDescription: String {
        switch reminderMinutes {
        case 15:
            return "15 minutes before"
        case 30:
            return "30 minutes before"
        case 60:
            return "1 hour before"
        case 120:
            return "2 hours before"
        default:
            return "\(reminderMinutes) minutes before"
        }
    }

    /// Calculated notification time text showing when reminders will be sent
    private var calculatedNotificationTimeText: String? {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        if schedulePattern == .splitDose, let first = firstDoseTime, let second = secondDoseTime {
            // Split-dose: Show both notification times
            guard
                let firstNotification = Calendar.current.date(
                    byAdding: .minute,
                    value: -reminderMinutes,
                    to: first
                ),
                let secondNotification = Calendar.current.date(
                    byAdding: .minute,
                    value: -reminderMinutes,
                    to: second
                )
            else {
                return nil
            }

            let firstTime = formatter.string(from: firstNotification)
            let secondTime = formatter.string(from: secondNotification)
            return "You'll be notified at \(firstTime) and \(secondTime)"
        } else if let dose = doseTime {
            // Weekly/Daily: Show single notification time
            guard
                let notificationTime = Calendar.current.date(
                    byAdding: .minute,
                    value: -reminderMinutes,
                    to: dose
                )
            else {
                return nil
            }

            return "You'll be notified at \(formatter.string(from: notificationTime)) (\(reminderTimeDescription))"
        }

        return nil
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var reminderMinutes = 60
    @Previewable @State var enableMultiple = false

    VStack(spacing: 24) {
        ReminderPreferencesView(
            reminderMinutes: $reminderMinutes,
            enableMultiple: $enableMultiple
        )

        // Show current settings
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Settings:")
                .font(.headline)
            Text("Reminder: \(reminderMinutes) minutes before")
            Text("Multiple: \(enableMultiple ? "Enabled" : "Disabled")")
        }
        .padding()
        .background(DesignTokens.Colors.primary.opacity(0.1))
        .cornerRadius(8)
    }
    .padding()
}
