//
//  ChartDataProcessorFilteringTests.swift
//  JabTracker
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Unit tests for ChartDataProcessor filtering, aggregation, and dose marker overlay functionality
/// Validates time period filtering, content filtering, and efficient aggregation for large datasets
@MainActor
struct ChartDataProcessorFilteringTests {

    // MARK: - Test Environment Setup

    var processor: ChartDataProcessor
    var testContainer: ModelContainer

    init() async throws {
        processor = ChartDataProcessor()
        testContainer = DataController.testContainer().container
    }

    // MARK: - Advanced Time Period Filtering Tests

    /// Test filtering doses by custom time periods with complex date ranges
    @Test("Filter doses by custom time periods")
    func testFilterDosesByCustomTimePeriods() async throws {
        let context = testContainer.mainContext

        // Create test user and medication profile
        let user = User(email: "test@example.com", name: "Test User")
        let medicationProfile = MedicationProfile(
            genericName: "Semaglutide",
            currentDose: 1.0,
            medicationType: Medication.semaglutide.rawValue
        )

        // Insert parent entities first
        context.insert(user)
        context.insert(medicationProfile)

        // Create doses spanning different time periods
        let now = Date()
        let dose1 = Dose(amount: 1.0, timestamp: now.addingTimeInterval(-1 * 24 * 3600))  // 1 day ago
        let dose2 = Dose(amount: 1.0, timestamp: now.addingTimeInterval(-5 * 24 * 3600))  // 5 days ago
        let dose3 = Dose(amount: 1.0, timestamp: now.addingTimeInterval(-10 * 24 * 3600))  // 10 days ago
        let dose4 = Dose(amount: 1.0, timestamp: now.addingTimeInterval(-40 * 24 * 3600))  // 40 days ago

        // Set relationships individually (never assign arrays to relationships)
        dose1.user = user
        dose1.medication = medicationProfile
        dose2.user = user
        dose2.medication = medicationProfile
        dose3.user = user
        dose3.medication = medicationProfile
        dose4.user = user
        dose4.medication = medicationProfile

        context.insert(dose1)
        context.insert(dose2)
        context.insert(dose3)
        context.insert(dose4)

        try context.save()

        let allDoses = [dose1, dose2, dose3, dose4]

        // Test filtering by custom date ranges
        let weekAgo = now.addingTimeInterval(-7 * 24 * 3600)
        let recentDoses = processor.filterDosesByCustomDateRange(
            allDoses,
            startDate: weekAgo,
            endDate: now
        )

        #expect(recentDoses.count == 2, "Should filter to 2 doses within past week")
        #expect(recentDoses.contains { $0.id == dose1.id }, "Should include dose from 1 day ago")
        #expect(recentDoses.contains { $0.id == dose2.id }, "Should include dose from 5 days ago")
        #expect(!recentDoses.contains { $0.id == dose3.id }, "Should exclude dose from 10 days ago")
        #expect(!recentDoses.contains { $0.id == dose4.id }, "Should exclude dose from 40 days ago")
    }

    /// Test filtering concentration points by dynamic time windows
    @Test("Filter concentration points by dynamic time windows")
    func testFilterConcentrationPointsByDynamicTimeWindows() async throws {
        // Create concentration points spanning different time periods
        let now = Date()
        let points = [
            ConcentrationPoint(date: now.addingTimeInterval(-2 * 3600), concentration: 10.0),  // 2 hours ago
            ConcentrationPoint(date: now.addingTimeInterval(-6 * 3600), concentration: 8.0),  // 6 hours ago
            ConcentrationPoint(date: now.addingTimeInterval(-12 * 3600), concentration: 6.0),  // 12 hours ago
            ConcentrationPoint(date: now.addingTimeInterval(-30 * 3600), concentration: 4.0),  // 30 hours ago
            ConcentrationPoint(date: now.addingTimeInterval(-50 * 3600), concentration: 2.0),  // 50 hours ago
        ]

        // Test filtering by rolling time window (last 24 hours)
        let rollingWindow = processor.filterConcentrationByRollingTimeWindow(
            points,
            windowHours: 24,
            referenceDate: now
        )

        #expect(rollingWindow.count == 3, "Should include 3 points within 24 hour window")
        #expect(
            rollingWindow.allSatisfy { point in
                now.timeIntervalSince(point.date) <= 24 * 3600
            }, "All filtered points should be within 24 hour window")
    }

    // MARK: - Content-Based Filtering Tests

    /// Test filtering doses by medication type with complex profiles
    @Test("Filter doses by medication type")
    func testFilterDosesByMedicationType() async throws {
        let context = testContainer.mainContext

        // Create test user
        let user = User(email: "test@example.com", name: "Test User")
        context.insert(user)

        // Create different medication profiles
        let semaglutideProfile = MedicationProfile(
            genericName: "Semaglutide",
            currentDose: 1.0,
            medicationType: Medication.semaglutide.rawValue
        )
        let tirzepatideProfile = MedicationProfile(
            genericName: "Tirzepatide",
            currentDose: 5.0,
            medicationType: Medication.tirzepatide.rawValue
        )

        context.insert(semaglutideProfile)
        context.insert(tirzepatideProfile)

        // Create doses for different medications
        let semaglutideDose1 = Dose(amount: 1.0, timestamp: Date())
        let semaglutideDose2 = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-3600))
        let tirzepatideDose1 = Dose(amount: 5.0, timestamp: Date().addingTimeInterval(-7200))

        // Set relationships individually
        semaglutideDose1.user = user
        semaglutideDose1.medication = semaglutideProfile
        semaglutideDose2.user = user
        semaglutideDose2.medication = semaglutideProfile
        tirzepatideDose1.user = user
        tirzepatideDose1.medication = tirzepatideProfile

        context.insert(semaglutideDose1)
        context.insert(semaglutideDose2)
        context.insert(tirzepatideDose1)

        try context.save()

        let allDoses = [semaglutideDose1, semaglutideDose2, tirzepatideDose1]

        // Test filtering by medication type
        let semaglutideDoses = processor.filterDosesByMedicationType(
            allDoses,
            medicationType: .semaglutide
        )

        #expect(semaglutideDoses.count == 2, "Should filter to 2 semaglutide doses")
        #expect(
            semaglutideDoses.allSatisfy { dose in
                dose.medication?.medicationType == Medication.semaglutide.rawValue
            }, "All filtered doses should be semaglutide")

        let tirzepatideDoses = processor.filterDosesByMedicationType(
            allDoses,
            medicationType: .tirzepatide
        )

        #expect(tirzepatideDoses.count == 1, "Should filter to 1 tirzepatide dose")
        #expect(
            tirzepatideDoses.first?.medication?.medicationType == Medication.tirzepatide.rawValue,
            "Filtered dose should be tirzepatide")
    }

    /// Test filtering doses by injection site with pattern matching
    @Test("Filter doses by injection site with pattern matching")
    func testFilterDosesByInjectionSite() async throws {
        let context = testContainer.mainContext

        // Create test user and medication profile
        let user = User(email: "test@example.com", name: "Test User")
        let medicationProfile = MedicationProfile(
            genericName: "Semaglutide",
            currentDose: 1.0,
            medicationType: Medication.semaglutide.rawValue
        )

        context.insert(user)
        context.insert(medicationProfile)

        // Create doses with different injection sites
        let thighDose1 = Dose(amount: 1.0, timestamp: Date(), site: "Left Thigh")
        let thighDose2 = Dose(
            amount: 1.0, timestamp: Date().addingTimeInterval(-3600), site: "Right Thigh")
        let armDose = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-7200), site: "Left Arm")
        let abdomenDose = Dose(
            amount: 1.0, timestamp: Date().addingTimeInterval(-10800), site: "Abdomen")

        // Set relationships individually
        thighDose1.user = user
        thighDose1.medication = medicationProfile
        thighDose2.user = user
        thighDose2.medication = medicationProfile
        armDose.user = user
        armDose.medication = medicationProfile
        abdomenDose.user = user
        abdomenDose.medication = medicationProfile

        context.insert(thighDose1)
        context.insert(thighDose2)
        context.insert(armDose)
        context.insert(abdomenDose)

        try context.save()

        let allDoses = [thighDose1, thighDose2, armDose, abdomenDose]

        // Test filtering by injection site pattern
        let thighDoses = processor.filterDosesByInjectionSitePattern(
            allDoses,
            sitePattern: "Thigh"
        )

        #expect(thighDoses.count == 2, "Should filter to 2 thigh injection doses")
        #expect(
            thighDoses.allSatisfy { dose in
                dose.site?.contains("Thigh") == true
            }, "All filtered doses should contain 'Thigh' in site")

        // Test filtering by specific injection sites
        let specificSites = processor.filterDosesBySpecificInjectionSites(
            allDoses,
            sites: ["Left Thigh", "Abdomen"]
        )

        #expect(specificSites.count == 2, "Should filter to 2 doses with specific sites")
        #expect(specificSites.contains { $0.site == "Left Thigh" }, "Should include left thigh dose")
        #expect(specificSites.contains { $0.site == "Abdomen" }, "Should include abdomen dose")
    }

    // MARK: - Dose Marker Overlay Logic Tests

    /// Test creating dose markers overlaid on concentration curves with timing alignment
    @Test("Create dose markers overlaid on concentration curves")
    func testCreateDoseMarkersOverlaidOnConcentrationCurves() async throws {
        let context = testContainer.mainContext

        // Create test data
        let user = User(email: "test@example.com", name: "Test User")
        let medicationProfile = MedicationProfile(
            genericName: "Semaglutide",
            currentDose: 1.0,
            medicationType: Medication.semaglutide.rawValue
        )

        context.insert(user)
        context.insert(medicationProfile)

        // Create dose at specific time
        let doseTime = Date()
        let dose = Dose(amount: 1.0, timestamp: doseTime, site: "Thigh")
        dose.user = user
        dose.medication = medicationProfile
        context.insert(dose)

        try context.save()

        // Create concentration points around dose time
        let concentrationPoints = [
            ConcentrationPoint(date: doseTime.addingTimeInterval(-3600), concentration: 5.0),  // 1 hour before
            ConcentrationPoint(date: doseTime, concentration: 15.0),  // At dose time (peak)
            ConcentrationPoint(date: doseTime.addingTimeInterval(3600), concentration: 12.0),  // 1 hour after
            ConcentrationPoint(date: doseTime.addingTimeInterval(7200), concentration: 8.0),  // 2 hours after
        ]

        // Test overlaying dose markers on concentration curve
        let overlaidMarkers = processor.createDoseMarkersOverlaidOnConcentrationCurve(
            doses: [dose],
            concentrationPoints: concentrationPoints,
            timeToleranceMinutes: 30
        )

        #expect(overlaidMarkers.count == 1, "Should create 1 overlaid dose marker")

        let marker = try #require(overlaidMarkers.first, "Should have at least one marker")
        #expect(marker.date == doseTime, "Marker date should match dose timestamp")
        #expect(marker.amount == 1.0, "Marker amount should match dose amount")
        #expect(marker.concentrationAtDose != nil, "Should include concentration at dose time")
        #expect(marker.concentrationAtDose == 15.0, "Should capture peak concentration at dose time")
    }

    /// Test generating enhanced dose markers with concentration context
    @Test("Generate enhanced dose markers with concentration context")
    func testGenerateEnhancedDoseMarkersWithConcentrationContext() async throws {
        let context = testContainer.mainContext

        // Create test data
        let user = User(email: "test@example.com", name: "Test User")
        let medicationProfile = MedicationProfile(
            genericName: "Semaglutide",
            currentDose: 1.0,
            medicationType: Medication.semaglutide.rawValue
        )

        context.insert(user)
        context.insert(medicationProfile)

        // Create doses at different times
        let now = Date()
        let dose1 = Dose(amount: 1.0, timestamp: now.addingTimeInterval(-7 * 24 * 3600))  // 1 week ago
        let dose2 = Dose(amount: 1.0, timestamp: now.addingTimeInterval(-3 * 24 * 3600))  // 3 days ago
        let dose3 = Dose(amount: 1.0, timestamp: now)  // Now

        dose1.user = user
        dose1.medication = medicationProfile
        dose2.user = user
        dose2.medication = medicationProfile
        dose3.user = user
        dose3.medication = medicationProfile

        context.insert(dose1)
        context.insert(dose2)
        context.insert(dose3)

        try context.save()

        // Mock concentration timeline
        let concentrationTimeline = [
            ConcentrationPoint(date: now.addingTimeInterval(-7 * 24 * 3600), concentration: 10.0),
            ConcentrationPoint(date: now.addingTimeInterval(-3 * 24 * 3600), concentration: 15.0),
            ConcentrationPoint(date: now, concentration: 20.0),
        ]

        // Test generating enhanced markers with concentration context
        let enhancedMarkers = processor.generateEnhancedDoseMarkersWithConcentrationContext(
            doses: [dose1, dose2, dose3],
            concentrationTimeline: concentrationTimeline
        )

        #expect(enhancedMarkers.count == 3, "Should create 3 enhanced dose markers")
        #expect(
            enhancedMarkers.allSatisfy { $0.concentrationAtDose != nil },
            "All markers should have concentration context")
        #expect(
            enhancedMarkers[0].concentrationAtDose == 10.0, "First marker should have concentration 10.0")
        #expect(
            enhancedMarkers[1].concentrationAtDose == 15.0, "Second marker should have concentration 15.0"
        )
        #expect(
            enhancedMarkers[2].concentrationAtDose == 20.0, "Third marker should have concentration 20.0")
    }

    // MARK: - Aggregation and Performance Tests

    /// Test efficient aggregation for large datasets with memory optimization
    @Test("Efficiently aggregate large datasets with memory optimization")
    func testEfficientlyAggregateLargeDatasetsWithMemoryOptimization() async throws {
        // Create large dataset (simulate 365 days of doses)
        let startDate = Date().addingTimeInterval(-365 * 24 * 3600)
        var largeDoseDataset: [Dose] = []

        for dayOffset in 0..<365 {
            let doseDate = startDate.addingTimeInterval(Double(dayOffset) * 24 * 3600)
            let dose = Dose(amount: 1.0, timestamp: doseDate)
            largeDoseDataset.append(dose)
        }

        // Test aggregating by weekly periods
        let weeklyAggregation = processor.aggregateDosesByTimePeriod(
            largeDoseDataset,
            aggregationPeriod: .weekly,
            maxDataPoints: 52  // One year of weekly data points
        )

        #expect(weeklyAggregation.count <= 52, "Should aggregate to maximum 52 weekly data points")
        #expect(weeklyAggregation.count >= 50, "Should have at least 50 weeks of data")

        // Test aggregating by monthly periods
        let monthlyAggregation = processor.aggregateDosesByTimePeriod(
            largeDoseDataset,
            aggregationPeriod: .monthly,
            maxDataPoints: 12  // One year of monthly data points
        )

        #expect(monthlyAggregation.count <= 12, "Should aggregate to maximum 12 monthly data points")
        #expect(monthlyAggregation.count >= 10, "Should have at least 10 months of data")

        // Verify aggregation preserves total dose amounts
        let totalOriginalDoses = largeDoseDataset.reduce(0) { $0 + $1.amount }
        let totalAggregatedDoses = weeklyAggregation.reduce(0) { $0 + $1.totalAmount }

        #expect(
            abs(totalOriginalDoses - totalAggregatedDoses) < 0.01,
            "Aggregation should preserve total dose amounts")
    }

    /// Test adaptive density control for chart performance
    @Test("Apply adaptive density control for chart performance")
    func testApplyAdaptiveDensityControlForChartPerformance() async throws {
        // Create high-density concentration data (hourly points for 30 days)
        let startDate = Date().addingTimeInterval(-30 * 24 * 3600)
        var highDensityPoints: [ConcentrationPoint] = []

        for hourOffset in 0..<(30 * 24) {  // 720 hours = 30 days
            let pointDate = startDate.addingTimeInterval(Double(hourOffset) * 3600)
            let concentration = 10.0 + sin(Double(hourOffset) * 0.1) * 5.0  // Simulated concentration curve
            highDensityPoints.append(ConcentrationPoint(date: pointDate, concentration: concentration))
        }

        // Test adaptive density control to reduce to manageable chart size
        let optimizedPoints = processor.applyAdaptiveDensityControl(
            highDensityPoints,
            targetDataPoints: 100,
            preserveExtremes: true
        )

        #expect(optimizedPoints.count <= 100, "Should reduce to target data point count")
        #expect(optimizedPoints.count >= 90, "Should maintain reasonable data density")

        // Verify extremes are preserved
        let originalMin = highDensityPoints.min { $0.concentration < $1.concentration }?.concentration
        let originalMax = highDensityPoints.max { $0.concentration < $1.concentration }?.concentration
        let optimizedMin = optimizedPoints.min { $0.concentration < $1.concentration }?.concentration
        let optimizedMax = optimizedPoints.max { $0.concentration < $1.concentration }?.concentration

        #expect(
            abs((originalMin ?? 0) - (optimizedMin ?? 0)) < 1.0,
            "Should preserve minimum concentration extremes")
        #expect(
            abs((originalMax ?? 0) - (optimizedMax ?? 0)) < 1.0,
            "Should preserve maximum concentration extremes")
    }
}
