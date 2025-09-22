//
//  DoseTitration.swift
//  JabTracker
//

import Foundation
import SwiftData

@Model
final class DoseTitration {
  var id: UUID = UUID()
  var fromDose: Double = 0.0  // Starting dose amount (CloudKit requires default)
  var toDose: Double = 0.0  // Target dose amount (CloudKit requires default)
  var scheduledDate: Date = Date()  // When titration should occur (CloudKit requires default)
  var isCompleted: Bool = false  // Whether titration has been completed
  var completedDate: Date?  // When titration was actually completed (optional)
  var notes: String = ""  // User notes about titration (CloudKit requires default)
  var createdAt: Date = Date()  // Track creation
  var updatedAt: Date = Date()  // Track modifications

  var medicationProfile: MedicationProfile?  // Parent medication profile relationship

  init(
    fromDose: Double = 0.0,
    toDose: Double = 0.0,
    scheduledDate: Date = Date(),
    isCompleted: Bool = false,
    completedDate: Date? = nil,
    notes: String = "",
    medicationProfile: MedicationProfile? = nil
  ) {
    self.fromDose = fromDose
    self.toDose = toDose
    self.scheduledDate = scheduledDate
    self.isCompleted = isCompleted
    self.completedDate = completedDate
    self.notes = notes
    self.medicationProfile = medicationProfile
    self.createdAt = Date()
    self.updatedAt = Date()
  }

  // MARK: - Computed Properties

  /// User-friendly description of the titration
  var titrationDescription: String {
    let fromFormatted = String(format: "%.2f", fromDose)
    let toFormatted = String(format: "%.2f", toDose)
    return "\(fromFormatted) mg → \(toFormatted) mg"
  }

  /// Status display text for UI
  var statusText: String {
    if self.isCompleted {
      return "Completed: \(self.titrationDescription)"
    } else {
      return "Scheduled: \(self.titrationDescription)"
    }
  }

  /// Whether this titration is scheduled for the future
  var isFuture: Bool {
    self.scheduledDate > Date() && !self.isCompleted
  }

  /// Whether this titration is overdue
  var isOverdue: Bool {
    self.scheduledDate < Date() && !self.isCompleted
  }

  // MARK: - Business Logic

  /// Mark titration as completed and update medication profile dose
  func markCompleted() {
    self.isCompleted = true
    self.completedDate = Date()
    self.updatedAt = Date()

    // Update medication profile current dose when titration is completed
    self.medicationProfile?.currentDose = self.toDose
    self.medicationProfile?.updatedAt = Date()
  }

  /// Validate that titration target dose is appropriate
  func validateTitration() -> Bool {
    // Allow for small time differences (1 minute) to handle test timing issues
    let now = Date()
    let oneMinuteAgo = now.addingTimeInterval(-60)
    return self.toDose > self.fromDose && self.scheduledDate >= oneMinuteAgo
  }
}
