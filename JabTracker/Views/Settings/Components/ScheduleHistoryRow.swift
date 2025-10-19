//
//  ScheduleHistoryRow.swift
//  JabTracker
//
//  Row view component for displaying schedule modification history.
//

import SwiftUI

/// Displays a single schedule history item with icon, type, description, and timestamp
struct ScheduleHistoryRow: View {
    // MARK: - Properties

    /// The history item to display
    let item: ScheduleHistoryItem

    // MARK: - Private Properties

    /// Date formatter for displaying timestamp (static to avoid recreation)
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Icon with color coding
            Image(systemName: item.changeType.iconName)
                .font(.title3)
                .foregroundStyle(item.changeType.color)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.changeType.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Timestamp
            Text(Self.dateFormatter.string(from: item.timestamp))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Accessibility

    /// Combined accessibility label for VoiceOver
    private var accessibilityText: String {
        let formattedDate = Self.dateFormatter.string(from: item.timestamp)
        return "\(item.changeType.displayName): \(item.description), \(formattedDate)"
    }
}

// MARK: - Previews

#Preview("Created") {
    List {
        ScheduleHistoryRow(
            item: ScheduleHistoryItem(
                changeType: .created,
                description: "Initial schedule created",
                timestamp: Date()
            )
        )
    }
}

#Preview("Modified") {
    List {
        ScheduleHistoryRow(
            item: ScheduleHistoryItem(
                changeType: .modified,
                description: "Updated dose time to 9:00 AM",
                timestamp: Date().addingTimeInterval(-86400 * 7)  // 1 week ago
            )
        )
    }
}

#Preview("Paused") {
    List {
        ScheduleHistoryRow(
            item: ScheduleHistoryItem(
                changeType: .paused,
                description: "Paused for vacation",
                timestamp: Date().addingTimeInterval(-86400 * 3)  // 3 days ago
            )
        )
    }
}

#Preview("Resumed") {
    List {
        ScheduleHistoryRow(
            item: ScheduleHistoryItem(
                changeType: .resumed,
                description: "Resumed after vacation",
                timestamp: Date().addingTimeInterval(-86400)  // 1 day ago
            )
        )
    }
}

#Preview("Deactivated") {
    List {
        ScheduleHistoryRow(
            item: ScheduleHistoryItem(
                changeType: .deactivated,
                description: "Schedule deactivated",
                timestamp: Date()
            )
        )
    }
}

#Preview("Multiple Items") {
    List {
        ScheduleHistoryRow(
            item: ScheduleHistoryItem(
                changeType: .created,
                description: "Initial schedule created",
                timestamp: Date().addingTimeInterval(-86400 * 30)
            )
        )
        ScheduleHistoryRow(
            item: ScheduleHistoryItem(
                changeType: .modified,
                description: "Changed from weekly to split-dose",
                timestamp: Date().addingTimeInterval(-86400 * 14)
            )
        )
        ScheduleHistoryRow(
            item: ScheduleHistoryItem(
                changeType: .paused,
                description: "Paused for medical reasons",
                timestamp: Date().addingTimeInterval(-86400 * 7)
            )
        )
        ScheduleHistoryRow(
            item: ScheduleHistoryItem(
                changeType: .resumed,
                description: "Resumed normal schedule",
                timestamp: Date()
            )
        )
    }
}
