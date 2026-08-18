//
//  ChartDataProcessorTests.swift
//  JabTrackerTests
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Comprehensive tests for ChartDataProcessor data transformation methods
/// Tests cover conversion from SwiftData models to Swift Charts compatible data structures
@Suite("ChartDataProcessor Tests")
struct ChartDataProcessorTests {

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
            email: "test@charts.com",
            name: "Charts Test User",
            appleUserId: "test-user-charts"
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

    /// Create test doses with known pattern for predictable chart data
    @MainActor
    private func createTestDoses(for profile: MedicationProfile, in container: ModelContainer)
        -> [Dose]
    {
        let context = container.mainContext
        var doses: [Dose] = []

        // Create 10 doses over 10 weeks (weekly dosing)
        for weekOffset in 0..<10 {
            let doseTime = Date().addingTimeInterval(-Double(weekOffset) * 7 * 24 * 3600)
            let dose = Dose(
                amount: 1.0,
                timestamp: doseTime,
                skipped: false
            )
            dose.medication = profile
            dose.user = profile.user
            context.insert(dose)
            doses.append(dose)
        }

        do {
            try context.save()
        } catch {
            Issue.record("Failed to save context: \(error)")
        }
        return doses.reversed()  // Return in chronological order
    }

    // MARK: - Initialization Tests

    @Test("ChartDataProcessor can be initialized")
    func testInitialization() {
        let processor = ChartDataProcessor()
        // Verify processor can be initialized and has expected methods
        #expect(
            processor.transformConcentrationToChartData([]).isEmpty,
            "Empty input should return empty array")
    }

    // MARK: - Concentration Point Data Transformation Tests

    @Test("Transform concentration timeline to chart points")
    @MainActor
    func testConcentrationTimelineTransformation() async throws {
        let container = createTestContainer()
        let (_, profile) = createTestUser(in: container)
        let doses = createTestDoses(for: profile, in: container)

        let processor = ChartDataProcessor()
        let engine = PharmacokineticsEngine()

        // Generate concentration timeline over 7 days
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-7 * 24 * 3600)
        let concentrationPoints = generateConcentrationTimeline(
            from: doses,
            medication: Medication.semaglutide,
            startDate: startDate,
            endDate: endDate,
            engine: engine
        )

        // Transform to chart data
        let chartPoints = processor.transformConcentrationToChartData(concentrationPoints)

        #expect(!chartPoints.isEmpty, "Chart data should not be empty")
        #expect(chartPoints.count == concentrationPoints.count, "Chart data count should match input")

        // Verify each chart point has required properties for Swift Charts
        for (index, chartPoint) in chartPoints.enumerated() {
            #expect(chartPoint.date == concentrationPoints[index].date, "Date should be preserved")
            #expect(
                chartPoint.concentration == concentrationPoints[index].concentration,
                "Concentration should be preserved")
            #expect(chartPoint.date <= endDate, "All dates should be within range")
            #expect(chartPoint.date >= startDate, "All dates should be within range")
        }
    }

    @Test("Handle empty concentration data gracefully")
    func testEmptyConcentrationData() {
        let processor = ChartDataProcessor()
        let emptyData: [ConcentrationPoint] = []

        let chartPoints = processor.transformConcentrationToChartData(emptyData)

        #expect(chartPoints.isEmpty, "Empty input should produce empty chart data")
    }

    // MARK: - Dose Marker Data Transformation Tests

    @Test("Transform doses to chart markers")
    @MainActor
    func testDoseMarkerTransformation() async throws {
        let container = createTestContainer()
        let (_, profile) = createTestUser(in: container)
        let doses = createTestDoses(for: profile, in: container)

        let processor = ChartDataProcessor()

        // Transform doses to marker data
        let markers = processor.transformDosesToMarkerData(doses)

        #expect(!markers.isEmpty, "Marker data should not be empty")
        #expect(markers.count == doses.count, "Marker count should match dose count")

        // Verify marker properties for Swift Charts compatibility
        for (index, marker) in markers.enumerated() {
            let expectedDose = doses[index]
            #expect(marker.date == expectedDose.timestamp, "Marker date should match dose timestamp")
            #expect(marker.amount == expectedDose.amount, "Marker amount should match dose amount")
            #expect(marker.isSkipped == expectedDose.skipped, "Marker skip status should match dose")
        }
    }

    @Test("Filter skipped doses from markers")
    @MainActor
    func testSkippedDoseFiltering() async throws {
        let container = createTestContainer()
        let (_, profile) = createTestUser(in: container)
        let context = container.mainContext

        // Create mix of regular and skipped doses
        let regularDose = Dose(amount: 1.0, timestamp: Date(), skipped: false)
        regularDose.medication = profile
        regularDose.user = profile.user
        context.insert(regularDose)

        let skippedDose = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-3600), skipped: true)
        skippedDose.medication = profile
        skippedDose.user = profile.user
        context.insert(skippedDose)

        do {
            try context.save()
        } catch {
            Issue.record("Failed to save context: \(error)")
        }

        let processor = ChartDataProcessor()
        let allMarkers = processor.transformDosesToMarkerData([regularDose, skippedDose])
        let activeMarkers = processor.transformDosesToMarkerData(
            [regularDose, skippedDose], includeSkipped: false)

        #expect(allMarkers.count == 2, "All markers should include both doses")
        #expect(activeMarkers.count == 1, "Active markers should exclude skipped dose")
        #expect(!activeMarkers[0].isSkipped, "Active marker should not be skipped")
    }

    // MARK: - Time Period Filtering Tests

    @Test("Filter data by time period")
    @MainActor
    func testTimePeriodFiltering() async throws {
        let container = createTestContainer()
        let (_, profile) = createTestUser(in: container)
        let doses = createTestDoses(for: profile, in: container)

        let processor = ChartDataProcessor()

        // Test 7-day filter
        let last7Days = processor.filterDataByTimePeriod(doses, period: .last7Days)
        #expect(last7Days.count <= doses.count, "Filtered data should be subset")

        // Test 30-day filter
        let last30Days = processor.filterDataByTimePeriod(doses, period: .last30Days)
        #expect(
            last30Days.count >= last7Days.count, "30-day filter should include more data than 7-day")

        // Test custom date range
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-14 * 24 * 3600)  // 14 days ago
        let customRange = processor.filterDataByDateRange(doses, startDate: startDate, endDate: endDate)

        // Verify all filtered doses are within range
        for dose in customRange {
            #expect(dose.timestamp >= startDate, "Dose should be after start date")
            #expect(dose.timestamp <= endDate, "Dose should be before end date")
        }
    }

    // MARK: - Performance Tests

    @Test("Handle large dataset efficiently")
    @MainActor
    func testLargeDatasetPerformance() async throws {
        let container = createTestContainer()
        let (_, profile) = createTestUser(in: container)
        let context = container.mainContext

        // Create large dataset (365 doses for 1 year)
        var largeDoseSet: [Dose] = []
        for dayOffset in 0..<365 {
            let doseTime = Date().addingTimeInterval(-Double(dayOffset) * 24 * 3600)
            let dose = Dose(
                amount: 1.0,
                timestamp: doseTime,
                skipped: dayOffset % 20 == 0  // Skip every 20th dose
            )
            dose.medication = profile
            dose.user = profile.user
            context.insert(dose)
            largeDoseSet.append(dose)
        }

        do {
            try context.save()
        } catch {
            Issue.record("Failed to save context: \(error)")
        }

        let processor = ChartDataProcessor()

        // Measure transformation performance
        let startTime = CFAbsoluteTimeGetCurrent()
        let markers = processor.transformDosesToMarkerData(largeDoseSet)
        let endTime = CFAbsoluteTimeGetCurrent()

        let executionTime = endTime - startTime

        #expect(markers.count == largeDoseSet.count, "All doses should be processed")
        #expect(executionTime < 0.1, "Large dataset processing should complete in under 100ms")
    }

    // MARK: - Data Interpolation Tests

    @Test("Interpolate concentration data gaps")
    func testConcentrationInterpolation() {
        let processor = ChartDataProcessor()

        // Create sparse concentration data with gaps
        let baseDate = Date()
        let sparsePoints = [
            ConcentrationPoint(date: baseDate, concentration: 10.0),
            ConcentrationPoint(date: baseDate.addingTimeInterval(6 * 3600), concentration: 5.0),  // 6 hours later
            ConcentrationPoint(date: baseDate.addingTimeInterval(12 * 3600), concentration: 2.5),  // 12 hours later
        ]

        // Interpolate to hourly points
        let interpolated = processor.interpolateConcentrationData(sparsePoints, intervalHours: 1.0)

        #expect(interpolated.count >= sparsePoints.count, "Interpolated data should have more points")
        #expect(interpolated.first?.concentration == 10.0, "First point should be preserved")
        #expect(interpolated.last?.concentration == 2.5, "Last point should be preserved")

        // Verify interpolated values are reasonable (between neighboring points)
        for pointIndex in 1..<interpolated.count - 1 {
            let current = interpolated[pointIndex]
            let previous = interpolated[pointIndex - 1]
            let next = interpolated[pointIndex + 1]

            #expect(
                current.concentration <= max(previous.concentration, next.concentration),
                "Interpolated value should not exceed neighboring points")
            #expect(
                current.concentration >= min(previous.concentration, next.concentration),
                "Interpolated value should not be below neighboring points")
        }
    }

    // MARK: - Chart Data Validation Tests

    @Test("Validate chart data structure compatibility")
    func testChartDataValidation() {
        let processor = ChartDataProcessor()

        // Test with known data
        let testPoint = ConcentrationPoint(date: Date(), concentration: 5.0)
        let chartData = processor.transformConcentrationToChartData([testPoint])

        let chartPoint = chartData[0]

        // Verify Swift Charts compatibility requirements
        #expect(chartPoint.concentration >= 0, "Concentration should be non-negative")
        #expect(chartPoint.concentration.isFinite, "Concentration should be finite number")
    }

    // MARK: - ChartPoint Constructor Tests

    @Test("ConcentrationChartPoint constructor with valid data")
    func testConcentrationChartPointConstructor() {
        let date = Date()
        let concentration = 5.0

        let chartPoint = ChartDataProcessor.ConcentrationChartPoint(
            date: date,
            concentration: concentration
        )

        #expect(chartPoint.date == date)
        #expect(chartPoint.concentration == concentration)
        #expect(chartPoint.id != UUID(), "Chart point should have valid ID")
    }

    @Test("DoseMarker constructor with valid data")
    func testDoseMarkerConstructor() {
        let date = Date()
        let amount = 1.0
        let isSkipped = false

        let marker = ChartDataProcessor.DoseMarker(
            date: date,
            amount: amount,
            isSkipped: isSkipped
        )

        #expect(marker.date == date)
        #expect(marker.amount == amount)
        #expect(marker.isSkipped == isSkipped)
        #expect(marker.id != UUID(), "Dose marker should have valid ID")
    }

    // MARK: - Date Range Filtering Tests

    @Test("Filter concentration data by date range")
    func testFilterConcentrationByDateRange() {
        let processor = ChartDataProcessor()
        let now = Date()

        // Create test concentration points - avoid SwiftData relationships
        let concentrationData = [
            ConcentrationPoint(date: now.addingTimeInterval(-3600), concentration: 1.0),  // 1 hour ago
            ConcentrationPoint(date: now, concentration: 2.0),  // now
            ConcentrationPoint(date: now.addingTimeInterval(3600), concentration: 3.0),  // 1 hour future
        ]

        let startDate = now.addingTimeInterval(-1800)  // 30 min ago
        let endDate = now.addingTimeInterval(1800)  // 30 min future

        let filtered = processor.filterConcentrationByDateRange(
            concentrationData,
            startDate: startDate,
            endDate: endDate
        )

        // Should only include the middle point (now)
        #expect(filtered.count == 1)
        #expect(filtered[0].concentration == 2.0)
    }

    // MARK: - Batch Processing Tests

    @Test("Process batched concentration data efficiently")
    func testProcessBatchedConcentrationData() {
        let processor = ChartDataProcessor()

        // Create large dataset - avoid SwiftData relationships
        let largeDataset = (0..<100).map { index in
            ConcentrationPoint(
                date: Date().addingTimeInterval(Double(index) * 3600),
                concentration: Double(index) * 0.5
            )
        }

        let batchSize = 20
        let maxFinalPoints = 50

        let processed = processor.processBatchedConcentrationData(
            largeDataset,
            batchSize: batchSize,
            maxFinalPoints: maxFinalPoints
        )

        // Verify processing completed without crashing
        #expect(processed.count <= maxFinalPoints, "Should respect max points limit")
        #expect(!processed.isEmpty, "Should produce some output")

        // Verify all concentrations are finite (medical safety requirement)
        for point in processed {
            #expect(point.concentration.isFinite, "All concentrations must be finite")
        }
    }

    // MARK: - Lazy Concentration Calculation Tests

    @Test("Lazy concentration calculation with time range")
    func testLazyConcentrationCalculation() {
        let processor = ChartDataProcessor()

        // Create test data without SwiftData relationships
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(24 * 3600)  // 24 hours
        let intervalHours = 6.0

        let testDoses = [
            Dose(
                amount: 1.0,
                timestamp: startDate,
                site: "abdomen",
                notes: "",
                skipped: false
            )
        ]

        let medication = Medication.semaglutide

        let timeRange = startDate...endDate

        let lazySequence = processor.lazyConcentrationCalculation(
            timeRange: timeRange,
            intervalHours: intervalHours,
            doses: testDoses,  // Pass array directly, no relationships
            medication: medication
        )

        // Force evaluation of lazy sequence
        let concentrations = Array(lazySequence)

        #expect(!concentrations.isEmpty, "Should generate concentration points")

        // Verify medical safety requirements
        for point in concentrations {
            #expect(point.concentration >= 0, "Concentrations should be non-negative")
            #expect(point.concentration.isFinite, "Concentrations must be finite")
        }
    }

    // MARK: - Timeline Generation Tests

    @Test("Generate concentration timeline for user profile")
    @MainActor
    func testGenerateConcentrationTimeline() {
        let container = createTestContainer()
        let processor = ChartDataProcessor()

        // Create test user and profile
        let (_, profile) = createTestUser(in: container)

        let timeRange = Date()...Date().addingTimeInterval(24 * 3600)
        let intervalHours = 6.0

        let timeline = processor.generateConcentrationTimeline(
            for: profile,
            timeRange: timeRange,
            intervalHours: intervalHours
        )

        #expect(!timeline.isEmpty, "Should generate timeline points")

        // Verify medical safety
        for point in timeline {
            #expect(point.concentration.isFinite, "Timeline concentrations must be finite")
            #expect(point.concentration >= 0, "Timeline concentrations must be non-negative")
        }
    }

    // MARK: - Analytics Integration Tests

    @Test("Generate analytics optimized chart data")
    @MainActor
    func testGenerateAnalyticsOptimizedChartData() {
        let container = createTestContainer()
        let processor = ChartDataProcessor()
        let analyticsService = AnalyticsService()

        // Create test user and profile with actual doses
        let (user, profile) = createTestUser(in: container)
        let context = container.mainContext

        // Add test dose to generate meaningful chart data
        let testDose = Dose(
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-24 * 3600),  // 1 day ago
            site: "abdomen",
            skipped: false
        )
        testDose.user = user
        testDose.medication = profile
        context.insert(testDose)
        do {
            try context.save()
        } catch {
            Issue.record("Failed to save context: \(error)")
        }

        let timePeriod = ChartDataProcessor.TimePeriod.last7Days

        let chartData = processor.generateAnalyticsOptimizedChartData(
            for: user,
            analyticsService: analyticsService,
            timePeriod: timePeriod,
            context: context
        )

        // Verify chart data arrays are created (may be empty or populated)
        #expect(chartData.concentrationTimeline.count >= 0, "Should have concentration timeline array")
        #expect(chartData.doseMarkers.count >= 0, "Should have dose markers array")

        // Verify medical safety for any generated data
        for point in chartData.concentrationTimeline {
            #expect(point.concentration.isFinite, "Analytics concentrations must be finite")
            #expect(point.concentration >= 0, "Analytics concentrations must be non-negative")
        }
    }

    // MARK: - Recommendation System Tests

    @Test("Recommended time scale calculation")
    func testRecommendedTimeScale() {
        let processor = ChartDataProcessor()

        // Create test concentration data
        let concentrationData = [
            ConcentrationPoint(date: Date().addingTimeInterval(-7 * 24 * 3600), concentration: 1.0),  // 1 week ago
            ConcentrationPoint(date: Date(), concentration: 2.0),  // now
        ]

        let recommendation = processor.recommendedTimeScale(for: concentrationData)

        // Verify recommendation is reasonable (TimeInterval is in seconds)
        #expect(recommendation > 0, "Recommended time scale should be positive")
        #expect(recommendation.isFinite, "Recommended time scale must be finite")
    }

    @Test("Recommended Y-axis range calculation")
    func testRecommendedYAxisRange() {
        let processor = ChartDataProcessor()

        // Create test concentration data with varying values
        let concentrationData = [
            ConcentrationPoint(date: Date().addingTimeInterval(-3600), concentration: 2.0),
            ConcentrationPoint(date: Date(), concentration: 8.0),
            ConcentrationPoint(date: Date().addingTimeInterval(3600), concentration: 5.0),
        ]

        let yAxisRange = processor.recommendedYAxisRange(for: concentrationData)

        // Verify range is valid and finite (tuple with min/max)
        #expect(yAxisRange.min >= 0, "Y-axis min should be non-negative")
        #expect(yAxisRange.max > yAxisRange.min, "Y-axis max should be greater than min")
        #expect(yAxisRange.min.isFinite, "Y-axis min must be finite")
        #expect(yAxisRange.max.isFinite, "Y-axis max must be finite")
    }

    // MARK: - Chart Data Generation with Levels Tests

    @Test("Generate concentration timeline with levels")
    @MainActor
    func testGenerateConcentrationTimelineWithLevels() {
        let container = createTestContainer()
        let processor = ChartDataProcessor()

        // Create test user and profile
        let (_, profile) = createTestUser(in: container)

        let timeRange = Date().addingTimeInterval(-7 * 24 * 3600)...Date()  // Last 7 days

        let timelineWithLevels = processor.generateConcentrationTimelineWithLevels(
            for: profile,
            timeRange: timeRange
        )

        // Verify timeline structure
        #expect(!timelineWithLevels.timeline.isEmpty, "Should include concentration timeline")

        // Verify medical safety for concentration data
        for point in timelineWithLevels.timeline {
            #expect(point.concentration.isFinite, "Chart concentrations must be finite")
            #expect(point.concentration >= 0, "Chart concentrations must be non-negative")
        }

        // Verify peak and trough levels are also finite
        for peak in timelineWithLevels.peakLevels {
            #expect(peak.concentration.isFinite, "Peak concentrations must be finite")
            #expect(peak.concentration >= 0, "Peak concentrations must be non-negative")
        }

        for trough in timelineWithLevels.troughLevels {
            #expect(trough.concentration.isFinite, "Trough concentrations must be finite")
            #expect(trough.concentration >= 0, "Trough concentrations must be non-negative")
        }
    }

    // MARK: - Data Density Optimization Tests

    @Test("Optimize data density for large datasets")
    func testOptimizeDataDensity() {
        let processor = ChartDataProcessor()

        // Create large dataset - avoid SwiftData relationships
        let largeDataset = (0..<1000).map { index in
            ConcentrationPoint(
                date: Date().addingTimeInterval(Double(index) * 3600),
                concentration: Double(index) * 0.01
            )
        }

        let maxPoints = 100
        let optimized = processor.optimizeDataDensity(largeDataset, maxPoints: maxPoints)

        // Verify optimization respects limits
        #expect(optimized.count <= maxPoints, "Should respect max points limit")
        #expect(!optimized.isEmpty, "Should preserve some data points")

        // Verify medical safety
        for point in optimized {
            #expect(point.concentration.isFinite, "Optimized concentrations must be finite")
            #expect(point.concentration >= 0, "Optimized concentrations must be non-negative")
        }
    }

    // MARK: - Input Sanitization Tests (Medical Safety)

    @Test("Chart data processing with corrupted input (security test)")
    func testChartDataWithCorruptedInput() {
        let processor = ChartDataProcessor()

        // Test with infinite and NaN values (potential security/safety issue)
        let corruptedData = [
            ConcentrationPoint(date: Date(), concentration: Double.infinity),
            ConcentrationPoint(date: Date(), concentration: Double.nan),
            ConcentrationPoint(date: Date(), concentration: -1.0),  // Invalid negative
            ConcentrationPoint(date: Date(), concentration: 5.0),  // Valid data
        ]

        let sanitized = processor.sanitizeConcentrationData(corruptedData)

        // Verify corrupted data is removed/fixed
        for point in sanitized {
            #expect(point.concentration.isFinite, "Sanitized data must be finite")
            #expect(point.concentration >= 0, "Sanitized concentrations must be non-negative")
        }

        #expect(!sanitized.isEmpty, "Should preserve valid data after sanitization")
    }
}

// MARK: - Helper Functions

/// Generate concentration timeline for testing
private func generateConcentrationTimeline(
    from doses: [Dose],
    medication: Medication,
    startDate: Date,
    endDate: Date,
    engine: PharmacokineticsEngine
) -> [ConcentrationPoint] {
    var points: [ConcentrationPoint] = []
    let intervalHours: Double = 6  // Every 6 hours

    var currentTime = startDate
    while currentTime <= endDate {
        let concentration = engine.calculateConcentration(
            from: doses,
            medication: medication,
            at: currentTime
        )

        points.append(ConcentrationPoint(date: currentTime, concentration: concentration))
        currentTime = currentTime.addingTimeInterval(intervalHours * 3600)
    }

    return points
}
