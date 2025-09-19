//
//  DoseService.swift
//  JabTracker
//
//  Service for coordinating dose persistence with pharmacokinetics calculations
//  Ensures PK engine is updated whenever dose data changes
//

import Foundation
import SwiftData
import Observation

/// Service layer for dose management with integrated pharmacokinetics calculations
/// Coordinates between dose persistence and PK engine updates for real-time dashboard updates
@Observable
final class DoseService {

    // MARK: - Dependencies

    private let pkEngine: PharmacokineticsEngine

    // MARK: - Published State

    /// Indicates if a dose operation is in progress
    var isProcessingDose: Bool = false

    /// Last error that occurred during dose operations
    var lastError: DoseServiceError?

    /// Timestamp of last successful dose operation (for dashboard refresh triggers)
    var lastDoseUpdateTime: Date?

    // MARK: - Initialization

    init(pkEngine: PharmacokineticsEngine) {
        self.pkEngine = pkEngine
    }

    // MARK: - Dose Creation

    /// Saves a new dose and triggers pharmacokinetics recalculation
    /// - Parameters:
    ///   - amount: Dose amount in mg
    ///   - timestamp: When the dose was administered
    ///   - medicationProfile: Associated medication profile
    ///   - site: Injection site (optional)
    ///   - notes: User notes (optional)
    ///   - skipped: Whether this dose was missed/skipped
    ///   - imageData: Optional photo of injection (optional)
    ///   - context: SwiftData model context for persistence
    /// - Returns: The saved dose object
    /// - Throws: DoseServiceError for validation or persistence failures
    @MainActor
    func saveDose(
        amount: Double,
        timestamp: Date,
        medicationProfile: MedicationProfile,
        site: String? = nil,
        notes: String? = nil,
        skipped: Bool = false,
        imageData: Data? = nil,
        context: ModelContext
    ) async throws -> Dose {
        print("🔍 DoseService.saveDose called with amount: \(amount), site: \(site ?? "nil"), notes: \(notes ?? "nil")")

        isProcessingDose = true
        lastError = nil

        defer {
            isProcessingDose = false
        }

        do {
            // Validate dose parameters
            try validateDoseParameters(
                amount: amount,
                timestamp: timestamp,
                medicationProfile: medicationProfile,
                site: site,
                notes: notes
            )

            // Create new dose
            let newDose = Dose(
                amount: amount,
                timestamp: timestamp,
                site: site,
                notes: notes,
                imageData: imageData,
                skipped: skipped,
                user: nil, // Will be set through medication profile relationship
                medication: medicationProfile
            )

            print("🔍 DoseService: Creating dose with ID: \(newDose.id), site: \(newDose.site ?? "nil")")

            // Insert and save to database
            context.insert(newDose)
            print("🔍 DoseService: Inserted dose into context")

            try context.save()
            print("🔍 DoseService: Saved context successfully")

            // Trigger PK engine recalculation
            await triggerPKRecalculation(for: medicationProfile)

            // Update last operation timestamp for dashboard refresh
            lastDoseUpdateTime = Date()

            return newDose

        } catch let error as DoseServiceError {
            lastError = error
            throw error
        } catch {
            let wrappedError = DoseServiceError.persistenceFailure(underlying: error)
            lastError = wrappedError
            throw wrappedError
        }
    }

    // MARK: - Dose Updates

    /// Updates an existing dose and recalculates pharmacokinetics
    /// - Parameters:
    ///   - editData: Updated dose information
    ///   - context: SwiftData model context
    /// - Throws: DoseServiceError for validation or persistence failures
    @MainActor
    func updateDose(with editData: DoseEditData, context: ModelContext) async throws {
        isProcessingDose = true
        lastError = nil

        defer {
            isProcessingDose = false
        }

        do {
            // Fetch existing dose
            let doseId = editData.id
            let doseDescriptor = FetchDescriptor<Dose>(
                predicate: #Predicate<Dose> { dose in
                    dose.id == doseId
                }
            )

            guard let existingDose = try context.fetch(doseDescriptor).first else {
                throw DoseServiceError.doseNotFound
            }

            // Validate updated parameters
            try validateDoseParameters(
                amount: editData.amount,
                timestamp: editData.timestamp,
                medicationProfile: editData.medicationProfile,
                site: editData.site,
                notes: editData.notes
            )

            // Update dose properties
            existingDose.amount = editData.amount
            existingDose.timestamp = editData.timestamp
            existingDose.site = editData.site
            existingDose.notes = editData.notes
            existingDose.imageData = editData.imageData
            existingDose.skipped = editData.skipped

            // Update medication profile if changed
            if existingDose.medication?.id != editData.medicationProfile.id {
                existingDose.medication = editData.medicationProfile
            }

            // Save changes
            try context.save()

            // Trigger PK recalculation for both old and new medication profiles
            await triggerPKRecalculation(for: editData.medicationProfile)

            // Update last operation timestamp
            lastDoseUpdateTime = Date()

        } catch let error as DoseServiceError {
            lastError = error
            throw error
        } catch {
            let wrappedError = DoseServiceError.persistenceFailure(underlying: error)
            lastError = wrappedError
            throw wrappedError
        }
    }

    // MARK: - Dose Deletion

    /// Deletes a dose and recalculates pharmacokinetics
    /// - Parameters:
    ///   - doseId: ID of dose to delete
    ///   - context: SwiftData model context
    /// - Throws: DoseServiceError for persistence failures
    @MainActor
    func deleteDose(with doseId: UUID, context: ModelContext) async throws {
        isProcessingDose = true
        lastError = nil

        defer {
            isProcessingDose = false
        }

        do {
            // Fetch dose to delete
            let doseDescriptor = FetchDescriptor<Dose>(
                predicate: #Predicate<Dose> { dose in
                    dose.id == doseId
                }
            )

            guard let doseToDelete = try context.fetch(doseDescriptor).first else {
                throw DoseServiceError.doseNotFound
            }

            let medicationProfile = doseToDelete.medication

            // Delete dose
            context.delete(doseToDelete)
            try context.save()

            // Trigger PK recalculation if medication profile exists
            if let profile = medicationProfile {
                await triggerPKRecalculation(for: profile)
            }

            // Update last operation timestamp
            lastDoseUpdateTime = Date()

        } catch let error as DoseServiceError {
            lastError = error
            throw error
        } catch {
            let wrappedError = DoseServiceError.persistenceFailure(underlying: error)
            lastError = wrappedError
            throw wrappedError
        }
    }

    // MARK: - PK Engine Integration

    /// Triggers pharmacokinetics recalculation for a medication profile
    /// This method can be called manually to refresh calculations without dose changes
    /// - Parameter medicationProfile: Profile to recalculate
    @MainActor
    private func triggerPKRecalculation(for medicationProfile: MedicationProfile) async {
        // Ensure PK engine has latest dose data
        // The engine will automatically use the updated doses when calculations are requested

        // Note: PK engine calculations are performed on-demand rather than cached
        // This ensures calculations always reflect the current dose data
        // Dashboard components will request fresh calculations when they update

        // Update the timestamp to signal dashboard components to refresh
        lastDoseUpdateTime = Date()
    }

    // MARK: - Validation

    /// Validates dose parameters before saving or updating
    /// - Parameters:
    ///   - amount: Dose amount to validate
    ///   - timestamp: Dose timestamp to validate
    ///   - medicationProfile: Associated medication profile
    ///   - site: Injection site (for validation consistency)
    ///   - notes: User notes (for validation consistency)
    /// - Throws: DoseServiceError for invalid parameters
    private func validateDoseParameters(
        amount: Double,
        timestamp: Date,
        medicationProfile: MedicationProfile,
        site: String? = nil,
        notes: String? = nil
    ) throws {
        // Validate dose amount
        guard amount >= 0 else {
            throw DoseServiceError.invalidDoseAmount("Dose amount cannot be negative")
        }

        guard amount <= 1000 else {
            throw DoseServiceError.invalidDoseAmount("Dose amount cannot exceed 1000mg")
        }

        // Validate timestamp (allow future doses for scheduled entries)
        let maxFutureTime = Date().addingTimeInterval(365 * 24 * 3600) // 1 year in future
        guard timestamp <= maxFutureTime else {
            throw DoseServiceError.invalidTimestamp("Dose timestamp cannot be more than 1 year in the future")
        }

        // Validate medication profile has required information
        guard medicationProfile.medication != nil else {
            throw DoseServiceError.invalidMedicationProfile("Medication profile must have medication type set")
        }

        // Validate PK calculation inputs if not skipped dose
        if amount > 0 {
            guard let medication = medicationProfile.medication else {
                throw DoseServiceError.invalidMedicationProfile("Missing medication for PK calculations")
            }

            let doses = medicationProfile.doses ?? []
            // Create temporary dose for validation WITHOUT setting the medication relationship
            // to prevent it from being accidentally persisted
            let tempDose = Dose(amount: amount, timestamp: timestamp, site: site, notes: notes)
            let dosesForValidation = doses + [tempDose]

            if !pkEngine.validateCalculationInputs(doses: dosesForValidation, medication: medication) {
                if let validationError = pkEngine.getValidationError(
                    doses: dosesForValidation,
                    medication: medication
                ) {
                    throw DoseServiceError.pkValidationFailure(validationError)
                } else {
                    throw DoseServiceError.pkValidationFailure(
                        "Invalid dose parameters for pharmacokinetic calculations"
                    )
                }
            }
        }
    }
}

// MARK: - Error Types

/// Errors that can occur during dose service operations
enum DoseServiceError: LocalizedError, Equatable {
    case invalidDoseAmount(String)
    case invalidTimestamp(String)
    case invalidMedicationProfile(String)
    case doseNotFound
    case pkValidationFailure(String)
    case persistenceFailure(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidDoseAmount(let message):
            return "Invalid dose amount: \(message)"
        case .invalidTimestamp(let message):
            return "Invalid dose timing: \(message)"
        case .invalidMedicationProfile(let message):
            return "Invalid medication profile: \(message)"
        case .doseNotFound:
            return "Dose not found"
        case .pkValidationFailure(let message):
            return "Pharmacokinetic validation failed: \(message)"
        case .persistenceFailure(let error):
            return "Failed to save dose: \(error.localizedDescription)"
        }
    }

    // MARK: - Equatable

    static func == (lhs: DoseServiceError, rhs: DoseServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidDoseAmount(let lhsMessage), .invalidDoseAmount(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.invalidTimestamp(let lhsMessage), .invalidTimestamp(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.invalidMedicationProfile(let lhsMessage), .invalidMedicationProfile(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.doseNotFound, .doseNotFound):
            return true
        case (.pkValidationFailure(let lhsMessage), .pkValidationFailure(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.persistenceFailure, .persistenceFailure):
            return true // Simplified comparison for underlying errors
        default:
            return false
        }
    }
}

// MARK: - Supporting Types

/// Data structure for dose editing operations
struct DoseEditData: Identifiable {
    let id: UUID
    let amount: Double
    let timestamp: Date
    let site: String?
    let notes: String?
    let imageData: Data?
    let skipped: Bool
    let medicationProfile: MedicationProfile
}
