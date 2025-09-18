//
//  PKDashboardIntegrationTests.swift
//  JabTrackerTests
//
//  Integration tests for dose entry → pharmacokinetics calculation → dashboard update flow
//  Tests the complete workflow from dose logging to concentration display
//

import Testing
import SwiftData
import Foundation
@testable import JabTracker

/// Integration tests for pharmacokinetics dashboard workflow
/// Tests the complete flow: dose entry → PK calculation → dashboard display update
@Suite("PK Dashboard Integration Tests")
struct PKDashboardIntegrationTests {

    // MARK: - Test Infrastructure

    private var container: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(
                for: User.self, MedicationProfile.self, Dose.self,
                configurations: config
            )
            return container
        } catch {
            fatalError("Failed to create test container: \(error)")
        }
    }

    private func createTestUser() -> User {
        User(
            appleUserId: "test-user-pk-integration",
            email: "test@pkintegration.com",
            name: "PK Integration Test User"
        )
    }

    private func createTestMedicationProfile(user: User) -> MedicationProfile {
        MedicationProfile(
            user: user,
            medicationName: "semaglutide",
            dosage: 1.0,
            frequency: .weekly,
            startDate: Date().addingTimeInterval(-14 * 24 * 3600) // 2 weeks ago
        )
    }

    // MARK: - Test: Dose Save Triggers PK Recalculation

    @Test("Dose save triggers PK recalculation", arguments: [
        ("New dose entry", 1.0, Date()),
        ("Higher dose entry", 2.5, Date().addingTimeInterval(-3600)),
        ("Lower dose entry", 0.5, Date().addingTimeInterval(-7200))
    ])
    func doseSaveTriggersRecalculation(_ testName: String, amount: Double, timestamp: Date) async throws {
        let testContainer = container
        let context = testContainer.mainContext

        // Setup test data
        let user = createTestUser()
        let medicationProfile = createTestMedicationProfile(user: user)

        context.insert(user)
        context.insert(medicationProfile)
        try context.save()

        // Create PK engine and dose service
        let pkEngine = PharmacokineticsEngine()
        let doseService = DoseService(pkEngine: pkEngine)

        // Initial concentration should be zero (no doses)
        let initialConcentration = pkEngine.calculateCurrentConcentration(
            for: user,
            medication: medicationProfile
        )
        #expect(initialConcentration == 0.0, "Initial concentration should be zero with no doses")

        // Save new dose through dose service
        let savedDose = try await doseService.saveDose(
            amount: amount,
            timestamp: timestamp,
            medicationProfile: medicationProfile,
            site: "Abdomen",
            notes: "Integration test dose",
            context: context
        )

        // Verify dose was saved
        #expect(savedDose.amount == amount, "Saved dose amount should match input")
        #expect(savedDose.timestamp == timestamp, "Saved dose timestamp should match input")

        // Verify PK calculations were triggered and concentration updated
        let updatedConcentration = pkEngine.calculateCurrentConcentration(
            for: user,
            medication: medicationProfile
        )

        if timestamp <= Date() {
            #expect(
                updatedConcentration > 0.0,
                "Concentration should be greater than zero after dose save for \(testName)"
            )
        } else {
            #expect(updatedConcentration == 0.0, "Future dose should not affect current concentration")
        }

        // Verify dose is included in medication profile
        let fetchedProfile = try context.fetch(FetchDescriptor<MedicationProfile>()).first
        #expect(fetchedProfile?.doses?.count == 1, "Medication profile should contain one dose")
        #expect(fetchedProfile?.doses?.first?.amount == amount, "Profile dose amount should match saved dose")
    }

    // MARK: - Test: Dashboard Updates After Dose Entry

    @Test("Dashboard updates automatically after dose entry")
    func dashboardUpdatesAfterDoseEntry() async throws {
        let testContainer = container
        let context = testContainer.mainContext

        // Setup test data
        let user = createTestUser()
        let medicationProfile = createTestMedicationProfile(user: user)

        context.insert(user)
        context.insert(medicationProfile)
        try context.save()

        // Create PK engine and dose service
        let pkEngine = PharmacokineticsEngine()
        let doseService = DoseService(pkEngine: pkEngine)

        // Initial dashboard state - no doses
        var currentConcentration = pkEngine.calculateCurrentConcentration(for: user, medication: medicationProfile)
        var peakLevel = pkEngine.calculatePeakLevel(
            for: Dose(amount: 1.0, timestamp: Date(), medication: medicationProfile),
            medication: medicationProfile
        )
        var troughLevel = pkEngine.calculateTroughLevel(for: medicationProfile)
        var steadyStateProgress = pkEngine.calculateSteadyStateProgress(for: medicationProfile)

        #expect(currentConcentration == 0.0, "Initial concentration should be zero")
        #expect(steadyStateProgress > 0.0, "Steady state progress should be > 0 after start date")

        // Add first dose
        let firstDose = try await doseService.saveDose(
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-24 * 3600), // 1 day ago
            medicationProfile: medicationProfile,
            site: "Abdomen",
            notes: "First dose",
            context: context
        )

        // Dashboard should update after first dose
        currentConcentration = pkEngine.calculateCurrentConcentration(for: user, medication: medicationProfile)
        peakLevel = pkEngine.calculatePeakLevel(for: firstDose, medication: medicationProfile)
        troughLevel = pkEngine.calculateTroughLevel(for: medicationProfile)

        #expect(currentConcentration > 0.0, "Concentration should be positive after first dose")
        #expect(peakLevel.level > 0.0, "Peak level should be calculated for first dose")
        #expect(peakLevel.time > firstDose.timestamp, "Peak time should be after dose time")
        #expect(troughLevel.level >= 0.0, "Trough level should be calculated")

        // Add second dose
        let secondDose = try await doseService.saveDose(
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            medicationProfile: medicationProfile,
            site: "Thigh",
            notes: "Second dose",
            context: context
        )

        // Dashboard should reflect cumulative effect
        let cumulativeConcentration = pkEngine.calculateCurrentConcentration(for: user, medication: medicationProfile)

        #expect(
            cumulativeConcentration > currentConcentration,
            "Cumulative concentration should be higher than single dose"
        )

        // Verify medication profile has both doses
        let updatedProfile = try context.fetch(FetchDescriptor<MedicationProfile>()).first
        #expect(updatedProfile?.doses?.count == 2, "Profile should contain both doses")
    }

    // MARK: - Test: Multiple Medication Profiles

    @Test("Multiple medication calculations work independently")
    func multipleMedicationCalculations() async throws {
        let testContainer = container
        let context = testContainer.mainContext

        // Setup test data
        let user = createTestUser()
        let semaglutideProfile = createTestMedicationProfile(user: user)

        // Create second medication profile
        let liraglutideProfile = MedicationProfile(
            user: user,
            medicationName: "liraglutide",
            dosage: 0.6,
            frequency: .daily,
            startDate: Date().addingTimeInterval(-7 * 24 * 3600)
        )

        context.insert(user)
        context.insert(semaglutideProfile)
        context.insert(liraglutideProfile)
        try context.save()

        // Create PK engine and dose service
        let pkEngine = PharmacokineticsEngine()
        let doseService = DoseService(pkEngine: pkEngine)

        // Add dose to first medication
        try await doseService.saveDose(
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-12 * 3600),
            medicationProfile: semaglutideProfile,
            site: "Abdomen",
            notes: "Semaglutide dose",
            context: context
        )

        // Add dose to second medication
        try await doseService.saveDose(
            amount: 0.6,
            timestamp: Date().addingTimeInterval(-6 * 3600),
            medicationProfile: liraglutideProfile,
            site: "Thigh",
            notes: "Liraglutide dose",
            context: context
        )

        // Calculate concentrations for both medications
        let semaglutideConcentration = pkEngine.calculateCurrentConcentration(for: user, medication: semaglutideProfile)
        let liraglutideConcentration = pkEngine.calculateCurrentConcentration(for: user, medication: liraglutideProfile)

        #expect(semaglutideConcentration > 0.0, "Semaglutide concentration should be positive")
        #expect(liraglutideConcentration > 0.0, "Liraglutide concentration should be positive")

        // Concentrations should be different due to different medications and timing
        #expect(
            semaglutideConcentration != liraglutideConcentration,
            "Different medications should have different concentrations"
        )

        // Verify steady state progress is calculated independently
        let semaglutideSteadyState = pkEngine.calculateSteadyStateProgress(for: semaglutideProfile)
        let liraglutideSteadyState = pkEngine.calculateSteadyStateProgress(for: liraglutideProfile)

        #expect(
            semaglutideSteadyState >= 0.0 && semaglutideSteadyState <= 1.0,
            "Semaglutide steady state should be valid percentage"
        )
        #expect(
            liraglutideSteadyState >= 0.0 && liraglutideSteadyState <= 1.0,
            "Liraglutide steady state should be valid percentage"
        )
    }

    // MARK: - Test: Dose Editing Updates Calculations

    @Test("Dose editing triggers PK recalculation")
    func doseEditingTriggersRecalculation() async throws {
        let testContainer = container
        let context = testContainer.mainContext

        // Setup test data
        let user = createTestUser()
        let medicationProfile = createTestMedicationProfile(user: user)

        context.insert(user)
        context.insert(medicationProfile)
        try context.save()

        // Create PK engine and dose service
        let pkEngine = PharmacokineticsEngine()
        let doseService = DoseService(pkEngine: pkEngine)

        // Save initial dose
        let originalDose = try await doseService.saveDose(
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-12 * 3600),
            medicationProfile: medicationProfile,
            site: "Abdomen",
            notes: "Original dose",
            context: context
        )

        let originalConcentration = pkEngine.calculateCurrentConcentration(for: user, medication: medicationProfile)
        #expect(originalConcentration > 0.0, "Original concentration should be positive")

        // Edit dose amount
        let editData = DoseEditData(
            id: originalDose.id,
            amount: 2.0, // Double the original dose
            timestamp: originalDose.timestamp,
            site: "Thigh",
            notes: "Edited dose - doubled amount",
            imageData: nil,
            skipped: false,
            medicationProfile: medicationProfile
        )

        try await doseService.updateDose(with: editData, context: context)

        // Verify concentration updated after edit
        let updatedConcentration = pkEngine.calculateCurrentConcentration(for: user, medication: medicationProfile)
        #expect(
            updatedConcentration > originalConcentration,
            "Concentration should increase after dose amount increase"
        )

        // Verify the dose was actually updated in the database
        let fetchedDoses = try context.fetch(FetchDescriptor<Dose>())
        #expect(fetchedDoses.count == 1, "Should still have only one dose")
        #expect(fetchedDoses.first?.amount == 2.0, "Dose amount should be updated to 2.0")
        #expect(fetchedDoses.first?.site == "Thigh", "Dose site should be updated")
    }

    // MARK: - Test: Missed Dose Handling

    @Test("Missed dose logging updates calculations correctly")
    func missedDoseLoggingUpdatesCalculations() async throws {
        let testContainer = container
        let context = testContainer.mainContext

        // Setup test data
        let user = createTestUser()
        let medicationProfile = createTestMedicationProfile(user: user)

        context.insert(user)
        context.insert(medicationProfile)
        try context.save()

        // Create PK engine and dose service
        let pkEngine = PharmacokineticsEngine()
        let doseService = DoseService(pkEngine: pkEngine)

        // Add normal dose
        try await doseService.saveDose(
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-14 * 24 * 3600), // 2 weeks ago
            medicationProfile: medicationProfile,
            site: "Abdomen",
            notes: "Normal dose",
            context: context
        )

        let concentrationAfterNormalDose = pkEngine.calculateCurrentConcentration(
            for: user,
            medication: medicationProfile
        )

        // Log missed dose (skipped = true)
        let missedDoseTimestamp = Date().addingTimeInterval(-7 * 24 * 3600) // 1 week ago
        try await doseService.saveDose(
            amount: 1.0,
            timestamp: missedDoseTimestamp,
            medicationProfile: medicationProfile,
            site: nil,
            notes: "Missed dose",
            skipped: true,
            context: context
        )

        // Concentration should not increase due to missed dose
        let concentrationAfterMissedDose = pkEngine.calculateCurrentConcentration(
            for: user,
            medication: medicationProfile
        )
        #expect(
            concentrationAfterMissedDose <= concentrationAfterNormalDose,
            "Missed dose should not increase concentration"
        )

        // Verify missed dose is recorded but marked as skipped
        let fetchedDoses = try context.fetch(FetchDescriptor<Dose>())
        let missedDose = fetchedDoses.first { $0.timestamp == missedDoseTimestamp }
        #expect(missedDose != nil, "Missed dose should be recorded")
        #expect(missedDose?.skipped == true, "Missed dose should be marked as skipped")

        // Add dose after missed dose to verify normal calculation resumes
        try await doseService.saveDose(
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            medicationProfile: medicationProfile,
            site: "Thigh",
            notes: "Resume dose",
            context: context
        )

        let concentrationAfterResume = pkEngine.calculateCurrentConcentration(
            for: user,
            medication: medicationProfile
        )
        #expect(
            concentrationAfterResume > concentrationAfterMissedDose,
            "Concentration should increase after resuming doses"
        )
    }

    // MARK: - Test: Dashboard Refresh Performance

    @Test("Dashboard calculation performance with large dose history")
    func dashboardPerformanceWithLargeDoseHistory() async throws {
        let testContainer = container
        let context = testContainer.mainContext

        // Setup test data
        let user = createTestUser()
        let medicationProfile = createTestMedicationProfile(user: user)

        context.insert(user)
        context.insert(medicationProfile)
        try context.save()

        // Create PK engine and dose service
        let pkEngine = PharmacokineticsEngine()
        let doseService = DoseService(pkEngine: pkEngine)

        // Add many doses to simulate long medication history
        let numberOfDoses = 100
        for index in 0..<numberOfDoses {
            let daysAgo = Double(numberOfDoses - index)
            try await doseService.saveDose(
                amount: 1.0,
                timestamp: Date().addingTimeInterval(-daysAgo * 24 * 3600),
                medicationProfile: medicationProfile,
                site: index % 2 == 0 ? "Abdomen" : "Thigh",
                notes: "Dose \(index + 1)",
                context: context
            )
        }

        // Measure calculation performance
        let startTime = Date()

        let concentration = pkEngine.calculateCurrentConcentration(
            for: user,
            medication: medicationProfile
        )
        _ = pkEngine.calculateTroughLevel(for: medicationProfile)
        _ = pkEngine.calculateSteadyStateProgress(for: medicationProfile)

        let calculationTime = Date().timeIntervalSince(startTime)

        // Verify calculations completed quickly (< 50ms as per requirements)
        #expect(
            calculationTime < 0.05,
            "Calculations should complete in under 50ms, actual: \(calculationTime * 1000)ms"
        )
        #expect(concentration > 0.0, "Concentration should be positive with large dose history")

        // Verify all doses were properly saved
        let allDoses = try context.fetch(FetchDescriptor<Dose>())
        #expect(allDoses.count == numberOfDoses, "All doses should be saved")
    }

    // MARK: - Test: Real-time Dashboard Updates

    @Test("Dashboard updates in real-time when dose data changes")
    func dashboardUpdatesInRealTime() async throws {
        let testContainer = container
        let context = testContainer.mainContext

        // Setup test data
        let user = createTestUser()
        let medicationProfile = createTestMedicationProfile(user: user)

        context.insert(user)
        context.insert(medicationProfile)
        try context.save()

        // Create PK engine and dose service
        let pkEngine = PharmacokineticsEngine()
        let doseService = DoseService(pkEngine: pkEngine)

        // Initial state
        var concentration = pkEngine.calculateCurrentConcentration(for: user, medication: medicationProfile)
        #expect(concentration == 0.0, "Initial concentration should be zero")

        // Add dose and verify immediate update
        try await doseService.saveDose(
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            medicationProfile: medicationProfile,
            site: "Abdomen",
            notes: "Real-time test dose",
            context: context
        )

        // Concentration should immediately reflect new dose
        concentration = pkEngine.calculateCurrentConcentration(for: user, medication: medicationProfile)
        #expect(concentration > 0.0, "Concentration should immediately update after dose save")

        // Test that calculation accounts for time passage
        let futureTime = Date().addingTimeInterval(3600) // 1 hour from now
        if let medication = medicationProfile.medication {
            let futureConcentration = pkEngine.calculateConcentration(
                from: medicationProfile.doses ?? [],
                medication: medication,
                at: futureTime
            )

            #expect(futureConcentration < concentration, "Future concentration should be lower due to decay")
            #expect(futureConcentration > 0.0, "Future concentration should still be positive")
        }
    }
}

// MARK: - Supporting Types

/// Mock data structure for dose editing in integration tests
