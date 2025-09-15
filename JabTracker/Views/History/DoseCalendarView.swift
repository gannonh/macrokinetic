//
//  DoseCalendarView.swift
//  JabTracker
//
//  Main calendar component for displaying doses in a monthly calendar layout
//

import SwiftUI
import SwiftData

/// Main calendar view component that displays doses in a monthly grid layout
/// Provides navigation between months and visual indicators for doses
struct DoseCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Dose.timestamp, order: .reverse) private var allDoses: [Dose]

    @State private var currentDate = Date()
    @State private var selectedDate: Date?
    @State private var showingDayDetail = false

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            // Month header with navigation
            monthHeaderView

            // Days of week header
            weekdayHeaderView

            // Calendar grid
            calendarGridView

            Spacer()
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingDayDetail) {
            if let selectedDate = selectedDate {
                DoseDayDetailView(
                    date: selectedDate,
                    doses: dosesForDate(selectedDate)
                )
            }
        }
        .accessibilityIdentifier("dose-calendar-view")
    }

    // MARK: - Subviews

    private var monthHeaderView: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .accessibilityLabel("Previous month")

            Spacer()

            Text(monthYearString)
                .font(.title)
                .fontWeight(.semibold)
                .accessibilityIdentifier("calendar-month-year")

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .accessibilityLabel("Next month")
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var weekdayHeaderView: some View {
        HStack {
            ForEach(calendar.weekdaySymbols.indices, id: \.self) { index in
                Text(calendar.veryShortWeekdaySymbols[index])
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var calendarGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 1) {
            ForEach(daysInMonth, id: \.self) { date in
                if let date = date {
                    CalendarDayView(
                        date: date,
                        doses: dosesForDate(date),
                        isToday: calendar.isDateInToday(date),
                        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                    ) {
                        selectedDate = date
                        showingDayDetail = true
                    }
                } else {
                    // Empty day cell for padding
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 44)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Computed Properties

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }

    private var daysInMonth: [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentDate),
              let firstOfMonth = calendar.dateInterval(of: .month, for: currentDate)?.start else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let paddingDays = firstWeekday - calendar.firstWeekday

        var days: [Date?] = Array(repeating: nil, count: paddingDays)

        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        // Pad to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    // MARK: - Helper Methods

    private func dosesForDate(_ date: Date) -> [Dose] {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        return allDoses.filter { dose in
            dose.timestamp >= startOfDay && dose.timestamp < endOfDay
        }.sorted { $0.timestamp < $1.timestamp }
    }

    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
                currentDate = newDate
            }
        }
    }

    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
                currentDate = newDate
            }
        }
    }
}

#Preview {
    NavigationStack {
        DoseCalendarView()
    }
    .modelContainer(DataController.preview.container)
}