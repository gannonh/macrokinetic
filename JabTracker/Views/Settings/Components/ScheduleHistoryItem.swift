//
//  ScheduleHistoryItem.swift
//  JabTracker
//
//  Data structure for schedule modification history timeline.
//

import Foundation
import SwiftUI

/// Represents a change event in a medication dose schedule's history
struct ScheduleHistoryItem: Identifiable {
    /// Unique identifier for the history item
    let id: UUID

    /// Type of schedule change that occurred
    let changeType: ScheduleChangeType

    /// Human-readable description of the change
    let description: String

    /// When the change occurred
    let timestamp: Date

    /// Creates a new schedule history item
    init(
        id: UUID = UUID(),
        changeType: ScheduleChangeType,
        description: String,
        timestamp: Date
    ) {
        self.id = id
        self.changeType = changeType
        self.description = description
        self.timestamp = timestamp
    }
}

/// Types of changes that can occur in a medication schedule
enum ScheduleChangeType {
    case created
    case modified
    case paused
    case resumed
    case deactivated

    /// User-facing display name for the change type
    var displayName: String {
        switch self {
        case .created:
            return "Created"
        case .modified:
            return "Modified"
        case .paused:
            return "Paused"
        case .resumed:
            return "Resumed"
        case .deactivated:
            return "Deactivated"
        }
    }

    /// SF Symbol icon name for the change type
    var iconName: String {
        switch self {
        case .created:
            return "plus.circle.fill"
        case .modified:
            return "pencil.circle.fill"
        case .paused:
            return "pause.circle.fill"
        case .resumed:
            return "play.circle.fill"
        case .deactivated:
            return "xmark.circle.fill"
        }
    }

    /// Color coding for the change type
    var color: Color {
        switch self {
        case .created:
            return .green
        case .modified:
            return .blue
        case .paused:
            return .orange
        case .resumed:
            return .green
        case .deactivated:
            return .red
        }
    }
}
