//
//  Dose+Filtering.swift
//  JabTracker
//

import Foundation

/// Extensions for Dose model to support filtering and searching operations
extension Dose {
  // MARK: - Text Search

  /// Check if dose matches search text across searchable fields
  func matches(searchText: String) -> Bool {
    let lowercased = searchText.lowercased()

    // Search in notes
    if let notes, notes.lowercased().contains(lowercased) {
      return true
    }

    // Search in injection site
    if let site, site.lowercased().contains(lowercased) {
      return true
    }

    // Search in medication name (generic and brand)
    if let medication {
      if medication.genericName.lowercased().contains(lowercased) {
        return true
      }
      if medication.brandName.lowercased().contains(lowercased) {
        return true
      }
    }

    // Search in dose amount (convert to string)
    if String(amount).contains(lowercased) {
      return true
    }

    // Search in formatted date
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    if dateFormatter.string(from: timestamp).lowercased().contains(lowercased) {
      return true
    }

    return false
  }

  // MARK: - Date Filtering

  /// Check if dose falls within a date range
  func isWithinDateRange(start: Date?, end: Date?) -> Bool {
    if let start, timestamp < start {
      return false
    }

    if let end {
      let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end
      if timestamp >= endOfDay {
        return false
      }
    }

    return true
  }

  /// Check if dose was taken on a specific date
  func isOnDate(_ date: Date) -> Bool {
    let calendar = Calendar.current
    return calendar.isDate(timestamp, inSameDayAs: date)
  }

  /// Check if dose was taken in a specific week
  func isInWeek(containing date: Date) -> Bool {
    let calendar = Calendar.current
    guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
      return false
    }
    return weekInterval.contains(timestamp)
  }

  /// Check if dose was taken in a specific month
  func isInMonth(containing date: Date) -> Bool {
    let calendar = Calendar.current
    let timestampComponents = calendar.dateComponents([.year, .month], from: timestamp)
    let dateComponents = calendar.dateComponents([.year, .month], from: date)

    return timestampComponents.year == dateComponents.year
      && timestampComponents.month == dateComponents.month
  }

  // MARK: - Medication Filtering

  /// Check if dose matches a specific medication type
  func hasMedication(_ medicationType: String) -> Bool {
    medication?.genericName == medicationType
  }

  /// Check if dose matches a specific brand
  func hasBrand(_ brandName: String) -> Bool {
    medication?.brandName == brandName
  }

  /// Check if dose is for any of the provided medication types
  func hasMedicationIn(_ medications: [String]) -> Bool {
    guard let medicationName = medication?.genericName else { return false }
    return medications.contains(medicationName)
  }

  // MARK: - Site Filtering

  /// Check if dose matches a specific injection site
  func hasInjectionSite(_ siteName: String) -> Bool {
    site == siteName
  }

  /// Check if dose is for any of the provided injection sites
  func hasInjectionSiteIn(_ sites: [String]) -> Bool {
    guard let doseSite = site else { return false }
    return sites.contains(doseSite)
  }

  // MARK: - Dose Amount Filtering

  /// Check if dose amount is within a specific range
  func amountIsInRange(min: Double?, max: Double?) -> Bool {
    if let min, amount < min {
      return false
    }

    if let max, amount > max {
      return false
    }

    return true
  }

  /// Check if dose amount equals a specific value (with tolerance for floating point comparison)
  func amountEquals(_ targetAmount: Double, tolerance: Double = 0.001) -> Bool {
    abs(amount - targetAmount) <= tolerance
  }

  // MARK: - Status Filtering

  /// Check if dose matches completion status
  func matchesCompletionStatus(completed: Bool) -> Bool {
    !skipped == completed
  }

  /// Check if dose has photo attachment
  var hasPhotoAttachment: Bool {
    imageData != nil
  }

  /// Check if dose has notes
  var hasNotes: Bool {
    notes != nil && !(notes?.isEmpty ?? true)
  }

  // MARK: - Time-based Filtering

  /// Check if dose was taken in the morning (before noon)
  var isMorningDose: Bool {
    let hour = Calendar.current.component(.hour, from: timestamp)
    return hour < 12
  }

  /// Check if dose was taken in the evening (after 6 PM)
  var isEveningDose: Bool {
    let hour = Calendar.current.component(.hour, from: timestamp)
    return hour >= 18
  }

  /// Check if dose was taken on a weekend
  var isWeekendDose: Bool {
    let weekday = Calendar.current.component(.weekday, from: timestamp)
    return weekday == 1 || weekday == 7  // Sunday or Saturday
  }

  // MARK: - Convenience Computed Properties

  /// Formatted dose amount with medication unit
  var formattedAmount: String {
    let unit = "mg"  // Default unit for all GLP-1 medications
    return String(format: "%.2f", amount) + " " + unit
  }

  /// Formatted timestamp for display
  var formattedTimestamp: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: timestamp)
  }

  /// Short date string for grouping
  var dateString: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: timestamp)
  }

  /// Time string for display within date groups
  var timeString: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter.string(from: timestamp)
  }
}

// MARK: - Array Extensions

extension [Dose] {
  /// Filter doses by multiple criteria
  func filtered(
    searchText: String? = nil,
    medication: String? = nil,
    injectionSite: String? = nil,
    dateRange: DateInterval? = nil,
    includeSkipped: Bool = true,
    amountRange: ClosedRange<Double>? = nil
  ) -> [Dose] {
    self.filter { dose in
      checkDoseMatches(
        dose,
        searchText: searchText,
        medication: medication,
        injectionSite: injectionSite,
        dateRange: dateRange,
        includeSkipped: includeSkipped,
        amountRange: amountRange)
    }
  }

  // swiftlint:disable function_parameter_count
  /// Helper to check if dose matches all filtering criteria
  private func checkDoseMatches(
    _ dose: Dose,
    searchText: String?,
    medication: String?,
    injectionSite: String?,
    dateRange: DateInterval?,
    includeSkipped: Bool,
    amountRange: ClosedRange<Double>?
  ) -> Bool {
    // Search text filter
    if let searchText, !searchText.isEmpty, !dose.matches(searchText: searchText) {
      return false
    }

    // Medication filter
    if let medication, !dose.hasMedication(medication) {
      return false
    }

    // Injection site filter
    if let injectionSite, !dose.hasInjectionSite(injectionSite) {
      return false
    }

    // Date range filter
    if let dateRange, !dateRange.contains(dose.timestamp) {
      return false
    }

    // Skipped filter
    if !includeSkipped, dose.skipped {
      return false
    }

    // Amount range filter
    if let amountRange, !amountRange.contains(dose.amount) {
      return false
    }

    return true
  }

  // swiftlint:enable function_parameter_count

  /// Sort doses by timestamp (most recent first by default)
  func sortedByTimestamp(ascending: Bool = false) -> [Dose] {
    sorted { first, second in
      ascending ? first.timestamp < second.timestamp : first.timestamp > second.timestamp
    }
  }

  /// Sort doses by amount
  func sortedByAmount(ascending: Bool = true) -> [Dose] {
    sorted { first, second in
      ascending ? first.amount < second.amount : first.amount > second.amount
    }
  }

  /// Group doses by date
  func groupedByDate() -> [(String, [Dose])] {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none

    let grouped = Dictionary(grouping: self) { dose in
      formatter.string(from: dose.timestamp)
    }

    return grouped.sorted { first, second in
      guard let firstDate = formatter.date(from: first.key),
        let secondDate = formatter.date(from: second.key)
      else {
        return first.key > second.key
      }
      return firstDate > secondDate
    }.map { key, doses in
      (key, doses.sorted { $0.timestamp > $1.timestamp })
    }
  }

  // NOTE: Removed problematic unique methods due to Swift compiler type inference issues
  // These are available as computed properties in DoseHistoryViewModel instead

  /// Get dose count for each medication
  var medicationCounts: [String: Int] {
    Dictionary(grouping: self) { $0.medication?.genericName ?? "Unknown" }
      .mapValues { $0.count }
  }

  /// Get dose count for each injection site
  var injectionSiteCounts: [String: Int] {
    Dictionary(grouping: self) { $0.site ?? "Unknown" }
      .mapValues { $0.count }
  }
}
