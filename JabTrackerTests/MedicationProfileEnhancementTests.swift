//
//  MedicationProfileEnhancementTests.swift
//  JabTrackerTests
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("MedicationProfile Enhancement Tests")
struct MedicationProfileEnhancementTests {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        self.container = try ModelContainer(
            for: User.self, MedicationProfile.self, Dose.self,
            configurations: config)
        self.context = ModelContext(self.container)
    }

    @Test("MedicationProfile has all new fields")
    func newFieldsExist() {
        // Given
        let profile = MedicationProfile()

        // Then: Verify all new fields exist with defaults
        #expect(profile.isCompounded == false)
        #expect(profile.vialStrength == nil)
        #expect(profile.reconstitutionVolume == nil)
        // penType field removed
        #expect(profile.notes == "")
        #expect(profile.updatedAt != Date.distantPast)
        #expect(profile.createdAt != Date.distantPast)
    }

    @Test("Create compounded medication profile")
    func createCompoundedProfile() {
        // Given
        let vialStrength = 10.0
        let reconstitutionVolume = 3.0

        // When
        let profile = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Compounded",
            currentDose: 1.0,
            medicationType: Medication.semaglutide.rawValue,
            isCompounded: true,
            vialStrength: vialStrength,
            reconstitutionVolume: reconstitutionVolume,
            notes: "From specialty pharmacy")

        // Then
        #expect(profile.isCompounded == true)
        #expect(profile.vialStrength == vialStrength)
        #expect(profile.reconstitutionVolume == reconstitutionVolume)
        // penType field removed
        #expect(profile.notes == "From specialty pharmacy")
    }

    @Test("Create branded medication profile")
    func createBrandedProfile() {
        // Given
        // penType parameter removed

        // When
        let profile = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Ozempic",
            currentDose: 0.5,
            medicationType: Medication.semaglutide.rawValue,
            isCompounded: false,
            notes: "Insurance covered")

        // Then
        #expect(profile.isCompounded == false)
        #expect(profile.vialStrength == nil)
        #expect(profile.reconstitutionVolume == nil)
        // penType field removed
        #expect(profile.notes == "Insurance covered")
    }

    @Test("MedicationProfile preserves existing fields")
    func existingFieldsPreserved() {
        // Given
        let startDate = Date()
        let refillDate = Date().addingTimeInterval(30 * 86400)

        // When
        let profile = MedicationProfile(
            genericName: "Tirzepatide",
            brandName: "Mounjaro",
            currentDose: 5.0,
            startDate: startDate,
            refillDate: refillDate,
            medicationType: Medication.tirzepatide.rawValue)

        // Then: Verify existing fields still work
        #expect(profile.genericName == "Tirzepatide")
        #expect(profile.brandName == "Mounjaro")
        #expect(profile.currentDose == 5.0)
        #expect(profile.startDate == startDate)
        #expect(profile.refillDate == refillDate)
        #expect(profile.medicationType == Medication.tirzepatide.rawValue)
    }

    @Test("Medication computed property works")
    func medicationComputedProperty() {
        // Given
        let profile = MedicationProfile()

        // When: Set via computed property
        profile.medication = .semaglutide

        // Then
        #expect(profile.medicationType == "semaglutide")
        #expect(profile.medication == .semaglutide)

        // When: Set to nil
        profile.medication = nil

        // Then
        #expect(profile.medicationType == "")
        #expect(profile.medication == nil)
    }

    @Test("Persist and fetch enhanced profile")
    func persistAndFetchEnhancedProfile() throws {
        // Given
        let profile = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Compounded",
            currentDose: 1.0,
            medicationType: Medication.semaglutide.rawValue,
            isCompounded: true,
            vialStrength: 5.0,
            reconstitutionVolume: 2.0,
            notes: "Test notes")

        // When
        self.context.insert(profile)
        try self.context.save()

        // Fetch
        let descriptor = FetchDescriptor<MedicationProfile>()
        let fetched = try context.fetch(descriptor)

        // Then
        #expect(fetched.count == 1)
        let fetchedProfile = fetched.first!
        #expect(fetchedProfile.isCompounded == true)
        #expect(fetchedProfile.vialStrength == 5.0)
        #expect(fetchedProfile.reconstitutionVolume == 2.0)
        #expect(fetchedProfile.notes == "Test notes")
    }

    @Test("Update timestamps on modification")
    func updateTimestamps() async throws {
        // Given
        let profile = MedicationProfile()
        let originalUpdatedAt = profile.updatedAt

        // When: Wait and modify
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
        profile.currentDose = 1.0
        profile.updatedAt = Date()

        // Then
        #expect(profile.updatedAt > originalUpdatedAt)
    }

    @Test("CloudKit compatibility with new fields")
    func cloudKitCompatibility() {
        // Given: All new fields should have default values for CloudKit
        let profile = MedicationProfile()

        // Then: Verify CloudKit-compatible defaults
        #expect(profile.isCompounded == false)  // Bool with default
        #expect(profile.vialStrength == nil)  // Optional is OK
        #expect(profile.reconstitutionVolume == nil)  // Optional is OK
        // penType field removed // Optional is OK
        #expect(profile.notes == "")  // String with default
        #expect(profile.updatedAt != Date.distantPast)  // Date with default
        #expect(profile.createdAt != Date.distantPast)  // Date with default
    }

    @Test("Validation: Compounded profile requires vial data")
    func compoundedValidation() {
        // Given
        let profile = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Compounded",
            currentDose: 1.0,
            isCompounded: true)

        // Then: Should have nil vial data if not provided
        #expect(profile.vialStrength == nil)
        #expect(profile.reconstitutionVolume == nil)

        // When: Add vial data
        profile.vialStrength = 5.0
        profile.reconstitutionVolume = 2.0

        // Then
        #expect(profile.vialStrength == 5.0)
        #expect(profile.reconstitutionVolume == 2.0)
    }

    @Test("Validation: Branded profile uses pen type")
    func brandedValidation() {
        // Given
        let profile = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Ozempic",
            currentDose: 0.5,
            isCompounded: false)

        // Then: Should have nil pen type if not provided
        // penType field removed

        // When: Add pen type
        // penType field removed

        // Then
        // penType field removed
        #expect(profile.vialStrength == nil)  // Should not have vial data
        #expect(profile.reconstitutionVolume == nil)
    }

    @Test("Edge case: Switch from compounded to branded")
    func switchCompoundedToBranded() {
        // Given: Start with compounded
        let profile = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Compounded",
            currentDose: 1.0,
            isCompounded: true,
            vialStrength: 5.0,
            reconstitutionVolume: 2.0)

        // When: Switch to branded
        profile.isCompounded = false
        profile.brandName = "Ozempic"
        // penType field removed
        profile.vialStrength = nil
        profile.reconstitutionVolume = nil

        // Then
        #expect(profile.isCompounded == false)
        // penType field removed
        #expect(profile.vialStrength == nil)
        #expect(profile.reconstitutionVolume == nil)
    }

    @Test("Notes field handles long text")
    func notesFieldLongText() {
        // Given
        let longNotes = String(repeating: "This is a long note. ", count: 100)

        // When
        let profile = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Ozempic",
            currentDose: 0.5,
            notes: longNotes)

        // Then
        #expect(profile.notes == longNotes)
        #expect(profile.notes.count > 2000)
    }
}
