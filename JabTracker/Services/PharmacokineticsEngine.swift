//
//  PharmacokineticsEngine.swift
//  JabTracker
//

import Foundation
import Observation

/// Core pharmacokinetics calculation engine for drug concentration modeling
/// Implements exponential decay models for GLP-1 receptor agonists
@Observable
final class PharmacokineticsEngine {
    // MARK: - Initialization

    init() {}

    // MARK: - Core Concentration Calculations

    /// Calculate the current drug concentration at a specific point in time
    /// Uses exponential decay model: C(t) = Σ(Dose_i × e^(-k × t_i))
    /// - Parameters:
    ///   - doses: Array of doses to include in calculation
    ///   - medication: The medication type for pharmacokinetic parameters
    ///   - currentTime: The time at which to calculate concentration
    /// - Returns: Total drug concentration at the specified time
    func calculateConcentration(
        from doses: [Dose],
        medication: Medication,
        at currentTime: Date
    ) -> Double {
        // Filter out skipped doses and future doses
        let validDoses = doses.filter { dose in
            !dose.skipped && dose.timestamp <= currentTime
        }

        guard !validDoses.isEmpty else { return 0.0 }

        // Sum the contribution of each dose using exponential decay
        let totalConcentration = validDoses.reduce(0.0) { sum, dose in
            let timeElapsedHours = currentTime.timeIntervalSince(dose.timestamp) / 3600
            guard timeElapsedHours >= 0 else { return sum }

            // Calculate concentration from this dose at current time
            // Apply bioavailability to get the effective dose concentration
            let effectiveDoseConcentration = dose.amount * medication.subcutaneousBioavailability
            let concentrationFromDose = medication.concentrationAtTime(
                initialConcentration: effectiveDoseConcentration,
                timeElapsedHours: timeElapsedHours)

            return sum + concentrationFromDose
        }

        return totalConcentration
    }

    /// Calculate the current concentration for a user's medication profile
    /// - Parameters:
    ///   - user: The user whose doses to analyze
    ///   - medicationProfile: The specific medication profile to analyze
    /// - Returns: Current drug concentration for this medication
    func calculateCurrentConcentration(
        for _: User,
        medication medicationProfile: MedicationProfile
    ) -> Double {
        guard let medication = medicationProfile.medication else { return 0.0 }

        let doses = medicationProfile.doses ?? []
        return self.calculateConcentration(
            from: doses,
            medication: medication,
            at: Date())
    }

    // MARK: - Peak Level Calculations

    /// Calculate the peak concentration level and timing for a specific dose
    /// - Parameters:
    ///   - dose: The dose to analyze
    ///   - medicationProfile: The medication profile containing medication type
    /// - Returns: Tuple containing peak level and the time it occurs
    func calculatePeakLevel(
        for dose: Dose,
        medication medicationProfile: MedicationProfile
    ) -> (level: Double, time: Date) {
        guard let medication = medicationProfile.medication else {
            return (level: 0.0, time: dose.timestamp)
        }

        // Peak time is medication-specific time after injection
        let peakTime = dose.timestamp.addingTimeInterval(medication.peakTimeHours * 3600)

        // Peak level includes contribution from all doses, not just the single dose
        // Calculate total concentration at peak time including all historical doses
        let allDoses = medicationProfile.doses ?? []
        let peakLevel = self.calculateConcentration(
            from: allDoses,
            medication: medication,
            at: peakTime)

        return (level: peakLevel, time: peakTime)
    }

    // MARK: - Trough Level Calculations

    /// Calculate the expected trough level (lowest concentration before next dose)
    /// - Parameter medicationProfile: The medication profile to analyze
    /// - Returns: Tuple containing trough level and the time it occurs
    func calculateTroughLevel(
        for medicationProfile: MedicationProfile
    ) -> (level: Double, time: Date) {
        guard let medication = medicationProfile.medication,
            let doses = medicationProfile.doses,
            !doses.isEmpty
        else {
            return (level: 0.0, time: Date())
        }

        // Find the most recent dose
        let sortedDoses = doses.sorted { $0.timestamp > $1.timestamp }
        guard let mostRecentDose = sortedDoses.first else {
            return (level: 0.0, time: Date())
        }

        // Trough time is just before the next scheduled dose
        let dosingIntervalHours: Double = (medication.frequency == .daily) ? 24 : (7 * 24)
        let nextDoseTime = mostRecentDose.timestamp.addingTimeInterval(dosingIntervalHours * 3600)
        let troughTime = nextDoseTime.addingTimeInterval(-3600)  // 1 hour before next dose

        // Calculate concentration at trough time from all historical doses
        let troughLevel = self.calculateConcentration(
            from: doses,
            medication: medication,
            at: troughTime)

        return (level: troughLevel, time: troughTime)
    }

    // MARK: - Steady State Calculations

    /// Calculate progress toward steady-state concentration
    /// Steady state is typically reached after 5 half-lives
    /// - Parameter medicationProfile: The medication profile to analyze
    /// - Returns: Percentage progress toward steady state (0-100)
    func calculateSteadyStateProgress(
        for medicationProfile: MedicationProfile
    ) -> Double {
        guard let medication = medicationProfile.medication else { return 0.0 }

        let timeOnMedicationHours = Date().timeIntervalSince(medicationProfile.startDate) / 3600
        return medication.steadyStateProgress(timeOnMedicationHours: timeOnMedicationHours)
    }

    // MARK: - Future Level Projections

    /// Project future concentration levels over a specified time period
    /// Assumes continued dosing at current dose and frequency
    /// - Parameters:
    ///   - medicationProfile: The medication profile to project
    ///   - days: Number of days to project into the future
    /// - Returns: Array of concentration points showing projected levels
    func projectFutureLevels(
        for medicationProfile: MedicationProfile,
        days: Int
    ) -> [ConcentrationPoint] {
        guard let medication = medicationProfile.medication else { return [] }

        let currentTime = Date()
        let projectionEndTime = currentTime.addingTimeInterval(Double(days) * 24 * 3600)

        // Get current dose history
        var allDoses = medicationProfile.doses ?? []

        // Add projected future doses based on current dosing schedule
        let projectedDoses = self.generateProjectedDoses(
            for: medicationProfile,
            from: currentTime,
            to: projectionEndTime)
        allDoses.append(contentsOf: projectedDoses)

        // Generate concentration points at regular intervals
        var projectionPoints: [ConcentrationPoint] = []
        let hoursToProject = Double(days) * 24
        let intervalHours = max(1.0, hoursToProject / 100)  // Up to 100 points

        var currentProjectionTime = currentTime
        while currentProjectionTime <= projectionEndTime {
            let concentration = self.calculateConcentration(
                from: allDoses,
                medication: medication,
                at: currentProjectionTime)

            projectionPoints.append(
                ConcentrationPoint(
                    date: currentProjectionTime,
                    concentration: concentration))

            currentProjectionTime = currentProjectionTime.addingTimeInterval(intervalHours * 3600)
        }

        return projectionPoints
    }

    // MARK: - Private Helper Methods

    /// Generate projected future doses based on current dosing pattern
    /// - Parameters:
    ///   - medicationProfile: The medication profile
    ///   - startTime: When to start projecting
    ///   - endTime: When to stop projecting
    /// - Returns: Array of projected doses
    private func generateProjectedDoses(
        for medicationProfile: MedicationProfile,
        from startTime: Date,
        to endTime: Date
    ) -> [Dose] {
        guard let medication = medicationProfile.medication else { return [] }

        var projectedDoses: [Dose] = []
        let dosingIntervalSeconds: TimeInterval =
            (medication.frequency == .daily) ? (24 * 3600) : (7 * 24 * 3600)

        // Find the last dose to determine next dose timing
        let existingDoses = medicationProfile.doses ?? []
        let lastDoseTime =
            existingDoses.max(by: { $0.timestamp < $1.timestamp })?.timestamp ?? startTime

        // Calculate next dose time
        var nextDoseTime = lastDoseTime.addingTimeInterval(dosingIntervalSeconds)

        // Generate projected doses
        while nextDoseTime <= endTime {
            let projectedDose = Dose(
                amount: medicationProfile.currentDose,
                timestamp: nextDoseTime,
                medication: medicationProfile)
            projectedDoses.append(projectedDose)

            nextDoseTime = nextDoseTime.addingTimeInterval(dosingIntervalSeconds)
        }

        return projectedDoses
    }
}

// MARK: - Calculation Validation

extension PharmacokineticsEngine {
    /// Validate that calculation inputs are within safe medical ranges
    /// - Parameters:
    ///   - doses: Doses to validate
    ///   - medication: Medication to validate
    /// - Returns: True if inputs are valid, false otherwise
    func validateCalculationInputs(
        doses: [Dose],
        medication: Medication
    ) -> Bool {
        // Check medication pharmacokinetics are valid
        guard medication.hasValidPharmacokinetics else { return false }

        // Check dose amounts are reasonable
        for dose in doses {
            if dose.amount < 0 || dose.amount > 1000 {  // Arbitrary upper limit
                return false
            }
        }

        return true
    }

    /// Get validation error message for invalid inputs
    /// - Parameters:
    ///   - doses: Doses to validate
    ///   - medication: Medication to validate
    /// - Returns: Error message if validation fails, nil if valid
    func getValidationError(
        doses: [Dose],
        medication: Medication
    ) -> String? {
        if !self.validateCalculationInputs(doses: doses, medication: medication) {
            if let pkError = medication.pharmacokineticValidationError {
                return pkError
            }
            return "Invalid dose or medication parameters for calculation"
        }
        return nil
    }
}

// MARK: - Performance Optimization

extension PharmacokineticsEngine {
    /// Calculate concentration with performance optimization for large dose histories
    /// Uses cutoff for very old doses that contribute negligibly to current concentration
    /// - Parameters:
    ///   - doses: All doses
    ///   - medication: Medication type
    ///   - currentTime: Time for calculation
    ///   - concentrationCutoff: Minimum concentration to include (default: 0.001)
    /// - Returns: Optimized concentration calculation
    func calculateConcentrationOptimized(
        from doses: [Dose],
        medication: Medication,
        at currentTime: Date,
        concentrationCutoff _: Double = 0.001
    ) -> Double {
        // Filter doses that could still contribute meaningfully
        let cutoffTime = currentTime.addingTimeInterval(-10 * medication.halfLifeDays * 24 * 3600)
        let recentDoses = doses.filter { dose in
            !dose.skipped && dose.timestamp <= currentTime && dose.timestamp >= cutoffTime
        }

        return self.calculateConcentration(
            from: recentDoses,
            medication: medication,
            at: currentTime)
    }
}
