//
//  ConcentrationCurvePreviewTests.swift
//  JabTrackerTests
//
//  Unit tests for ConcentrationCurvePreview concentration calculations
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
struct ConcentrationCurvePreviewTests {
    let pkEngine: PharmacokineticsEngine

    init() {
        self.pkEngine = PharmacokineticsEngine()
    }

    // MARK: - Sample Schedule Generation Tests

    @Test("Generate weekly schedule produces correct dose count")
    func testWeeklyScheduleGeneration() {
        let medication = Medication.semaglutide
        let doseAmount = 0.5
        let days = 28  // 4 weeks

        // Weekly dosing should produce 4 doses over 28 days
        let doses = generateSampleDoses(
            pattern: .weekly,
            medication: medication,
            doseAmount: doseAmount,
            days: days
        )

        #expect(doses.count == 4)
    }

    @Test("Generate split-dose schedule produces correct dose count")
    func testSplitDoseScheduleGeneration() {
        let medication = Medication.semaglutide
        let doseAmount = 0.5
        let days = 28  // 4 weeks

        // Split dosing (twice weekly) should produce 8 doses over 28 days
        let doses = generateSampleDoses(
            pattern: .splitDose,
            medication: medication,
            doseAmount: doseAmount,
            days: days
        )

        #expect(doses.count == 8)
    }

    // MARK: - Concentration Curve Calculation Tests

    @Test("Calculate concentration curve for weekly pattern")
    func testWeeklyConcentrationCurve() {
        let medication = Medication.semaglutide
        let doseAmount = 0.5
        let days = 28

        let doses = generateSampleDoses(
            pattern: .weekly,
            medication: medication,
            doseAmount: doseAmount,
            days: days
        )

        // Calculate concentration points
        let concentrationPoints = calculateConcentrationCurve(
            doses: doses,
            medication: medication,
            days: days
        )

        // Should have data points for visualization
        #expect(concentrationPoints.count > 0)

        // Concentrations should be non-negative
        for point in concentrationPoints {
            #expect(point.concentration >= 0.0)
        }
    }

    @Test("Calculate concentration curve for split-dose pattern")
    func testSplitDoseConcentrationCurve() {
        let medication = Medication.semaglutide
        let doseAmount = 0.5
        let days = 28

        let doses = generateSampleDoses(
            pattern: .splitDose,
            medication: medication,
            doseAmount: doseAmount,
            days: days
        )

        let concentrationPoints = calculateConcentrationCurve(
            doses: doses,
            medication: medication,
            days: days
        )

        // Split dose should have more frequent dosing
        #expect(concentrationPoints.count > 0)

        // Verify concentrations are valid
        for point in concentrationPoints {
            #expect(point.concentration >= 0.0)
            #expect(point.concentration.isFinite)
        }
    }

    // MARK: - Peak/Trough Calculation Tests

    @Test("Calculate peak concentration")
    func testPeakConcentrationCalculation() {
        let medication = Medication.semaglutide
        let doseAmount = 0.5
        let days = 28

        let doses = generateSampleDoses(
            pattern: .weekly,
            medication: medication,
            doseAmount: doseAmount,
            days: days
        )

        let concentrationPoints = calculateConcentrationCurve(
            doses: doses,
            medication: medication,
            days: days
        )

        guard !concentrationPoints.isEmpty else {
            Issue.record("No concentration points generated")
            return
        }

        let peak = concentrationPoints.max(by: { $0.concentration < $1.concentration })
        #expect(peak != nil)
        #expect(peak!.concentration > 0.0)
    }

    @Test("Calculate trough concentration")
    func testTroughConcentrationCalculation() {
        let medication = Medication.semaglutide
        let doseAmount = 0.5
        let days = 28

        let doses = generateSampleDoses(
            pattern: .weekly,
            medication: medication,
            doseAmount: doseAmount,
            days: days
        )

        let concentrationPoints = calculateConcentrationCurve(
            doses: doses,
            medication: medication,
            days: days
        )

        guard !concentrationPoints.isEmpty else {
            Issue.record("No concentration points generated")
            return
        }

        let trough = concentrationPoints.min(by: { $0.concentration < $1.concentration })
        #expect(trough != nil)
        #expect(trough!.concentration >= 0.0)
    }

    @Test("Peak concentration is higher than trough")
    func testPeakHigherThanTrough() {
        let medication = Medication.semaglutide
        let doseAmount = 0.5
        let days = 28

        let doses = generateSampleDoses(
            pattern: .weekly,
            medication: medication,
            doseAmount: doseAmount,
            days: days
        )

        let concentrationPoints = calculateConcentrationCurve(
            doses: doses,
            medication: medication,
            days: days
        )

        guard !concentrationPoints.isEmpty else {
            Issue.record("No concentration points generated")
            return
        }

        let peak = concentrationPoints.max(by: { $0.concentration < $1.concentration })!
        let trough = concentrationPoints.min(by: { $0.concentration < $1.concentration })!

        #expect(peak.concentration > trough.concentration)
    }

    // MARK: - Helper Methods

    /// Generate sample doses for preview based on pattern
    private func generateSampleDoses(
        pattern: SchedulePatternType,
        medication: Medication,
        doseAmount: Double,
        days: Int
    ) -> [Dose] {
        var doses: [Dose] = []
        let startDate = Date().addingTimeInterval(-Double(days) * 24 * 3600)

        let intervalSeconds: TimeInterval
        switch pattern {
        case .weekly:
            intervalSeconds = 7 * 24 * 3600  // 7 days
        case .splitDose:
            intervalSeconds = 3.5 * 24 * 3600  // 3.5 days (twice weekly)
        case .custom:
            intervalSeconds = 7 * 24 * 3600  // Default to weekly
        }

        var currentDate = startDate
        let endDate = Date()

        while currentDate < endDate {
            let dose = Dose(
                amount: doseAmount,
                timestamp: currentDate,
                site: "Thigh"
            )
            doses.append(dose)
            currentDate = currentDate.addingTimeInterval(intervalSeconds)
        }

        return doses
    }

    /// Calculate concentration curve from doses
    private func calculateConcentrationCurve(
        doses: [Dose],
        medication: Medication,
        days: Int
    ) -> [PreviewConcentrationPoint] {
        var points: [PreviewConcentrationPoint] = []
        let startDate = doses.first?.timestamp ?? Date()
        let endDate = Date()

        // Generate points every 12 hours for smooth curve
        var currentTime = startDate
        let intervalHours: Double = 12

        while currentTime <= endDate {
            let concentration = pkEngine.calculateConcentration(
                from: doses,
                medication: medication,
                at: currentTime
            )

            points.append(
                PreviewConcentrationPoint(
                    date: currentTime,
                    concentration: concentration
                ))

            currentTime = currentTime.addingTimeInterval(intervalHours * 3600)
        }

        return points
    }
}

/// Data structure for concentration curve points
struct PreviewConcentrationPoint: Identifiable {
    let id = UUID()
    let date: Date
    let concentration: Double
}
