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
    let doses: [Dose]
    let isToday: Bool
    let isSelected: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                backgroundView

                VStack(spacing: 2) {
                    // Day number
                    Text("\(dayNumber)")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(isToday ? .bold : .medium)
                        .foregroundColor(textColor)

                    // Dose indicators
                    doseIndicatorView
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: 44)
        .accessibilityIdentifier("calendar-day-\(dayNumber)")
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    // MARK: - Subviews

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }

    private var doseIndicatorView: some View {
        HStack(spacing: 2) {
            if doses.isEmpty {
                // No indicator for days without doses
                Color.clear
                    .frame(height: 4)
            } else if doses.count == 1 {
                // Single dose indicator
                singleDoseIndicator(dose: doses.first!)
            } else {
                // Multiple doses indicator
                multipleDoseIndicator()
            }
        }
        .frame(height: 4)
    }

    private func singleDoseIndicator(dose: Dose) -> some View {
        Circle()
            .fill(indicatorColor(for: dose))
            .frame(width: 6, height: 6)
    }

    private func multipleDoseIndicator() -> some View {
        HStack(spacing: 1) {
            ForEach(0..<min(doses.count, 3), id: \.self) { index in
                Circle()
                    .fill(indicatorColor(for: doses[index]))
                    .frame(width: 4, height: 4)
            }
            if doses.count > 3 {
                Text("+")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Computed Properties

    private var dayNumber: Int {
        calendar.component(.day, from: date)
    }

    private var backgroundColor: Color {
        if isSelected {
            return .accentColor.opacity(0.2)
        } else if isToday {
            return .accentColor.opacity(0.1)
        } else {
            return Color.clear
        }
    }

    private var textColor: Color {
        if isSelected {
            return .accentColor
        } else if isToday {
            return .accentColor
        } else {
            return .primary
        }
    }

    private var borderColor: Color {
        if isSelected {
            return .accentColor
        } else if isToday {
            return .accentColor.opacity(0.5)
        } else {
            return Color.clear
        }
    }

    private var borderWidth: CGFloat {
        if isSelected {
            return 2
        } else if isToday {
            return 1
        } else {
            return 0
        }
    }

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: date)

        var label = dateString
        if isToday {
            label += ", today"
        }
        if !doses.isEmpty {
            label += ", \(doses.count) dose\(doses.count == 1 ? "" : "s")"
        }
        return label
    }

    private var accessibilityHint: String {
        if doses.isEmpty {
            return "No doses recorded for this date"
        } else {
            return "Tap to view dose details"
        }
    }

    // MARK: - Helper Methods

    private func indicatorColor(for dose: Dose) -> Color {
        if dose.skipped {
            return .orange.opacity(0.7) // Missed dose indicator
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
            return .accentColor // Default color for unknown or nil sites
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
        medication: nil
    )

    VStack {
        CalendarDayView(
            date: today,
            doses: [mockDose],
            isToday: true,
            isSelected: false
        ) {
            print("Tapped today")
        }

        CalendarDayView(
            date: calendar.date(byAdding: .day, value: 1, to: today)!,
            doses: [],
            isToday: false,
            isSelected: false
        ) {
            print("Tapped tomorrow")
        }

        CalendarDayView(
            date: calendar.date(byAdding: .day, value: -1, to: today)!,
            doses: [mockDose, mockDose],
            isToday: false,
            isSelected: true
        ) {
            print("Tapped yesterday")
        }
    }
    .padding()
}
