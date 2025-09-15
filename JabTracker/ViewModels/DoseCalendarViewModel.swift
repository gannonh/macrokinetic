//
//  DoseCalendarViewModel.swift
//  JabTracker
//
//  View model for dose calendar with monthly statistics, adherence tracking,
//  and dose indicators. Handles calendar navigation and data processing.
//

import Foundation
import SwiftData

/// View model for calendar-based dose tracking with statistics
@MainActor
class DoseCalendarViewModel: ObservableObject {

    // MARK: - Published Properties

    /// All doses fetched from SwiftData
    @Published var allDoses: [Dose] = [] {
        didSet {
            updateCalendarData()
        }
    }

    /// Currently displayed month
    @Published var currentMonth: Date = Date() {
        didSet {
            updateCalendarData()
        }
    }

    /// Doses for the current month
    @Published var monthlyDoses: [Dose] = []

    /// Monthly statistics for current month
    @Published var monthlyStatistics: AdherenceStatistics?

    /// Doses grouped by date for calendar display
    @Published var dosesByDate: [Date: [Dose]] = [:]

    /// Loading state
    @Published var isLoading: Bool = false

    /// Error message for display
    @Published var errorMessage: String?

    // MARK: - Computed Properties

    /// Start of the current month
    var monthStart: Date {
        Calendar.current.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
    }

    /// End of the current month
    var monthEnd: Date {
        Calendar.current.dateInterval(of: .month, for: currentMonth)?.end ?? currentMonth
    }

    /// Days in the current month
    var daysInMonth: [Date] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: currentMonth) else {
            return []
        }

        var days: [Date] = []
        var date = monthInterval.start

        while date < monthInterval.end {
            days.append(date)
            date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        }

        return days
    }

    /// Whether current month has any dose data
    var hasDataForCurrentMonth: Bool {
        !monthlyDoses.isEmpty
    }

    /// Current month display string
    var currentMonthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    // MARK: - Initialization

    init() {
        updateCalendarData()
    }

    // MARK: - Data Loading

    /// Set doses from @Query for automatic reactivity
    func setDoses(_ doses: [Dose]) {
        self.allDoses = doses
    }

    /// Load dose data from SwiftData context (fallback method)
    func loadData(context: ModelContext) {
        Task { @MainActor in
            do {
                isLoading = true
                errorMessage = nil

                // Create fetch descriptor for all doses
                let descriptor = FetchDescriptor<Dose>(
                    sortBy: [SortDescriptor(\Dose.timestamp, order: .forward)]
                )

                // Fetch all doses
                allDoses = try context.fetch(descriptor)
                updateCalendarData()

                isLoading = false

            } catch {
                errorMessage = "Failed to load dose data: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    // MARK: - Calendar Navigation

    /// Navigate to previous month
    func navigateToPreviousMonth() {
        if let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = previousMonth
        }
    }

    /// Navigate to next month
    func navigateToNextMonth() {
        if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = nextMonth
        }
    }

    /// Navigate to current month (today)
    func navigateToCurrentMonth() {
        currentMonth = Date()
    }

    /// Navigate to specific month
    func navigateToMonth(_ date: Date) {
        currentMonth = date
    }

    // MARK: - Date Utilities

    /// Get doses for a specific date
    func doses(for date: Date) -> [Dose] {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

        return dosesByDate[dayStart] ?? []
    }

    /// Check if date has any doses
    func hasdoses(for date: Date) -> Bool {
        !doses(for: date).isEmpty
    }

    /// Get number of doses for a specific date
    func doseCount(for date: Date) -> Int {
        doses(for: date).count
    }

    /// Check if date has multiple doses
    func hasMultipleDoses(for date: Date) -> Bool {
        doseCount(for: date) > 1
    }

    /// Get primary injection site for a date (most common if multiple doses)
    func primaryInjectionSite(for date: Date) -> String? {
        let dayDoses = doses(for: date)
        let sites = dayDoses.compactMap { $0.site }

        guard !sites.isEmpty else { return nil }

        // Return most frequent site, or first if tied
        let siteCount = Dictionary(grouping: sites) { $0 }.mapValues { $0.count }
        return siteCount.max(by: { $0.value < $1.value })?.key
    }

    /// Check if date is today
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    /// Check if date is in the past
    func isPastDate(_ date: Date) -> Bool {
        Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedAscending
    }

    /// Check if date is in the future
    func isFutureDate(_ date: Date) -> Bool {
        Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
    }

    // MARK: - Statistics

    /// Calculate statistics for a specific month
    func calculateStatistics(for month: Date) -> AdherenceStatistics {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: month) else {
            return .empty(periodStart: month, periodEnd: month)
        }

        let monthDoses = allDoses.filter { dose in
            dose.timestamp >= monthInterval.start && dose.timestamp < monthInterval.end
        }

        return AdherenceStatisticsCalculator.calculate(
            doses: monthDoses,
            periodStart: monthInterval.start,
            periodEnd: monthInterval.end,
            medicationFrequency: .weekly // Default to weekly, could be made configurable
        )
    }

    /// Get adherence rate for current month as percentage string
    var currentMonthAdherenceRate: String {
        monthlyStatistics?.adherenceRatePercentage ?? "0.0%"
    }

    /// Get current streak display string
    var currentStreakDisplay: String {
        guard let stats = monthlyStatistics else { return "0 days" }

        let days = stats.currentStreak
        let dayText = days == 1 ? "day" : "days"
        let activeText = stats.isCurrentStreakActive ? " (active)" : ""

        return "\(days) \(dayText)\(activeText)"
    }

    // MARK: - Private Methods

    /// Update calendar data when month or doses change
    private func updateCalendarData() {
        updateMonthlyDoses()
        updateDosesByDate()
        updateMonthlyStatistics()
    }

    /// Filter doses to current month
    private func updateMonthlyDoses() {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: currentMonth) else {
            monthlyDoses = []
            return
        }

        monthlyDoses = allDoses.filter { dose in
            dose.timestamp >= monthInterval.start && dose.timestamp < monthInterval.end
        }
    }

    /// Group doses by date for calendar display
    private func updateDosesByDate() {
        let calendar = Calendar.current
        dosesByDate = Dictionary(grouping: monthlyDoses) { dose in
            calendar.startOfDay(for: dose.timestamp)
        }
    }

    /// Calculate monthly statistics
    private func updateMonthlyStatistics() {
        monthlyStatistics = calculateStatistics(for: currentMonth)
    }
}