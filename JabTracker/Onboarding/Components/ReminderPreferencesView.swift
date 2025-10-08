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
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
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
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    .padding()
}
