//
//  FoodDayView.swift
//  JabTracker
//
//  Individual day cell for the week calendar strip showing weekday, day number, and entry indicator.
//

import SwiftUI

/// Individual day cell for the food log week calendar
/// Displays weekday abbreviation, day number, and entry indicator dot
struct FoodDayView: View {
    let date: Date
    let entryCount: Int
    let isToday: Bool
    let isSelected: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current

    // MARK: - Static Formatters (cached for performance)

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Weekday abbreviation (Mon, Tue, etc.)
                Text(weekdayAbbreviation)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)

                // Day number
                Text("\(dayNumber)")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(isToday ? .bold : .medium)
                    .foregroundColor(textColor)

                // Entry indicator dot
                Circle()
                    .fill(entryCount > 0 ? Color.accentColor : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(backgroundView)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("food-day-\(dayNumber)")
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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

    // MARK: - Computed Properties

    private var dayNumber: Int {
        calendar.component(.day, from: date)
    }

    private var weekdayAbbreviation: String {
        Self.weekdayFormatter.string(from: date)
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
        if isSelected || isToday {
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
        var label = Self.fullDateFormatter.string(from: date)

        if isToday {
            label += ", today"
        }

        if entryCount > 0 {
            label += ", \(entryCount) food \(entryCount == 1 ? "entry" : "entries")"
        } else {
            label += ", no entries"
        }

        return label
    }
}

#Preview {
    HStack(spacing: 4) {
        FoodDayView(
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            entryCount: 3,
            isToday: false,
            isSelected: false,
            onTap: {}
        )

        FoodDayView(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            entryCount: 0,
            isToday: false,
            isSelected: false,
            onTap: {}
        )

        FoodDayView(
            date: Date(),
            entryCount: 5,
            isToday: true,
            isSelected: true,
            onTap: {}
        )

        FoodDayView(
            date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            entryCount: 0,
            isToday: false,
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
}
