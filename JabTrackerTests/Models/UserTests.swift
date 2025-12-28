//
//  UserTests.swift
//  JabTrackerTests
//
//  Tests for User SwiftData model - height, gender, and age properties
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

// MARK: - Test Utilities

/// Creates an in-memory SwiftData context for testing
/// Returns both context and container - container must be kept alive for context to remain valid
@MainActor
private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
    let schema = Schema([
        User.self,
        Dose.self,
        MedicationProfile.self,
        DoseTitration.self,
        DoseSchedule.self,
        ScheduledDose.self,
        Food.self,
        FoodEntry.self,
        WeightEntry.self,
        MetricsEntry.self,
        ProgressPhoto.self,
        NutritionGoal.self,
        NutritionProgram.self,
    ])
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
    )
    let container = try! ModelContainer(for: schema, configurations: [config])
    return (container.mainContext, container)
}

// MARK: - UserTests - Height, Gender, Age Properties

@Suite("User Height, Gender, and Age Tests")
struct UserHeightGenderAgeTests {

    // MARK: - Height Property Tests

    @Test("heightCm property exists and defaults to nil")
    @MainActor
    func testHeightCmDefaultsToNil() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let user = User()
        context.insert(user)
        try context.save()

        // Then
        #expect(user.heightCm == nil)
    }

    @Test("heightCm can be set and persisted")
    @MainActor
    func testHeightCmPersists() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let user = User()
        user.heightCm = 180.0
        context.insert(user)
        try context.save()

        // Then
        let fetched = try context.fetch(FetchDescriptor<User>()).first
        #expect(fetched?.heightCm == 180.0)
    }

    @Test("heightCm can be initialized via constructor")
    @MainActor
    func testHeightCmInitialization() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let user = User(heightCm: 165.5)
        context.insert(user)
        try context.save()

        // Then
        #expect(user.heightCm == 165.5)
    }

    // MARK: - Gender Property Tests

    @Test("gender property exists and defaults to empty string")
    @MainActor
    func testGenderDefaultsToEmptyString() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let user = User()
        context.insert(user)
        try context.save()

        // Then
        #expect(user.gender == "")
    }

    @Test("gender can be set and persisted")
    @MainActor
    func testGenderPersists() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let user = User()
        user.gender = "male"
        context.insert(user)
        try context.save()

        // Then
        let fetched = try context.fetch(FetchDescriptor<User>()).first
        #expect(fetched?.gender == "male")
    }

    @Test("gender can be initialized via constructor")
    @MainActor
    func testGenderInitialization() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let user = User(gender: "female")
        context.insert(user)
        try context.save()

        // Then
        #expect(user.gender == "female")
    }

    // MARK: - Age Computed Property Tests

    @Test("age returns nil when dateOfBirth is nil")
    @MainActor
    func testAgeReturnsNilWhenNoBirthDate() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let user = User()
        user.dateOfBirth = nil
        context.insert(user)

        // Then
        #expect(user.age == nil)
    }

    @Test("age calculates correctly from dateOfBirth")
    @MainActor
    func testAgeCalculatesCorrectly() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current
        // Set birth date to exactly 30 years ago
        let thirtyYearsAgo = calendar.date(byAdding: .year, value: -30, to: Date())!

        // When
        let user = User()
        user.dateOfBirth = thirtyYearsAgo
        context.insert(user)

        // Then
        #expect(user.age == 30)
    }

    @Test("age calculates correctly for different ages")
    @MainActor
    func testAgeCalculationsForDifferentAges() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current

        // Test 25 years old
        let user25 = User()
        user25.dateOfBirth = calendar.date(byAdding: .year, value: -25, to: Date())!
        context.insert(user25)
        #expect(user25.age == 25)

        // Test 50 years old
        let user50 = User()
        user50.dateOfBirth = calendar.date(byAdding: .year, value: -50, to: Date())!
        context.insert(user50)
        #expect(user50.age == 50)

        // Test 18 years old
        let user18 = User()
        user18.dateOfBirth = calendar.date(byAdding: .year, value: -18, to: Date())!
        context.insert(user18)
        #expect(user18.age == 18)
    }

    @Test("age handles birthday not yet occurred this year")
    @MainActor
    func testAgeHandlesBirthdayNotYetOccurred() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current
        // Set birth date to 30 years ago plus 1 day (birthday hasn't happened yet)
        var thirtyYearsAgo = calendar.date(byAdding: .year, value: -30, to: Date())!
        thirtyYearsAgo = calendar.date(byAdding: .day, value: 1, to: thirtyYearsAgo)!

        // When
        let user = User()
        user.dateOfBirth = thirtyYearsAgo
        context.insert(user)

        // Then - should be 29, not 30, since birthday hasn't occurred yet
        #expect(user.age == 29)
    }

    // MARK: - Combined Initialization Tests

    @Test("User can be initialized with all new TDEE-related fields")
    @MainActor
    func testFullTDEEFieldsInitialization() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .year, value: -35, to: Date())!

        // When
        let user = User(
            dateOfBirth: birthDate,
            heightCm: 175.0,
            gender: "male"
        )
        context.insert(user)
        try context.save()

        // Then
        #expect(user.heightCm == 175.0)
        #expect(user.gender == "male")
        #expect(user.age == 35)
    }
}
