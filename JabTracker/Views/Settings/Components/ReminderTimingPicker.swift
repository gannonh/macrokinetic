import SwiftUI

/// A picker component for selecting dose reminder timing preferences.
///
/// Provides options for scheduling notifications before the scheduled dose time:
/// - 15 minutes before
/// - 30 minutes before
/// - 1 hour before (default)
/// - 2 hours before
///
/// Usage:
/// ```swift
/// @State private var reminderMinutes = 60
///
/// ReminderTimingPicker(selectedMinutes: $reminderMinutes)
/// ```
struct ReminderTimingPicker: View {
    /// Binding to the selected reminder timing in minutes
    @Binding var selectedMinutes: Int

    /// Available reminder timing options
    private let reminderOptions = [
        (value: 15, label: "15 minutes before"),
        (value: 30, label: "30 minutes before"),
        (value: 60, label: "1 hour before"),
        (value: 120, label: "2 hours before"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminder Timing")
                .font(DesignTokens.Typography.body)

            Picker("Reminder Timing", selection: $selectedMinutes) {
                ForEach(reminderOptions, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("reminder-timing-picker")
        }
    }
}

#Preview {
    @Previewable @State var minutes = 60

    DesignCard {
        ReminderTimingPicker(selectedMinutes: $minutes)
    }
    .padding()
}
