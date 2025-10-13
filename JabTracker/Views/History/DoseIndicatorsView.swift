//
//  DoseIndicatorsView.swift
//  JabTracker
//
//  Combined dose indicator display for calendar days
//

import SwiftUI

/// Displays multiple dose indicators with overflow handling
///
/// Shows up to 3 dose indicators for a calendar day, with overflow indicator for additional doses.
/// Prioritizes logged doses over scheduled doses for display.
struct DoseIndicatorsView: View {
    let events: [DoseEvent]
    let maxDisplayCount: Int = 3

    var body: some View {
        HStack(spacing: 2) {
            if self.events.isEmpty {
                // Reserve space even when empty
                Color.clear
                    .frame(height: 12)
            } else {
                ForEach(Array(self.displayedEvents.enumerated()), id: \.offset) { _, event in
                    ScheduledDoseIndicator(
                        status: event.type,
                        size: self.events.count > 1 ? .small : .medium
                    )
                }

                if self.overflowCount > 0 {
                    Text("+\(self.overflowCount)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 12)
        .accessibilityLabel(self.accessibilityLabel)
    }

    // MARK: - Computed Properties

    /// Events to display (up to maxDisplayCount)
    private var displayedEvents: [DoseEvent] {
        // Sort: taken first, then scheduled, then missed/skipped
        let sorted = self.events.sorted { lhs, rhs in
            let lhsPriority = self.displayPriority(for: lhs.type)
            let rhsPriority = self.displayPriority(for: rhs.type)
            return lhsPriority < rhsPriority
        }

        return Array(sorted.prefix(self.maxDisplayCount))
    }

    /// Number of events beyond the display limit
    private var overflowCount: Int {
        max(0, self.events.count - self.maxDisplayCount)
    }

    private var accessibilityLabel: String {
        if self.events.isEmpty {
            return "No doses"
        }

        let loggedCount = self.events.filter { $0.type == .taken }.count
        let scheduledCount = self.events.filter { $0.type == .scheduled }.count
        let missedCount = self.events.filter { $0.type == .missed }.count
        let skippedCount = self.events.filter { $0.type == .skipped }.count

        var parts: [String] = []

        if loggedCount > 0 {
            parts.append("\(loggedCount) logged")
        }
        if scheduledCount > 0 {
            parts.append("\(scheduledCount) scheduled")
        }
        if missedCount > 0 {
            parts.append("\(missedCount) missed")
        }
        if skippedCount > 0 {
            parts.append("\(skippedCount) skipped")
        }

        return parts.joined(separator: ", ")
    }

    // MARK: - Helper Methods

    /// Priority for display order (lower = higher priority)
    private func displayPriority(for type: DoseEventType) -> Int {
        switch type {
        case .taken: return 0  // Highest priority
        case .scheduled: return 1
        case .missed: return 2
        case .skipped: return 3  // Lowest priority
        }
    }
}
