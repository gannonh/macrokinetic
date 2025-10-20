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

        // Weekly dosing should produce 4 doses over 28 days (days -28, -21, -14, -7, exclusive of day 0)
        let doses = generateSampleDoses(
            pattern: .weekly,
            medication: medication,
            doseAmount: doseAmount,
            days: days
        )

        #expect(doses.count == 4, "28-day period with 7-day intervals (exclusive end) = 4 doses")
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

    // MARK: - Boundary Validation Tests (Issue #234)

    @Test("Weekly pattern boundary: exactly 4 doses over 28 days, no off-by-one")
    func testWeeklyBoundaryExact28Days() {
        let doseAmount = 0.5

        // Test with exact 28-day period
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-28 * 24 * 3600)

        var doses: [Dose] = []
        var currentDate = startDate
        let intervalSeconds: TimeInterval = 7 * 24 * 3600  // 7 days

        while currentDate < endDate {
            doses.append(Dose(amount: doseAmount, timestamp: currentDate, site: "Thigh"))
            currentDate = currentDate.addingTimeInterval(intervalSeconds)
        }

        // Weekly pattern over exactly 28 days should produce exactly 4 doses
        // Day 0, Day 7, Day 14, Day 21 (Day 28 excluded by < boundary)
        #expect(doses.count == 4, "Weekly pattern over 28 days must produce exactly 4 doses")

        // Verify dose timestamps
        if doses.count == 4 {
            #expect(doses[0].timestamp.timeIntervalSince(startDate) < 1.0, "First dose at start")
            #expect(doses[1].timestamp.timeIntervalSince(startDate) >= 7 * 24 * 3600 - 1, "Second dose at day 7")
            #expect(doses[2].timestamp.timeIntervalSince(startDate) >= 14 * 24 * 3600 - 1, "Third dose at day 14")
            #expect(doses[3].timestamp.timeIntervalSince(startDate) >= 21 * 24 * 3600 - 1, "Fourth dose at day 21")
            #expect(doses[3].timestamp < endDate, "Last dose before end date")
        }
    }

    @Test("Split-dose pattern boundary: exactly 8 doses over 28 days, no off-by-one")
    func testSplitDoseBoundaryExact28Days() {
        let doseAmount = 0.5

        // Test with exact 28-day period
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-28 * 24 * 3600)

        var doses: [Dose] = []
        var currentDate = startDate
        let intervalSeconds: TimeInterval = 3.5 * 24 * 3600  // 3.5 days

        while currentDate < endDate {
            doses.append(Dose(amount: doseAmount, timestamp: currentDate, site: "Thigh"))
            currentDate = currentDate.addingTimeInterval(intervalSeconds)
        }

        // Split-dose pattern over exactly 28 days should produce exactly 8 doses
        // Days: 0, 3.5, 7, 10.5, 14, 17.5, 21, 24.5 (Day 28 excluded by < boundary)
        #expect(doses.count == 8, "Split-dose pattern over 28 days must produce exactly 8 doses")

        // Verify first and last doses are within range
        if !doses.isEmpty {
            #expect(doses.first!.timestamp >= startDate, "First dose at or after start")
            #expect(doses.last!.timestamp < endDate, "Last dose before end date")
        }
    }

    @Test("Boundary validation: < vs <= logic ensures correct dose count")
    func testBoundaryLogicLessThanNotLessThanOrEqual() {
        let doseAmount = 0.5

        // Create exact boundary scenario
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-7 * 24 * 3600)  // Exactly 7 days

        var doses: [Dose] = []
        var currentDate = startDate
        let intervalSeconds: TimeInterval = 7 * 24 * 3600  // 7 days

        // Using < (not <=) should produce exactly 1 dose
        while currentDate < endDate {
            doses.append(Dose(amount: doseAmount, timestamp: currentDate, site: "Thigh"))
            currentDate = currentDate.addingTimeInterval(intervalSeconds)
        }

        #expect(doses.count == 1, "With < boundary, exactly 7 days should produce 1 dose (not 2)")

        // Verify the single dose is at start, not at end
        if doses.count == 1 {
            #expect(doses[0].timestamp.timeIntervalSince(startDate) < 1.0, "Single dose at start date")
        }
    }

    @Test("Different time periods scale correctly: 56 days produces 8 weekly doses")
    func testLongerPeriodScalesCorrectly() {
        let doseAmount = 0.5

        // Test with 56-day period (8 weeks)
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-56 * 24 * 3600)

        var doses: [Dose] = []
        var currentDate = startDate
        let intervalSeconds: TimeInterval = 7 * 24 * 3600  // 7 days

        while currentDate < endDate {
            doses.append(Dose(amount: doseAmount, timestamp: currentDate, site: "Thigh"))
            currentDate = currentDate.addingTimeInterval(intervalSeconds)
        }

        // 56 days with weekly dosing should produce exactly 8 doses
        #expect(doses.count == 8, "56 days with weekly pattern must produce exactly 8 doses")
    }

    @Test("Edge case: 1-day period with weekly pattern produces 1 dose")
    func testSingleDayPeriod() {
        let doseAmount = 0.5

        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-1 * 24 * 3600)  // 1 day

        var doses: [Dose] = []
        var currentDate = startDate
        let intervalSeconds: TimeInterval = 7 * 24 * 3600  // 7 days

        while currentDate < endDate {
            doses.append(Dose(amount: doseAmount, timestamp: currentDate, site: "Thigh"))
            currentDate = currentDate.addingTimeInterval(intervalSeconds)
        }

        // 1 day with 7-day interval should produce exactly 1 dose
        #expect(doses.count == 1, "1-day period with weekly pattern must produce exactly 1 dose")
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
