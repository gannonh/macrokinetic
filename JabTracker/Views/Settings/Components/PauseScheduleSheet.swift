//
//  PauseScheduleSheet.swift
//  JabTracker
//
//  Sheet component for pausing a medication schedule with duration options.
//

import SwiftUI

/// Duration options for pausing a schedule
enum PauseDuration: String, CaseIterable, Identifiable {
    case oneWeek = "1_week"
    case twoWeeks = "2_weeks"
    case oneMonth = "1_month"
    case custom
    case indefinite

    var id: String { rawValue }

    /// User-facing display name
    var displayName: String {
        switch self {
        case .oneWeek:
            return "1 Week"
        case .twoWeeks:
            return "2 Weeks"
        case .oneMonth:
            return "1 Month"
        case .custom:
            return "Custom"
        case .indefinite:
            return "Indefinitely"
        }
    }

    /// Calculate the end date for this duration from a given start date
    ///
    /// - Parameter startDate: The date to calculate from (typically now)
    /// - Returns: The calculated end date, or nil for custom/indefinite
    func calculateEndDate(from startDate: Date) -> Date? {
        let calendar = Calendar.current

        switch self {
        case .oneWeek:
            return calendar.date(byAdding: .day, value: 7, to: startDate)
        case .twoWeeks:
            return calendar.date(byAdding: .day, value: 14, to: startDate)
        case .oneMonth:
            return calendar.date(byAdding: .month, value: 1, to: startDate)
        case .custom:
            return nil  // User selects date via DatePicker
        case .indefinite:
            return nil  // No end date
        }
    }
}

/// Sheet for selecting schedule pause duration
struct PauseScheduleSheet: View {
    // MARK: - Properties

    /// Currently selected pause duration
    @State private var selectedDuration: PauseDuration = .oneWeek

    /// Custom end date when .custom is selected
    @State private var customEndDate: Date =
        Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()

    /// Completion handler called when user confirms pause
    let onPause: (Date?) -> Void

    /// Dismissal action
    @Environment(\.dismiss) private var dismiss

    // MARK: - Private Properties

    /// Minimum date for custom picker (tomorrow)
    private var minimumDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Duration", selection: $selectedDuration) {
                        ForEach(PauseDuration.allCases) { duration in
                            Text(duration.displayName).tag(duration)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("pause-duration-picker")
                }

                if selectedDuration == .custom {
                    Section {
                        DatePicker(
                            "Resume Date",
                            selection: $customEndDate,
                            in: minimumDate...,
                            displayedComponents: .date
                        )
                        .accessibilityIdentifier("custom-end-date-picker")
                    }
                }

                Section {
                    Text("Scheduled doses and reminders will be paused. You can still log doses manually.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Pause Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("pause-cancel-button")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Pause") {
                        confirmPause()
                    }
                    .accessibilityIdentifier("pause-confirm-button")
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    /// Confirms the pause and calls completion handler
    private func confirmPause() {
        let endDate: Date?

        switch selectedDuration {
        case .custom:
            endDate = customEndDate
        case .indefinite:
            endDate = nil
        default:
            endDate = selectedDuration.calculateEndDate(from: Date())
        }

        onPause(endDate)
        dismiss()
    }
}

// MARK: - Previews

#Preview("One Week Selected") {
    PauseScheduleSheet { date in
        print("Paused until: \(date?.formatted(date: .abbreviated, time: .omitted) ?? "indefinite")")
    }
}

#Preview("Custom Selected") {
    struct PreviewWrapper: View {
        @State private var showSheet = true

        var body: some View {
            Color.clear
                .sheet(isPresented: $showSheet) {
                    PauseScheduleSheet { date in
                        print("Paused until: \(date?.formatted(date: .abbreviated, time: .omitted) ?? "indefinite")")
                    }
                }
        }
    }

    return PreviewWrapper()
}

#Preview("Indefinite Selected") {
    PauseScheduleSheet { date in
        print("Paused until: \(date?.formatted(date: .abbreviated, time: .omitted) ?? "indefinite")")
    }
}
