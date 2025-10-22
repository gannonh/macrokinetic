//
//  MedicationProfile.swift
//  JabTracker
//

import Foundation
import SwiftData

@Model
final class MedicationProfile {
    var id: UUID = UUID()
    var genericName: String = ""  // CloudKit requires default value
    var brandName: String = ""  // CloudKit requires default value
    var currentDose: Double = 0.0  // CloudKit requires default value
    var startDate: Date = Date()  // Required with default
    var refillDate: Date?  // Optional - may not have refill scheduled yet
    var medicationType: String = ""  // Store Medication enum rawValue for CloudKit compatibility

    // Enhanced fields for compounding and pen support
    var isCompounded: Bool = false  // Compounded vs branded medication
    var vialStrength: Double?  // For compounded: mg in vial
    var reconstitutionVolume: Double?  // For compounded: ml of water to add
    var concentration: Double?  // For compounded: mg/ml (calculated from reconstitution)
    var unitsPerDose: Double?  // For compounded: units to draw (calculated from dose/concentration)
    var preferredInjectionSites: [String] = ["Thigh"]  // Preferred injection sites from onboarding
    var notes: String = ""  // User notes about medication
    var isActive: Bool = true  // Whether this medication profile is active (soft delete support)
    var updatedAt: Date = Date()  // Track modifications
    var createdAt: Date = Date()  // Track creation

    @Relationship(deleteRule: .nullify, inverse: \Dose.medication)
    var doses: [Dose]?  // Changed to nullify - preserve historical doses when profile deleted

    @Relationship(deleteRule: .cascade, inverse: \DoseTitration.medicationProfile)
    var doseTitrations: [DoseTitration]?  // Titration plans for this medication

    @Relationship(deleteRule: .cascade, inverse: \DoseSchedule.medicationProfile)
    var schedules: [DoseSchedule]?  // Dose schedules for this medication

    var user: User?  // Parent user relationship

    init(
        genericName: String = "",
        brandName: String = "",
        currentDose: Double = 0.0,
        startDate: Date = Date(),
        refillDate: Date? = nil,
        medicationType: String = "",
        isCompounded: Bool = false,
        vialStrength: Double? = nil,
        reconstitutionVolume: Double? = nil,
        concentration: Double? = nil,
        unitsPerDose: Double? = nil,
        preferredInjectionSites: [String] = ["Thigh"],
        notes: String = "",
        isActive: Bool = true
    ) {
        self.genericName = genericName
        self.brandName = brandName
        self.currentDose = currentDose
        self.startDate = startDate
        self.refillDate = refillDate
        // If medicationType is empty but genericName matches a known medication, use that
        if medicationType.isEmpty, !genericName.isEmpty {
            self.medicationType = Medication.fromGenericName(genericName)?.rawValue ?? ""
        } else {
            self.medicationType = medicationType
        }
        self.isCompounded = isCompounded
        self.vialStrength = vialStrength
        self.reconstitutionVolume = reconstitutionVolume
        self.concentration = concentration
        self.unitsPerDose = unitsPerDose
        self.preferredInjectionSites = preferredInjectionSites
        self.notes = notes
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
        // Don't initialize optional relationship - let SwiftData handle it
    }

    // MARK: - Computed Properties

    var medication: Medication? {
        get {
            Medication(rawValue: self.medicationType)
        }
        set {
            self.medicationType = newValue?.rawValue ?? ""
        }
    }
}

// MARK: - Analytics Data Structures

/// Time-based effectiveness insight for medication analysis
struct EffectivenessInsight {
    let period: String
    let effectivenessChange: Double?
    let note: String?
}

// MARK: - Analytics Extensions

extension MedicationProfile {
    /// Calculate adherence rate for a given time period
    /// - Parameters:
    ///   - startDate: Start of the period to analyze
    ///   - endDate: End of the period to analyze
    ///   - context: ModelContext for database queries
    /// - Returns: Adherence rate from 0.0 to 1.0
    func calculateAdherence(from startDate: Date, to endDate: Date, context _: ModelContext) -> Double {
        guard let medicationDoses = doses else { return 0.0 }

        let periodDoses = medicationDoses.filter { dose in
            dose.timestamp >= startDate && dose.timestamp <= endDate
        }

        guard !periodDoses.isEmpty else { return 0.0 }

        let takenDoses = periodDoses.filter { !$0.skipped }
        return Double(takenDoses.count) / Double(periodDoses.count)
    }

    /// Calculate effectiveness score based on adherence and time on medication
    /// - Parameters:
    ///   - adherence: Adherence rate (0.0 to 1.0)
    ///   - timeOnMedicationDays: Number of days on this medication
    /// - Returns: Overall effectiveness score from 0.0 to 1.0
    func calculateEffectivenessScore(adherence: Double, timeOnMedicationDays: Int) -> Double {
        guard let med = medication else { return 0.0 }

        let baseScore = med.baseEffectivenessScore
        let adherenceMultiplier = adherence

        // Time factor - effectiveness may increase over time up to steady state
        let steadyStateDays = med.timeToSteadyStateDays
        let timeFactor = min(Double(timeOnMedicationDays) / steadyStateDays, 1.0)

        return baseScore * adherenceMultiplier * timeFactor
    }

    /// Generate time-based effectiveness insights
    var timeBasedEffectivenessInsights: [EffectivenessInsight] {
        var insights: [EffectivenessInsight] = []

        guard let med = medication else {
            return [
                EffectivenessInsight(
                    period: "Unknown", effectivenessChange: nil, note: "Medication type not set")
            ]
        }

        let daysOnMedication =
            Calendar.current.dateComponents([.day], from: self.startDate, to: Date()).day ?? 0
        let steadyStateDays = Int(med.timeToSteadyStateDays)

        if daysOnMedication < 7 {
            insights.append(
                EffectivenessInsight(
                    period: "First Week",
                    effectivenessChange: nil,
                    note: "Medication is building up in your system. Full effects may not be noticeable yet.")
            )
        } else if daysOnMedication < steadyStateDays {
            let progressPercent = Int((Double(daysOnMedication) / Double(steadyStateDays)) * 100)
            insights.append(
                EffectivenessInsight(
                    period: "Building to Steady State",
                    effectivenessChange: Double(progressPercent) / 100.0,
                    note: "Approximately \(progressPercent)% toward maximum effectiveness."))
        } else {
            insights.append(
                EffectivenessInsight(
                    period: "Steady State",
                    effectivenessChange: 1.0,
                    note: "Medication has reached steady state. Maximum effectiveness achieved."))
        }

        return insights
    }

    /// Generate concentration timeline for visualization
    /// - Parameters:
    ///   - startDate: Start date for timeline
    ///   - endDate: End date for timeline
    ///   - context: ModelContext for database queries
    /// - Returns: Array of concentration points over time
    func generateConcentrationTimeline(
        from startDate: Date, to endDate: Date, context _: ModelContext
    ) -> [ConcentrationPoint] {
        guard let med = medication,
            let medicationDoses = doses
        else { return [] }

        let relevantDoses = medicationDoses.filter { dose in
            dose.timestamp >= startDate && dose.timestamp <= endDate && !dose.skipped
        }.sorted { $0.timestamp < $1.timestamp }

        guard !relevantDoses.isEmpty else { return [] }

        var timeline: [ConcentrationPoint] = []
        let calendar = Calendar.current

        // Generate points at regular intervals (daily)
        var currentDate = startDate
        while currentDate <= endDate {
            var totalConcentration = 0.0

            // Calculate cumulative concentration from all doses up to this point
            for dose in relevantDoses {
                guard dose.timestamp <= currentDate else { continue }

                let hoursElapsed = currentDate.timeIntervalSince(dose.timestamp) / 3600.0

                // Use pharmacokinetic calculation from existing extension
                let initialConcentration = dose.amount * med.subcutaneousBioavailability
                let currentConcentration = med.concentrationAtTime(
                    initialConcentration: initialConcentration,
                    timeElapsedHours: hoursElapsed)

                totalConcentration += currentConcentration
            }

            timeline.append(ConcentrationPoint(date: currentDate, concentration: totalConcentration))

            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return timeline
    }
}
