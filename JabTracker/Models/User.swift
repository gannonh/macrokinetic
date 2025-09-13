//
//  User.swift
//  JabTracker
//

import Foundation
import SwiftData

@Model
final class User {
    var id: UUID = UUID()
    var email: String? // Optional - genuinely no email vs empty string ambiguity resolved
    var name: String? // Optional - Apple might not provide
    var dateOfBirth: Date? // Optional - user may choose not to provide
    var weight: Double = 70.0 // Required with default for medical app
    var weightUnit: String = "kg" // Required with default
    var timezone: String = TimeZone.current.identifier // Required with default
    var appleUserId: String? // For Sign in with Apple linking
    var createdAt: Date = Date() // Required - auto-generated
    var updatedAt: Date = Date() // Required - auto-generated

    // Onboarding tracking
    var hasCompletedOnboarding: Bool = false // Track onboarding completion
    var onboardingCompletedAt: Date? // When onboarding was completed

    @Relationship(deleteRule: .cascade)
    var doses: [Dose]? // CloudKit requires optional relationships

    @Relationship(deleteRule: .cascade)
    var medicationProfiles: [MedicationProfile]? // CloudKit requires optional relationships

    init(
        email: String? = nil,
        name: String? = nil,
        dateOfBirth: Date? = nil,
        weight: Double = 70.0,
        weightUnit: String = "kg",
        timezone: String = TimeZone.current.identifier,
        appleUserId: String? = nil,
        hasCompletedOnboarding: Bool = false)
    {
        self.email = email
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.weight = weight
        self.weightUnit = weightUnit
        self.timezone = timezone
        self.appleUserId = appleUserId
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = Date()
        self.updatedAt = Date()
        // Don't initialize optional relationship - let SwiftData handle it
    }
}

// MARK: - Computed Properties

extension User {
    /// Formatted weight display for UI presentation
    var weightDisplay: String {
        String(format: "%.1f %@", self.weight, self.weightUnit)
    }

    /// CloudKit-compatible email field - returns empty string if email is nil
    /// This handles CloudKit's requirement for non-nil values while preserving semantic meaning
    var emailForCloudKit: String {
        self.email ?? ""
    }

    /// Display email - handles nil email gracefully for UI presentation
    var displayEmail: String {
        self.email ?? "No email"
    }
}
