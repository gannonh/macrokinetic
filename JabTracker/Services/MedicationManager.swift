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
                return "Dose \(dose) mg is outside the available range for \(medication.displayName). Valid range: \(min) - \(max) mg."
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

    /// Fetch all medication profiles for the current user
    func fetchProfiles(for user: User? = nil) {
        if let user {
            // Filter profiles by user relationship using the user's ID
            let userId = user.id
            let descriptor = FetchDescriptor<MedicationProfile>(
                predicate: #Predicate<MedicationProfile> { profile in
                    profile.user?.id == userId
                },
                sortBy: [SortDescriptor(\.startDate, order: .reverse)])

            do {
                self.profiles = try self.modelContext.fetch(descriptor)
                self.activeProfile = self.profiles.first { profile in
                    // Most recent profile is considered active
                    profile.startDate <= Date()
                }
            } catch {
                print("Failed to fetch medication profiles for user: \(error)")
                self.profiles = []
            }
        } else {
            // Fetch all profiles (for backward compatibility)
            let descriptor = FetchDescriptor<MedicationProfile>(
                sortBy: [SortDescriptor(\.startDate, order: .reverse)]
            )

            do {
                self.profiles = try self.modelContext.fetch(descriptor)
                self.activeProfile = self.profiles.first { profile in
                    // Most recent profile is considered active
                    profile.startDate <= Date()
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
        isCompounded: Bool = false,
        vialStrength: Double? = nil,
        reconstitutionVolume: Double? = nil,
        penType: String? = nil,
        notes: String = "") throws -> MedicationProfile
    {
        // Validate dose is within medication range
        guard medication.availableDoses.contains(where: { abs($0 - currentDose) < 0.01 }) else {
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
            startDate: Date(),
            refillDate: nil,
            medicationType: medication.rawValue,
            isCompounded: isCompounded,
            vialStrength: vialStrength,
            reconstitutionVolume: reconstitutionVolume,
            penType: penType,
            notes: notes)

        // Link profile to user
        profile.user = user

        self.modelContext.insert(profile)

        do {
            try self.modelContext.save()
            self.fetchProfiles(for: user)
            return profile
        } catch {
            throw MedicationError.saveFailed
        }
    }

    /// Update an existing medication profile
    func updateProfile(
        _ profile: MedicationProfile,
        medication: Medication? = nil,
        brandName: String? = nil,
        currentDose: Double? = nil,
        refillDate: Date? = nil,
        isCompounded: Bool? = nil,
        vialStrength: Double? = nil,
        reconstitutionVolume: Double? = nil,
        penType: String? = nil,
        notes: String? = nil) throws
    {
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
            guard medicationForValidation.availableDoses.contains(where: { abs($0 - currentDose) < 0.01 }) else {
                throw MedicationError.doseOutOfRange(medication: medicationForValidation, currentDose: currentDose)
            }
            profile.currentDose = currentDose
        }

        // Update other fields if provided
        if let refillDate {
            profile.refillDate = refillDate
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

        if let penType {
            profile.penType = penType
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

    /// Delete a medication profile
    func deleteProfile(_ profile: MedicationProfile) throws {
        self.modelContext.delete(profile)

        do {
            try self.modelContext.save()
            self.fetchProfiles()
        } catch {
            throw MedicationError.saveFailed
        }
    }

    // MARK: - Validation Helpers

    /// Check if a dose is valid for a medication
    func isValidDose(_ dose: Double, for medication: Medication) -> Bool {
        medication.availableDoses.contains { availableDose in
            abs(availableDose - dose) < 0.01
        }
    }

    /// Get the next recommended dose for escalation
    func nextEscalationDose(for profile: MedicationProfile) -> Double? {
        guard let medication = profile.medication else { return nil }

        let currentDose = profile.currentDose
        let availableDoses = medication.availableDoses.sorted()

        // Find the next higher dose
        for dose in availableDoses where dose > currentDose {
            return dose
        }

        return nil // Already at maximum dose
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
    func calculateReconstitution(for profile: MedicationProfile) throws -> ReconstitutionCalculator.ReconstitutionResult? {
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

    // MARK: - Pen Click Helpers

    /// Calculate pen clicks for a branded profile
    func calculatePenClicks(for profile: MedicationProfile) throws -> PenClickCalculator.PenClickResult? {
        guard !profile.isCompounded,
              let penTypeString = profile.penType,
              let penType = PenClickCalculator.PenType(rawValue: penTypeString)
        else {
            return nil
        }

        return try PenClickCalculator.calculate(
            penType: penType,
            targetDose: profile.currentDose)
    }
}
