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
    let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    return try! ModelContainer(
      for: User.self, Dose.self, MedicationProfile.self, configurations: config)
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

    try! context.save()
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

    try! context.save()
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

    try! context.save()

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

    try! context.save()

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
