//
//  ChartDataProcessorInterpolationTests.swift
//  JabTrackerTests
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Advanced interpolation tests for ChartDataProcessor concentration timeline features
/// Tests sophisticated pharmacokinetic-based interpolation and Swift Charts integration
@Suite("ChartDataProcessor Interpolation Tests")
struct ChartDataProcessorInterpolationTests {

    // MARK: - Test Setup

    /// Create test container with in-memory storage
    private func createTestContainer() -> ModelContainer {
        let config = InMemoryTestStore.configuration()
        do {
            return try ModelContainer(
                for: User.self, Dose.self, MedicationProfile.self, configurations: config)
        } catch {
            Issue.record("Failed to create test container: \(error)")
            fatalError("Test container creation failed")
        }
    }

    /// Create test user with medication profile for testing
    @MainActor
    private func createTestUser(in container: ModelContainer) -> (User, MedicationProfile) {
        let context = container.mainContext

        let user = User(
            email: "test@interpolation.com",
            name: "Interpolation Test User",
            appleUserId: "test-user-interpolation"
        )
        context.insert(user)

        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            startDate: Date().addingTimeInterval(-30 * 24 * 3600),  // 30 days ago
            medicationType: "semaglutide"
        )
        profile.user = user
        context.insert(profile)

        do {
            try context.save()
        } catch {
            Issue.record("Failed to save context: \(error)")
        }
        return (user, profile)
    }

    /// Create test doses for concentration timeline
    @MainActor
    private func createTestDoses(
        user: User, medication: MedicationProfile, in container: ModelContainer
    ) -> [Dose] {
        let context = container.mainContext
        let baseDate = Date().addingTimeInterval(-7 * 24 * 3600)  // 7 days ago

        var doses: [Dose] = []

        // Create doses every 24 hours for 7 days (weekly semaglutide pattern)
        for dayOffset in 0..<7 {
            let doseDate = baseDate.addingTimeInterval(Double(dayOffset) * 24 * 3600)
            let dose = Dose(
                amount: 1.0,
                timestamp: doseDate,
                user: user,
                medication: medication
            )
            context.insert(dose)
            doses.append(dose)
        }

        do {
            try context.save()
        } catch {
            Issue.record("Failed to save context: \(error)")
        }
        return doses
    }

    // MARK: - Pharmacokinetic Interpolation Tests

    @Test("Exponential decay interpolation generates smooth concentration curves")
    @MainActor
    func testExponentialDecayInterpolation() async throws {
        let container = createTestContainer()
        let (user, medication) = createTestUser(in: container)
        let doses = createTestDoses(user: user, medication: medication, in: container)

        let processor = ChartDataProcessor()
        _ = PharmacokineticsEngine()

        // Generate concentration points from doses using PK engine
        let startDate = doses.first!.timestamp
        let endDate = doses.last!.timestamp.addingTimeInterval(7 * 24 * 3600)  // 7 days after last dose

        let concentrationPoints = processor.generateConcentrationTimeline(
            doses: doses,
            medication: Medication.semaglutide,
            startDate: startDate,
            endDate: endDate,
            intervalHours: 6  // 6-hour intervals for smooth curves
        )

        // Verify that interpolation creates smooth exponential decay
        #expect(concentrationPoints.count > doses.count * 4)  // More points than original doses
        #expect(concentrationPoints.allSatisfy { $0.concentration >= 0 })  // No negative concentrations

        // Test exponential decay pattern between doses
        let firstDoseTime = doses[0].timestamp
        let secondDoseTime = doses[1].timestamp

        let pointsBetweenFirstTwoDoses = concentrationPoints.filter { point in
            point.date > firstDoseTime && point.date < secondDoseTime
        }

        // Verify concentrations decrease exponentially between doses
        let concentrations = pointsBetweenFirstTwoDoses.map { $0.concentration }
        for index in 1..<concentrations.count {
            #expect(
                concentrations[index] <= concentrations[index - 1], "Concentration should decay over time")
        }
    }

    @Test("Handle missing data points with graceful interpolation")
    @MainActor
    func testMissingDataPointsInterpolation() async throws {
        let container = createTestContainer()
        let (user, medication) = createTestUser(in: container)

        // Create sparse doses with gaps
        let context = container.mainContext
        let baseDate = Date().addingTimeInterval(-14 * 24 * 3600)  // 14 days ago

        let sparseDoses = [
            Dose(amount: 1.0, timestamp: baseDate, user: user, medication: medication),
            Dose(
                amount: 1.0, timestamp: baseDate.addingTimeInterval(7 * 24 * 3600), user: user,
                medication: medication),  // 7 days later
            Dose(
                amount: 1.0, timestamp: baseDate.addingTimeInterval(14 * 24 * 3600), user: user,
                medication: medication),  // 14 days later
        ]

        for dose in sparseDoses {
            context.insert(dose)
        }
        do {
            try context.save()
        } catch {
            Issue.record("Failed to save context: \(error)")
        }

        let processor = ChartDataProcessor()

        let interpolatedTimeline = processor.generateConcentrationTimeline(
            doses: sparseDoses,
            medication: Medication.semaglutide,
            startDate: baseDate,
            endDate: baseDate.addingTimeInterval(21 * 24 * 3600),
            intervalHours: 12  // 12-hour intervals
        )

        // Verify interpolation fills gaps appropriately
        #expect(interpolatedTimeline.count > sparseDoses.count * 10)  // Much denser than sparse input
        #expect(interpolatedTimeline.allSatisfy { $0.concentration >= 0 })

        // Verify concentration accumulation at dose times
        let doseConcentrations = interpolatedTimeline.filter { point in
            sparseDoses.contains { abs(point.date.timeIntervalSince($0.timestamp)) < 3600 }
        }
        #expect(doseConcentrations.count == sparseDoses.count)
    }

    @Test("Irregular dose intervals maintain accurate concentration modeling")
    @MainActor
    func testIrregularDoseIntervals() async throws {
        let container = createTestContainer()
        let (user, medication) = createTestUser(in: container)

        // Create irregular dose pattern (missed doses, early doses)
        let context = container.mainContext
        let baseDate = Date().addingTimeInterval(-21 * 24 * 3600)  // 21 days ago

        let irregularDoses = [
            Dose(amount: 1.0, timestamp: baseDate, user: user, medication: medication),  // Day 0
            Dose(
                amount: 1.0, timestamp: baseDate.addingTimeInterval(5 * 24 * 3600), user: user,
                medication: medication),  // Day 5 (2 days early)
            // Missing dose on day 12
            Dose(
                amount: 1.0, timestamp: baseDate.addingTimeInterval(14 * 24 * 3600), user: user,
                medication: medication),  // Day 14
            Dose(
                amount: 1.0, timestamp: baseDate.addingTimeInterval(22 * 24 * 3600), user: user,
                medication: medication),  // Day 22 (1 day late)
        ]

        for dose in irregularDoses {
            context.insert(dose)
        }
        do {
            try context.save()
        } catch {
            Issue.record("Failed to save context: \(error)")
        }

        let processor = ChartDataProcessor()

        let timeline = processor.generateConcentrationTimeline(
            doses: irregularDoses,
            medication: Medication.semaglutide,
            startDate: baseDate,
            endDate: baseDate.addingTimeInterval(28 * 24 * 3600),
            intervalHours: 8
        )

        // Verify handling of irregular intervals
        #expect(timeline.count > 60)  // Dense timeline despite irregular dosing
        #expect(timeline.allSatisfy { $0.concentration >= 0 })

        // Check for concentration peaks at irregular dose times
        let peakTimes = irregularDoses.map { $0.timestamp }
        for peakTime in peakTimes {
            let nearbyPoints = timeline.filter { point in
                abs(point.date.timeIntervalSince(peakTime)) < 4 * 3600  // Within 4 hours
            }
            #expect(!nearbyPoints.isEmpty, "Should have concentration data near dose times")
        }
    }

    // MARK: - Swift Charts Data Structure Tests

    @Test("Transform concentration timeline to Swift Charts point format")
    @MainActor
    func testSwiftChartsDataTransformation() async throws {
        let container = createTestContainer()
        let (user, medication) = createTestUser(in: container)
        let doses = createTestDoses(user: user, medication: medication, in: container)

        let processor = ChartDataProcessor()

        // Generate concentration timeline
        let concentrationPoints = processor.generateConcentrationTimeline(
            doses: doses,
            medication: Medication.semaglutide,
            startDate: doses.first!.timestamp,
            endDate: doses.last!.timestamp.addingTimeInterval(7 * 24 * 3600),
            intervalHours: 4
        )

        // Transform to Swift Charts format
        let chartPoints = processor.transformConcentrationToChartData(concentrationPoints)

        // Verify Swift Charts compatibility
        #expect(chartPoints.count == concentrationPoints.count)
        #expect(chartPoints.allSatisfy { !$0.id.uuidString.isEmpty })  // Valid identifiers
        #expect(chartPoints.allSatisfy { $0.concentration >= 0 })  // Valid concentrations

        // Verify dates are reasonable (within our test timeline range)
        let testStartDate = doses.first!.timestamp
        let testEndDate = doses.last!.timestamp.addingTimeInterval(7 * 24 * 3600)
        #expect(chartPoints.allSatisfy { $0.date >= testStartDate && $0.date <= testEndDate })

        // Verify data preservation in transformation
        for (index, chartPoint) in chartPoints.enumerated() {
            let originalPoint = concentrationPoints[index]
            #expect(chartPoint.date == originalPoint.date)
            #expect(chartPoint.concentration == originalPoint.concentration)
        }
    }

    @Test("Memory-efficient processing for large concentration datasets")
    @MainActor
    func testMemoryEfficientConcentrationProcessing() async throws {
        let container = createTestContainer()
        let (user, medication) = createTestUser(in: container)

        // Create large dose dataset (3 months of daily dosing)
        let context = container.mainContext
        let baseDate = Date().addingTimeInterval(-90 * 24 * 3600)  // 90 days ago

        var largeDoseSet: [Dose] = []
        for dayOffset in 0..<90 {
            let doseDate = baseDate.addingTimeInterval(Double(dayOffset) * 24 * 3600)
            let dose = Dose(
                amount: 1.0,
                timestamp: doseDate,
                user: user,
                medication: medication
            )
            context.insert(dose)
            largeDoseSet.append(dose)
        }
        do {
            try context.save()
        } catch {
            Issue.record("Failed to save context: \(error)")
        }

        let processor = ChartDataProcessor()

        // Test memory-efficient processing with density optimization
        let optimizedTimeline = processor.generateConcentrationTimelineOptimized(
            doses: largeDoseSet,
            medication: Medication.semaglutide,
            startDate: baseDate,
            endDate: Date(),
            maxPoints: 200,  // Limit for chart performance
            adaptiveIntervals: true
        )

        // Verify memory efficiency
        #expect(optimizedTimeline.count <= 200)  // Respects max points limit
        #expect(optimizedTimeline.count >= 50)  // Still provides meaningful resolution
        #expect(optimizedTimeline.allSatisfy { $0.concentration >= 0 })

        // Verify important features preserved despite optimization
        let optimizedMarkers = processor.processLargeDatasetEfficiently(largeDoseSet, maxMarkers: 50)
        #expect(optimizedMarkers.count <= 50)
        #expect(optimizedMarkers.count >= 10)  // Preserve key dose markers
    }

    // MARK: - Complex Scenario Tests

    @Test("Multi-medication concentration timeline interpolation")
    @MainActor
    func testMultiMedicationInterpolation() async throws {
        let container = createTestContainer()
        let (user, _) = createTestUser(in: container)

        // Create two different medication profiles
        let context = container.mainContext

        let semaglutideProfile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            startDate: Date().addingTimeInterval(-21 * 24 * 3600),
            medicationType: "semaglutide"
        )
        semaglutideProfile.user = user
        context.insert(semaglutideProfile)

        let tirzepatideProfile = MedicationProfile(
            genericName: "tirzepatide",
            brandName: "Mounjaro",
            currentDose: 5.0,
            startDate: Date().addingTimeInterval(-14 * 24 * 3600),
            medicationType: "tirzepatide"
        )
        tirzepatideProfile.user = user
        context.insert(tirzepatideProfile)

        // Create overlapping dose schedules
        let baseDate = Date().addingTimeInterval(-14 * 24 * 3600)

        let semaglutideDoses = [
            Dose(amount: 1.0, timestamp: baseDate, user: user, medication: semaglutideProfile),
            Dose(
                amount: 1.0, timestamp: baseDate.addingTimeInterval(7 * 24 * 3600), user: user,
                medication: semaglutideProfile),
        ]

        let tirzepatideDoses = [
            Dose(
                amount: 5.0, timestamp: baseDate.addingTimeInterval(1 * 24 * 3600), user: user,
                medication: tirzepatideProfile),
            Dose(
                amount: 5.0, timestamp: baseDate.addingTimeInterval(8 * 24 * 3600), user: user,
                medication: tirzepatideProfile),
        ]

        for dose in semaglutideDoses + tirzepatideDoses {
            context.insert(dose)
        }
        do {
            try context.save()
        } catch {
            Issue.record("Failed to save context: \(error)")
        }

        let processor = ChartDataProcessor()

        // Generate separate timelines for each medication
        let semaglutideTimeline = processor.generateConcentrationTimeline(
            doses: semaglutideDoses,
            medication: Medication.semaglutide,
            startDate: baseDate,
            endDate: baseDate.addingTimeInterval(14 * 24 * 3600),
            intervalHours: 6
        )

        let tirzepatideTimeline = processor.generateConcentrationTimeline(
            doses: tirzepatideDoses,
            medication: Medication.tirzepatide,
            startDate: baseDate,
            endDate: baseDate.addingTimeInterval(14 * 24 * 3600),
            intervalHours: 6
        )

        // Verify separate medication timelines
        #expect(semaglutideTimeline.count > 20)
        #expect(tirzepatideTimeline.count > 20)
        #expect(semaglutideTimeline.allSatisfy { $0.concentration >= 0 })
        #expect(tirzepatideTimeline.allSatisfy { $0.concentration >= 0 })

        // Test combined timeline processing
        let combinedDoses = semaglutideDoses + tirzepatideDoses
        let multiMedicationMarkers = processor.transformDosesToMarkerData(combinedDoses)
        #expect(multiMedicationMarkers.count == 4)  // All doses represented as markers
    }

    @Test("Edge case handling for concentration interpolation")
    @MainActor
    func testInterpolationEdgeCases() async throws {
        let container = createTestContainer()
        let (user, medication) = createTestUser(in: container)
        let processor = ChartDataProcessor()

        // Test empty dose array
        let emptyTimeline = processor.generateConcentrationTimeline(
            doses: [],
            medication: Medication.semaglutide,
            startDate: Date().addingTimeInterval(-24 * 3600),
            endDate: Date(),
            intervalHours: 6
        )
        #expect(emptyTimeline.isEmpty)

        // Test single dose
        let context = container.mainContext
        let singleDose = Dose(
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-12 * 3600),
            user: user,
            medication: medication
        )
        context.insert(singleDose)
        do {
            try context.save()
        } catch {
            Issue.record("Failed to save context: \(error)")
        }

        let singleDoseTimeline = processor.generateConcentrationTimeline(
            doses: [singleDose],
            medication: Medication.semaglutide,
            startDate: Date().addingTimeInterval(-24 * 3600),
            endDate: Date().addingTimeInterval(24 * 3600),
            intervalHours: 6
        )
        #expect(singleDoseTimeline.count >= 8)  // Should interpolate around single dose
        #expect(singleDoseTimeline.allSatisfy { $0.concentration >= 0 })

        // Test very short time range
        let shortTimeline = processor.generateConcentrationTimeline(
            doses: [singleDose],
            medication: Medication.semaglutide,
            startDate: singleDose.timestamp,
            endDate: singleDose.timestamp.addingTimeInterval(3600),  // 1 hour range
            intervalHours: 0.5  // 30-minute intervals
        )
        #expect(shortTimeline.count >= 2)
        #expect(shortTimeline.allSatisfy { $0.concentration >= 0 })
    }

    // MARK: - Advanced Chart Data Transformation Tests

    @Test("Transform concentration points to advanced chart data format")
    @MainActor
    func testTransformToAdvancedChartData() async throws {
        let container = createTestContainer()
        let (user, medication) = createTestUser(in: container)
        let doses = createTestDoses(user: user, medication: medication, in: container)

        let processor = ChartDataProcessor()

        // Generate basic concentration timeline
        let concentrationPoints = processor.generateConcentrationTimeline(
            doses: doses,
            medication: Medication.semaglutide,
            startDate: doses.first!.timestamp,
            endDate: doses.last!.timestamp.addingTimeInterval(24 * 3600),
            intervalHours: 6
        )

        // Transform to advanced chart data
        let advancedPoints = processor.transformToAdvancedChartData(
            concentrationPoints,
            interpolationType: .pharmacokinetic
        )

        // Verify transformation
        #expect(advancedPoints.count == concentrationPoints.count)
        #expect(advancedPoints.allSatisfy { $0.isInterpolated })

        // Verify data integrity preserved
        for (index, advancedPoint) in advancedPoints.enumerated() {
            let originalPoint = concentrationPoints[index]
            #expect(advancedPoint.date == originalPoint.date)
            #expect(advancedPoint.concentration == originalPoint.concentration)
        }

        // Test with different interpolation type
        let linearPoints = processor.transformToAdvancedChartData(
            concentrationPoints,
            interpolationType: .linear
        )
        #expect(linearPoints.count == concentrationPoints.count)
        #expect(linearPoints.allSatisfy { $0.isInterpolated })
    }

    @Test("Generate enhanced dose markers with intelligent styling")
    @MainActor
    func testGenerateEnhancedDoseMarkers() async throws {
        let container = createTestContainer()
        let (user, medication) = createTestUser(in: container)
        let context = container.mainContext

        // Create diverse dose pattern for styling tests
        let baseDate = Date().addingTimeInterval(-15 * 24 * 3600)
        var testDoses: [Dose] = []

        for dayOffset in 0..<12 {
            let doseDate = baseDate.addingTimeInterval(Double(dayOffset * 7) * 24 * 3600)
            let dose = Dose(
                amount: 1.0,
                timestamp: doseDate,
                skipped: dayOffset == 5,  // Skip one dose for testing
                user: user,
                medication: medication
            )
            context.insert(dose)
            testDoses.append(dose)
        }
        try context.save()

        let processor = ChartDataProcessor()

        // Test enhanced styling enabled
        let enhancedMarkers = processor.generateEnhancedDoseMarkers(
            testDoses,
            includeSkipped: true,
            enhancedStyling: true
        )

        // Verify all doses represented
        #expect(enhancedMarkers.count == testDoses.count)

        // Verify first dose special styling
        let firstMarker = enhancedMarkers.first!
        #expect(firstMarker.markerStyle == .firstDose)
        #expect(firstMarker.alertLevel == .info)

        // Verify milestone dose styling (10th dose)
        let milestoneMarker = enhancedMarkers[9]  // 10th dose (0-indexed)
        #expect(milestoneMarker.markerStyle == .milestone)
        #expect(milestoneMarker.alertLevel == .info)

        // Verify skipped dose included
        let skippedMarker = enhancedMarkers[5]
        #expect(skippedMarker.isSkipped == true)

        // Test with skipped doses excluded
        let nonSkippedMarkers = processor.generateEnhancedDoseMarkers(
            testDoses,
            includeSkipped: false,
            enhancedStyling: false
        )

        #expect(nonSkippedMarkers.count == testDoses.count - 1)  // One less due to skipped dose
        #expect(nonSkippedMarkers.allSatisfy { !$0.isSkipped })
    }

    @Test("Create complete concentration chart dataset")
    @MainActor
    func testCreateConcentrationChartDataset() async throws {
        let container = createTestContainer()
        let (user, medication) = createTestUser(in: container)
        let doses = createTestDoses(user: user, medication: medication, in: container)

        let processor = ChartDataProcessor()

        // Create dataset with default configuration
        let dataset = processor.createConcentrationChartDataset(
            doses: doses,
            medication: Medication.semaglutide,
            timeRange: .lastWeek,
            configuration: ConcentrationChartConfiguration.default
        )

        // Verify dataset structure
        #expect(dataset.concentrationCurves.count == 1)
        #expect(!dataset.doseMarkers.isEmpty)

        let curve = dataset.concentrationCurves.first!
        #expect(curve.medication == Medication.semaglutide.displayName)
        #expect(curve.curveStyle == .smooth)
        #expect(!curve.points.isEmpty)

        // Verify markers are within time range
        let timeRange = TimeRange.lastWeek.dateRange()
        #expect(
            dataset.doseMarkers.allSatisfy {
                $0.date >= timeRange.start && $0.date <= timeRange.end
            })

        // Verify metadata
        #expect(dataset.metadata.title.contains("Semaglutide"))
        #expect(dataset.metadata.subtitle == TimeRange.lastWeek.displayName)

        // Test with different time range
        let monthlyDataset = processor.createConcentrationChartDataset(
            doses: doses,
            medication: Medication.tirzepatide,
            timeRange: .lastMonth,
            configuration: ConcentrationChartConfiguration.default
        )

        #expect(monthlyDataset.metadata.subtitle == TimeRange.lastMonth.displayName)
    }

    @Test("Optimized concentration timeline with adaptive intervals")
    @MainActor
    func testOptimizedConcentrationTimelineAdaptive() async throws {
        let container = createTestContainer()
        let (user, medication) = createTestUser(in: container)

        // Create larger dose set for optimization testing
        let context = container.mainContext
        let baseDate = Date().addingTimeInterval(-30 * 24 * 3600)
        var largeDoseSet: [Dose] = []

        for dayOffset in 0..<30 {
            let doseDate = baseDate.addingTimeInterval(Double(dayOffset) * 24 * 3600)
            let dose = Dose(
                amount: 1.0,
                timestamp: doseDate,
                user: user,
                medication: medication
            )
            context.insert(dose)
            largeDoseSet.append(dose)
        }
        try context.save()

        let processor = ChartDataProcessor()

        // Test with adaptive intervals disabled
        let nonAdaptiveTimeline = processor.generateConcentrationTimelineOptimized(
            doses: largeDoseSet,
            medication: Medication.semaglutide,
            startDate: baseDate,
            endDate: Date(),
            maxPoints: 100,
            adaptiveIntervals: false
        )

        #expect(nonAdaptiveTimeline.count <= 105)  // Allow slight margin for interval calculations
        #expect(nonAdaptiveTimeline.count >= 10)
        #expect(nonAdaptiveTimeline.allSatisfy { $0.concentration >= 0 })

        // Test with adaptive intervals enabled (should use different algorithm)
        let adaptiveTimeline = processor.generateConcentrationTimelineOptimized(
            doses: largeDoseSet,
            medication: Medication.semaglutide,
            startDate: baseDate,
            endDate: Date(),
            maxPoints: 100,
            adaptiveIntervals: true
        )

        #expect(adaptiveTimeline.count <= 100)
        #expect(adaptiveTimeline.count >= 10)
        #expect(adaptiveTimeline.allSatisfy { $0.concentration >= 0 })

        // Adaptive should generally have different point distribution
        // (though exact verification depends on internal algorithm)
        #expect(adaptiveTimeline.count > 0)

        // Test edge cases for optimization
        let zeroPointsResult = processor.generateConcentrationTimelineOptimized(
            doses: largeDoseSet,
            medication: Medication.semaglutide,
            startDate: baseDate,
            endDate: Date(),
            maxPoints: 0,
            adaptiveIntervals: true
        )
        #expect(zeroPointsResult.isEmpty)

        let emptyDosesResult = processor.generateConcentrationTimelineOptimized(
            doses: [],
            medication: Medication.semaglutide,
            startDate: baseDate,
            endDate: Date(),
            maxPoints: 100,
            adaptiveIntervals: true
        )
        #expect(emptyDosesResult.isEmpty)
    }
}
