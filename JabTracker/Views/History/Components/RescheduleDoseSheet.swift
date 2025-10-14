//
//  RescheduleDoseSheet.swift
//  JabTracker
//
//  Sheet for rescheduling doses with date picker and smart suggestions
//  Stream B: Action Sheet UI & Dose Management (Issue #178)
//

import SwiftData
import SwiftUI

/// Sheet for rescheduling a scheduled dose with date/time picker and smart suggestions
///
/// Provides date picker with future-only validation and quick suggestion buttons
/// for common reschedule scenarios (tomorrow, +24h, +48h).
struct RescheduleDoseSheet: View {
    let scheduledDose: ScheduledDose
    let onRescheduled: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var newDate: Date
    @State private var isRescheduling = false

    init(scheduledDose: ScheduledDose, onRescheduled: @escaping () -> Void) {
        self.scheduledDose = scheduledDose
        self.onRescheduled = onRescheduled

        // Initialize with smart suggestion (+24 hours)
        _newDate = State(initialValue: scheduledDose.scheduledTime.addingTimeInterval(24 * 60 * 60))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Date picker section
                Section {
                    DatePicker(
                        "Date",
                        selection: $newDate,
                        in: Date()...,  // Prevent past dates
                        displayedComponents: .date
                    )
                    .accessibilityIdentifier("reschedule-date-picker")
                    .accessibilityLabel("Select new date")

                    DatePicker(
                        "Time",
                        selection: $newDate,
                        displayedComponents: .hourAndMinute
                    )
                    .accessibilityIdentifier("reschedule-time-picker")
                    .accessibilityLabel("Select new time")
                } header: {
                    Text("New Date & Time")
                }

                // Quick options section
                Section("Quick Options") {
                    Button("Tomorrow, Same Time") {
                        if let tomorrow = Calendar.current.date(
                            byAdding: .day,
                            value: 1,
                            to: scheduledDose.scheduledTime
                        ) {
                            newDate = tomorrow
                        }
                    }
                    .accessibilityIdentifier("reschedule-tomorrow-button")
                    .accessibilityLabel("Tomorrow, same time")
                    .accessibilityHint("Reschedule to tomorrow at the same time")

                    Button("In 24 Hours") {
                        newDate = scheduledDose.scheduledTime.addingTimeInterval(24 * 60 * 60)
                    }
                    .accessibilityIdentifier("reschedule-24h-button")
                    .accessibilityLabel("In 24 hours")
                    .accessibilityHint("Reschedule to exactly 24 hours from original time")

                    Button("In 48 Hours") {
                        newDate = scheduledDose.scheduledTime.addingTimeInterval(48 * 60 * 60)
                    }
                    .accessibilityIdentifier("reschedule-48h-button")
                    .accessibilityLabel("In 48 hours")
                    .accessibilityHint("Reschedule to exactly 48 hours from original time")
                }

                // Current schedule section
                Section("Current Schedule") {
                    HStack {
                        Text("Currently scheduled")
                        Spacer()
                        Text(scheduledDose.scheduledTime.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    .accessibilityIdentifier("reschedule-current-time")

                    HStack {
                        Text("New schedule")
                        Spacer()
                        Text(newDate.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.accentColor)
                            .bold()
                    }
                    .font(.caption)
                    .accessibilityIdentifier("reschedule-new-time")
                }
            }
            .navigationTitle("Reschedule Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("reschedule-cancel")
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isRescheduling {
                        ProgressView()
                    } else {
                        Button("Reschedule") {
                            reschedule()
                        }
                        .disabled(newDate <= Date())  // Prevent past dates
                        .accessibilityIdentifier("reschedule-confirm")
                        .accessibilityLabel("Confirm reschedule")
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .accessibilityIdentifier("reschedule-dose-sheet")
    }

    // MARK: - Actions

    private func reschedule() {
        isRescheduling = true

        // Reschedule the dose
        scheduledDose.reschedule(to: newDate)

        // Small delay for UI feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isRescheduling = false
            onRescheduled()
            dismiss()
        }
    }
}

#Preview {
    let profile = MedicationProfile(
        genericName: "semaglutide",
        brandName: "Ozempic",
        currentDose: 0.5
    )

    let schedule = DoseSchedule(
        medicationProfile: profile,
        patternType: .weekly
    )

    let scheduledTime = Date()
    let scheduledDose = ScheduledDose(
        scheduledTime: scheduledTime,
        doseAmount: 0.5,
        windowStart: scheduledTime.addingTimeInterval(-2 * 60 * 60),
        windowEnd: scheduledTime.addingTimeInterval(2 * 60 * 60)
    )
    scheduledDose.schedule = schedule

    return RescheduleDoseSheet(
        scheduledDose: scheduledDose,
        onRescheduled: {
            print("Rescheduled")
        }
    )
    .modelContainer(DataController.preview.container)
}
