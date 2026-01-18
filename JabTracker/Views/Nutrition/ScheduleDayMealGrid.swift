//
//  ScheduleDayMealGrid.swift
//  JabTracker
//
//  Grid for selecting day/meal schedule combinations.
//

import SwiftUI

/// Grid for selecting which day/meal combinations to schedule
struct ScheduleDayMealGrid: View {
    @Binding var selectedConfigs: Set<DayMealKey>

    private let days = ScheduleDay.allCases
    private let meals = MealSection.allCases

    var body: some View {
        VStack(spacing: 0) {
            // Header row with meal initials
            headerRow

            // Day rows
            ForEach(days) { day in
                dayRow(day)
            }
        }
    }

    private var headerRow: some View {
        HStack {
            Text("")
                .frame(width: 50)
            ForEach(meals) { meal in
                Text(String(meal.displayName.prefix(1)))
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 8)
    }

    private func dayRow(_ day: ScheduleDay) -> some View {
        HStack {
            Text(day.shortName)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)

            ForEach(meals) { meal in
                toggleCell(day: day, meal: meal)
            }
        }
        .padding(.vertical, 4)
    }

    private func toggleCell(day: ScheduleDay, meal: MealSection) -> some View {
        let key = DayMealKey(day: day, meal: meal)
        let isSelected = selectedConfigs.contains(key)

        return Button {
            if isSelected {
                selectedConfigs.remove(key)
            } else {
                selectedConfigs.insert(key)
            }
        } label: {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(isSelected ? .accentColor : .secondary.opacity(0.5))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("schedule-grid-\(day.shortName.lowercased())-\(meal.rawValue)")
    }
}

/// Hashable key for day/meal selection (used in Set for O(1) lookups)
struct DayMealKey: Hashable {
    let day: ScheduleDay
    let meal: MealSection
}

#Preview {
    struct PreviewWrapper: View {
        @State var selected: Set<DayMealKey> = [
            DayMealKey(day: .monday, meal: .breakfast),
            DayMealKey(day: .wednesday, meal: .lunch),
        ]

        var body: some View {
            ScheduleDayMealGrid(selectedConfigs: $selected)
                .padding()
        }
    }
    return PreviewWrapper()
}
