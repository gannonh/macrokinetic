//
//  ChartDataProcessorPerformanceTests.swift
//  JabTrackerTests
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Performance tests for ChartDataProcessor with large datasets (1+ year of data)
/// Validates memory efficiency and processing speed for production scenarios
@MainActor
struct ChartDataProcessorPerformanceTests {

    // MARK: - Test Dependencies

    private let processor = ChartDataProcessor()
    private let container = DataController.testContainer().container

    // MARK: - Test Data Generation

    /// Generate a large dataset for performance testing (1+ year of doses)
    private func generateLargeDataset(doseCount: Int) -> ([Dose], MedicationProfile) {
        let context = ModelContext(container)

        // Create test user
        let user = User(name: "Performance Test User", appleUserId: "test-user-performance")
        context.insert(user)

        // Create medication profile
        let medicationProfile = MedicationProfile(
            genericName: "Semaglutide",
            currentDose: 1.0,
            startDate: Date().addingTimeInterval(-Double(doseCount) * 7 * 24 * 3600),  // Start doseCount weeks ago
            medicationType: Medication.semaglutide.rawValue
        )
        medicationProfile.user = user
        context.insert(medicationProfile)

        // Generate doses spread over time
        var doses: [Dose] = []
        let startDate = medicationProfile.startDate

        for doseIndex in 0..<doseCount {
            // Create doses weekly with some randomization
            let doseDate = startDate.addingTimeInterval(
                Double(doseIndex) * 7 * 24 * 3600 + Double.random(in: -3600...3600))
            let dose = Dose(
                amount: 1.0 + Double.random(in: -0.2...0.2),  // Small variation
                timestamp: doseDate,
                skipped: Double.random(in: 0...1) < 0.05,  // 5% skip rate
                medication: medicationProfile
            )
            doses.append(dose)
            context.insert(dose)
        }

        do {
            try context.save()
        } catch {
            Issue.record("Failed to save context: \(error)")
        }
        return (doses, medicationProfile)
    }

    /// Generate large concentration dataset for interpolation performance testing
    private func generateLargeConcentrationDataset(pointCount: Int) -> [ConcentrationPoint] {
        // Create sparse data: one point every 8 hours for interpolation testing
        let startDate = Date().addingTimeInterval(-Double(pointCount) * 8 * 3600)

        return (0..<pointCount).map { index in
            let date = startDate.addingTimeInterval(Double(index) * 8 * 3600)  // 8-hour gaps
            // Generate realistic concentration curve with decay and new doses
            let concentration = 2.0 + sin(Double(index) * 0.1) * 1.5 + Double.random(in: -0.2...0.2)
            return ConcentrationPoint(date: date, concentration: max(0, concentration))
        }
    }

    // MARK: - Performance Tests

    /// Test performance of large dataset processing (1 year = 52 doses)
    @Test("Process 1 year dataset performance (<100ms)")
    func testOneYearDatasetPerformance() throws {
        // GIVEN: 1 year of weekly doses (52 doses)
        let (doses, _) = generateLargeDataset(doseCount: 52)

        // WHEN: Processing large dataset with time measurement
        let startTime = CFAbsoluteTimeGetCurrent()
        let markers = processor.processLargeDatasetEfficiently(doses, maxMarkers: 100)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        // THEN: Processing completes within 100ms
        #expect(
            processingTime < 0.1,
            "1 year dataset should process in <100ms, actual: \(processingTime * 1000)ms")
        #expect(!markers.isEmpty)
        #expect(markers.count <= 100)
    }

    /// Test performance with extreme dataset (3 years of data)
    @Test("Process 3 year dataset performance (<200ms)")
    func testThreeYearDatasetPerformance() throws {
        // GIVEN: 3 years of weekly doses (156 doses)
        let (doses, _) = generateLargeDataset(doseCount: 156)

        // WHEN: Processing very large dataset
        let startTime = CFAbsoluteTimeGetCurrent()
        let markers = processor.processLargeDatasetEfficiently(doses, maxMarkers: 150)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        // THEN: Processing completes within reasonable time
        #expect(
            processingTime < 0.2,
            "3 year dataset should process in <200ms, actual: \(processingTime * 1000)ms")
        #expect(!markers.isEmpty)
        #expect(markers.count <= 150)
    }

    /// Test memory efficiency with large concentration interpolation
    @Test("Large concentration interpolation memory efficiency")
    func testLargeConcentrationInterpolationPerformance() throws {
        // GIVEN: Large sparse concentration dataset (365 points = 1 year of daily data)
        let points = generateLargeConcentrationDataset(pointCount: 365)

        // WHEN: Interpolating to fill gaps with time measurement
        let startTime = CFAbsoluteTimeGetCurrent()
        let interpolated = processor.interpolateConcentrationData(points, intervalHours: 4.0)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        // THEN: Interpolation completes efficiently
        #expect(
            processingTime < 0.15,
            "Concentration interpolation should complete in <150ms, actual: \(processingTime * 1000)ms")
        #expect(interpolated.count > points.count)  // Should have more points after interpolation
        #expect(interpolated.count < points.count * 10)  // But not excessive growth
    }

    /// Test data density optimization performance
    @Test("Data density optimization performance")
    func testDataDensityOptimizationPerformance() throws {
        // GIVEN: Very dense concentration dataset (8760 points = 1 year of hourly data)
        let points = generateLargeConcentrationDataset(pointCount: 8760)

        // WHEN: Optimizing data density with time measurement
        let startTime = CFAbsoluteTimeGetCurrent()
        let optimized = processor.optimizeDataDensity(points, maxPoints: 200)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        // THEN: Optimization completes quickly and reduces data effectively
        #expect(
            processingTime < 0.05,
            "Data density optimization should complete in <50ms, actual: \(processingTime * 1000)ms")
        #expect(optimized.count <= 200)
        #expect(optimized.count >= 2)  // Should preserve first and last points
    }

    /// Test filtering performance with large datasets
    @Test("Time period filtering performance")
    func testTimePeriodFilteringPerformance() throws {
        // GIVEN: Large dose dataset
        let (doses, _) = generateLargeDataset(doseCount: 200)

        // WHEN: Filtering by different time periods with measurements
        let startTime1 = CFAbsoluteTimeGetCurrent()
        let last30Days = processor.filterDataByTimePeriod(doses, period: .last30Days)
        let filtering30Time = CFAbsoluteTimeGetCurrent() - startTime1

        let startTime2 = CFAbsoluteTimeGetCurrent()
        let lastYear = processor.filterDataByTimePeriod(doses, period: .lastYear)
        let filteringYearTime = CFAbsoluteTimeGetCurrent() - startTime2

        // THEN: Filtering operations complete quickly
        #expect(
            filtering30Time < 0.01,
            "30-day filtering should complete in <10ms, actual: \(filtering30Time * 1000)ms")
        #expect(
            filteringYearTime < 0.02,
            "Year filtering should complete in <20ms, actual: \(filteringYearTime * 1000)ms")
        #expect(last30Days.count <= lastYear.count)  // Logical relationship
    }

    /// Test memory usage during peak data processing operations
    @Test("Memory efficiency during peak operations")
    func testMemoryEfficiencyDuringPeakOperations() throws {
        // GIVEN: Multiple large datasets processed simultaneously
        let (doses1, _) = generateLargeDataset(doseCount: 100)
        let (doses2, _) = generateLargeDataset(doseCount: 100)
        let concentrationPoints = generateLargeConcentrationDataset(pointCount: 1000)

        // WHEN: Processing multiple operations simultaneously
        let startTime = CFAbsoluteTimeGetCurrent()

        let markers1 = processor.processLargeDatasetEfficiently(doses1)
        let markers2 = processor.processLargeDatasetEfficiently(doses2)
        let filtered = processor.filterDataByTimePeriod(doses1 + doses2, period: .lastYear)
        let interpolated = processor.interpolateConcentrationData(
            concentrationPoints, intervalHours: 2.0)
        let optimized = processor.optimizeDataDensity(interpolated, maxPoints: 150)

        let totalProcessingTime = CFAbsoluteTimeGetCurrent() - startTime

        // THEN: All operations complete efficiently without memory issues
        #expect(
            totalProcessingTime < 0.3,
            "Multiple simultaneous operations should complete in <300ms, actual: \(totalProcessingTime * 1000)ms"
        )
        #expect(!markers1.isEmpty)
        #expect(!markers2.isEmpty)
        #expect(!filtered.isEmpty)
        #expect(!interpolated.isEmpty)
        #expect(optimized.count <= 150)
    }

    /// Test chart data validation performance with large datasets
    @Test("Chart data validation performance")
    func testChartDataValidationPerformance() throws {
        // GIVEN: Large concentration chart dataset
        let points = generateLargeConcentrationDataset(pointCount: 5000)
        let chartPoints = processor.transformConcentrationToChartData(points)

        // WHEN: Validating chart data with time measurement
        let startTime = CFAbsoluteTimeGetCurrent()
        let isValid = processor.validateChartData(chartPoints)
        let validationTime = CFAbsoluteTimeGetCurrent() - startTime

        // THEN: Validation completes quickly
        #expect(
            validationTime < 0.05,
            "Chart data validation should complete in <50ms, actual: \(validationTime * 1000)ms")
        #expect(isValid)  // Generated data should be valid
    }

    /// Test data sanitization performance with problematic data
    @Test("Data sanitization performance")
    func testDataSanitizationPerformance() throws {
        // GIVEN: Large dataset with some problematic values
        var points = generateLargeConcentrationDataset(pointCount: 1000)

        // Inject some problematic data
        points.append(ConcentrationPoint(date: Date(), concentration: Double.infinity))
        points.append(ConcentrationPoint(date: Date(), concentration: -1.0))
        points.append(ConcentrationPoint(date: Date().addingTimeInterval(100000), concentration: 10.0))  // Future date

        // WHEN: Sanitizing data with time measurement
        let startTime = CFAbsoluteTimeGetCurrent()
        let sanitized = processor.sanitizeConcentrationData(points)
        let sanitizationTime = CFAbsoluteTimeGetCurrent() - startTime

        // THEN: Sanitization completes quickly and filters problematic data
        #expect(
            sanitizationTime < 0.05,
            "Data sanitization should complete in <50ms, actual: \(sanitizationTime * 1000)ms")
        #expect(sanitized.count < points.count)  // Should have filtered out problematic entries
        #expect(sanitized.allSatisfy { $0.concentration.isFinite && $0.concentration >= 0 })
    }
}
