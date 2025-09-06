//
//  MedicationManagerTests.swift
//  JabTrackerTests
//

import Foundation
import Testing
import SwiftData
@testable import JabTracker

@Suite("MedicationManager Tests")
struct MedicationManagerTests {
    
    let container: ModelContainer
    let context: ModelContext
    
    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: User.self, MedicationProfile.self, Dose.self,
            configurations: config
        )
        context = ModelContext(container)
    }
    
    @Test("Create medication profile with valid data")
    @MainActor
    func testCreateValidProfile() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let medication = Medication.semaglutide
        let brandName = "Ozempic"
        let currentDose = 0.5
        
        // When
        let profile = try manager.createProfile(
            medication: medication,
            brandName: brandName,
            currentDose: currentDose,
            isCompounded: false,
            penType: "Ozempic 1mg pen"
        )
        
        // Then
        #expect(profile.genericName == medication.displayName)
        #expect(profile.brandName == brandName)
        #expect(profile.currentDose == currentDose)
        #expect(profile.isCompounded == false)
        #expect(profile.penType == "Ozempic 1mg pen")
        #expect(profile.medicationType == medication.rawValue)
    }
    
    @Test("Create compounded medication profile")
    @MainActor
    func testCreateCompoundedProfile() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let medication = Medication.tirzepatide
        let vialStrength = 10.0
        let reconstitutionVolume = 2.0
        let currentDose = 2.5
        
        // When
        let profile = try manager.createProfile(
            medication: medication,
            brandName: "Compounded",
            currentDose: currentDose,
            isCompounded: true,
            vialStrength: vialStrength,
            reconstitutionVolume: reconstitutionVolume
        )
        
        // Then
        #expect(profile.isCompounded == true)
        #expect(profile.vialStrength == vialStrength)
        #expect(profile.reconstitutionVolume == reconstitutionVolume)
        #expect(profile.currentDose == currentDose)
    }
    
    @Test("Create profile with invalid dose throws error")
    @MainActor
    func testCreateProfileWithInvalidDose() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let medication = Medication.semaglutide
        let invalidDose = 5.0 // Exceeds maximum for semaglutide
        
        // When/Then
        #expect(throws: MedicationManager.MedicationError.doseOutOfRange(medication: medication, currentDose: invalidDose)) {
            try manager.createProfile(
                medication: medication,
                brandName: "Ozempic",
                currentDose: invalidDose
            )
        }
    }
    
    @Test("Create compounded profile with invalid settings throws error")
    @MainActor
    func testCreateCompoundedProfileWithInvalidSettings() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let medication = Medication.semaglutide
        
        // When/Then: Vial strength less than target dose
        #expect(throws: MedicationManager.MedicationError.invalidCompoundingSettings) {
            try manager.createProfile(
                medication: medication,
                brandName: "Compounded",
                currentDose: 2.0,
                isCompounded: true,
                vialStrength: 1.0, // Less than current dose
                reconstitutionVolume: 2.0
            )
        }
    }
    
    @Test("Update medication profile dose")
    @MainActor
    func testUpdateProfileDose() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let profile = try manager.createProfile(
            medication: .semaglutide,
            brandName: "Ozempic",
            currentDose: 0.25
        )
        
        // When
        try manager.updateProfile(profile, currentDose: 0.5)
        
        // Then
        #expect(profile.currentDose == 0.5)
        #expect(profile.updatedAt > profile.createdAt)
    }
    
    @Test("Update profile with invalid dose throws error")
    @MainActor
    func testUpdateProfileWithInvalidDose() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let profile = try manager.createProfile(
            medication: .semaglutide,
            brandName: "Ozempic",
            currentDose: 0.25
        )
        let invalidDose = 10.0
        
        // When/Then
        #expect(throws: MedicationManager.MedicationError.doseOutOfRange(medication: .semaglutide, currentDose: invalidDose)) {
            try manager.updateProfile(profile, currentDose: invalidDose)
        }
    }
    
    @Test("Delete medication profile")
    @MainActor
    func testDeleteProfile() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let profile = try manager.createProfile(
            medication: .semaglutide,
            brandName: "Ozempic",
            currentDose: 0.5
        )
        
        // When
        try manager.deleteProfile(profile)
        
        // Then
        manager.fetchProfiles()
        #expect(manager.profiles.isEmpty)
    }
    
    @Test("Fetch profiles returns sorted by date")
    @MainActor
    func testFetchProfilesSortedByDate() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        
        // Create profiles with different dates
        let profile1 = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Ozempic",
            currentDose: 0.5,
            startDate: Date().addingTimeInterval(-86400) // Yesterday
        )
        let profile2 = MedicationProfile(
            genericName: "Tirzepatide",
            brandName: "Mounjaro",
            currentDose: 2.5,
            startDate: Date() // Today
        )
        
        context.insert(profile1)
        context.insert(profile2)
        try context.save()
        
        // When
        manager.fetchProfiles()
        
        // Then
        #expect(manager.profiles.count == 2)
        #expect(manager.profiles.first?.brandName == "Mounjaro") // Most recent first
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
        let profile = try manager.createProfile(
            medication: .semaglutide,
            brandName: "Ozempic",
            currentDose: 0.25
        )
        
        // When
        let nextDose = manager.nextEscalationDose(for: profile)
        
        // Then
        #expect(nextDose == 0.5)
    }
    
    @Test("Get next escalation dose at maximum returns nil")
    @MainActor
    func testNextEscalationDoseAtMaximum() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let profile = try manager.createProfile(
            medication: .semaglutide,
            brandName: "Ozempic",
            currentDose: 2.4 // Maximum dose
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
        let futureDate = Date().addingTimeInterval(7 * 86400) // 7 days from now
        let profile = try manager.createProfile(
            medication: .semaglutide,
            brandName: "Ozempic",
            currentDose: 0.5
        )
        
        // When
        try manager.updateProfile(profile, refillDate: futureDate)
        let days = manager.daysUntilRefill(for: profile)
        
        // Then
        #expect(days != nil)
        #expect(days! >= 6 && days! <= 7) // Account for test execution time
    }
    
    @Test("Calculate reconstitution for compounded profile")
    @MainActor
    func testCalculateReconstitution() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let profile = try manager.createProfile(
            medication: .semaglutide,
            brandName: "Compounded",
            currentDose: 0.5,
            isCompounded: true,
            vialStrength: 5.0,
            reconstitutionVolume: 2.0
        )
        
        // When
        let result = try manager.calculateReconstitution(for: profile)
        
        // Then
        #expect(result != nil)
        #expect(result?.waterVolume == 2.0)
        #expect(result?.unitsPerDose == 20.0) // 0.5mg / 2.5mg/ml * 100
    }
    
    @Test("Calculate pen clicks for branded profile")
    @MainActor
    func testCalculatePenClicks() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        let profile = try manager.createProfile(
            medication: .semaglutide,
            brandName: "Ozempic",
            currentDose: 0.5,
            isCompounded: false,
            penType: PenClickCalculator.PenType.ozempic1mg.rawValue
        )
        
        // When
        let result = try manager.calculatePenClicks(for: profile)
        
        // Then
        #expect(result != nil)
        #expect(result?.clicks == 50) // 0.5mg / 0.01mg per click
        #expect(result?.actualDose == 0.5)
    }
    
    @Test("Active profile selection")
    @MainActor
    func testActiveProfileSelection() throws {
        // Given
        let manager = MedicationManager(modelContext: context)
        
        // Create past profile
        let pastProfile = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Ozempic",
            currentDose: 0.25,
            startDate: Date().addingTimeInterval(-86400) // Yesterday
        )
        
        // Create future profile
        let futureProfile = MedicationProfile(
            genericName: "Tirzepatide",
            brandName: "Mounjaro",
            currentDose: 2.5,
            startDate: Date().addingTimeInterval(86400) // Tomorrow
        )
        
        context.insert(pastProfile)
        context.insert(futureProfile)
        try context.save()
        
        // When
        manager.fetchProfiles()
        
        // Then
        #expect(manager.activeProfile?.brandName == "Ozempic") // Past profile is active
    }
}
