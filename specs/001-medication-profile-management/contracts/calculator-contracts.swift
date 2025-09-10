// Calculator Service Contracts
// Defines interfaces for reconstitution and pen click calculations

import Foundation

// MARK: - Reconstitution Calculator Contract

/// Service for calculating compounded medication reconstitution
protocol ReconstitutionCalculatorProtocol {
    /// Calculates reconstitution instructions for compounded medication
    /// - Parameters:
    ///   - vialStrength: Total medication in vial (mg)
    ///   - targetDose: Desired dose per injection (mg)
    ///   - waterVolume: Volume of water to add (ml) - defaults to 10ml
    /// - Returns: Reconstitution calculation result
    /// - Throws: CalculationError for invalid inputs
    func calculateReconstitution(
        vialStrength: Double,
        targetDose: Double,
        waterVolume: Double = 10.0) throws -> ReconstitutionResult

    /// Validates reconstitution inputs
    /// - Parameters:
    ///   - vialStrength: Vial strength to validate
    ///   - targetDose: Target dose to validate
    ///   - waterVolume: Water volume to validate
    /// - Returns: True if all inputs are valid
    func validateInputs(
        vialStrength: Double,
        targetDose: Double,
        waterVolume: Double) -> Bool

    /// Gets recommended water volume for given vial strength
    /// - Parameter vialStrength: Strength of vial in mg
    /// - Returns: Recommended water volume in ml
    func getRecommendedWaterVolume(for vialStrength: Double) -> Double
}

// MARK: - Pen Click Calculator Contract

/// Service for calculating pen click adjustments for branded medications
protocol PenClickCalculatorProtocol {
    /// Calculates pen clicks needed for target dose
    /// - Parameters:
    ///   - medication: Medication type (for click ratio lookup)
    ///   - targetDose: Desired dose in mg
    ///   - penType: Specific pen model (optional)
    /// - Returns: Pen click calculation result
    /// - Throws: CalculationError for unsupported combinations
    func calculatePenClicks(
        for medication: Medication,
        targetDose: Double,
        penType: String?) throws -> PenClickResult

    /// Gets available pen types for a medication
    /// - Parameter medication: Medication to get pen types for
    /// - Returns: Array of supported pen type names
    func getAvailablePenTypes(for medication: Medication) -> [String]

    /// Gets click-to-dose ratio for specific pen
    /// - Parameters:
    ///   - medication: Medication type
    ///   - penType: Pen model name
    /// - Returns: Clicks per mg, or nil if unsupported
    func getClickRatio(
        for medication: Medication,
        penType: String?) -> Double?

    /// Validates that pen clicks will deliver accurate dose
    /// - Parameters:
    ///   - clicks: Number of clicks
    ///   - medication: Medication type
    ///   - penType: Pen model
    /// - Returns: True if clicks deliver accurate dose
    func validateClickAccuracy(
        clicks: Int,
        for medication: Medication,
        penType: String?) -> Bool
}

// MARK: - Common Types and Errors

/// Errors that can occur during calculations
enum CalculationError: LocalizedError {
    case invalidInput(String)
    case unsupportedCombination(String)
    case calculationFailed(String)
    case precisionWarning(String)

    var errorDescription: String? {
        switch self {
        case let .invalidInput(message):
            return "Invalid input: \(message)"
        case let .unsupportedCombination(message):
            return "Unsupported combination: \(message)"
        case let .calculationFailed(message):
            return "Calculation failed: \(message)"
        case let .precisionWarning(message):
            return "Precision warning: \(message)"
        }
    }
}

// MARK: - Test Contracts

/// Expected behavior for ReconstitutionCalculator tests
protocol ReconstitutionCalculatorTestContract {
    /// Should calculate correct units for standard scenarios
    func testCalculateReconstitution_StandardInputs_ReturnsCorrectUnits() throws

    /// Should handle edge cases with very small doses
    func testCalculateReconstitution_SmallDoses_HandlesCorrectly() throws

    /// Should reject invalid inputs (target > vial strength)
    func testCalculateReconstitution_InvalidInputs_ThrowsError() throws

    /// Should validate all input parameters correctly
    func testValidateInputs_VariousScenarios_ReturnsCorrectResults()

    /// Should recommend appropriate water volumes
    func testGetRecommendedWaterVolume_AllVialSizes_ReturnsAppropriateVolume()

    /// Should format display text clearly
    func testReconstitutionResult_DisplayText_IsUserFriendly()
}

/// Expected behavior for PenClickCalculator tests
protocol PenClickCalculatorTestContract {
    /// Should calculate correct clicks for all supported medications
    func testCalculatePenClicks_AllMedications_ReturnsCorrectClicks() throws

    /// Should handle pen-specific variations correctly
    func testCalculatePenClicks_DifferentPenTypes_HandlesVariations() throws

    /// Should reject unsupported medication/pen combinations
    func testCalculatePenClicks_UnsupportedCombination_ThrowsError() throws

    /// Should return correct available pen types
    func testGetAvailablePenTypes_AllMedications_ReturnsCorrectTypes()

    /// Should validate click accuracy within acceptable tolerance
    func testValidateClickAccuracy_VariousInputs_ReturnsCorrectValidation()

    /// Should format click instructions clearly
    func testPenClickResult_DisplayText_IsUserFriendly()
}

// MARK: - Integration Test Contract

/// Expected behavior for integrated calculator testing
protocol CalculatorIntegrationTestContract {
    /// Should handle complete medication profile setup workflow
    func testMedicationProfileWorkflow_WithCalculations_CompletesSuccessfully() async throws

    /// Should maintain calculation accuracy across profile updates
    func testProfileUpdates_MaintainCalculationAccuracy() async throws

    /// Should handle switching between compounded and branded medications
    func testMedicationSwitch_CompoundedToBranded_UpdatesCalculationsCorrectly() async throws
}
