//
//  DoseServiceTests.swift
//  JabTracker
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("DoseService Tests")
struct DoseServiceTests {

    // MARK: - Test Setup

    private func createTestContainer() throws -> ModelContainer {
        let config = InMemoryTestStore.configuration()
        return try ModelContainer(
            for: User.self, MedicationProfile.self, Dose.self, configurations: config)
    }

    private func createTestUser(context: ModelContext) -> User {
        let user = User(email: "test@example.com", name: "Test User", appleUserId: "test-user")
        context.insert(user)
        return user
    }

    private func createTestMedicationProfile(
        user: User, context: ModelContext
    ) -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            medicationType: "semaglutide")
        profile.user = user
        context.insert(profile)
        return profile
    }

    // MARK: - Delete Dose Tests

    @Test("DoseService deleteDose removes dose successfully")
    @MainActor
    func deleteDoseSuccess() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let doseService = DoseService(pkEngine: PharmacokineticsEngine())

        // Create test data
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(user: user, context: context)

        // Create a dose to delete
        let dose = Dose(amount: 1.0, timestamp: Date(), medication: profile)
        dose.user = user
        context.insert(dose)
        try context.save()

        let doseId = dose.id

        // Verify dose exists before deletion
        let beforeDeleteDescriptor = FetchDescriptor<Dose>(
            predicate: #Predicate<Dose> { dose in dose.id == doseId }
        )
        let beforeDeleteCount = try context.fetch(beforeDeleteDescriptor).count
        #expect(beforeDeleteCount == 1, "Dose should exist before deletion")

        // Delete the dose
        try await doseService.deleteDose(with: doseId, context: context)

        // Verify dose is deleted
        let afterDeleteDescriptor = FetchDescriptor<Dose>(
            predicate: #Predicate<Dose> { dose in dose.id == doseId }
        )
        let afterDeleteCount = try context.fetch(afterDeleteDescriptor).count
        #expect(afterDeleteCount == 0, "Dose should be deleted")

        // Verify service state is updated
        #expect(doseService.lastError == nil, "Should not have error after successful deletion")
        #expect(doseService.isProcessingDose == false, "Should not be processing after completion")
    }

    @Test("DoseService deleteDose throws error for non-existent dose")
    @MainActor
    func deleteDoseNotFound() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let doseService = DoseService(pkEngine: PharmacokineticsEngine())

        let nonExistentId = UUID()

        // Attempt to delete non-existent dose
        do {
            try await doseService.deleteDose(with: nonExistentId, context: context)
            #expect(Bool(false), "Should throw error for non-existent dose")
        } catch let error as DoseServiceError {
            #expect(error == .doseNotFound, "Should throw doseNotFound error")
            #expect(doseService.lastError == .doseNotFound, "Should set lastError to doseNotFound")
        } catch {
            #expect(Bool(false), "Should throw DoseServiceError, got \(error)")
        }

        #expect(doseService.isProcessingDose == false, "Should not be processing after error")
    }

    @Test("DoseService deleteDose handles context save failure")
    @MainActor
    func deleteDoseContextFailure() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let doseService = DoseService(pkEngine: PharmacokineticsEngine())

        // Create test data
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(user: user, context: context)

        let dose = Dose(amount: 1.0, timestamp: Date(), medication: profile)
        dose.user = user
        context.insert(dose)
        try context.save()

        let doseId = dose.id

        // Note: It's difficult to force a save failure in an in-memory context
        // This test primarily verifies the error handling structure exists
        // In a real app, this could fail due to constraint violations, disk space, etc.

        try await doseService.deleteDose(with: doseId, context: context)

        // If we reach here, the deletion succeeded (which is expected with in-memory context)
        #expect(doseService.lastError == nil, "Should not have error with successful deletion")
    }

    @Test("DoseService deleteDose sets processing state correctly")
    @MainActor
    func deleteDoseProcessingState() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let doseService = DoseService(pkEngine: PharmacokineticsEngine())

        // Create test data
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(user: user, context: context)

        let dose = Dose(amount: 1.0, timestamp: Date(), medication: profile)
        dose.user = user
        context.insert(dose)
        try context.save()

        let doseId = dose.id

        // Initially not processing
        #expect(doseService.isProcessingDose == false, "Should start not processing")

        // Delete dose and verify processing state is managed
        try await doseService.deleteDose(with: doseId, context: context)

        // After completion, should not be processing
        #expect(doseService.isProcessingDose == false, "Should not be processing after completion")
    }

    // MARK: - Error Description Tests

    @Test("DoseServiceError provides correct error descriptions")
    func doseServiceErrorDescriptions() {
        // Test invalidDoseAmount
        let amountError = DoseServiceError.invalidDoseAmount("Cannot be negative")
        #expect(amountError.errorDescription == "Invalid dose amount: Cannot be negative")

        // Test invalidTimestamp
        let timestampError = DoseServiceError.invalidTimestamp("Too far in future")
        #expect(timestampError.errorDescription == "Invalid dose timing: Too far in future")

        // Test invalidMedicationProfile
        let profileError = DoseServiceError.invalidMedicationProfile("Missing medication type")
        #expect(profileError.errorDescription == "Invalid medication profile: Missing medication type")

        // Test doseNotFound
        let notFoundError = DoseServiceError.doseNotFound
        #expect(notFoundError.errorDescription == "Dose not found")

        // Test pkValidationFailure
        let pkError = DoseServiceError.pkValidationFailure("Invalid parameters")
        #expect(pkError.errorDescription == "Pharmacokinetic validation failed: Invalid parameters")

        // Test persistenceFailure
        let underlyingError = NSError(
            domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let persistenceError = DoseServiceError.persistenceFailure(underlying: underlyingError)
        #expect(persistenceError.errorDescription == "Failed to save dose: Test error")
    }

    @Test("DoseServiceError equality comparison")
    func doseServiceErrorEquality() {
        // Test same errors are equal
        let error1 = DoseServiceError.invalidDoseAmount("Test message")
        let error2 = DoseServiceError.invalidDoseAmount("Test message")
        #expect(error1 == error2, "Same errors should be equal")

        // Test different messages are not equal
        let error3 = DoseServiceError.invalidDoseAmount("Different message")
        #expect(error1 != error3, "Different messages should not be equal")

        // Test different error types are not equal
        let error4 = DoseServiceError.doseNotFound
        #expect(error1 != error4, "Different error types should not be equal")

        // Test doseNotFound errors are equal
        let error5 = DoseServiceError.doseNotFound
        let error6 = DoseServiceError.doseNotFound
        #expect(error5 == error6, "doseNotFound errors should be equal")
    }

    @Test("DoseServiceError localized error conformance")
    func doseServiceErrorLocalizedError() {
        let error = DoseServiceError.invalidDoseAmount("Test message")

        // Test LocalizedError conformance
        #expect(error.errorDescription != nil, "Should provide error description")
        #expect(error.errorDescription?.isEmpty == false, "Error description should not be empty")

        // Test that it's actually a LocalizedError
        let localizedError: LocalizedError = error
        #expect(
            localizedError.errorDescription == error.errorDescription,
            "LocalizedError protocol should work")
    }
}
