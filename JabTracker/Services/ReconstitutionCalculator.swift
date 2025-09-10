//
//  ReconstitutionCalculator.swift
//  JabTracker
//

import Foundation

/// Calculates reconstitution instructions for compounded GLP-1 medications
enum ReconstitutionCalculator {
    /// Represents the result of a reconstitution calculation
    struct ReconstitutionResult {
        let waterVolume: Double // ml to add
        let unitsPerDose: Double // units to inject for target dose
        let concentration: Double // mg per ml after reconstitution
        let totalUnits: Double // total units in reconstituted vial

        var displayText: String {
            let water = self.waterVolume.formatted(.number.precision(.fractionLength(1)))
            let units = self.unitsPerDose.formatted(.number.precision(.fractionLength(1)))
            return "Add \(water) ml water. Your dose is \(units) units"
        }
    }

    /// Error types for reconstitution calculations
    enum ReconstitutionError: LocalizedError {
        case invalidVialStrength
        case invalidTargetDose
        case targetDoseExceedsVialStrength
        case invalidWaterVolume

        var errorDescription: String? {
            switch self {
            case .invalidVialStrength:
                return "Vial strength must be greater than 0"
            case .invalidTargetDose:
                return "Target dose must be greater than 0"
            case .targetDoseExceedsVialStrength:
                return "Target dose cannot exceed vial strength"
            case .invalidWaterVolume:
                return "Water volume must be greater than 0"
            }
        }
    }

    /// Calculate reconstitution instructions for a compounded medication
    /// - Parameters:
    ///   - vialStrength: Total medication amount in vial (mg)
    ///   - targetDose: Desired dose per injection (mg)
    ///   - waterVolume: Amount of bacteriostatic water to add (ml)
    /// - Returns: ReconstitutionResult with instructions
    /// - Throws: ReconstitutionError for invalid inputs
    static func calculate(
        vialStrength: Double,
        targetDose: Double,
        waterVolume: Double) throws -> ReconstitutionResult
    {
        // Validate inputs
        guard vialStrength > 0 else {
            throw ReconstitutionError.invalidVialStrength
        }

        guard targetDose > 0 else {
            throw ReconstitutionError.invalidTargetDose
        }

        guard targetDose <= vialStrength else {
            throw ReconstitutionError.targetDoseExceedsVialStrength
        }

        guard waterVolume > 0 else {
            throw ReconstitutionError.invalidWaterVolume
        }

        // Calculate concentration after reconstitution
        let concentration = vialStrength / waterVolume // mg per ml

        // Calculate volume needed for target dose
        let volumePerDose = targetDose / concentration // ml

        // Convert to insulin units (100 units = 1 ml)
        let unitsPerDose = volumePerDose * 100.0
        let totalUnits = waterVolume * 100.0

        return ReconstitutionResult(
            waterVolume: waterVolume,
            unitsPerDose: unitsPerDose,
            concentration: concentration,
            totalUnits: totalUnits)
    }

    /// Calculate water volume needed for a desired units-per-dose
    /// - Parameters:
    ///   - vialStrength: Total medication amount in vial (mg)
    ///   - targetDose: Desired dose per injection (mg)
    ///   - desiredUnits: Desired number of units per dose
    /// - Returns: Water volume to add (ml)
    /// - Throws: ReconstitutionError for invalid inputs
    static func calculateWaterVolume(
        vialStrength: Double,
        targetDose: Double,
        desiredUnits: Double) throws -> Double
    {
        // Validate inputs
        guard vialStrength > 0 else {
            throw ReconstitutionError.invalidVialStrength
        }

        guard targetDose > 0 else {
            throw ReconstitutionError.invalidTargetDose
        }

        guard targetDose <= vialStrength else {
            throw ReconstitutionError.targetDoseExceedsVialStrength
        }

        guard desiredUnits > 0 else {
            throw ReconstitutionError.invalidWaterVolume
        }

        // Calculate water volume needed
        // Formula: waterVolume = (vialStrength * desiredUnits) / (targetDose * 100)
        let waterVolume = (vialStrength * desiredUnits) / (targetDose * 100.0)

        return waterVolume
    }

    /// Common reconstitution scenarios for quick reference
    static func commonScenarios() -> [(String, ReconstitutionResult)] {
        var scenarios: [(String, ReconstitutionResult)] = []

        // Common vial and dose combinations
        let commonCombinations = [
            (vialStrength: 5.0, targetDose: 0.25, waterVolume: 2.0, label: "5mg vial, 0.25mg dose"),
            (vialStrength: 5.0, targetDose: 0.5, waterVolume: 2.0, label: "5mg vial, 0.5mg dose"),
            (vialStrength: 5.0, targetDose: 1.0, waterVolume: 2.0, label: "5mg vial, 1.0mg dose"),
            (vialStrength: 10.0, targetDose: 1.0, waterVolume: 2.0, label: "10mg vial, 1.0mg dose"),
            (vialStrength: 10.0, targetDose: 2.0, waterVolume: 2.0, label: "10mg vial, 2.0mg dose"),
            (vialStrength: 10.0, targetDose: 2.5, waterVolume: 3.0, label: "10mg vial, 2.5mg dose"),
        ]

        for combo in commonCombinations {
            if let result = try? calculate(
                vialStrength: combo.vialStrength,
                targetDose: combo.targetDose,
                waterVolume: combo.waterVolume)
            {
                scenarios.append((combo.label, result))
            }
        }

        return scenarios
    }
}
