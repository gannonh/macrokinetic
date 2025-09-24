// MedicationManager Service Contract
// This file defines the expected interface for medication profile management

import Foundation
import SwiftData

/// Service for managing medication profiles with CRUD operations
protocol MedicationManagerProtocol {
    // MARK: - Profile Management

    /// Creates a new medication profile for the current user
    /// - Parameters:
    ///   - medicationType: The GLP-1 medication type
    ///   - brandName: Specific brand name
    ///   - currentDose: Starting dose in mg
    ///   - isCompounded: Whether medication is compounded
    /// - Returns: Created medication profile
    /// - Throws: MedicationError for validation failures
    func createMedicationProfile(
        medicationType: Medication,
        brandName: String,
        currentDose: Double,
        isCompounded: Bool
    ) async throws -> MedicationProfile

    /// Retrieves all medication profiles for the current user
    /// - Returns: Array of medication profiles, ordered by creation date
    func getMedicationProfiles() async -> [MedicationProfile]

    /// Gets the currently active medication profile
    /// - Returns: Active profile, or nil if none set
    func getActiveMedicationProfile() async -> MedicationProfile?

    /// Updates an existing medication profile
    /// - Parameters:
    ///   - profile: Profile to update
    ///   - updates: Dictionary of field updates
    /// - Throws: MedicationError for validation failures
    func updateMedicationProfile(
        _ profile: MedicationProfile,
        updates: [String: Any]) async throws

    /// Deletes a medication profile and all related data
    /// - Parameter profile: Profile to delete
    /// - Throws: MedicationError if profile is currently active
    func deleteMedicationProfile(_ profile: MedicationProfile) async throws

    // MARK: - Dose Escalation

    /// Creates a dose escalation schedule
    /// - Parameters:
    ///   - profile: Medication profile to escalate
    ///   - targetDose: Target dose in mg
    ///   - scheduledDate: When escalation should occur
    /// - Returns: Created escalation record
    /// - Throws: MedicationError for validation failures
    func createDoseEscalation(
        for profile: MedicationProfile,
        targetDose: Double,
        scheduledDate: Date
    ) async throws -> DoseEscalation

    /// Marks dose escalation as completed
    /// - Parameters:
    ///   - escalation: Escalation to complete
    ///   - actualDate: When escalation was actually completed
    func completeDoseEscalation(
        _ escalation: DoseEscalation,
        actualDate: Date) async throws

    // MARK: - Validation

    /// Validates dose against medication constraints
    /// - Parameters:
    ///   - dose: Dose to validate in mg
    ///   - medication: Medication type
    /// - Returns: True if dose is valid
    func validateDose(_ dose: Double, for medication: Medication) -> Bool

    /// Validates compounded medication settings
    /// - Parameters:
    ///   - vialStrength: Strength of vial in mg
    ///   - targetDose: Desired dose in mg
    /// - Returns: True if settings are valid
    func validateCompoundedSettings(
        vialStrength: Double,
        targetDose: Double
    ) -> Bool
}

/// Errors that can occur during medication management
enum MedicationError: LocalizedError {
    case invalidDose(String)
    case invalidCompounding(String)
    case profileNotFound
    case activeProfileExists
    case escalationInvalid(String)
    case persistenceError(Error)

    var errorDescription: String? {
        switch self {
        case let .invalidDose(message):
            return "Invalid dose: \(message)"
        case let .invalidCompounding(message):
            return "Invalid compounding settings: \(message)"
        case .profileNotFound:
            return "Medication profile not found"
        case .activeProfileExists:
            return "An active medication profile already exists"
        case let .escalationInvalid(message):
            return "Invalid dose escalation: \(message)"
        case let .persistenceError(error):
            return "Data storage error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Test Contract Expectations

/// Expected behavior for MedicationManager tests
protocol MedicationManagerTestContract {
    /// Should create valid medication profile with correct properties
    func testCreateMedicationProfile_ValidInput_ReturnsProfile() async throws

    /// Should reject invalid doses outside medication range
    func testCreateMedicationProfile_InvalidDose_ThrowsError() async throws

    /// Should handle compounded medication settings correctly
    func testCreateMedicationProfile_CompoundedSettings_ValidatesCorrectly() async throws

    /// Should retrieve all profiles for user in correct order
    func testGetMedicationProfiles_ReturnsUserProfilesOnly() async throws

    /// Should update profile fields correctly
    func testUpdateMedicationProfile_ValidChanges_UpdatesCorrectly() async throws

    /// Should prevent deletion of active profile
    func testDeleteMedicationProfile_ActiveProfile_ThrowsError() async throws

    /// Should create valid dose escalation
    func testCreateDoseEscalation_ValidTarget_CreatesEscalation() async throws

    /// Should validate dose constraints for each medication type
    func testValidateDose_AllMedicationTypes_ReturnsCorrectResults() async throws

    /// Should validate compounded medication constraints
    func testValidateCompoundedSettings_VariousInputs_ReturnsCorrectResults() async throws
}
