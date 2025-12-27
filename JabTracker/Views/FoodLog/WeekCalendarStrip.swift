//
//  WeekCalendarStrip.swift
//  JabTracker
//
//  Horizontal 7-day calendar strip for navigating food log by date.
//

import SwiftUI

/// Horizontal week calendar strip for food log navigation
/// Shows 7 days with navigation arrows and entry indicators
struct WeekCalendarStrip: View {
    @Binding var selectedDate: Date
    let entriesGroupedByDate: [Date: Int]

    /// The start of the currently displayed week (Sunday/Monday depending on locale)
    @State private var currentWeekStart: Date = Date()
    /// Whether the view has been initialized
    @State private var hasInitialized = false

    private let calendar = Calendar.current

    // MARK: - Static Formatters (cached for performance)

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 12) {
            // Navigation header
            navigationHeader

            // Week days
            weekDaysRow
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .cardStyle(cornerRadius: 12)
        .accessibilityIdentifier("week-calendar-strip")
        .onAppear {
            // Initialize currentWeekStart on first appear only
            if !hasInitialized {
                currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
                hasInitialized = true
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            // Update week if selected date is outside current week
            if !isDateInCurrentWeek(newDate) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: newDate)?.start ?? newDate
                }
            }
        }
    }

    // MARK: - Subviews

    private var navigationHeader: some View {
        HStack {
            Button {
                navigateWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous week")
            .accessibilityIdentifier("week-calendar-previous")

            Spacer()

            Text(monthYearString)
                .font(.headline)
                .accessibilityIdentifier("week-calendar-title")

            Spacer()

            Button {
                navigateWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next week")
            .accessibilityIdentifier("week-calendar-next")
        }
        .padding(.horizontal, 8)
    }

    private var weekDaysRow: some View {
        HStack(spacing: 4) {
            ForEach(daysInWeek, id: \.self) { date in
                FoodDayView(
                    date: date,
                    entryCount: entryCount(for: date),
                    isToday: calendar.isDateInToday(date),
                    isSelected: calendar.isDate(selectedDate, inSameDayAs: date),
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = date
                        }
                    }
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var daysInWeek: [Date] {
        (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: currentWeekStart)
        }
    }

    private var monthYearString: String {
        // Use selectedDate for header to show correct month when week spans month boundary
        Self.monthYearFormatter.string(from: selectedDate)
    }

    // MARK: - Helper Methods

    private func entryCount(for date: Date) -> Int {
        let startOfDay = calendar.startOfDay(for: date)
        return entriesGroupedByDate[startOfDay] ?? 0
    }

    private func isDateInCurrentWeek(_ date: Date) -> Bool {
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart) else {
            return false
        }
        let startOfDay = calendar.startOfDay(for: date)
        let weekStartDay = calendar.startOfDay(for: currentWeekStart)
        let weekEndDay = calendar.startOfDay(for: weekEnd)
        return startOfDay >= weekStartDay && startOfDay <= weekEndDay
    }

    /// Navigate by the given number of weeks (-1 for previous, +1 for next)
    private func navigateWeek(by offset: Int) {
        guard let newStart = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) else {
            return
        }
        // Update week start first (no animation on this)
        currentWeekStart = newStart
        // Then update selected date with animation
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDate = newStart
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedDate = Date()

        var body: some View {
            VStack {
                WeekCalendarStrip(
                    selectedDate: $selectedDate,
                    entriesGroupedByDate: [
                        Calendar.current.startOfDay(for: Date()): 5,
                        Calendar.current.startOfDay(
                            for: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                        ): 3,
                    ]
                )
                .padding()

                Text("Selected: \(selectedDate.formatted(date: .complete, time: .omitted))")
            }
        }
    }

    return PreviewWrapper()
}
