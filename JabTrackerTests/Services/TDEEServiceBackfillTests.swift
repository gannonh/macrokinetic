//
//  TDEEServiceBackfillTests.swift
//  JabTrackerTests
//
//  Unit tests for TDEEService daily snapshot backfill functionality.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

// MARK: - Test Helpers

/// Create an in-memory model container for testing
private func createTestContainer() throws -> ModelContainer {
    let schema = Schema([
        User.self,
        NutritionGoal.self,
        NutritionProgram.self,
        TDEESnapshot.self,
        FoodEntry.self,
        Food.self,
        WeightEntry.self,
    ])
    let configuration = InMemoryTestStore.configuration()
    return try ModelContainer(for: schema, configurations: configuration)
}

/// Create a test user with nutrition goal
@MainActor
private func createTestUserWithGoal(in context: ModelContext) -> (user: User, goal: NutritionGoal) {
    let user = User(
        email: "test@example.com",
        name: "Test User",
        weight: 70.0,
        weightUnit: "kg",
        timezone: "UTC"
    )
    context.insert(user)

    let goal = NutritionGoal()
    goal.initialEstimatedTDEE = 2200.0
    goal.lastCalculatedTDEE = 2200.0
    goal.isActive = true
    goal.createdAt = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    goal.user = user  // Set relationship from child side
    context.insert(goal)

    return (user, goal)
}

/// Create food entries for a specific date
@MainActor
private func createFoodEntry(in context: ModelContext, on date: Date) {
    let entry = FoodEntry(
        foodName: "Test Food",
        mealSection: .breakfast,
        loggedAt: date,
        servingGrams: 100,
        caloriesPer100g: 500,
        proteinPer100g: 20,
        carbsPer100g: 50,
        fatPer100g: 15
    )
    context.insert(entry)
}

/// Create weight entry for a specific date
@MainActor
private func createWeightEntry(in context: ModelContext, on date: Date, weightKg: Double = 70.0) {
    let entry = WeightEntry(timestamp: date, weightKg: weightKg)
    context.insert(entry)
}

// MARK: - Data Sufficiency Tests

@Suite("TDEEService Data Sufficiency Check")
struct TDEEServiceDataSufficiencyTests {

    @Test("hasSufficientData returns false when no food entries")
    @MainActor
    func noFoodEntriesReturnsFalse() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let service = TDEEService(context: context)
        let result = service.hasSufficientData(asOf: Date())

        #expect(result == false)
    }

    @Test("hasSufficientData returns false when less than 3 food days")
    @MainActor
    func insufficientFoodDaysReturnsFalse() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let today = Date()
        let calendar = Calendar.current

        // Create 2 days of food (below threshold of 3)
        createFoodEntry(in: context, on: calendar.date(byAdding: .day, value: -1, to: today)!)
        createFoodEntry(in: context, on: calendar.date(byAdding: .day, value: -2, to: today)!)

        // Create 1 weight entry (meets threshold)
        createWeightEntry(in: context, on: calendar.date(byAdding: .day, value: -1, to: today)!)

        try context.save()

        let service = TDEEService(context: context)
        let result = service.hasSufficientData(asOf: today)

        #expect(result == false)
    }

    @Test("hasSufficientData returns false when no weight entries")
    @MainActor
    func noWeightEntriesReturnsFalse() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let today = Date()
        let calendar = Calendar.current

        // Create 4 days of food (meets threshold)
        for dayOffset in 1...4 {
            createFoodEntry(in: context, on: calendar.date(byAdding: .day, value: -dayOffset, to: today)!)
        }
        // No weight entries

        try context.save()

        let service = TDEEService(context: context)
        let result = service.hasSufficientData(asOf: today)

        #expect(result == false)
    }

    @Test("hasSufficientData returns true when 3+ food days and 1+ weight days")
    @MainActor
    func sufficientDataReturnsTrue() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let today = Date()
        let calendar = Calendar.current

        // Create 4 days of food (meets threshold)
        for dayOffset in 1...4 {
            createFoodEntry(in: context, on: calendar.date(byAdding: .day, value: -dayOffset, to: today)!)
        }

        // Create 2 weight entries (meets threshold)
        createWeightEntry(in: context, on: calendar.date(byAdding: .day, value: -1, to: today)!)
        createWeightEntry(in: context, on: calendar.date(byAdding: .day, value: -3, to: today)!)

        try context.save()

        let service = TDEEService(context: context)
        let result = service.hasSufficientData(asOf: today)

        #expect(result == true)
    }

    @Test("hasSufficientData only counts data within 7-day window")
    @MainActor
    func onlyCountsDataWithin7DayWindow() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let today = Date()
        let calendar = Calendar.current

        // Create food entries outside 7-day window (8-11 days ago)
        for dayOffset in 8...11 {
            createFoodEntry(in: context, on: calendar.date(byAdding: .day, value: -dayOffset, to: today)!)
        }

        // Create only 1 food entry within window
        createFoodEntry(in: context, on: calendar.date(byAdding: .day, value: -1, to: today)!)

        // Create weight entry within window
        createWeightEntry(in: context, on: calendar.date(byAdding: .day, value: -1, to: today)!)

        try context.save()

        let service = TDEEService(context: context)
        let result = service.hasSufficientData(asOf: today)

        // Should be false because only 1 food day within window
        #expect(result == false)
    }
}

// MARK: - Snapshot Helper Tests

@Suite("TDEEService Snapshot Helpers")
struct TDEEServiceSnapshotHelperTests {

    @Test("getLastSnapshotDate returns nil when no snapshots")
    @MainActor
    func noSnapshotsReturnsNil() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let service = TDEEService(context: context)
        let result = try service.getLastSnapshotDate()

        #expect(result == nil)
    }

    @Test("getLastSnapshotDate returns most recent date")
    @MainActor
    func returnsMostRecentDate() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        // Insert snapshots out of order
        let oldSnapshot = TDEESnapshot(timestamp: twoDaysAgo, tdeeValue: 2100, source: .adaptive)
        context.insert(oldSnapshot)

        let newSnapshot = TDEESnapshot(timestamp: yesterday, tdeeValue: 2150, source: .adaptive)
        context.insert(newSnapshot)

        try context.save()

        let service = TDEEService(context: context)
        let result = try service.getLastSnapshotDate()

        #expect(result != nil)
        // Compare day components since we're using startOfDay
        let resultDay = calendar.startOfDay(for: result!)
        #expect(resultDay == yesterday)
    }

    @Test("getLastTDEEValue returns most recent value")
    @MainActor
    func returnsMostRecentValue() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        let oldSnapshot = TDEESnapshot(timestamp: twoDaysAgo, tdeeValue: 2100, source: .adaptive)
        context.insert(oldSnapshot)

        let newSnapshot = TDEESnapshot(timestamp: yesterday, tdeeValue: 2150, source: .adaptive)
        context.insert(newSnapshot)

        try context.save()

        let service = TDEEService(context: context)
        let result = try service.getLastTDEEValue()

        #expect(result == 2150)
    }

    @Test("getLastConfidence returns most recent confidence")
    @MainActor
    func returnsMostRecentConfidence() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let snapshot = TDEESnapshot(timestamp: yesterday, tdeeValue: 2150, confidence: 0.85, source: .adaptive)
        context.insert(snapshot)

        try context.save()

        let service = TDEEService(context: context)
        let result = try service.getLastConfidence()

        #expect(result == 0.85)
    }
}

// MARK: - Backfill Tests

@Suite("TDEEService Daily Snapshot Backfill")
struct TDEEServiceBackfillTests {

    @Test("ensureDailySnapshots creates no snapshots if already up to date")
    @MainActor
    func noSnapshotsIfUpToDate() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let (_, goal) = createTestUserWithGoal(in: context)

        // Create snapshot for today
        let today = Calendar.current.startOfDay(for: Date())
        let todaySnapshot = TDEESnapshot(timestamp: today, tdeeValue: 2200, source: .adaptive)
        context.insert(todaySnapshot)

        try context.save()

        let initialCount = try context.fetchCount(FetchDescriptor<TDEESnapshot>())

        let service = TDEEService(context: context)
        try await service.ensureDailySnapshots(for: goal)

        let finalCount = try context.fetchCount(FetchDescriptor<TDEESnapshot>())

        // No new snapshots should be created
        #expect(finalCount == initialCount)
    }

    @Test("ensureDailySnapshots creates holding snapshot when insufficient data")
    @MainActor
    func createsHoldingSnapshotWhenInsufficientData() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let (_, goal) = createTestUserWithGoal(in: context)

        // Create snapshot for yesterday (so we need to create today's)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let yesterdaySnapshot = TDEESnapshot(timestamp: yesterday, tdeeValue: 2200, confidence: 0.8, source: .adaptive)
        context.insert(yesterdaySnapshot)

        // No food or weight data - insufficient for adaptive calculation

        try context.save()

        let service = TDEEService(context: context)
        try await service.ensureDailySnapshots(for: goal)

        // Find today's snapshot
        let descriptor = FetchDescriptor<TDEESnapshot>(
            predicate: #Predicate { snapshot in
                snapshot.timestamp >= today
            }
        )
        let todaySnapshots = try context.fetch(descriptor)

        #expect(todaySnapshots.count == 1)
        #expect(todaySnapshots.first?.sourceType == .holding)
        #expect(todaySnapshots.first?.tdeeValue == 2200)  // Carried forward
    }

    @Test("ensureDailySnapshots backfills multiple days correctly")
    @MainActor
    func backfillsMultipleDays() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let (_, goal) = createTestUserWithGoal(in: context)

        // Create snapshot for 5 days ago
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today)!

        let oldSnapshot = TDEESnapshot(timestamp: fiveDaysAgo, tdeeValue: 2200, confidence: 0.8, source: .adaptive)
        context.insert(oldSnapshot)

        try context.save()

        let service = TDEEService(context: context)
        try await service.ensureDailySnapshots(for: goal)

        // Should have created 5 new snapshots (for days -4, -3, -2, -1, 0)
        let allSnapshots = try context.fetch(FetchDescriptor<TDEESnapshot>())
        #expect(allSnapshots.count == 6)  // 1 original + 5 new
    }

    @Test("Confidence decays for consecutive holding snapshots")
    @MainActor
    func confidenceDecaysForHoldingSnapshots() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let (_, goal) = createTestUserWithGoal(in: context)

        // Create snapshot for 3 days ago with high confidence
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!

        let oldSnapshot = TDEESnapshot(timestamp: threeDaysAgo, tdeeValue: 2200, confidence: 1.0, source: .adaptive)
        context.insert(oldSnapshot)

        // No food/weight data - all will be holding snapshots

        try context.save()

        let service = TDEEService(context: context)
        try await service.ensureDailySnapshots(for: goal)

        // Get snapshots sorted by date
        var descriptor = FetchDescriptor<TDEESnapshot>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        let snapshots = try context.fetch(descriptor)

        // Verify confidence decreases
        var previousConfidence = 1.0
        for (index, snapshot) in snapshots.enumerated() {
            if index > 0 {  // Skip original snapshot
                #expect(snapshot.confidence < previousConfidence)
                #expect(snapshot.confidence >= 0.3)  // Minimum floor
            }
            previousConfidence = snapshot.confidence
        }
    }

    @Test("saveTDEESnapshot accepts custom timestamp")
    @MainActor
    func saveTDEESnapshotWithCustomTimestamp() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        let service = TDEEService(context: context)
        try service.saveTDEESnapshot(
            tdee: 2300,
            confidence: 0.75,
            source: .holding,
            timestamp: yesterday
        )

        let snapshots = try context.fetch(FetchDescriptor<TDEESnapshot>())
        #expect(snapshots.count == 1)
        #expect(snapshots.first?.tdeeValue == 2300)
        #expect(snapshots.first?.sourceType == .holding)

        // Verify timestamp is yesterday (compare day components)
        let snapshotDay = calendar.startOfDay(for: snapshots.first!.timestamp)
        let expectedDay = calendar.startOfDay(for: yesterday)
        #expect(snapshotDay == expectedDay)
    }
}
