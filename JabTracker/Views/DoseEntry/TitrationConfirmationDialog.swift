//
//  TitrationConfirmationDialog.swift
//  JabTracker
//
//  Confirmation dialog shown when user attempts to log a dose on/after scheduled titration date
//  Provides three actions: Complete Now, Reschedule, Remind Me Later
//  Issue #286 - Stream B
//

import SwiftData
import SwiftUI

/// Dialog shown when user attempts to log dose on/after titration date
/// Provides clear information about dose change and three action options
struct TitrationConfirmationDialog: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let titration: DoseTitration
    let onComplete: () -> Void
    let onReschedule: (Date) -> Void
    let onRemindLater: () -> Void

    // MARK: - State

    @State private var showingReschedulePicker = false
    @State private var rescheduleDate: Date = Date()
    @State private var isProcessing = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // Title and Icon
            VStack(spacing: 12) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
                    .accessibilityIdentifier("titration-dialog-icon")

                Text("Dose Increase Scheduled")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("titration-dialog-title")
            }

            // Dose Information
            VStack(spacing: 8) {
                Text("Your scheduled dose change:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    // From Dose
                    VStack(spacing: 4) {
                        Text("Current")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(titration.fromDose, specifier: "%.1f") mg")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    .accessibilityIdentifier("titration-from-dose")

                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    // To Dose
                    VStack(spacing: 4) {
                        Text("New")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(titration.toDose, specifier: "%.1f") mg")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .accessibilityIdentifier("titration-to-dose")
                }
                .accessibilityIdentifier("titration-dose-comparison")

                Text("Scheduled for \(formattedScheduledDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("titration-scheduled-date")
            }
            .padding(.vertical, 8)

            // Error Message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("titration-error-message")
            }

            // Action Buttons
            VStack(spacing: 12) {
                // Complete Now Button
                Button(action: handleCompleteNow) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete Now")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }
                .disabled(isProcessing)
                .accessibilityIdentifier("titration-complete-now-button")
                .accessibilityLabel("Complete dose increase now and use new dose amount")

                // Reschedule Button
                Button(action: { showingReschedulePicker = true }) {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Reschedule")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .foregroundStyle(.primary)
                    .cornerRadius(10)
                }
                .disabled(isProcessing)
                .accessibilityIdentifier("titration-reschedule-button")
                .accessibilityLabel("Reschedule dose increase to a different date")

                // Remind Me Later Button
                Button(action: handleRemindLater) {
                    HStack {
                        Image(systemName: "clock")
                        Text("Remind Me Later")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .foregroundStyle(.primary)
                    .cornerRadius(10)
                }
                .disabled(isProcessing)
                .accessibilityIdentifier("titration-remind-later-button")
                .accessibilityLabel("Dismiss dialog and remind me again on next dose entry")
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 20)
        .accessibilityIdentifier("titration-confirmation-dialog")
        .sheet(isPresented: $showingReschedulePicker) {
            RescheduleTitrationSheet(
                currentDate: titration.scheduledDate,
                onSave: handleReschedule)
        }
    }

    // MARK: - Computed Properties

    private var formattedScheduledDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: titration.scheduledDate)
    }

    // MARK: - Actions

    private func handleCompleteNow() {
        isProcessing = true
        errorMessage = nil

        do {
            // Mark titration as completed
            titration.markCompleted()

            // Save changes
            try modelContext.save()

            // Notify parent view
            onComplete()

            // Dismiss dialog
            dismiss()

        } catch {
            errorMessage = "Failed to complete titration: \(error.localizedDescription)"
            isProcessing = false
        }
    }

    private func handleReschedule(_ newDate: Date) {
        isProcessing = true
        errorMessage = nil

        do {
            // Update titration scheduled date
            titration.scheduledDate = newDate
            titration.updatedAt = Date()

            // Save changes
            try modelContext.save()

            // Notify parent view
            onReschedule(newDate)

            // Dismiss dialog
            dismiss()

        } catch {
            errorMessage = "Failed to reschedule: \(error.localizedDescription)"
            isProcessing = false
        }
    }

    private func handleRemindLater() {
        // Notify parent view to set remind later flag
        onRemindLater()

        // Dismiss dialog
        dismiss()
    }
}

// MARK: - Reschedule Sheet

private struct RescheduleTitrationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let currentDate: Date
    let onSave: (Date) -> Void

    @State private var selectedDate: Date

    init(currentDate: Date, onSave: @escaping (Date) -> Void) {
        self.currentDate = currentDate
        self.onSave = onSave
        self._selectedDate = State(initialValue: currentDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Select New Titration Date")
                    .font(.headline)
                    .padding(.top)

                DatePicker(
                    "New Date",
                    selection: $selectedDate,
                    in: Date()...,  // Only allow future dates
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                .accessibilityIdentifier("titration-reschedule-date-picker")

                Spacer()
            }
            .navigationTitle("Reschedule Titration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("titration-reschedule-cancel-button")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selectedDate)
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("titration-reschedule-save-button")
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Previews

#Preview("Titration Dialog") {
    let titration = DoseTitration(
        fromDose: 1.0,
        toDose: 2.0,
        scheduledDate: Date(),
        isCompleted: false)

    return TitrationConfirmationDialog(
        titration: titration,
        onComplete: { print("Completed") },
        onReschedule: { date in print("Rescheduled to \(date)") },
        onRemindLater: { print("Remind later") }
    )
    .frame(maxWidth: 400)
}
