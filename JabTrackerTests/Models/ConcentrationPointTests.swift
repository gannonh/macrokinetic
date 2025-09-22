//
//  ConcentrationPointTests.swift
//  JabTracker
//

import Foundation
import Testing

@testable import JabTracker

@Suite("ConcentrationPoint Model Tests")
struct ConcentrationPointTests {

  // MARK: - Test Data

  private var testDate: Date {
    Calendar.current.date(
      from: DateComponents(year: 2024, month: 1, day: 15, hour: 10, minute: 30))!
  }

  private var testConcentration: Double { 2.5 }

  private func createTestPoint() -> ConcentrationPoint {
    ConcentrationPoint(date: testDate, concentration: testConcentration)
  }

  // MARK: - Initialization Tests

  @Test("ConcentrationPoint initialization")
  func concentrationPointInitialization() {
    let point = createTestPoint()

    #expect(point.date == testDate)
    #expect(point.concentration == testConcentration)
  }

  // MARK: - Identifiable Tests

  @Test("ConcentrationPoint id property")
  func concentrationPointId() {
    let point = createTestPoint()

    #expect(point.id == testDate)
  }

  // MARK: - Comparable Tests

  @Test("ConcentrationPoint comparison by date")
  func concentrationPointComparison() {
    let earlierDate = Calendar.current.date(byAdding: .hour, value: -1, to: testDate)!
    let laterDate = Calendar.current.date(byAdding: .hour, value: 1, to: testDate)!

    let earlierPoint = ConcentrationPoint(date: earlierDate, concentration: 1.0)
    let currentPoint = createTestPoint()
    let laterPoint = ConcentrationPoint(date: laterDate, concentration: 3.0)

    #expect(earlierPoint < currentPoint)
    #expect(currentPoint < laterPoint)
    #expect(!(laterPoint < earlierPoint))
  }

  @Test("ConcentrationPoint sorting by date")
  func concentrationPointSorting() {
    let dates = [
      Calendar.current.date(byAdding: .hour, value: 2, to: testDate)!,
      testDate,
      Calendar.current.date(byAdding: .hour, value: -1, to: testDate)!,
    ]

    let points = dates.map { ConcentrationPoint(date: $0, concentration: 1.0) }
    let sortedPoints = points.sorted()

    #expect(sortedPoints[0].date < sortedPoints[1].date)
    #expect(sortedPoints[1].date < sortedPoints[2].date)
  }

  // MARK: - Display Property Tests

  @Test("ConcentrationPoint concentration display formatting")
  func concentrationDisplay() {
    let point = createTestPoint()

    #expect(point.concentrationDisplay == "2.50")

    // Test different concentration values
    let highPrecisionPoint = ConcentrationPoint(date: testDate, concentration: 1.23456)
    #expect(highPrecisionPoint.concentrationDisplay == "1.23")

    let zeroPoint = ConcentrationPoint(date: testDate, concentration: 0.0)
    #expect(zeroPoint.concentrationDisplay == "0.00")

    let integerPoint = ConcentrationPoint(date: testDate, concentration: 5.0)
    #expect(integerPoint.concentrationDisplay == "5.00")
  }

  @Test("ConcentrationPoint date display formatting")
  func dateDisplay() {
    let point = createTestPoint()
    let displayString = point.dateDisplay

    // Verify the format contains date and time components
    #expect(
      displayString.contains("1/15/24") || displayString.contains("15/1/24")
        || displayString.contains("2024"))
    #expect(displayString.contains("10:30") || displayString.contains("10.30"))
  }

  // MARK: - Codable Tests

  @Test("ConcentrationPoint Codable encoding and decoding")
  func concentrationPointCodable() throws {
    let originalPoint = createTestPoint()

    // Encode
    let encoded = try JSONEncoder().encode(originalPoint)

    // Decode
    let decodedPoint = try JSONDecoder().decode(ConcentrationPoint.self, from: encoded)

    #expect(decodedPoint.date.timeIntervalSince1970 == originalPoint.date.timeIntervalSince1970)
    #expect(decodedPoint.concentration == originalPoint.concentration)
  }

  // MARK: - Equatable Tests

  @Test("ConcentrationPoint equality")
  func concentrationPointEquality() {
    let point1 = createTestPoint()
    let point2 = createTestPoint()
    let differentDatePoint = ConcentrationPoint(
      date: Calendar.current.date(byAdding: .minute, value: 1, to: testDate)!,
      concentration: testConcentration
    )
    let differentConcentrationPoint = ConcentrationPoint(
      date: testDate,
      concentration: testConcentration + 1.0
    )

    #expect(point1 == point2)
    #expect(point1 != differentDatePoint)
    #expect(point1 != differentConcentrationPoint)
  }

  // MARK: - Hashable Tests

  @Test("ConcentrationPoint hashability")
  func concentrationPointHashability() {
    let point1 = createTestPoint()
    let point2 = createTestPoint()
    let differentPoint = ConcentrationPoint(
      date: Calendar.current.date(byAdding: .minute, value: 1, to: testDate)!,
      concentration: testConcentration
    )

    #expect(point1.hashValue == point2.hashValue)
    #expect(point1.hashValue != differentPoint.hashValue)

    // Test in Set
    let pointSet: Set<ConcentrationPoint> = [point1, point2, differentPoint]
    #expect(pointSet.count == 2)  // point1 and point2 should be considered the same
  }

  // MARK: - Edge Case Tests

  @Test("ConcentrationPoint with extreme values")
  func concentrationPointExtremeValues() {
    let futureDate = Date(timeIntervalSinceNow: 86400 * 365)  // 1 year in future
    let pastDate = Date(timeIntervalSinceNow: -86400 * 365)  // 1 year in past

    let futurePoint = ConcentrationPoint(
      date: futureDate, concentration: Double.greatestFiniteMagnitude)
    let pastPoint = ConcentrationPoint(date: pastDate, concentration: 0.0)

    #expect(futurePoint.date == futureDate)
    #expect(futurePoint.concentration == Double.greatestFiniteMagnitude)
    #expect(pastPoint.date == pastDate)
    #expect(pastPoint.concentration == 0.0)

    // Test display formatting with extreme values
    #expect(pastPoint.concentrationDisplay == "0.00")
    #expect(
      futurePoint.concentrationDisplay.contains("e") || futurePoint.concentrationDisplay.count > 5)  // Scientific notation or very large number
  }
}
