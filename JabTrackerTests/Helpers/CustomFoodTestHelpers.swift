//
//  CustomFoodTestHelpers.swift
//  JabTrackerTests
//
//  Shared test helpers for custom food testing.
//

import Foundation
import SwiftData

@testable import JabTracker

/// Isolated in-memory SwiftData stores so parallel Swift Testing workers
/// do not share one default configuration and crash with SIGTRAP.
enum InMemoryTestStore {
    static func configuration(schema: Schema? = nil) -> ModelConfiguration {
        ModelConfiguration(
            "test-\(UUID().uuidString)",
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
    }
}

/// Shared helpers for custom food tests
enum CustomFoodTestHelpers {

    /// Create an in-memory SwiftData context for testing
    /// - Returns: Tuple of context and container (container must be kept alive)
    @MainActor
    static func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([
            User.self,
            Dose.self,
            MedicationProfile.self,
            DoseTitration.self,
            DoseSchedule.self,
            ScheduledDose.self,
            Food.self,
            FoodEntry.self,
            FoodSchedule.self,
        ])
        let configuration = InMemoryTestStore.configuration(schema: schema)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        return (ModelContext(container), container)
    }

    /// Create a CustomFoodInput with sensible defaults
    static func makeInput(
        name: String = "Test Food",
        brand: String = "",
        caloriesPer100g: Double = 100,
        proteinPer100g: Double = 10,
        carbsPer100g: Double = 10,
        fatPer100g: Double = 5,
        fiberPer100g: Double = 0,
        servingSize: Double = 100,
        servingUnit: String = "g",
        servingDescription: String = "",
        barcode: String = ""
    ) -> CustomFoodInput {
        CustomFoodInput(
            name: name,
            brand: brand,
            caloriesPer100g: caloriesPer100g,
            proteinPer100g: proteinPer100g,
            carbsPer100g: carbsPer100g,
            fatPer100g: fatPer100g,
            fiberPer100g: fiberPer100g,
            servingSize: servingSize,
            servingUnit: servingUnit,
            servingDescription: servingDescription,
            barcode: barcode
        )
    }
}
