//
//  MedicationManager.swift
//  JabTracker
//

import Foundation
import SwiftData

/// Manages CRUD operations for medication profiles with validation
@MainActor
class MedicationManager: ObservableObject {
    private let modelContext: ModelContext
    @Published var profiles: [MedicationProfile] = []
    @Published var activeProfile: MedicationProfile?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.fetchProfiles()
    }

    /// Error types for medication management
    enum MedicationError: LocalizedError, Equatable {
        case invalidDose
        case doseOutOfRange(medication: Medication, currentDose: Double)
        case profileNotFound
        case invalidCompoundingSettings
        case saveFailed

        var errorDescription: String? {
            switch self {
            case .invalidDose:
                return "Invalid dose amount"
            case let .doseOutOfRange(medication, currentDose):
                let minDose = medication.availableDoses.min() ?? 0.0
                let maxDose = medication.availableDoses.max() ?? 0.0
                let dose = String(format: "%.2f", currentDose)
                let min = String(format: "%.2f", minDose)
                let max = String(format: "%.2f", maxDose)
                let displayName = medication.displayName
                return "Dose \(dose) mg is outside the available range for \(displayName). "
                    + "Valid range: \(min) - \(max) mg."
            case .profileNotFound:
                return "Medication profile not found"
            case .invalidCompoundingSettings:
                return "Invalid compounding settings. Please check vial strength and water volume"
            case .saveFailed:
                return "Failed to save medication profile"
            }
        }
    }

    // MARK: - CRUD Operations

    /// Fetch all medication profiles for the current user (including disabled)
    func fetchProfiles(for user: User? = nil) {
        if let user {
            // Filter profiles by user relationship (includes both active and disabled)
            let userId = user.id
            let descriptor = FetchDescriptor<MedicationProfile>(
                predicate: #Predicate<MedicationProfile> { profile in
                    profile.user?.id == userId
                },
                sortBy: [SortDescriptor(\.startDate, order: .reverse)])

            do {
                self.profiles = try self.modelContext.fetch(descriptor)
                self.activeProfile = self.profiles.first { profile in
                    // Most recent ACTIVE profile is considered active
                    profile.isActive && profile.startDate <= Date()
                }
            } catch {
                print("Failed to fetch medication profiles for user: \(error)")
                self.profiles = []
            }
        } else {
            // Fetch all profiles (for backward compatibility - includes both active and disabled)
            let descriptor = FetchDescriptor<MedicationProfile>(
                sortBy: [SortDescriptor(\.startDate, order: .reverse)]
            )

            do {
                self.profiles = try self.modelContext.fetch(descriptor)
                self.activeProfile = self.profiles.first { profile in
                    // Most recent ACTIVE profile is considered active
                    profile.isActive && profile.startDate <= Date()
                }
            } catch {
                print("Failed to fetch medication profiles: \(error)")
                self.profiles = []
            }
        }
    }

    /// Create a new medication profile
    func createProfile(
        for user: User,
        medication: Medication,
        brandName: String,
        currentDose: Double,
        startDate: Date = Date(),
        preferredInjectionSites: [String] = ["Thigh"],
        isCompounded: Bool = false,
        vialStrength: Double? = nil,
        reconstitutionVolume: Double? = nil,
        concentration: Double? = nil,
        unitsPerDose: Double? = nil,
        notes: String = ""
    ) throws -> MedicationProfile {
        // Validate dose is within brand-specific medication range
        let validDoses = medication.availableDoses(for: brandName)
        guard validDoses.contains(where: { abs($0 - currentDose) < 0.01 }) else {
            throw MedicationError.doseOutOfRange(medication: medication, currentDose: currentDose)
        }

        // Validate compounding settings if applicable
        if isCompounded {
            guard let vialStrength,
                let reconstitutionVolume,
                vialStrength >= currentDose,
                reconstitutionVolume > 0
            else {
                throw MedicationError.invalidCompoundingSettings
            }
        }

        let profile = MedicationProfile(
            genericName: medication.displayName,
            brandName: brandName,
            currentDose: currentDose,
            startDate: startDate,
            refillDate: nil,
            medicationType: medication.rawValue,
            isCompounded: isCompounded,
            vialStrength: vialStrength,
            reconstitutionVolume: reconstitutionVolume,
            concentration: concentration,
            unitsPerDose: unitsPerDose,
            preferredInjectionSites: preferredInjectionSites,
            notes: notes)

        // Link profile to user
        profile.user = user

        self.modelContext.insert(profile)

        // Create initial dose schedule for the new profile
        try createScheduleForProfile(profile)

        do {
            try self.modelContext.save()
            self.fetchProfiles(for: user)
            return profile
        } catch {
            throw MedicationError.saveFailed
        }
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    /// Update an existing medication profile
    /// Complex medical validation logic requiring multiple parameter validation paths for patient safety
    func updateProfile(
        _ profile: MedicationProfile,
        medication: Medication? = nil,
        brandName: String? = nil,
        currentDose: Double? = nil,
        startDate: Date? = nil,
        refillDate: Date? = nil,
        preferredInjectionSites: [String]? = nil,
        isCompounded: Bool? = nil,
        vialStrength: Double? = nil,
        reconstitutionVolume: Double? = nil,
        concentration: Double? = nil,
        unitsPerDose: Double? = nil,
        notes: String? = nil
    ) throws {
        // Update medication type if provided
        if let medication {
            profile.medicationType = medication.rawValue
        }

        // Update brand name if provided
        if let brandName {
            profile.brandName = brandName
        }

        // Determine the medication to use for dose validation
        let medicationForValidation = medication ?? profile.medication

        // Validate dose if provided
        if let currentDose,
            let medicationForValidation
        {
            let brandNameForValidation = brandName ?? profile.brandName
            let validDoses = medicationForValidation.availableDoses(for: brandNameForValidation)
            guard validDoses.contains(where: { abs($0 - currentDose) < 0.01 }) else {
                throw MedicationError.doseOutOfRange(
                    medication: medicationForValidation, currentDose: currentDose)
            }
            profile.currentDose = currentDose
        }

        // Update other fields if provided
        if let startDate {
            profile.startDate = startDate
        }

        if let refillDate {
            profile.refillDate = refillDate
        }

        if let preferredInjectionSites {
            profile.preferredInjectionSites = preferredInjectionSites
        }

        if let isCompounded {
            profile.isCompounded = isCompounded
        }

        if let vialStrength {
            profile.vialStrength = vialStrength
        }

        if let reconstitutionVolume {
            profile.reconstitutionVolume = reconstitutionVolume
        }

        if let concentration {
            profile.concentration = concentration
        }

        if let unitsPerDose {
            profile.unitsPerDose = unitsPerDose
        }

        if let notes {
            profile.notes = notes
        }

        // Validate compounding settings if compounded
        if profile.isCompounded {
            guard let vialStrength = profile.vialStrength,
                let reconstitutionVolume = profile.reconstitutionVolume,
                vialStrength >= profile.currentDose,
                reconstitutionVolume > 0
            else {
                throw MedicationError.invalidCompoundingSettings
            }
        }

        profile.updatedAt = Date()

        do {
            try self.modelContext.save()
            self.fetchProfiles()
        } catch {
            throw MedicationError.saveFailed
        }
    }

    // swiftlint:enable cyclomatic_complexity function_body_length

    /// Disable a medication profile (soft delete - preserves historical dose data)
    ///
    /// This is the recommended way to "delete" a medication profile as it preserves
    /// all historical dose data and analytics while removing the profile from active
    /// medication lists. Schedules are deleted but historical doses are preserved.
    /// The profile can be re-enabled later if needed.
    ///
    /// - Parameter profile: The medication profile to disable
    /// - Throws: MedicationError.saveFailed if the save operation fails
    func disableProfile(_ profile: MedicationProfile) throws {
        // Delete schedules (user no longer using this medication)
        if let schedules = profile.schedules {
            for schedule in schedules {
                self.modelContext.delete(schedule)
            }
        }

        // Mark profile as inactive (preserves historical doses)
        profile.isActive = false
        profile.updatedAt = Date()

        do {
            try self.modelContext.save()
            self.fetchProfiles()
        } catch {
            throw MedicationError.saveFailed
        }
    }

    /// Enable a previously disabled medication profile
    ///
    /// Re-activates a disabled profile, making it visible in active medication lists again.
    /// Creates a new dose schedule starting from the re-enable date.
    ///
    /// - Parameter profile: The medication profile to enable
    /// - Throws: MedicationError.saveFailed if the save operation fails
    func enableProfile(_ profile: MedicationProfile) throws {
        profile.isActive = true
        profile.updatedAt = Date()

        // Create a new dose schedule when re-enabling
        try createScheduleForProfile(profile)

        do {
            try self.modelContext.save()
            self.fetchProfiles()
        } catch {
            throw MedicationError.saveFailed
        }
    }

    /// Creates a default dose schedule for a medication profile
    /// - Parameter profile: The medication profile to create a schedule for
    /// - Throws: MedicationError.saveFailed if schedule creation fails
    private func createScheduleForProfile(_ profile: MedicationProfile) throws {
        // Get medication frequency
        guard let medication = profile.medication else {
            throw MedicationError.saveFailed
        }

        // Create schedule service
        let scheduleService = ScheduleService(context: self.modelContext)

        // Determine pattern and configuration based on medication frequency
        let now = Date()
        let calendar = Calendar.current
        let pattern: SchedulePatternType
        let interval: Int
        let dayOfWeek: Int?

        switch medication.frequency {
        case .daily:
            pattern = .daily
            interval = 1
            dayOfWeek = nil
        case .weekly:
            pattern = .weekly
            interval = 7
            dayOfWeek = calendar.component(.weekday, from: now)
        }

        // Create default configuration
        let scheduleConfig = ScheduleConfiguration(
            dayOfWeek: dayOfWeek,
            timeOfDay: TimeComponents(
                hour: calendar.component(.hour, from: now),
                minute: calendar.component(.minute, from: now)
            ),
            interval: interval,
            doseAmount: profile.currentDose,
            windowMinutesBefore: 120,  // 2 hours before
            windowMinutesAfter: 120,  // 2 hours after
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        // Create the schedule
        _ = try scheduleService.createSchedule(
            for: profile,
            pattern: pattern,
            startDate: now,
            baseSchedule: scheduleConfig
        )
    }

    /// Permanently delete a medication profile and all associated data
    ///
    /// ⚠️ **WARNING**: This is a destructive operation that cannot be undone.
    /// All historical doses, schedules, and titrations will be permanently deleted.
    ///
    /// **Recommended**: Use `disableProfile()` instead to preserve historical dose data.
    ///
    /// - Parameter profile: The medication profile to permanently delete
    /// - Throws: MedicationError.saveFailed if the save operation fails
    func permanentlyDeleteProfile(_ profile: MedicationProfile) throws {
        // Manually delete associated schedules (cascade delete may not work reliably with SwiftData)
        // Each schedule has cascade delete configured for ScheduledDose, so deleting the schedule
        // will delete the scheduled doses as well
        if let schedules = profile.schedules {
            for schedule in schedules {
                self.modelContext.delete(schedule)
            }
        }

        // Manually delete associated doses (cascade delete may not work reliably with SwiftData)
        if let doses = profile.doses {
            for dose in doses {
                self.modelContext.delete(dose)
            }
        }

        // Delete the profile itself
        self.modelContext.delete(profile)

        do {
            try self.modelContext.save()
            self.fetchProfiles()
        } catch {
            throw MedicationError.saveFailed
        }
    }

    /// Legacy method - now calls disableProfile() for backward compatibility
    /// - Deprecated: Use disableProfile() or permanentlyDeleteProfile() explicitly
    @available(
        *, deprecated, renamed: "disableProfile",
        message: "Use disableProfile() for soft delete or permanentlyDeleteProfile() for hard delete"
    )
    func deleteProfile(_ profile: MedicationProfile) throws {
        try disableProfile(profile)
    }

    // MARK: - Validation Helpers

    /// Check if a dose is valid for a medication
    func isValidDose(_ dose: Double, for medication: Medication) -> Bool {
        medication.availableDoses.contains { availableDose in
            abs(availableDose - dose) < 0.01
        }
    }

    /// Check if a dose is valid for a specific medication brand
    func isValidDose(_ dose: Double, for medication: Medication, brandName: String) -> Bool {
        medication.availableDoses(for: brandName).contains { availableDose in
            abs(availableDose - dose) < 0.01
        }
    }

    /// Get the next recommended dose for escalation
    func nextEscalationDose(for profile: MedicationProfile) -> Double? {
        guard let medication = profile.medication else { return nil }

        let currentDose = profile.currentDose
        let brandName = profile.brandName
        let availableDoses = medication.availableDoses(for: brandName).sorted()

        // Find the next higher dose for this specific brand
        for dose in availableDoses where dose > currentDose {
            return dose
        }

        return nil  // Already at maximum dose for this brand
    }

    /// Calculate days until refill needed
    func daysUntilRefill(for profile: MedicationProfile) -> Int? {
        guard let refillDate = profile.refillDate else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: refillDate)
        return components.day
    }

    // MARK: - Reconstitution Helpers

    /// Calculate reconstitution for a compounded profile
    func calculateReconstitution(for profile: MedicationProfile) throws
        -> ReconstitutionCalculator.ReconstitutionResult?
    {
        guard profile.isCompounded,
            let vialStrength = profile.vialStrength,
            let reconstitutionVolume = profile.reconstitutionVolume
        else {
            return nil
        }

        return try ReconstitutionCalculator.calculate(
            vialStrength: vialStrength,
            targetDose: profile.currentDose,
            waterVolume: reconstitutionVolume)
    }
}
