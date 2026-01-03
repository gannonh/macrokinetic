//
//  UserPropertiesTests.swift
//  JabTrackerTests
//
//  Tests for User SwiftData model - active energy preference properties
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

// MARK: - User Active Energy Properties Tests

@Suite("User Active Energy Properties Tests")
struct UserPropertiesTests {

    // MARK: - Default Values Tests

    @Test("Active Energy properties have correct default values")
    @MainActor
    func testDefaultValues() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let user = User()
        context.insert(user)
        try context.save()

        // Then
        #expect(user.addBurnedCaloriesEnabled == false)
        #expect(user.rolloverCaloriesEnabled == false)
        #expect(user.predictiveActivityEnabled == false)
        #expect(user.predictedActivityBonus == 0.0)
    }

    // MARK: - Initialization Tests

    @Test("Active Energy properties can be initialized via constructor")
    @MainActor
    func testInitialization() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let user = User(
            addBurnedCaloriesEnabled: true,
            rolloverCaloriesEnabled: true,
            predictiveActivityEnabled: true,
            predictedActivityBonus: 250.5
        )
        context.insert(user)
        try context.save()

        // Then
        #expect(user.addBurnedCaloriesEnabled == true)
        #expect(user.rolloverCaloriesEnabled == true)
        #expect(user.predictiveActivityEnabled == true)
        #expect(user.predictedActivityBonus == 250.5)
    }

    // MARK: - Persistence Tests

    @Test("Active Energy properties can be modified and persisted")
    @MainActor
    func testPersistence() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = User()
        context.insert(user)
        try context.save()

        // When
        user.addBurnedCaloriesEnabled = true
        user.rolloverCaloriesEnabled = true
        user.predictiveActivityEnabled = true
        user.predictedActivityBonus = 100.0
        try context.save()

        // Then
        let fetched = try context.fetch(FetchDescriptor<User>()).first
        #expect(fetched?.addBurnedCaloriesEnabled == true)
        #expect(fetched?.rolloverCaloriesEnabled == true)
        #expect(fetched?.predictiveActivityEnabled == true)
        #expect(fetched?.predictedActivityBonus == 100.0)
    }
}
