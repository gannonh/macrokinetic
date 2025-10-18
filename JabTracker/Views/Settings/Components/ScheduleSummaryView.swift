//
//  ScheduleSummaryView.swift
//  JabTracker
//
//  View component displaying comprehensive schedule summary with titration warnings.
//

import SwiftUI

/// Displays current medication schedule summary with titration warnings
struct ScheduleSummaryView: View {
    // MARK: - Properties

    /// Schedule pattern type (weekly, split-dose, custom)
    let patternType: SchedulePatternType

    /// Schedule frequency description (e.g., "Once weekly", "Twice daily")
    let frequency: String

    /// Next scheduled dose date
    let nextDose: Date?

    /// Reminder preferences in minutes before dose
    let reminderMinutes: Int

    /// Whether schedule is currently paused
    let isPaused: Bool

    /// Optional titration warning text (nil if no upcoming dose change)
    let titrationWarning: String?

    /// Action to perform when titration warning is tapped
    let onTitrationWarningTap: (() -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Schedule pattern and frequency
            scheduleInfoSection

            // Next dose countdown
            if let nextDose = nextDose, !isPaused {
                nextDoseSection(nextDose: nextDose)
            }

            // Paused status badge
            if isPaused {
                pausedBadge
            }

            // Reminder preferences
            reminderSection

            // Titration warning (conditional - AC11-13)
            if let warning = titrationWarning, !warning.isEmpty {
                titrationWarningSection(warning: warning)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Subviews

    /// Schedule pattern and frequency info
    private var scheduleInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Schedule Pattern")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(patternType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            HStack {
                Text("Frequency")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(frequency)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }

    /// Next dose countdown
    private func nextDoseSection(nextDose: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Next Dose")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.blue)

                Text(formatTimeUntil(nextDose))
                    .font(.headline)

                Spacer()

                Text(nextDose, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next dose in \(formatTimeUntil(nextDose))")
    }

    /// Paused status badge
    private var pausedBadge: some View {
        HStack {
            Image(systemName: "pause.circle.fill")
                .foregroundStyle(.orange)

            Text("Schedule Paused")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.orange)
        }
        .accessibilityLabel("Schedule is currently paused")
    }

    /// Reminder preferences section
    private var reminderSection: some View {
        HStack {
            Text("Reminders")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(reminderMinutes) minutes before")
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    /// Titration warning section (AC11-13)
    private func titrationWarningSection(warning: String) -> some View {
Button(action: {
            onTitrationWarningTap?()
        }, label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Upcoming Dose Change")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(warning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        })
        .buttonStyle(.plain)
        .accessibilityLabel("Upcoming dose change: \(warning)")
        .accessibilityHint("Tap to view dose titration plan")

    // MARK: - Helper Functions

    /// Format time interval until a future date
    private func formatTimeUntil(_ date: Date) -> String {
        let interval = date.timeIntervalSinceNow

        if interval < 3600 {  // Less than 1 hour
            return "Less than 1 hour"
        } else if interval < 86400 {  // Less than 1 day
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {  // 1 day or more
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s")"
        }
    }
}

// MARK: - Previews

#Preview("Standard Weekly Schedule") {
    ScheduleSummaryView(
        patternType: .weekly,
        frequency: "Once weekly",
        nextDose: Date(timeIntervalSinceNow: 86400 * 3),  // 3 days from now
        reminderMinutes: 30,
        isPaused: false,
        titrationWarning: nil,
        onTitrationWarningTap: nil
    )
    .padding()
}

#Preview("Paused Schedule") {
    ScheduleSummaryView(
        patternType: .weekly,
        frequency: "Once weekly",
        nextDose: Date(timeIntervalSinceNow: 86400 * 7),
        reminderMinutes: 60,
        isPaused: true,
        titrationWarning: nil,
        onTitrationWarningTap: nil
    )
    .padding()
}

#Preview("With Titration Warning") {
    ScheduleSummaryView(
        patternType: .weekly,
        frequency: "Once weekly",
        nextDose: Date(timeIntervalSinceNow: 86400 * 2),  // 2 days from now
        reminderMinutes: 30,
        isPaused: false,
        titrationWarning: "Your next dose on Oct 20 will increase from 0.25mg to 0.50mg",
        onTitrationWarningTap: {
            print("Navigate to titration plan")
        }
    )
    .padding()
}

#Preview("Split-Dose Schedule") {
    ScheduleSummaryView(
        patternType: .splitDose,
        frequency: "Twice daily",
        nextDose: Date(timeIntervalSinceNow: 14400),  // 4 hours from now
        reminderMinutes: 15,
        isPaused: false,
        titrationWarning: nil,
        onTitrationWarningTap: nil
    )
    .padding()
}

#Preview("Next Dose Soon") {
    ScheduleSummaryView(
        patternType: .weekly,
        frequency: "Once weekly",
        nextDose: Date(timeIntervalSinceNow: 1800),  // 30 minutes from now
        reminderMinutes: 30,
        isPaused: false,
        titrationWarning: nil,
        onTitrationWarningTap: nil
    )
    .padding()
}
