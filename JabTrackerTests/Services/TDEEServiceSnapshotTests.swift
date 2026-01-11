//
//  TDEEServiceSnapshotTests.swift
//  JabTrackerTests
//
//  Unit tests for TDEEService snapshot saving functionality.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

// MARK: - Test Fixtures

@MainActor
private struct TDEEServiceSnapshotTestFixture {
    let container: ModelContainer
    let context: ModelContext
    let service: TDEEService

    init() throws {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        container = try ModelContainer(
            for: User.self, NutritionGoal.self, NutritionProgram.self,
            WeightEntry.self, FoodEntry.self, TDEESnapshot.self,
            configurations: configuration
        )
        context = ModelContext(container)
        service = TDEEService(context: context)
    }

    func fetchSnapshots() throws -> [TDEESnapshot] {
        let descriptor = FetchDescriptor<TDEESnapshot>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return try context.fetch(descriptor)
    }
}

// MARK: - Save Snapshot Tests

@Suite("TDEEService Snapshot Saving")
struct TDEEServiceSnapshotSavingTests {

    @Test("saveTDEESnapshot creates snapshot with correct values")
    @MainActor
    func saveTDEESnapshotCreatesCorrectSnapshot() async throws {
        let fixture = try TDEEServiceSnapshotTestFixture()

        try fixture.service.saveTDEESnapshot(
            tdee: 2500.0,
            confidence: 0.85,
            source: .adaptive
        )

        let snapshots = try fixture.fetchSnapshots()
        #expect(snapshots.count == 1)
        #expect(snapshots.first?.tdeeValue == 2500.0)
        #expect(snapshots.first?.confidence == 0.85)
        #expect(snapshots.first?.sourceType == .adaptive)
    }

    @Test("saveTDEESnapshot saves initial source type correctly")
    @MainActor
    func saveTDEESnapshotInitialSourceType() async throws {
        let fixture = try TDEEServiceSnapshotTestFixture()

        try fixture.service.saveTDEESnapshot(
            tdee: 2000.0,
            confidence: 1.0,
            source: .initial
        )

        let snapshots = try fixture.fetchSnapshots()
        #expect(snapshots.first?.sourceType == .initial)
    }

    @Test("saveTDEESnapshot saves manual source type correctly")
    @MainActor
    func saveTDEESnapshotManualSourceType() async throws {
        let fixture = try TDEEServiceSnapshotTestFixture()

        try fixture.service.saveTDEESnapshot(
            tdee: 2200.0,
            confidence: 0.7,
            source: .manual
        )

        let snapshots = try fixture.fetchSnapshots()
        #expect(snapshots.first?.sourceType == .manual)
    }

    @Test("multiple saveTDEESnapshot calls create multiple snapshots")
    @MainActor
    func multipleSaveTDEESnapshotCalls() async throws {
        let fixture = try TDEEServiceSnapshotTestFixture()

        try fixture.service.saveTDEESnapshot(tdee: 2000.0, confidence: 1.0, source: .initial)
        try fixture.service.saveTDEESnapshot(tdee: 2100.0, confidence: 0.8, source: .adaptive)
        try fixture.service.saveTDEESnapshot(tdee: 2050.0, confidence: 0.9, source: .adaptive)

        let snapshots = try fixture.fetchSnapshots()
        #expect(snapshots.count == 3)
    }
}

// MARK: - Query Snapshot Tests

@Suite("TDEEService Snapshot Queries")
struct TDEEServiceSnapshotQueryTests {

    @Test("getTDEESnapshots returns snapshots in date range")
    @MainActor
    func getTDEESnapshotsReturnsInRange() async throws {
        let fixture = try TDEEServiceSnapshotTestFixture()
        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: now)!

        // Create snapshots at different times
        let oldSnapshot = TDEESnapshot(timestamp: twoWeeksAgo, tdeeValue: 1900.0)
        let midSnapshot = TDEESnapshot(timestamp: oneWeekAgo, tdeeValue: 2000.0)
        let newSnapshot = TDEESnapshot(timestamp: now, tdeeValue: 2100.0)

        fixture.context.insert(oldSnapshot)
        fixture.context.insert(midSnapshot)
        fixture.context.insert(newSnapshot)
        try fixture.context.save()

        // Query for last 10 days (should get 2 snapshots)
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: now)!
        let results = try fixture.service.getTDEESnapshots(from: tenDaysAgo, to: now)

        #expect(results.count == 2)
        #expect(results.first?.tdeeValue == 2000.0)  // midSnapshot (sorted by date ascending)
        #expect(results.last?.tdeeValue == 2100.0)  // newSnapshot
    }

    @Test("getTDEESnapshots returns empty array when no snapshots exist")
    @MainActor
    func getTDEESnapshotsReturnsEmptyWhenNoData() async throws {
        let fixture = try TDEEServiceSnapshotTestFixture()
        let now = Date()
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!

        let results = try fixture.service.getTDEESnapshots(from: oneMonthAgo, to: now)

        #expect(results.isEmpty)
    }

    @Test("getTDEESnapshots excludes snapshots outside date range")
    @MainActor
    func getTDEESnapshotsExcludesOutsideRange() async throws {
        let fixture = try TDEEServiceSnapshotTestFixture()
        let now = Date()
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: now)!

        // Create snapshot outside query range
        let oldSnapshot = TDEESnapshot(timestamp: twoMonthsAgo, tdeeValue: 1800.0)
        fixture.context.insert(oldSnapshot)
        try fixture.context.save()

        // Query for last 7 days only
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let results = try fixture.service.getTDEESnapshots(from: oneWeekAgo, to: now)

        #expect(results.isEmpty)
    }

    @Test("getTDEESnapshots returns results sorted by timestamp ascending")
    @MainActor
    func getTDEESnapshotsSortedByTimestamp() async throws {
        let fixture = try TDEEServiceSnapshotTestFixture()
        let now = Date()

        // Create snapshots in non-chronological order
        let day3 = Calendar.current.date(byAdding: .day, value: -3, to: now)!
        let day1 = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let day5 = Calendar.current.date(byAdding: .day, value: -5, to: now)!

        fixture.context.insert(TDEESnapshot(timestamp: day3, tdeeValue: 2000.0))
        fixture.context.insert(TDEESnapshot(timestamp: day1, tdeeValue: 2100.0))
        fixture.context.insert(TDEESnapshot(timestamp: day5, tdeeValue: 1900.0))
        try fixture.context.save()

        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let results = try fixture.service.getTDEESnapshots(from: oneWeekAgo, to: now)

        #expect(results.count == 3)
        #expect(results[0].tdeeValue == 1900.0)  // day5 (oldest)
        #expect(results[1].tdeeValue == 2000.0)  // day3 (middle)
        #expect(results[2].tdeeValue == 2100.0)  // day1 (newest)
    }
}
