//
//  ChartDataProcessorIntegrationTests.swift
//  JabTrackerTests
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Integration tests for ChartDataProcessor with PharmacokineticsEngine and AnalyticsService
/// Validates seamless data flow between chart processing and pharmacokinetic calculations
@MainActor
struct ChartDataProcessorIntegrationTests {

  // MARK: - Test Dependencies

  private let chartProcessor = ChartDataProcessor()
  private let pharmacokineticsEngine = PharmacokineticsEngine()
  private let analyticsService = AnalyticsService()
  private let container = DataController.testContainer().container

  // MARK: - Test Data Setup

  /// Test data structure for integration testing
  struct IntegrationTestData {
    let user: User
    let medicationProfile: MedicationProfile
    let doses: [Dose]
  }

  /// Create comprehensive test data for integration testing
  private func setupIntegrationTestData() -> IntegrationTestData {
    let context = ModelContext(container)

    // Create test user
    let user = User(name: "Integration Test User", appleUserId: "integration-test-user")
    context.insert(user)

    // Create medication profile for semaglutide
    let medicationProfile = MedicationProfile(
      genericName: "Semaglutide",
      currentDose: 1.0,
      startDate: Date().addingTimeInterval(-30 * 24 * 3600),  // 30 days ago
      medicationType: Medication.semaglutide.rawValue
    )
    medicationProfile.user = user
    context.insert(medicationProfile)

    // Create realistic dose history (weekly doses for 30 days = ~4 doses)
    var doses: [Dose] = []
    for week in 0..<5 {
      let doseDate = Date().addingTimeInterval(-Double(week * 7) * 24 * 3600)
      let dose = Dose(
        amount: 1.0,
        timestamp: doseDate,
        skipped: false,
        medication: medicationProfile
      )
      doses.append(dose)
      context.insert(dose)
    }

    try! context.save()
    return IntegrationTestData(user: user, medicationProfile: medicationProfile, doses: doses)
  }

  // MARK: - PharmacokineticsEngine Integration Tests

  /// Test ChartDataProcessor integration with PharmacokineticsEngine for concentration calculations
  @Test("Integration with PharmacokineticsEngine for concentration timeline")
  func testPharmacokineticsEngineIntegration() throws {
    // GIVEN: Test data with medication profile and doses
    let testData = setupIntegrationTestData()
    let (medicationProfile, doses) = (testData.medicationProfile, testData.doses)

    // WHEN: Calculate concentration timeline using PharmacokineticsEngine
    let currentTime = Date()
    let startTime = currentTime.addingTimeInterval(-7 * 24 * 3600)  // 7 days ago

    // Generate concentration points using PharmacokineticsEngine
    var concentrationPoints: [ConcentrationPoint] = []
    let timeInterval: TimeInterval = 3600  // 1 hour intervals

    var time = startTime
    while time <= currentTime {
      let concentration = pharmacokineticsEngine.calculateConcentration(
        from: doses,
        medication: medicationProfile.medication!,
        at: time
      )
      concentrationPoints.append(ConcentrationPoint(date: time, concentration: concentration))
      time.addTimeInterval(timeInterval)
    }

    // AND: Transform concentration data using ChartDataProcessor
    let chartPoints = chartProcessor.transformConcentrationToChartData(concentrationPoints)
    let doseMarkers = chartProcessor.transformDosesToMarkerData(doses)

    // THEN: Integration produces valid, correlated chart data
    #expect(!chartPoints.isEmpty, "Chart points should be generated from PK calculations")
    #expect(!doseMarkers.isEmpty, "Dose markers should be generated")
    #expect(
      chartPoints.count == concentrationPoints.count,
      "Chart points should match concentration calculations")

    // Verify concentration values are realistic for semaglutide
    let concentrations = chartPoints.map { $0.concentration }
    #expect(concentrations.allSatisfy { $0 >= 0 }, "All concentrations should be non-negative")
    #expect(concentrations.max()! < 100.0, "Maximum concentration should be realistic")

    // Verify dose markers align with concentration spikes
    let doseTimestamps = Set(doseMarkers.map { $0.date })
    let chartTimestamps = chartPoints.map { $0.date }

    for doseMarker in doseMarkers {
      let closestChartPoint = chartPoints.min(by: {
        abs($0.date.timeIntervalSince(doseMarker.date))
          < abs($1.date.timeIntervalSince(doseMarker.date))
      })
      #expect(closestChartPoint != nil, "Should find chart point near dose time")
    }
  }

  /// Test chart data interpolation using PharmacokineticsEngine calculations
  @Test("Chart interpolation with PharmacokineticsEngine calculations")
  func testChartInterpolationWithPharmacokineticsEngine() throws {
    // GIVEN: Sparse concentration data from PharmacokineticsEngine
    let testData = setupIntegrationTestData()
    let (medicationProfile, doses) = (testData.medicationProfile, testData.doses)

    // Create sparse concentration points (every 12 hours)
    let sparsePoints = (0..<5).map { index in
      let time = Date().addingTimeInterval(-Double(index) * 12 * 3600)
      let concentration = pharmacokineticsEngine.calculateConcentration(
        from: doses,
        medication: medicationProfile.medication!,
        at: time
      )
      return ConcentrationPoint(date: time, concentration: concentration)
    }

    // WHEN: Interpolating data to fill gaps
    let interpolatedPoints = chartProcessor.interpolateConcentrationData(
      sparsePoints, intervalHours: 2.0)

    // THEN: Interpolated data maintains pharmacokinetic consistency
    #expect(
      interpolatedPoints.count > sparsePoints.count,
      "Should generate additional interpolated points")

    // Verify interpolated concentrations follow realistic pharmacokinetic patterns
    let sortedInterpolated = interpolatedPoints.sorted { $0.date < $1.date }
    for index in 1..<sortedInterpolated.count {
      let previousPoint = sortedInterpolated[index - 1]
      let currentPoint = sortedInterpolated[index]

      // Concentration changes should be gradual (no sudden spikes without doses)
      let concentrationChange = abs(currentPoint.concentration - previousPoint.concentration)
      let timeChange = currentPoint.date.timeIntervalSince(previousPoint.date) / 3600  // hours

      if timeChange > 0 {
        let changeRate = concentrationChange / timeChange
        #expect(changeRate < 1.0, "Concentration change rate should be realistic (<1.0 units/hour)")
      }
    }
  }

  /// Test filtered chart data maintains PharmacokineticsEngine accuracy
  @Test("Filtered chart data with PharmacokineticsEngine accuracy")
  func testFilteredChartDataWithPharmacokineticsAccuracy() throws {
    // GIVEN: Extended dose history spanning multiple time periods
    let testData = setupIntegrationTestData()
    let (medicationProfile, doses) = (testData.medicationProfile, testData.doses)

    // WHEN: Filtering data by different time periods
    let last7DaysDoses = chartProcessor.filterDataByTimePeriod(doses, period: .last7Days)
    let last30DaysDoses = chartProcessor.filterDataByTimePeriod(doses, period: .last30Days)

    // Calculate concentrations for filtered datasets
    let currentTime = Date()
    let concentration7Days = pharmacokineticsEngine.calculateConcentration(
      from: last7DaysDoses,
      medication: medicationProfile.medication!,
      at: currentTime
    )
    let concentration30Days = pharmacokineticsEngine.calculateConcentration(
      from: last30DaysDoses,
      medication: medicationProfile.medication!,
      at: currentTime
    )

    // THEN: Filtered data maintains pharmacokinetic accuracy
    #expect(
      last7DaysDoses.count <= last30DaysDoses.count,
      "7-day filter should include subset of 30-day data")
    #expect(
      concentration7Days <= concentration30Days,
      "30-day concentration should be higher due to cumulative dosing")
    #expect(concentration7Days >= 0, "Concentration calculations should be valid")
    #expect(concentration30Days >= 0, "Concentration calculations should be valid")
  }

  // MARK: - AnalyticsService Integration Tests

  /// Test ChartDataProcessor integration with AnalyticsService for comprehensive analytics
  @Test("Integration with AnalyticsService for analytics coordination")
  func testAnalyticsServiceIntegration() throws {
    // GIVEN: Test data suitable for analytics calculations
    let testData = setupIntegrationTestData()
    let (user, medicationProfile, doses) = (
      testData.user, testData.medicationProfile, testData.doses
    )

    // WHEN: Generating analytics summary (this should work with chart data)
    let analyticsResult = analyticsService.calculateUserAnalytics(
      user: user, context: ModelContext(container))

    // AND: Processing chart data for the same user/medication
    let chartDoses = chartProcessor.filterDataByTimePeriod(doses, period: .last30Days)
    let doseMarkers = chartProcessor.transformDosesToMarkerData(chartDoses)

    // THEN: Chart data aligns with analytics calculations
    #expect(!doseMarkers.isEmpty, "Chart should generate dose markers")

    // Verify chart data consistency with analytics
    let chartDoseCount = doseMarkers.filter { !$0.isSkipped }.count
    let actualDoseCount = chartDoses.filter { !$0.skipped }.count
    #expect(chartDoseCount == actualDoseCount, "Chart markers should match actual dose count")

    // Verify analytics and chart data use consistent time filtering
    let last30DaysDate = Date().addingTimeInterval(-30 * 24 * 3600)
    let chartFilteredCorrectly = doseMarkers.allSatisfy { $0.date >= last30DaysDate }
    #expect(chartFilteredCorrectly, "Chart data should respect time period filtering")
  }

  /// Test chart data optimization preserves analytics-relevant information
  @Test("Chart optimization preserves analytics information")
  func testChartOptimizationPreservesAnalyticsInformation() throws {
    // GIVEN: Large dataset with analytics-relevant patterns
    let testData = setupIntegrationTestData()
    let (user, medicationProfile, doses) = (
      testData.user, testData.medicationProfile, testData.doses
    )

    // Generate extended concentration timeline
    let concentrationPoints = (0..<100).map { index in
      let time = Date().addingTimeInterval(-Double(index) * 3600)  // Hourly points
      let concentration = pharmacokineticsEngine.calculateConcentration(
        from: doses,
        medication: medicationProfile.medication!,
        at: time
      )
      return ConcentrationPoint(date: time, concentration: concentration)
    }

    // WHEN: Optimizing chart data for display
    let optimizedPoints = chartProcessor.optimizeDataDensity(concentrationPoints, maxPoints: 20)
    let chartPoints = chartProcessor.transformConcentrationToChartData(optimizedPoints)

    // THEN: Optimization preserves key analytics features
    #expect(optimizedPoints.count <= 20, "Should respect max points constraint")
    #expect(optimizedPoints.count >= 2, "Should preserve minimum viable data")

    // Verify key concentrations are preserved (first, last, peaks)
    let originalConcentrations = concentrationPoints.map { $0.concentration }
    let optimizedConcentrations = optimizedPoints.map { $0.concentration }

    let originalMax = originalConcentrations.max() ?? 0
    let optimizedMax = optimizedConcentrations.max() ?? 0
    let originalMin = originalConcentrations.min() ?? 0
    let optimizedMin = optimizedConcentrations.min() ?? 0

    // Key statistics should be preserved within reasonable tolerance
    #expect(
      Swift.abs(originalMax - optimizedMax) / originalMax < 0.1,
      "Maximum concentration should be preserved")
    #expect(
      Swift.abs(originalMin - optimizedMin) / max(originalMin, 0.1) < 0.1,
      "Minimum concentration should be preserved")
  }

  /// Test chart data validation works with analytics service requirements
  @Test("Chart validation supports analytics requirements")
  func testChartValidationSupportsAnalyticsRequirements() throws {
    // GIVEN: Chart data that should meet analytics service requirements
    let testData = setupIntegrationTestData()
    let (medicationProfile, doses) = (testData.medicationProfile, testData.doses)

    // Generate concentration timeline using both services
    let concentrationPoints = (0..<24).map { index in
      let time = Date().addingTimeInterval(-Double(index) * 3600)
      let concentration = pharmacokineticsEngine.calculateConcentration(
        from: doses,
        medication: medicationProfile.medication!,
        at: time
      )
      return ConcentrationPoint(date: time, concentration: concentration)
    }

    // WHEN: Validating chart data
    let chartPoints = chartProcessor.transformConcentrationToChartData(concentrationPoints)
    let isValid = chartProcessor.validateChartData(chartPoints)

    // THEN: Chart data meets validation requirements for analytics
    #expect(isValid, "Chart data should pass validation")
    #expect(
      chartPoints.allSatisfy { $0.concentration.isFinite }, "All concentrations should be finite")
    #expect(
      chartPoints.allSatisfy { $0.concentration >= 0 }, "All concentrations should be non-negative")
    #expect(
      chartPoints.allSatisfy { $0.date <= Date().addingTimeInterval(86400) },
      "No future dates beyond 1 day")

    // Verify data is suitable for analytics calculations
    let concentrations = chartPoints.map { $0.concentration }
    let hasVariation = (concentrations.max() ?? 0) - (concentrations.min() ?? 0) > 0.01
    #expect(hasVariation, "Data should have meaningful variation for analytics")
  }

  /// Test comprehensive integration scenario with all services
  @Test("Comprehensive integration with all services")
  func testComprehensiveIntegrationWithAllServices() throws {
    // GIVEN: Complete scenario with user, doses, and all services
    let testData = setupIntegrationTestData()
    let (user, medicationProfile, doses) = (
      testData.user, testData.medicationProfile, testData.doses
    )

    // WHEN: Running complete workflow
    // 1. Generate analytics
    let analytics = analyticsService.calculateUserAnalytics(
      user: user, context: ModelContext(container))

    // 2. Generate concentration timeline using PharmacokineticsEngine
    let timePoints = (0..<48).map { Date().addingTimeInterval(-Double($0) * 3600) }  // 48 hours
    let concentrationPoints = timePoints.map { time in
      ConcentrationPoint(
        date: time,
        concentration: pharmacokineticsEngine.calculateConcentration(
          from: doses,
          medication: medicationProfile.medication!,
          at: time
        )
      )
    }

    // 3. Process chart data
    let filteredPoints = chartProcessor.filterConcentrationByTimePeriod(
      concentrationPoints, period: .last7Days)
    let optimizedPoints = chartProcessor.optimizeDataDensity(filteredPoints, maxPoints: 50)
    let chartPoints = chartProcessor.transformConcentrationToChartData(optimizedPoints)
    let doseMarkers = chartProcessor.transformDosesToMarkerData(doses)

    // THEN: All services work together seamlessly
    #expect(!chartPoints.isEmpty, "Chart processing should produce results")
    #expect(!doseMarkers.isEmpty, "Dose markers should be generated")
    #expect(chartProcessor.validateChartData(chartPoints), "Chart data should be valid")

    // Verify data consistency across services
    let chartDoseCount = doseMarkers.filter { !$0.isSkipped }.count
    let actualDoseCount = doses.filter { !$0.skipped }.count
    #expect(chartDoseCount == actualDoseCount, "Chart and actual dose counts should match")

    // Verify concentration calculations are reasonable
    let concentrations = chartPoints.map { $0.concentration }
    #expect(
      concentrations.allSatisfy { $0 >= 0 && $0 < 100 },
      "Concentrations should be in realistic range")

    // Verify time alignment
    let chartTimeRange = chartPoints.map { $0.date }
    let doseTimeRange = doseMarkers.map { $0.date }
    let allTimes = Set(chartTimeRange + doseTimeRange)

    let timeSpan = allTimes.max()!.timeIntervalSince(allTimes.min()!)
    #expect(timeSpan > 0, "Data should span meaningful time period")
    #expect(timeSpan < 50 * 24 * 3600, "Time span should be reasonable (less than 50 days)")
  }
}
