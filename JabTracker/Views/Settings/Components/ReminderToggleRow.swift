import OSLog
import SwiftUI

private let logger = Logger(
    subsystem: "com.gannonhall.JabTracker",
    category: "ReminderToggleRow"
)

/// Reusable reminder toggle row with conditional time picker and error handling.
///
/// Encapsulates the common pattern of:
/// - Toggle for enabling/disabling a reminder
/// - Conditional DatePicker when enabled
/// - Proper error handling for async scheduling operations
/// - Accessibility identifiers for testing
struct ReminderToggleRow: View {
    let label: String
    let toggleIdentifier: String
    let timePickerIdentifier: String
    @Binding var isEnabled: Bool
    @Binding var time: Date
    let onToggle: (Bool) async throws -> Void
    let onTimeChange: (Date) async throws -> Void

    @State private var errorMessage: String?

    var body: some View {
        Group {
            Toggle(
                label,
                isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        isEnabled = newValue
                        Task {
                            do {
                                try await onToggle(newValue)
                            } catch {
                                logger.error("Failed to toggle \(label) reminder: \(error)")
                                errorMessage = "Failed to update reminder: \(error.localizedDescription)"
                            }
                        }
                    }
                )
            )
            .accessibilityIdentifier(toggleIdentifier)

            if isEnabled {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { time },
                        set: { newValue in
                            time = newValue
                            Task {
                                do {
                                    try await onTimeChange(newValue)
                                } catch {
                                    logger.error("Failed to update \(label) time: \(error)")
                                    errorMessage = "Failed to update time: \(error.localizedDescription)"
                                }
                            }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .accessibilityIdentifier(timePickerIdentifier)
            }
        }
        .alert("Notification Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }
}
