//
//  ConcentrationPoint.swift
//  JabTracker
//

import Foundation

/// Represents a point in time with the calculated drug concentration at that moment
/// Used for pharmacokinetic modeling and visualization of drug levels over time
struct ConcentrationPoint: Codable, Equatable, Hashable {
  /// The specific date and time for this concentration measurement
  let date: Date

  /// The calculated drug concentration at this point in time (arbitrary units)
  /// Represents the cumulative effect of all doses up to this point,
  /// accounting for exponential decay based on medication half-life
  let concentration: Double
}

// MARK: - Comparable

extension ConcentrationPoint: Comparable {
  static func < (lhs: ConcentrationPoint, rhs: ConcentrationPoint) -> Bool {
    lhs.date < rhs.date
  }
}

// MARK: - Identifiable

extension ConcentrationPoint: Identifiable {
  var id: Date { self.date }
}

// MARK: - Helper Properties

extension ConcentrationPoint {
  /// Returns a formatted string representation of the concentration for display
  var concentrationDisplay: String {
    String(format: "%.2f", self.concentration)
  }

  /// Returns a formatted string representation of the date for display
  var dateDisplay: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: self.date)
  }
}
