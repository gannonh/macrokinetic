//
//  DoseCalendarView.swift
//  JabTracker
//
//  Main calendar component for displaying doses in a monthly calendar layout
//

import SwiftData
import SwiftUI

/// Main calendar view component that displays doses in a monthly grid layout
/// Provides navigation between months and visual indicators for doses
struct DoseCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Dose.timestamp, order: .reverse) private var allDoses: [Dose]

    // MARK: - Stream A: Scheduled Dose Loading

    @Query(filter: #Predicate<DoseSchedule> { $0.isActive })
    private var activeSchedules: [DoseSchedule]

    @State private var scheduledDosesForMonth: [ScheduledDose] = []

    @State private var currentDate = Date()
    @State private var selectedDate: Date?
    @State private var showingDayDetail = false

    // MARK: - Stream B: Long-Press Gesture Handling

    @State private var selectedDoseEvent: DoseEvent?
    @State private var showingActionSheet = false

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            // Month header with navigation
            self.monthHeaderView

            // Days of week header
            self.weekdayHeaderView

            // Calendar grid
            self.calendarGridView

            Spacer()
        }
        .sheet(isPresented: self.$showingDayDetail) {
            if let selectedDate {
                DoseDayDetailView(
                    date: selectedDate,
                    doses: self.dosesForDate(selectedDate))
            }
        }
        .sheet(isPresented: self.$showingActionSheet) {
            if let event = selectedDoseEvent {
                DoseActionSheet(event: event)
            }
        }
        .accessibilityIdentifier("dose-calendar-view")
    }

    // MARK: - Subviews

    private var monthHeaderView: some View {
        HStack {
            Button(action: self.previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .accessibilityLabel("Previous month")

            Spacer()

            Text(self.monthYearString)
                .font(.title)
                .fontWeight(.semibold)
                .accessibilityIdentifier("calendar-month-year")

            Spacer()

            Button(action: self.nextMonth) {
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
            ForEach(self.calendar.weekdaySymbols.indices, id: \.self) { index in
                Text(self.calendar.veryShortWeekdaySymbols[index])
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
            ForEach(Array(self.daysInMonth.enumerated()), id: \.offset) { _, date in
                if let date {
                    CalendarDayView(
                        date: date,
                        events: self.doseEventsForDate(date),
                        isToday: self.calendar.isDateInToday(date),
                        isSelected: self.selectedDate.map { self.calendar.isDate($0, inSameDayAs: date) }
                            ?? false,
                        onTap: {
                            self.selectedDate = date
                            self.showingDayDetail = true
                        },
                        onLongPress: { event in
                            // Stream B: Handle long-press for dose actions
                            self.selectedDoseEvent = event
                            self.showingActionSheet = true
                        }
                    )
                } else {
                    // Empty day cell for padding
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 44)
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            self.loadScheduledDosesForMonth()
        }
        .onChange(of: self.currentDate) {
            self.loadScheduledDosesForMonth()
        }
    }

    // MARK: - Computed Properties

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self.currentDate)
    }

    private var daysInMonth: [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentDate),
            let firstOfMonth = calendar.dateInterval(of: .month, for: currentDate)?.start
        else {
            return []
        }

        let firstWeekday = self.calendar.component(.weekday, from: firstOfMonth)
        let paddingDays = firstWeekday - self.calendar.firstWeekday

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
        let startOfDay = self.calendar.startOfDay(for: date)
        let endOfDay = self.calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        return self.allDoses.filter { dose in
            dose.timestamp >= startOfDay && dose.timestamp < endOfDay
        }.sorted { $0.timestamp < $1.timestamp }
    }

    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
                self.currentDate = newDate
            }
        }
    }

    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
                self.currentDate = newDate
            }
        }
    }

    // MARK: - Stream A: Scheduled Dose Methods

    /// Load scheduled doses for the currently displayed month (lazy loading per NFR3)
    private func loadScheduledDosesForMonth() {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else {
            self.scheduledDosesForMonth = []
            return
        }

        let scheduleService = ScheduleService(context: modelContext)
        var allScheduledDoses: [ScheduledDose] = []

        // Generate scheduled doses for each active schedule
        for schedule in activeSchedules {
            let doses = scheduleService.generateScheduledDoses(
                for: schedule,
                from: monthInterval.start,
                to: monthInterval.end
            )
            allScheduledDoses.append(contentsOf: doses)
        }

        self.scheduledDosesForMonth = allScheduledDoses
    }

    /// Get dose events (combination of logged and scheduled doses) for a specific date
    private func doseEventsForDate(_ date: Date) -> [DoseEvent] {
        let startOfDay = self.calendar.startOfDay(for: date)
        let endOfDay = self.calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        var events: [DoseEvent] = []

        // Get logged doses and scheduled doses for this date
        let loggedDoses = self.dosesForDate(date)
        let scheduledDoses = self.scheduledDosesForMonth.filter { scheduled in
            scheduled.scheduledTime >= startOfDay && scheduled.scheduledTime < endOfDay
        }

        // Add logged doses as events
        events.append(contentsOf: loggedDoses.map { DoseEvent.from(actualDose: $0) })

        // Add scheduled doses ONLY if they haven't been logged
        for scheduledDose in scheduledDoses {
            // Check if any logged dose on this date falls within this scheduled dose's window
            let wasLogged = loggedDoses.contains { dose in
                dose.timestamp >= scheduledDose.windowStart && dose.timestamp <= scheduledDose.windowEnd
            }

            // Only add scheduled dose if it wasn't logged
            if !wasLogged {
                // Get medication profile information by looking up the schedule in activeSchedules
                // (scheduledDose.schedule relationship is unreliable on in-memory objects)
                let medicationProfile = self.getMedicationProfile(for: scheduledDose)

                // Check if it's in the past (missed) or future (scheduled)
                let now = Date()
                if scheduledDose.windowEnd < now {
                    // Missed dose - past the adherence window
                    events.append(
                        DoseEvent.from(
                            scheduledDose: scheduledDose,
                            medicationBrandName: medicationProfile?.brandName,
                            medicationGenericName: medicationProfile?.genericName
                        ))
                } else {
                    // Future scheduled dose
                    events.append(
                        DoseEvent.from(
                            scheduledDose: scheduledDose,
                            medicationBrandName: medicationProfile?.brandName,
                            medicationGenericName: medicationProfile?.genericName
                        ))
                }
            }
        }

        return events.sorted { $0.timestamp < $1.timestamp }
    }

    /// Look up the medication profile for a scheduled dose from activeSchedules
    ///
    /// Since ScheduledDose objects are generated in-memory, their schedule.medicationProfile
    /// relationship may not be accessible. This helper finds the schedule in activeSchedules
    /// to get the medication profile information.
    private func getMedicationProfile(for scheduledDose: ScheduledDose) -> MedicationProfile? {
        // Find the schedule in activeSchedules by matching the schedule reference
        guard let schedule = scheduledDose.schedule else { return nil }

        // Find matching schedule in activeSchedules (same persistent ID)
        if let matchingSchedule = activeSchedules.first(where: { $0.persistentModelID == schedule.persistentModelID }) {
            return matchingSchedule.medicationProfile
        }

        return nil
    }
}

#Preview {
    NavigationStack {
        DoseCalendarView()
    }
    .modelContainer(DataController.preview.container)
}
