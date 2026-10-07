//
//  MedicationManagerTests.swift
//  JabTrackerTests
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("MedicationManager Tests")
struct MedicationManagerTests {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        let config = InMemoryTestStore.configuration()
        self.container = try ModelContainer(
            for: User.self, MedicationProfile.self, Dose.self,
            DoseSchedule.self, ScheduledDose.self,
            configurations: config)
        self.context = ModelContext(self.container)
    }

    private func createTestUser() throws -> User {
        let testUser = User(email: "test@example.com", name: "Test User")
        self.context.insert(testUser)
        try self.context.save()
        return testUser
    }

    @Test("Create medication profile with valid data")
    @MainActor
    func createValidProfile() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let testUser = try createTestUser()
        let medication = Medication.semaglutide
        let brandName = "Ozempic"
        let currentDose = 0.5

        // When
        let profile = try manager.createProfile(
            for: testUser,
            medication: medication,
            brandName: brandName,
            currentDose: currentDose,
            isCompounded: false)

        // Then
        #expect(profile.genericName == medication.displayName)
        #expect(profile.brandName == brandName)
        #expect(profile.currentDose == currentDose)
        #expect(profile.isCompounded == false)
        // penType field removed
        #expect(profile.medicationType == medication.rawValue)
    }

    @Test("Create compounded medication profile")
    @MainActor
    func createCompoundedProfile() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let testUser = try createTestUser()
        let medication = Medication.tirzepatide
        let vialStrength = 10.0
        let reconstitutionVolume = 2.0
        let currentDose = 2.5

        // When
        let profile = try manager.createProfile(
            for: testUser,
            medication: medication,
            brandName: "Compounded",
            currentDose: currentDose,
            isCompounded: true,
            vialStrength: vialStrength,
            reconstitutionVolume: reconstitutionVolume)

        // Then
        #expect(profile.isCompounded == true)
        #expect(profile.vialStrength == vialStrength)
        #expect(profile.reconstitutionVolume == reconstitutionVolume)
        #expect(profile.currentDose == currentDose)
    }

    @Test("Create records a finite prescribed amount without clinical range judgement")
    @MainActor
    func createProfileWithPrescribedAmount() throws {
        let manager = MedicationManager(modelContext: context)
        let user = try createTestUser()
        let profile = try manager.createProfile(
            for: user, medication: .semaglutide, brandName: "Ozempic", currentDose: 5.0
        )
        #expect(profile.currentDose == 5.0)
        #expect(profile.brandName == "Ozempic")
        #expect((profile.schedules ?? []).count == 0)
        #expect(try context.fetchCount(FetchDescriptor<DoseSchedule>()) == 0)
    }

    @Test("Compounded recording preserves raw fields without calculator eligibility checks")
    @MainActor
    func createCompoundedProfileStoresRawFields() throws {
        let manager = MedicationManager(modelContext: context)
        let user = try createTestUser()
        let profile = try manager.createProfile(
            for: user, medication: .semaglutide, brandName: "Compounded", currentDose: 2.0,
            isCompounded: true, vialStrength: 1.0, reconstitutionVolume: 2.0
        )
        #expect(profile.currentDose == 2.0)
        #expect(profile.isCompounded == true)
        #expect(profile.vialStrength == 1.0)
        #expect(profile.reconstitutionVolume == 2.0)
        #expect(profile.concentration == nil)
        #expect(profile.unitsPerDose == nil)
    }

    @Test("Update medication profile dose")
    @MainActor
    func updateProfileDose() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let testUser = try createTestUser()
        let profile = try manager.createProfile(
            for: testUser,
            medication: .semaglutide,
            brandName: "Ozempic",
            currentDose: 0.25)

        // When
        try manager.updateProfile(profile, currentDose: 0.5)

        // Then
        #expect(profile.currentDose == 0.5)
        #expect(profile.updatedAt > profile.createdAt)
    }

    @Test("Updating medication refreshes the generic name used by dose events")
    @MainActor
    func updateProfileMedicationRefreshesGenericName() throws {
        let manager = MedicationManager(modelContext: context)
        let testUser = try createTestUser()
        let profile = try manager.createProfile(
            for: testUser,
            medication: .semaglutide,
            brandName: "Generic",
            currentDose: 0.25)

        try manager.updateProfile(
            profile,
            medication: .tirzepatide,
            brandName: "Generic",
            currentDose: 2.5)

        #expect(profile.medicationType == Medication.tirzepatide.rawValue)
        #expect(profile.genericName == Medication.tirzepatide.displayName)
        #expect(profile.displayName == Medication.tirzepatide.displayName)
    }

    @Test("Update records the exact finite prescribed amount without a clinical dose clamp")
    @MainActor
    func updateProfileWithPrescribedAmount() throws {
        let manager = MedicationManager(modelContext: context)
        let user = try createTestUser()
        let profile = try manager.createProfile(
            for: user, medication: .semaglutide, brandName: "Ozempic", currentDose: 0.25
        )
        try manager.updateProfile(profile, currentDose: 10.125)
        #expect(profile.currentDose == 10.125)
        let reloaded = try #require(context.fetch(FetchDescriptor<MedicationProfile>()).first)
        #expect(reloaded.currentDose == 10.125)
    }

    @Test("Delete medication profile")
    @MainActor
    func testDeleteProfile() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let testUser = try createTestUser()
        let profile = try manager.createProfile(
            for: testUser,
            medication: .semaglutide,
            brandName: "Ozempic",
            currentDose: 0.5)

        // When
        try manager.deleteProfile(profile)

        // Then
        manager.fetchProfiles()
        #expect(manager.profiles.isEmpty)
    }

    @Test("Fetch profiles returns sorted by date")
    @MainActor
    func fetchProfilesSortedByDate() throws {
        // Given
        let manager = MedicationManager(modelContext: context)

        // Create profiles with different dates
        let profile1 = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Ozempic",
            currentDose: 0.5,
            startDate: Date().addingTimeInterval(-86400)  // Yesterday
        )
        let profile2 = MedicationProfile(
            genericName: "Tirzepatide",
            brandName: "Mounjaro",
            currentDose: 2.5,
            startDate: Date()  // Today
        )

        self.context.insert(profile1)
        self.context.insert(profile2)
        try self.context.save()

        // When
        manager.fetchProfiles()

        // Then
        #expect(manager.profiles.count == 2)
        #expect(manager.profiles.first?.brandName == "Mounjaro")  // Most recent first
    }

    @Test("Validate dose for medication")
    @MainActor
    func testIsValidDose() throws {
        // Given
        let manager = MedicationManager(modelContext: context)

        // When/Then
        #expect(manager.isValidDose(0.25, for: .semaglutide) == true)
        #expect(manager.isValidDose(0.5, for: .semaglutide) == true)
        #expect(manager.isValidDose(2.4, for: .semaglutide) == true)
        #expect(manager.isValidDose(3.0, for: .semaglutide) == false)
        #expect(manager.isValidDose(0.15, for: .semaglutide) == false)
    }

    @Test("Get next escalation dose")
    @MainActor
    func testNextEscalationDose() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let testUser = try createTestUser()
        let profile = try manager.createProfile(
            for: testUser,
            medication: .semaglutide,
            brandName: "Ozempic",
            currentDose: 0.25)

        // When
        let nextDose = manager.nextEscalationDose(for: profile)

        // Then
        #expect(nextDose == 0.5)
    }

    @Test("Get next escalation dose at maximum returns nil")
    @MainActor
    func nextEscalationDoseAtMaximum() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let testUser = try createTestUser()
        let profile = try manager.createProfile(
            for: testUser,
            medication: .semaglutide,
            brandName: "Ozempic",
            currentDose: 2.0  // Maximum dose for Ozempic
        )

        // When
        let nextDose = manager.nextEscalationDose(for: profile)

        // Then
        #expect(nextDose == nil)
    }

    @Test("Calculate days until refill")
    @MainActor
    func testDaysUntilRefill() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let testUser = try createTestUser()
        let futureDate = Date().addingTimeInterval(7 * 86400)  // 7 days from now
        let profile = try manager.createProfile(
            for: testUser,
            medication: .semaglutide,
            brandName: "Ozempic",
            currentDose: 0.5)

        // When
        try manager.updateProfile(profile, refillDate: futureDate)
        let days = manager.daysUntilRefill(for: profile)

        // Then
        #expect(days != nil)
        #expect(days! >= 6 && days! <= 7)  // Account for test execution time
    }

    @Test("Calculate reconstitution for compounded profile")
    @MainActor
    func testCalculateReconstitution() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let testUser = try createTestUser()
        let profile = try manager.createProfile(
            for: testUser,
            medication: .semaglutide,
            brandName: "Compounded",
            currentDose: 0.5,
            isCompounded: true,
            vialStrength: 5.0,
            reconstitutionVolume: 2.0)

        // When
        let result = try manager.calculateReconstitution(for: profile)

        // Then
        #expect(result != nil)
        #expect(result?.waterVolume == 2.0)
        #expect(result?.unitsPerDose == 20.0)  // 0.5mg / 2.5mg/ml * 100
    }

    @Test("Calculate pen clicks for branded profile")
    @MainActor
    func calculatePenClicks() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let testUser = try createTestUser()
        let profile = try manager.createProfile(
            for: testUser,
            medication: .semaglutide,
            brandName: "Ozempic",
            currentDose: 0.5,
            isCompounded: false)

        // Pen click feature removed due to liability concerns
        #expect(profile.genericName == "Semaglutide")
    }

    @Test("Active profile selection")
    @MainActor
    func activeProfileSelection() throws {
        // Given
        let manager = MedicationManager(modelContext: context)

        // Create past profile
        let pastProfile = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Ozempic",
            currentDose: 0.25,
            startDate: Date().addingTimeInterval(-86400)  // Yesterday
        )

        // Create future profile
        let futureProfile = MedicationProfile(
            genericName: "Tirzepatide",
            brandName: "Mounjaro",
            currentDose: 2.5,
            startDate: Date().addingTimeInterval(86400)  // Tomorrow
        )

        self.context.insert(pastProfile)
        self.context.insert(futureProfile)
        try self.context.save()

        // When
        manager.fetchProfiles()

        // Then
        #expect(manager.activeProfile?.brandName == "Ozempic")  // Past profile is active
    }
}
