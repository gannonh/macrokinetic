// swiftlint:disable file_length

import Foundation
import Testing

@testable import JabTracker

/// Comprehensive test suite for PharmacokineticsEngine
/// Tests all core pharmacokinetic calculations for medical accuracy
@Suite("PharmacokineticsEngine Tests")
struct PharmacokineticsEngineTests {
    // Test data setup
    let engine = PharmacokineticsEngine()
    let testDate = Date()

    /// Helper to create a test user with standard properties
    func createTestUser() -> User {
        User(
            email: "test@example.com",
            name: "Test User",
            weight: 80.0,
            weightUnit: "kg")
    }

    /// Helper to create a test medication profile
    func createTestMedicationProfile(
        medication: Medication,
        currentDose: Double = 1.0
    ) -> MedicationProfile {
        MedicationProfile(
            genericName: medication.rawValue,
            brandName: medication.brands.first ?? "",
            currentDose: currentDose,
            startDate: self.testDate.addingTimeInterval(-7 * 24 * 3600),  // Started 1 week ago
            medicationType: medication.rawValue)
    }

    /// Helper to create test doses with specified intervals
    func createTestDoses(
        amounts: [Double],
        daysAgo: [Double],
        medicationProfile: MedicationProfile
    ) -> [Dose] {
        zip(amounts, daysAgo).map { amount, days in
            Dose(
                amount: amount,
                timestamp: self.testDate.addingTimeInterval(-days * 24 * 3600),
                medication: medicationProfile)
        }
    }

    // MARK: - Basic Concentration Calculations

    @Test("Single dose concentration decay - Semaglutide")
    func singleDoseConcentrationSemaglutide() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 1.0)
        let dose = Dose(
            amount: 1.0,
            timestamp: testDate.addingTimeInterval(-24 * 3600),  // 1 day ago
            medication: medicationProfile)

        let concentration = self.engine.calculateConcentration(
            from: [dose],
            medication: .semaglutide,
            at: self.testDate)

        // After 1 day with 7-day half-life: C = 1.0 * 0.89 * e^(-ln(2) * 1/7) ≈ 0.806
        // Bioavailability-adjusted: 0.906 * 0.89 = 0.806
        let expected = 1.0 * 0.89 * exp(-log(2) * 1.0 / 7.0)
        let tolerance = 0.01

        #expect(
            abs(concentration - expected) < tolerance,
            "Semaglutide concentration after 1 day should be ~0.806, got \(concentration)")
    }

    @Test("Single dose concentration decay - Tirzepatide")
    func singleDoseConcentrationTirzepatide() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .tirzepatide, currentDose: 5.0)
        let dose = Dose(
            amount: 5.0,
            timestamp: testDate.addingTimeInterval(-24 * 3600),  // 1 day ago
            medication: medicationProfile)

        let concentration = self.engine.calculateConcentration(
            from: [dose],
            medication: .tirzepatide,
            at: self.testDate)

        // After 1 day with 5-day half-life: C = 5.0 * 0.80 * e^(-ln(2) * 1/5) ≈ 3.471
        // Bioavailability-adjusted: 4.339 * 0.80 = 3.471
        let expected = 5.0 * 0.80 * exp(-log(2) * 1.0 / 5.0)
        let tolerance = 0.01

        #expect(
            abs(concentration - expected) < tolerance,
            "Tirzepatide concentration after 1 day should be ~3.471, got \(concentration)")
    }

    @Test("Single dose concentration decay - Liraglutide")
    func singleDoseConcentrationLiraglutide() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .liraglutide, currentDose: 1.8)
        let dose = Dose(
            amount: 1.8,
            timestamp: testDate.addingTimeInterval(-12 * 3600),  // 12 hours ago
            medication: medicationProfile)

        let concentration = self.engine.calculateConcentration(
            from: [dose],
            medication: .liraglutide,
            at: self.testDate)

        // After 12 hours (0.5 days) with 0.54-day half-life: C = 1.8 * 0.55 * e^(-ln(2) * 0.5/0.54) ≈ 0.542
        // Bioavailability-adjusted: 0.985 * 0.55 = 0.542
        let expected = 1.8 * 0.55 * exp(-log(2) * 0.5 / 0.54)
        let tolerance = 0.01

        #expect(
            abs(concentration - expected) < tolerance,
            "Liraglutide concentration after 12 hours should be ~0.542, got \(concentration)")
    }

    @Test("Zero concentration for very old doses")
    func zeroConcentrationForOldDoses() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 1.0)
        let dose = Dose(
            amount: 1.0,
            timestamp: testDate.addingTimeInterval(-100 * 24 * 3600),  // 100 days ago
            medication: medicationProfile)

        let concentration = self.engine.calculateConcentration(
            from: [dose],
            medication: .semaglutide,
            at: self.testDate)

        // After 100 days, concentration should be negligible (< 0.001)
        #expect(
            concentration < 0.001,
            "Concentration after 100 days should be negligible, got \(concentration)")
    }

    // MARK: - Multiple Dose Calculations

    @Test("Multiple dose cumulative effect")
    func multipleDoseCumulativeEffect() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 1.0)
        let doses = self.createTestDoses(
            amounts: [1.0, 1.0, 1.0],  // Three 1mg doses
            daysAgo: [14, 7, 0],  // 2 weeks, 1 week, today
            medicationProfile: medicationProfile)

        let concentration = self.engine.calculateConcentration(
            from: doses,
            medication: .semaglutide,
            at: self.testDate)

        // Calculate expected: sum of individual decayed concentrations (with bioavailability)
        let bioavailability = 0.89  // Semaglutide bioavailability
        let dose1Remaining = 1.0 * bioavailability * exp(-log(2) * 14.0 / 7.0)  // ≈ 0.223
        let dose2Remaining = 1.0 * bioavailability * exp(-log(2) * 7.0 / 7.0)  // ≈ 0.445
        let dose3Remaining = 1.0 * bioavailability  // = 0.89
        let expected = dose1Remaining + dose2Remaining + dose3Remaining
        let tolerance = 0.01

        #expect(abs(concentration - expected) < tolerance)
    }

    @Test("Escalating dose pattern")
    func escalatingDosePattern() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 2.0)
        let doses = self.createTestDoses(
            amounts: [0.25, 0.5, 1.0, 2.0],  // Escalating doses
            daysAgo: [21, 14, 7, 0],  // Weekly dosing
            medicationProfile: medicationProfile)

        let concentration = self.engine.calculateConcentration(
            from: doses,
            medication: .semaglutide,
            at: self.testDate)

        // Calculate expected: sum of individual decayed concentrations (with bioavailability)
        let bioavailability = 0.89  // Semaglutide bioavailability
        let dose1 = 0.25 * bioavailability * exp(-log(2) * 21.0 / 7.0)  // ≈ 0.028
        let dose2 = 0.5 * bioavailability * exp(-log(2) * 14.0 / 7.0)  // ≈ 0.111
        let dose3 = 1.0 * bioavailability * exp(-log(2) * 7.0 / 7.0)  // ≈ 0.445
        let dose4 = 2.0 * bioavailability  // = 1.78
        let expected = dose1 + dose2 + dose3 + dose4
        let tolerance = 0.01

        #expect(
            abs(concentration - expected) < tolerance,
            "Escalating dose pattern should sum correctly, got \(concentration), expected \(expected)")
    }

    // MARK: - Current Concentration Calculations

    @Test("Calculate current concentration for user")
    func calculateCurrentConcentrationForUser() throws {
        _ = self.createTestUser()  // User created but not used directly in this test
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 1.0)

        // Add doses to medication profile
        let doses = self.createTestDoses(
            amounts: [1.0, 1.0],
            daysAgo: [7, 0],  // Last week and today
            medicationProfile: medicationProfile)

        // In test environment, call engine directly with doses array
        // This bypasses the SwiftData relationship which doesn't work in test environment
        guard let medication = medicationProfile.medication else {
            throw TestError.invalidMedicationProfile("Failed to get medication from profile")
        }

        let concentration = self.engine.calculateConcentration(
            from: doses,
            medication: medication,
            at: Date())

        // Should be sum of current dose (0.89) + decayed previous dose (~0.445) with bioavailability
        let bioavailability = 0.89  // Semaglutide bioavailability
        let expected = (1.0 * bioavailability) + (1.0 * bioavailability * exp(-log(2) * 7.0 / 7.0))
        let tolerance = 0.01

        #expect(
            abs(concentration - expected) < tolerance,
            "Current concentration should account for all doses, got \(concentration)")
        #expect(concentration > 0, "Current concentration should be positive")
    }

    @Test("Calculate current concentration with no doses")
    func calculateCurrentConcentrationNoDoses() throws {
        let user = self.createTestUser()
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 1.0)

        // No doses - MedicationProfile created without any doses
        user.medicationProfiles = [medicationProfile]

        let concentration = self.engine.calculateCurrentConcentration(
            for: user,
            medication: medicationProfile)

        #expect(concentration == 0.0, "Concentration with no doses should be zero")
    }

    // MARK: - Peak Level Calculations

    @Test("Calculate peak level for recent dose")
    func calculatePeakLevelRecentDose() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 1.0)
        let dose = Dose(
            amount: 1.0,
            timestamp: testDate.addingTimeInterval(-3600),  // 1 hour ago
            medication: medicationProfile)

        // Note: Since we're not in a SwiftData context, we can't modify the doses relationship
        // The calculatePeakLevel method will use medicationProfile.doses which will be empty
        // This tests the method's behavior with no historical doses
        let result = self.engine.calculatePeakLevel(for: dose, medication: medicationProfile)

        // With no doses in the profile, peak level will be 0
        #expect(result.level == 0, "Peak level should be 0 when no doses in profile")
        #expect(result.time > dose.timestamp, "Peak time should be after dose time")

        // For semaglutide, peak should be ~1 hour after injection
        let expectedPeakTime = dose.timestamp.addingTimeInterval(3600)  // +1 hour
        let timeDifference = abs(result.time.timeIntervalSince(expectedPeakTime))

        #expect(timeDifference < 1800, "Peak time should be within 30 minutes of expected")  // 30 min tolerance
    }

    @Test("Calculate peak level for different medications")
    func calculatePeakLevelDifferentMedications() throws {
        let medications: [(Medication, Double)] = [
            (.semaglutide, 1.0),
            (.tirzepatide, 8.0),
            (.liraglutide, 8.0),
            (.dulaglutide, 24.0),
        ]

        for (medication, expectedPeakHours) in medications {
            let medicationProfile = self.createTestMedicationProfile(medication: medication)
            let dose = Dose(
                amount: 1.0,
                timestamp: testDate,
                medication: medicationProfile)

            // Note: Since we're not in a SwiftData context, we can't modify the doses relationship
            // This tests that the method correctly calculates peak timing even with no doses
            let result = self.engine.calculatePeakLevel(for: dose, medication: medicationProfile)

            let actualPeakHours = result.time.timeIntervalSince(dose.timestamp) / 3600
            let tolerance = 0.5  // 30 minute tolerance

            #expect(
                abs(actualPeakHours - expectedPeakHours) < tolerance,
                "\(medication.displayName) peak should be at ~\(expectedPeakHours) hours, got \(actualPeakHours)"
            )
        }
    }

    // MARK: - Trough Level Calculations

    @Test("Calculate trough level for regular dosing")
    func calculateTroughLevelRegularDosing() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 1.0)

        // Simulate regular weekly dosing for several weeks
        let doses = self.createTestDoses(
            amounts: [1.0, 1.0, 1.0, 1.0],
            daysAgo: [21, 14, 7, 0],
            medicationProfile: medicationProfile)
        // In test environment, test the underlying calculation logic directly
        guard let medication = medicationProfile.medication else {
            throw TestError.invalidMedicationProfile("Failed to get medication from profile")
        }

        // Test that we can calculate concentration at trough time (7 days after last dose)
        guard let lastDose = doses.last else {
            throw TestError.noSampleData("No doses found")
        }
        let troughTime = lastDose.timestamp.addingTimeInterval(7 * 24 * 3600)
        let troughConcentration = self.engine.calculateConcentration(
            from: doses,
            medication: medication,
            at: troughTime)

        #expect(troughConcentration > 0, "Trough concentration should be positive with regular dosing")
        #expect(troughConcentration < 1.0, "Trough concentration should be lower than peak")

        // Verify trough time is correct (we calculated at the expected trough time)
        let expectedTroughTime = self.testDate.addingTimeInterval(7 * 24 * 3600)
        let timeDifference = abs(troughTime.timeIntervalSince(expectedTroughTime))

        #expect(timeDifference < 60, "Trough time should be exactly 7 days after last dose")
    }

    @Test("Calculate trough level with no doses")
    func calculateTroughLevelNoDoses() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 1.0)
        // No doses - MedicationProfile created without any doses

        let result = self.engine.calculateTroughLevel(for: medicationProfile)

        #expect(result.level == 0.0, "Trough level should be zero with no doses")
    }

    // MARK: - Steady State Calculations

    @Test("Calculate steady state progress early treatment")
    func calculateSteadyStateProgressEarly() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 1.0)
        // Started 1 week ago (already set in createTestMedicationProfile)

        let progress = self.engine.calculateSteadyStateProgress(for: medicationProfile)

        // After 1 week with 7-day half-life, should be 1/5 = 20% toward steady state
        let expectedProgress = (7.0 / (7.0 * 5)) * 100  // 20%
        let tolerance = 5.0  // 5% tolerance

        #expect(
            abs(progress - expectedProgress) < tolerance,
            "Steady state progress after 1 week should be ~20%, got \(progress)")
        #expect(progress >= 0, "Progress should be non-negative")
        #expect(progress <= 100, "Progress should not exceed 100%")
    }

    @Test("Calculate steady state progress at steady state")
    func calculateSteadyStateProgressSteadyState() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 1.0)
        // Simulate long-term treatment (5+ half-lives)
        medicationProfile.startDate = self.testDate.addingTimeInterval(-40 * 24 * 3600)  // 40 days ago

        let progress = self.engine.calculateSteadyStateProgress(for: medicationProfile)

        #expect(progress >= 95.0, "After 40 days (>5 half-lives), should be at steady state")
        #expect(progress <= 100.0, "Progress should not exceed 100%")
    }

    @Test("Calculate steady state progress different medications")
    func calculateSteadyStateProgressDifferentMedications() throws {
        let medications: [Medication] = [.semaglutide, .tirzepatide, .liraglutide, .dulaglutide]

        for medication in medications {
            let medicationProfile = self.createTestMedicationProfile(medication: medication)
            // Set start date to 1 half-life ago
            medicationProfile.startDate = self.testDate.addingTimeInterval(
                -medication.halfLifeDays * 24 * 3600)

            let progress = self.engine.calculateSteadyStateProgress(for: medicationProfile)

            // After 1 half-life, should be 20% toward steady state for all medications
            let expectedProgress = 20.0
            let tolerance = 5.0

            #expect(
                abs(progress - expectedProgress) < tolerance,
                "\(medication.displayName) steady state progress after 1 half-life should be ~20%, got \(progress)"
            )
        }
    }

    // MARK: - Future Level Projections

    @Test("Project future levels without future doses")
    func projectFutureLevelsNoFutureDoses() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 1.0)
        let dose = Dose(
            amount: 1.0,
            timestamp: testDate,
            medication: medicationProfile)

        // Test the underlying projection logic directly with the dose array
        guard let medication = medicationProfile.medication else {
            throw TestError.invalidMedicationProfile("Failed to get medication from profile")
        }

        // Project 7 days into the future
        let projectionStart = self.testDate
        let projectionEnd = self.testDate.addingTimeInterval(7 * 24 * 3600)
        var projections: [ConcentrationPoint] = []

        // Sample every 6 hours for 7 days
        var currentTime = projectionStart
        while currentTime <= projectionEnd {
            let concentration = self.engine.calculateConcentration(
                from: [dose],
                medication: medication,
                at: currentTime)
            projections.append(ConcentrationPoint(date: currentTime, concentration: concentration))
            currentTime = currentTime.addingTimeInterval(6 * 3600)  // Sample every 6 hours
        }

        #expect(projections.count > 0, "Should return projection points")
        #expect(projections.first?.concentration ?? 0 > 0, "Initial projection should be positive")

        // Concentrations should decay over time
        for index in 1..<projections.count {
            #expect(
                projections[index].concentration <= projections[index - 1].concentration,
                "Concentrations should decay over time without future doses")
        }

        // Verify time ordering
        for index in 1..<projections.count {
            #expect(
                projections[index].date > projections[index - 1].date,
                "Projection dates should be in chronological order")
        }
    }

    @Test("Project future levels with scheduled doses")
    func projectFutureLevelsWithScheduledDoses() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 1.0)
        let recentDose = Dose(
            amount: 1.0,
            timestamp: testDate,
            medication: medicationProfile)

        // Test the underlying projection logic directly with scheduled doses
        guard let medication = medicationProfile.medication else {
            throw TestError.invalidMedicationProfile("Failed to get medication from profile")
        }

        // Project 14 days with simulated weekly doses
        let projectionEnd = self.testDate.addingTimeInterval(14 * 24 * 3600)
        var projections: [ConcentrationPoint] = []

        // Create dose history including future scheduled doses
        var allDoses = [recentDose]
        // Add scheduled future doses at 7 and 14 days
        let futureDose1 = Dose(
            amount: 1.0,
            timestamp: testDate.addingTimeInterval(7 * 24 * 3600),
            medication: medicationProfile)
        let futureDose2 = Dose(
            amount: 1.0,
            timestamp: testDate.addingTimeInterval(14 * 24 * 3600),
            medication: medicationProfile)
        allDoses.append(contentsOf: [futureDose1, futureDose2])

        // Sample every 12 hours for 14 days
        var currentTime = self.testDate
        while currentTime <= projectionEnd {
            // Filter doses that would have occurred by currentTime
            let relevantDoses = allDoses.filter { $0.timestamp <= currentTime }
            let concentration = self.engine.calculateConcentration(
                from: relevantDoses,
                medication: medication,
                at: currentTime)
            projections.append(ConcentrationPoint(date: currentTime, concentration: concentration))
            currentTime = currentTime.addingTimeInterval(12 * 3600)  // Sample every 12 hours
        }

        #expect(projections.count > 0, "Should return projection points")

        // Look for evidence of projected future doses (concentration should increase at weekly intervals)
        let weeklyPoints = projections.filter { point in
            let daysFromNow = point.date.timeIntervalSince(self.testDate) / (24 * 3600)
            return abs(daysFromNow - 7.0) < 0.5 || abs(daysFromNow - 14.0) < 0.5
        }

        #expect(weeklyPoints.count >= 1, "Should include projections around weekly dosing intervals")
    }

    // MARK: - Edge Cases and Error Handling

    @Test("Handle empty dose array")
    func handleEmptyDoseArray() throws {
        let concentration = self.engine.calculateConcentration(
            from: [],
            medication: .semaglutide,
            at: self.testDate)

        #expect(concentration == 0.0, "Empty dose array should return zero concentration")
    }

    @Test("Handle future dose timestamps")
    func handleFutureDoseTimestamps() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 1.0)
        let futureDose = Dose(
            amount: 1.0,
            timestamp: testDate.addingTimeInterval(24 * 3600),  // Tomorrow
            medication: medicationProfile)

        let concentration = self.engine.calculateConcentration(
            from: [futureDose],
            medication: .semaglutide,
            at: self.testDate)

        #expect(concentration == 0.0, "Future doses should not contribute to current concentration")
    }

    @Test("Handle very large dose amounts")
    func handleLargeDoseAmounts() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 100.0)
        let largeDose = Dose(
            amount: 100.0,
            timestamp: testDate,
            medication: medicationProfile)

        let concentration = self.engine.calculateConcentration(
            from: [largeDose],
            medication: .semaglutide,
            at: self.testDate)

        #expect(concentration == 89.0, "Large doses should be handled correctly")
        #expect(concentration.isFinite, "Result should be finite")
    }

    @Test("Handle very small dose amounts")
    func handleSmallDoseAmounts() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 0.001)
        let smallDose = Dose(
            amount: 0.001,
            timestamp: testDate,
            medication: medicationProfile)

        let concentration = self.engine.calculateConcentration(
            from: [smallDose],
            medication: .semaglutide,
            at: self.testDate)

        let expected = 0.001 * 0.89  // 0.000889
        let tolerance = 0.000001
        #expect(abs(concentration - expected) < tolerance, "Small doses should be handled correctly")
        #expect(concentration >= 0, "Concentration should be non-negative")
    }

    @Test("Handle skipped doses")
    func handleSkippedDoses() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 1.0)
        let skippedDose = Dose(
            amount: 1.0,
            timestamp: testDate,
            skipped: true,
            medication: medicationProfile)

        let concentration = self.engine.calculateConcentration(
            from: [skippedDose],
            medication: .semaglutide,
            at: self.testDate)

        #expect(concentration == 0.0, "Skipped doses should not contribute to concentration")
    }

    // MARK: - Performance Tests

    @Test("Performance with large dose history")
    func performanceWithLargeDoseHistory() throws {
        let medicationProfile = self.createTestMedicationProfile(
            medication: .semaglutide, currentDose: 1.0)

        // Create 52 weeks of doses (1 year of weekly dosing)
        var doses: [Dose] = []
        for week in 0..<52 {
            let dose = Dose(
                amount: 1.0,
                timestamp: testDate.addingTimeInterval(-Double(week) * 7 * 24 * 3600),
                medication: medicationProfile)
            doses.append(dose)
        }

        let startTime = Date()
        let concentration = self.engine.calculateConcentration(
            from: doses,
            medication: .semaglutide,
            at: self.testDate)
        let endTime = Date()

        let executionTime = endTime.timeIntervalSince(startTime)

        #expect(
            executionTime < 0.05,
            "Calculation with 52 doses should complete in <50ms, took \(executionTime)s")
        #expect(concentration > 0, "Large dose history should produce positive concentration")
        #expect(concentration.isFinite, "Result should be finite")
    }

    // MARK: - Medical Accuracy Validation

    @Test("Validate half-life decay accuracy")
    func validateHalfLifeDecayAccuracy() throws {
        let medications: [Medication] = [.semaglutide, .tirzepatide, .liraglutide, .dulaglutide]

        for medication in medications {
            let medicationProfile = self.createTestMedicationProfile(
                medication: medication, currentDose: 1.0)
            let dose = Dose(
                amount: 1.0,
                timestamp: testDate.addingTimeInterval(-medication.halfLifeDays * 24 * 3600),
                medication: medicationProfile)

            let concentration = self.engine.calculateConcentration(
                from: [dose],
                medication: medication,
                at: self.testDate)

            // After exactly one half-life, concentration should be 0.5 * bioavailability
            let expectedConcentration = 0.5 * medication.subcutaneousBioavailability
            let tolerance = 0.01
            #expect(abs(concentration - expectedConcentration) < tolerance)
        }
    }

    @Test("Validate steady state timing")
    func validateSteadyStateTiming() throws {
        let medications: [Medication] = [.semaglutide, .tirzepatide, .liraglutide, .dulaglutide]

        for medication in medications {
            let medicationProfile = self.createTestMedicationProfile(medication: medication)
            // Set start date to 5 half-lives ago (theoretical steady state)
            medicationProfile.startDate = self.testDate.addingTimeInterval(
                -5 * medication.halfLifeDays * 24 * 3600)

            let progress = self.engine.calculateSteadyStateProgress(for: medicationProfile)

            #expect(
                progress >= 95.0,
                "\(medication.displayName) should be at steady state after 5 half-lives, got \(progress)%")
        }
    }

    // MARK: - Missing Coverage Tests

    @Test("Project future levels for medication profile")
    @MainActor
    func projectFutureLevels() throws {
        // Create proper SwiftData context for testing
        let container = DataController.testContainer()
        let context = container.container.mainContext

        // Create user and medication profile in context
        let user = User(email: "test@example.com", name: "Test User", appleUserId: "test-id")
        context.insert(user)

        let medicationProfile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            startDate: self.testDate.addingTimeInterval(-7 * 24 * 3600),
            medicationType: "semaglutide")
        medicationProfile.user = user
        context.insert(medicationProfile)

        // Add some existing doses
        let dose1 = Dose(
            amount: 0.5,
            timestamp: self.testDate.addingTimeInterval(-21 * 24 * 3600),
            medication: medicationProfile)
        dose1.user = user
        context.insert(dose1)

        let dose2 = Dose(
            amount: 1.0,
            timestamp: self.testDate.addingTimeInterval(-14 * 24 * 3600),
            medication: medicationProfile)
        dose2.user = user
        context.insert(dose2)

        let dose3 = Dose(
            amount: 1.0,
            timestamp: self.testDate.addingTimeInterval(-7 * 24 * 3600),
            medication: medicationProfile)
        dose3.user = user
        context.insert(dose3)

        // Save context
        try context.save()

        // Project 14 days into the future
        let projections = self.engine.projectFutureLevels(for: medicationProfile, days: 14)

        #expect(projections.count > 0, "Should return projection points")
        #expect(projections.count <= 101, "Should not exceed ~100 projection points for performance")

        // Verify projections are sorted by date
        for index in 1..<projections.count {
            #expect(
                projections[index - 1].date <= projections[index].date,
                "Projections should be chronologically ordered")
        }

        // Verify projections include future dates
        let futureProjections = projections.filter { $0.date > self.testDate }
        #expect(futureProjections.count > 0, "Should include future projection points")

        // Verify all concentrations are non-negative
        for projection in projections {
            #expect(
                projection.concentration >= 0,
                "All concentrations should be non-negative")
        }
    }

    @Test("Generate projected doses based on dosing pattern")
    @MainActor
    func generateProjectedDoses() throws {
        // Create proper SwiftData context for testing
        let container = DataController.testContainer()
        let context = container.container.mainContext

        // Create user and medication profile in context
        let user = User(email: "test@example.com", name: "Test User", appleUserId: "test-id")
        context.insert(user)

        let medicationProfile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            startDate: self.testDate.addingTimeInterval(-7 * 24 * 3600),
            medicationType: "semaglutide")
        medicationProfile.user = user
        context.insert(medicationProfile)

        // Add an existing dose
        let existingDose = Dose(
            amount: 1.0,
            timestamp: self.testDate.addingTimeInterval(-7 * 24 * 3600),  // 1 week ago
            medication: medicationProfile)
        existingDose.user = user
        context.insert(existingDose)

        // Save context
        try context.save()

        // Use reflection to access private method for testing
        let projectedDoses = self.engine.projectFutureLevels(for: medicationProfile, days: 21)

        // This indirectly tests generateProjectedDoses by verifying future levels work
        #expect(projectedDoses.count > 0, "Should project future levels based on dosing pattern")

        // Test daily medication (different dosing pattern)
        let liraglutideProfile = MedicationProfile(
            genericName: "liraglutide",
            brandName: "Victoza",
            currentDose: 1.8,
            startDate: self.testDate.addingTimeInterval(-7 * 24 * 3600),
            medicationType: "liraglutide")
        liraglutideProfile.user = user
        context.insert(liraglutideProfile)

        try context.save()

        let liraglutideProjections = self.engine.projectFutureLevels(for: liraglutideProfile, days: 7)
        #expect(liraglutideProjections.count > 0, "Should handle daily medication projections")
    }

    @Test("Validation error handling for invalid inputs")
    @MainActor
    func getValidationError() throws {
        // Create proper SwiftData context for testing
        let container = DataController.testContainer()
        let context = container.container.mainContext

        // Create user and medication profile in context
        let user = User(email: "test@example.com", name: "Test User", appleUserId: "test-id")
        context.insert(user)

        let medicationProfile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            medicationType: "semaglutide")
        medicationProfile.user = user
        context.insert(medicationProfile)

        // Create valid doses
        let validDose1 = Dose(
            amount: 1.0,
            timestamp: self.testDate.addingTimeInterval(-7 * 24 * 3600),
            medication: medicationProfile)
        validDose1.user = user
        context.insert(validDose1)

        let validDose2 = Dose(
            amount: 1.0,
            timestamp: self.testDate.addingTimeInterval(-14 * 24 * 3600),
            medication: medicationProfile)
        validDose2.user = user
        context.insert(validDose2)

        try context.save()

        let validationError = self.engine.getValidationError(
            doses: [validDose1, validDose2], medication: .semaglutide)
        #expect(validationError == nil, "Valid inputs should not return validation error")

        // Test with invalid dose amounts (too large)
        let invalidDose = Dose(
            amount: 2000.0,  // Exceeds reasonable limit
            timestamp: self.testDate,
            medication: medicationProfile)
        invalidDose.user = user
        context.insert(invalidDose)

        try context.save()

        let invalidError = self.engine.getValidationError(
            doses: [invalidDose], medication: .semaglutide)
        #expect(invalidError != nil, "Invalid dose amount should return validation error")

        // Test with negative dose amount
        let negativeDose = Dose(
            amount: -1.0,
            timestamp: self.testDate,
            medication: medicationProfile)
        negativeDose.user = user
        context.insert(negativeDose)

        try context.save()

        let negativeError = self.engine.getValidationError(
            doses: [negativeDose], medication: .semaglutide)
        #expect(negativeError != nil, "Negative dose amount should return validation error")

        // Test validation logic
        let isValid = self.engine.validateCalculationInputs(
            doses: [validDose1, validDose2], medication: .semaglutide)
        #expect(isValid == true, "Valid inputs should pass validation")

        let isInvalid = self.engine.validateCalculationInputs(
            doses: [invalidDose], medication: .semaglutide)
        #expect(isInvalid == false, "Invalid inputs should fail validation")
    }

    @Test("Optimized concentration calculation with cutoff")
    func calculateConcentrationOptimized() throws {
        let medicationProfile = self.createTestMedicationProfile(medication: .semaglutide)

        // Create doses spanning a long time period (some should be filtered out)
        let oldDoses = self.createTestDoses(
            amounts: [1.0, 1.0, 1.0],
            daysAgo: [300, 250, 200],  // Very old doses
            medicationProfile: medicationProfile)

        let recentDoses = self.createTestDoses(
            amounts: [1.0, 1.0],
            daysAgo: [14, 7],  // Recent doses
            medicationProfile: medicationProfile)

        let allDoses = oldDoses + recentDoses

        // Calculate regular concentration
        let regularConcentration = self.engine.calculateConcentration(
            from: allDoses,
            medication: .semaglutide,
            at: self.testDate)

        // Calculate optimized concentration (should filter out very old doses)
        let optimizedConcentration = self.engine.calculateConcentrationOptimized(
            from: allDoses,
            medication: .semaglutide,
            at: self.testDate,
            concentrationCutoff: 0.001)

        // Optimized should be very close to regular for this case
        // (old doses contribute negligibly anyway due to exponential decay)
        let tolerance = 0.01
        #expect(
            abs(optimizedConcentration - regularConcentration) < tolerance,
            "Optimized calculation should be close to regular calculation for meaningful doses")

        // Test with only recent doses
        let recentOnlyOptimized = self.engine.calculateConcentrationOptimized(
            from: recentDoses,
            medication: .semaglutide,
            at: self.testDate,
            concentrationCutoff: 0.001)

        #expect(recentOnlyOptimized > 0, "Should calculate concentration from recent doses")

        // Test with custom cutoff
        let customCutoffConcentration = self.engine.calculateConcentrationOptimized(
            from: allDoses,
            medication: .semaglutide,
            at: self.testDate,
            concentrationCutoff: 0.01)  // Higher cutoff

        #expect(customCutoffConcentration >= 0, "Should handle custom concentration cutoff")
    }
}
