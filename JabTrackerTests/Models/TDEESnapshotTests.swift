//
//  TDEESnapshotTests.swift
//  JabTrackerTests
//
//  Unit tests for TDEESnapshot model.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

// MARK: - Test Helpers

/// Create an in-memory model container for testing
private func createTestContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(
        for: TDEESnapshot.self,
        configurations: configuration
    )
}

// MARK: - Initialization Tests

@Suite("TDEESnapshot Initialization")
struct TDEESnapshotInitializationTests {

    @Test("Default initialization creates valid snapshot")
    func defaultInitialization() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let snapshot = TDEESnapshot()
        context.insert(snapshot)

        #expect(snapshot.id != UUID())
        #expect(snapshot.tdeeValue == 2000.0)
        #expect(snapshot.confidence == 0.5)
        #expect(snapshot.source == "initial")
        #expect(snapshot.timestamp <= Date())
        #expect(snapshot.createdAt <= Date())
    }

    @Test("Custom initialization sets all values correctly")
    func customInitialization() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let customDate = Date(timeIntervalSinceNow: -86400)  // Yesterday
        let snapshot = TDEESnapshot(
            timestamp: customDate,
            tdeeValue: 2500.0,
            confidence: 0.95,
            source: .adaptive
        )
        context.insert(snapshot)

        #expect(snapshot.tdeeValue == 2500.0)
        #expect(snapshot.confidence == 0.95)
        #expect(snapshot.source == TDEESourceType.adaptive.rawValue)
        #expect(snapshot.timestamp == customDate)
    }
}

// MARK: - Computed Property Tests

@Suite("TDEESnapshot Computed Properties")
struct TDEESnapshotComputedPropertyTests {

    @Test("sourceType returns correct enum value")
    func sourceTypeEnumAccessor() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let initialSnapshot = TDEESnapshot(source: .initial)
        context.insert(initialSnapshot)
        #expect(initialSnapshot.sourceType == .initial)

        let adaptiveSnapshot = TDEESnapshot(source: .adaptive)
        context.insert(adaptiveSnapshot)
        #expect(adaptiveSnapshot.sourceType == .adaptive)

        let manualSnapshot = TDEESnapshot(source: .manual)
        context.insert(manualSnapshot)
        #expect(manualSnapshot.sourceType == .manual)
    }

    @Test("status returns holding for recent snapshots (< 14 days)")
    func statusReturnsHoldingForRecent() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        // Snapshot from 5 days ago
        let recentDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let snapshot = TDEESnapshot(timestamp: recentDate)
        context.insert(snapshot)

        #expect(snapshot.status == .holding)
    }

    @Test("status returns updating for medium-age snapshots (14-60 days)")
    func statusReturnsUpdatingForMediumAge() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        // Snapshot from 30 days ago
        let mediumDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let snapshot = TDEESnapshot(timestamp: mediumDate)
        context.insert(snapshot)

        #expect(snapshot.status == .updating)
    }

    @Test("status returns fluxRange for old snapshots (> 60 days)")
    func statusReturnsFluxRangeForOld() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        // Snapshot from 90 days ago
        let oldDate = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        let snapshot = TDEESnapshot(timestamp: oldDate)
        context.insert(snapshot)

        #expect(snapshot.status == .fluxRange)
    }

    @Test("fluxMargin is tight for high confidence")
    func fluxMarginTightForHighConfidence() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let snapshot = TDEESnapshot(confidence: 0.95)
        context.insert(snapshot)

        // High confidence should give tighter margin (around 15)
        #expect(snapshot.fluxMargin <= 20)
        #expect(snapshot.fluxMargin >= 10)
    }

    @Test("fluxMargin is wide for low confidence")
    func fluxMarginWideForLowConfidence() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let snapshot = TDEESnapshot(confidence: 0.3)
        context.insert(snapshot)

        // Low confidence should give wider margin (around 35-40)
        #expect(snapshot.fluxMargin >= 30)
        #expect(snapshot.fluxMargin <= 50)
    }

    @Test("fluxMargin is moderate for medium confidence")
    func fluxMarginModerateForMediumConfidence() throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let snapshot = TDEESnapshot(confidence: 0.5)
        context.insert(snapshot)

        // Medium confidence should give moderate margin
        #expect(snapshot.fluxMargin >= 20)
        #expect(snapshot.fluxMargin <= 35)
    }
}

// MARK: - Source Type Enum Tests

@Suite("TDEESourceType Enum")
struct TDEESourceTypeTests {

    @Test("rawValue matches expected strings")
    func rawValueStrings() {
        #expect(TDEESourceType.initial.rawValue == "initial")
        #expect(TDEESourceType.adaptive.rawValue == "adaptive")
        #expect(TDEESourceType.manual.rawValue == "manual")
    }

    @Test("init from rawValue works correctly")
    func initFromRawValue() {
        #expect(TDEESourceType(rawValue: "initial") == .initial)
        #expect(TDEESourceType(rawValue: "adaptive") == .adaptive)
        #expect(TDEESourceType(rawValue: "manual") == .manual)
        #expect(TDEESourceType(rawValue: "invalid") == nil)
    }
}
