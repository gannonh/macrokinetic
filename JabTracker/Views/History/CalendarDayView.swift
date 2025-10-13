//
//  CalendarDayView.swift
//  JabTracker
//
//  Individual calendar day cell component
//

import SwiftUI

/// Individual calendar day cell that displays dose indicators and handles interaction
struct CalendarDayView: View {
    let date: Date
    let events: [DoseEvent]  // Stream A: Changed from [Dose] to [DoseEvent] to support scheduled doses
    let isToday: Bool
    let isSelected: Bool
    let onTap: () -> Void

    // MARK: - Stream B: Long-Press Handler

    var onLongPress: ((DoseEvent) -> Void)?

    private let calendar = Calendar.current

    // MARK: - Stream A: Legacy Support

    /// Legacy computed property for backward compatibility with existing code
    private var doses: [Dose] {
        events.compactMap { $0.actualDose }
    }

    var body: some View {
        ZStack {
            // Background
            self.backgroundView

            VStack(spacing: 2) {
                // Day number
                Text("\(self.dayNumber)")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(self.isToday ? .bold : .medium)
                    .foregroundColor(self.textColor)

                // Dose indicators
                self.doseIndicatorView
            }
        }
        .frame(height: 44)
        .contentShape(Rectangle())  // Make entire frame tappable
        .onTapGesture {
            self.onTap()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            // Stream B: Handle long-press for scheduled doses
            handleLongPress()
        }
        .accessibilityIdentifier("calendar-day-\(self.dayNumber)")
        .accessibilityLabel(self.accessibilityLabel)
        .accessibilityHint(self.accessibilityHint)
    }

    // MARK: - Subviews

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(self.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(self.borderColor, lineWidth: self.borderWidth)
            )
    }

    // MARK: - Stream A: Scheduled Dose Indicators

    private var doseIndicatorView: some View {
        DoseIndicatorsView(events: self.events)
    }

    // MARK: - Computed Properties

    private var dayNumber: Int {
        self.calendar.component(.day, from: self.date)
    }

    private var backgroundColor: Color {
        if self.isSelected {
            return .accentColor.opacity(0.2)
        } else if self.isToday {
            return .accentColor.opacity(0.1)
        } else {
            return Color.clear
        }
    }

    private var textColor: Color {
        if self.isSelected {
            return .accentColor
        } else if self.isToday {
            return .accentColor
        } else {
            return .primary
        }
    }

    private var borderColor: Color {
        if self.isSelected {
            return .accentColor
        } else if self.isToday {
            return .accentColor.opacity(0.5)
        } else {
            return Color.clear
        }
    }

    private var borderWidth: CGFloat {
        if self.isSelected {
            return 2
        } else if self.isToday {
            return 1
        } else {
            return 0
        }
    }

    // MARK: - Stream A: Accessibility with Scheduled Doses

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: self.date)

        var label = dateString
        if self.isToday {
            label += ", today"
        }

        // Count different types of events
        let loggedCount = events.filter { $0.type == .taken }.count
        let scheduledCount = events.filter { $0.type == .scheduled }.count
        let missedCount = events.filter { $0.type == .missed }.count
        let skippedCount = events.filter { $0.type == .skipped }.count

        var doseParts: [String] = []

        if loggedCount > 0 {
            doseParts.append("\(loggedCount) logged")
        }
        if scheduledCount > 0 {
            doseParts.append("\(scheduledCount) scheduled")
        }
        if missedCount > 0 {
            doseParts.append("\(missedCount) missed")
        }
        if skippedCount > 0 {
            doseParts.append("\(skippedCount) skipped")
        }

        if !doseParts.isEmpty {
            label += ", " + doseParts.joined(separator: ", ")
        }

        return label
    }

    private var accessibilityHint: String {
        let scheduledCount = events.filter { $0.type == .scheduled }.count

        if events.isEmpty {
            return "No doses recorded for this date"
        } else if scheduledCount > 0 {
            return "Tap to view dose details. Long press to manage scheduled doses"
        } else {
            return "Tap to view dose details"
        }
    }

    // MARK: - Helper Methods

    private func indicatorColor(for dose: Dose) -> Color {
        if dose.skipped {
            return .orange.opacity(0.7)  // Missed dose indicator
        }

        // Color coding based on injection site
        switch dose.site?.lowercased() {
        case "abdomen":
            return .blue
        case "thigh":
            return .green
        case "arm":
            return .purple
        default:
            return .accentColor  // Default color for unknown or nil sites
        }
    }

    // MARK: - Stream B: Long-Press Handling

    /// Handle long-press gesture on calendar day
    ///
    /// Finds the first scheduled dose event and triggers the long-press handler
    private func handleLongPress() {
        // Find first scheduled dose event
        if let scheduledEvent = events.first(where: { $0.type == .scheduled }) {
            onLongPress?(scheduledEvent)
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()
    let mockDose = Dose(
        amount: 1.0,
        timestamp: today,
        site: "Abdomen",
        notes: "Morning dose",
        imageData: nil,
        skipped: false,
        user: nil,
        medication: nil)

    let loggedEvent = DoseEvent.from(actualDose: mockDose)
    let scheduledEvent = DoseEvent(
        id: UUID(),
        timestamp: today,
        type: .scheduled,
        scheduledDose: nil,
        actualDose: nil,
        doseAmount: 1.0,
        adherenceStatus: .pending
    )

    VStack {
        CalendarDayView(
            date: today,
            events: [loggedEvent],
            isToday: true,
            isSelected: false
        ) {
            print("Tapped today")
        }

        CalendarDayView(
            date: calendar.date(byAdding: .day, value: 1, to: today) ?? today,
            events: [scheduledEvent],
            isToday: false,
            isSelected: false
        ) {
            print("Tapped tomorrow")
        }

        CalendarDayView(
            date: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
            events: [loggedEvent, scheduledEvent],
            isToday: false,
            isSelected: true
        ) {
            print("Tapped yesterday")
        }
    }
    .padding()
}
