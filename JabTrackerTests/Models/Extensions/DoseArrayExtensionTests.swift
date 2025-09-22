//
//  DoseArrayExtensionTests.swift
//  JabTrackerTests
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
@Suite("Dose Array Extension Tests")
struct DoseArrayExtensionTests {
  // MARK: - Helper Methods

  private func createTestDoses(in context: ModelContext) -> [Dose] {
    let calendar = Calendar.current
    let semaglutide = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")
    let tirzepatide = MedicationProfile(genericName: "tirzepatide", brandName: "Mounjaro")
    context.insert(semaglutide)
    context.insert(tirzepatide)

    let dose1 = Dose(
      amount: 1.0,
      timestamp: calendar.date(from: DateComponents(year: 2024, month: 1, day: 15)) ?? Date())
    dose1.site = "Left arm"
    dose1.notes = "Morning dose"
    dose1.medication = semaglutide
    context.insert(dose1)

    let dose2 = Dose(
      amount: 2.5,
      timestamp: calendar.date(from: DateComponents(year: 2024, month: 1, day: 16)) ?? Date())
    dose2.site = "Right thigh"
    dose2.notes = "Evening dose"
    dose2.skipped = true
    dose2.medication = tirzepatide
    context.insert(dose2)

    let dose3 = Dose(
      amount: 0.5,
      timestamp: calendar.date(from: DateComponents(year: 2024, month: 1, day: 17)) ?? Date())
    dose3.site = "Abdomen"
    dose3.medication = semaglutide
    context.insert(dose3)

    let dose4 = Dose(
      amount: 1.5,
      timestamp: calendar.date(from: DateComponents(year: 2024, month: 1, day: 18)) ?? Date())
    dose4.site = "Left arm"
    dose4.notes = "Reduced dose"
    dose4.medication = semaglutide
    context.insert(dose4)

    try? context.save()

    return [dose1, dose2, dose3, dose4]
  }

  // MARK: - Filtering Tests

  @Test("Filtered method works with search text")
  func filteredWithSearchText() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext
    let doses = self.createTestDoses(in: context)

    let morningResults = doses.filtered(searchText: "morning")
    #expect(morningResults.count == 1)
    #expect(morningResults.first?.notes == "Morning dose")

    let armResults = doses.filtered(searchText: "arm")
    #expect(armResults.count == 2)

    let emptyResults = doses.filtered(searchText: "nonexistent")
    #expect(emptyResults.isEmpty)
  }

  @Test("Filtered method works with medication filter")
  func filteredWithMedication() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext
    let doses = self.createTestDoses(in: context)

    let semaglutideResults = doses.filtered(medication: "semaglutide")
    #expect(semaglutideResults.count == 3)

    let tirzepatideResults = doses.filtered(medication: "tirzepatide")
    #expect(tirzepatideResults.count == 1)

    let nonexistentResults = doses.filtered(medication: "liraglutide")
    #expect(nonexistentResults.isEmpty)
  }

  @Test("Filtered method works with injection site filter")
  func filteredWithInjectionSite() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext
    let doses = self.createTestDoses(in: context)

    let leftArmResults = doses.filtered(injectionSite: "Left arm")
    #expect(leftArmResults.count == 2)

    let thighResults = doses.filtered(injectionSite: "Right thigh")
    #expect(thighResults.count == 1)

    let nonexistentResults = doses.filtered(injectionSite: "Right arm")
    #expect(nonexistentResults.isEmpty)
  }

  @Test("Filtered method works with date range filter")
  func filteredWithDateRange() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext
    let doses = self.createTestDoses(in: context)
    let calendar = Calendar.current

    guard let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 16)),
      let endDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 17))
    else {
      Issue.record("Failed to create test dates")
      return
    }
    let dateInterval = DateInterval(start: startDate, end: endDate)

    let results = doses.filtered(dateRange: dateInterval)
    #expect(results.count == 2)  // Jan 16 and Jan 17
  }

  @Test("Filtered method works with skipped filter")
  func filteredWithSkippedFilter() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext
    let doses = self.createTestDoses(in: context)

    let includingSkipped = doses.filtered(includeSkipped: true)
    #expect(includingSkipped.count == 4)

    let excludingSkipped = doses.filtered(includeSkipped: false)
    #expect(excludingSkipped.count == 3)  // One dose is skipped
  }

  @Test("Filtered method works with amount range filter")
  func filteredWithAmountRange() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext
    let doses = self.createTestDoses(in: context)

    let lowDoseRange = 0.5...1.5
    let lowDoseResults = doses.filtered(amountRange: lowDoseRange)
    #expect(lowDoseResults.count == 3)  // 1.0, 0.5, 1.5

    let highDoseRange = 2.0...3.0
    let highDoseResults = doses.filtered(amountRange: highDoseRange)
    #expect(highDoseResults.count == 1)  // 2.5
  }

  @Test("Filtered method works with multiple filters")
  func filteredWithMultipleFilters() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext
    let doses = self.createTestDoses(in: context)

    let results = doses.filtered(
      searchText: "arm",
      medication: "semaglutide",
      includeSkipped: false)
    #expect(results.count == 2)  // Both left arm semaglutide doses, excluding skipped
  }

  // MARK: - Sorting Tests

  @Test("Sort by timestamp ascending works correctly")
  func sortByTimestampAscending() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext
    let doses = self.createTestDoses(in: context)
    let sorted = doses.sortedByTimestamp(ascending: true)

    #expect(sorted.count == 4)
    // Should be sorted from earliest to latest (Jan 15, 16, 17, 18)
    for index in 0..<sorted.count - 1 {
      #expect(sorted[index].timestamp <= sorted[index + 1].timestamp)
    }
  }

  @Test("Sort by timestamp descending works correctly")
  func sortByTimestampDescending() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext
    let doses = self.createTestDoses(in: context)
    let sorted = doses.sortedByTimestamp(ascending: false)

    #expect(sorted.count == 4)
    // Should be sorted from latest to earliest (Jan 18, 17, 16, 15)
    for index in 0..<sorted.count - 1 {
      #expect(sorted[index].timestamp >= sorted[index + 1].timestamp)
    }
  }

  @Test("Sort by amount ascending works correctly")
  func sortByAmountAscending() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext
    let doses = self.createTestDoses(in: context)
    let sorted = doses.sortedByAmount(ascending: true)

    #expect(sorted.count == 4)
    // Should be sorted from smallest to largest amount (0.5, 1.0, 1.5, 2.5)
    for index in 0..<sorted.count - 1 {
      #expect(sorted[index].amount <= sorted[index + 1].amount)
    }
  }

  @Test("Sort by amount descending works correctly")
  func sortByAmountDescending() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext
    let doses = self.createTestDoses(in: context)
    let sorted = doses.sortedByAmount(ascending: false)

    #expect(sorted.count == 4)
    // Should be sorted from largest to smallest amount (2.5, 1.5, 1.0, 0.5)
    for index in 0..<sorted.count - 1 {
      #expect(sorted[index].amount >= sorted[index + 1].amount)
    }
  }

  // MARK: - Grouping Tests

  @Test("Group by date works correctly")
  func groupByDate() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext
    let doses = self.createTestDoses(in: context)
    let grouped = doses.groupedByDate()

    #expect(grouped.count == 4)  // 4 different dates

    // Check that each group has the correct number of doses
    for (_, dosesInGroup) in grouped {
      #expect(dosesInGroup.count == 1)  // Each day has one dose in our test data
    }

    // Check that dates are sorted in descending order (most recent first)
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none

    for index in 0..<grouped.count - 1 {
      guard let firstDate = formatter.date(from: grouped[index].0),
        let secondDate = formatter.date(from: grouped[index + 1].0)
      else {
        Issue.record("Failed to parse dates in grouped results")
        continue
      }
      #expect(firstDate >= secondDate)
    }
  }

  @Test("Group by date with multiple doses per day")
  func groupByDateMultipleDosesPerDay() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext

    let calendar = Calendar.current
    guard let sameDay = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15)),
      let sameDayEvening = calendar.date(
        from: DateComponents(year: 2024, month: 1, day: 15, hour: 18))
    else {
      Issue.record("Failed to create test dates")
      return
    }

    let dose1 = Dose(amount: 1.0, timestamp: sameDay)
    let dose2 = Dose(amount: 0.5, timestamp: sameDayEvening)
    context.insert(dose1)
    context.insert(dose2)
    try context.save()

    let doses = [dose1, dose2]
    let grouped = doses.groupedByDate()

    #expect(grouped.count == 1)  // Only one date group
    #expect(grouped.first?.1.count == 2)  // Two doses in that group

    // Check that doses within the group are sorted by timestamp (descending)
    guard let dosesInGroup = grouped.first?.1 else {
      Issue.record("No grouped doses found")
      return
    }
    #expect(dosesInGroup[0].timestamp >= dosesInGroup[1].timestamp)
  }

  // MARK: - Statistics Tests

  @Test("Medication counts work correctly")
  func testMedicationCounts() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext
    let doses = self.createTestDoses(in: context)
    let counts = doses.medicationCounts

    #expect(counts["semaglutide"] == 3)
    #expect(counts["tirzepatide"] == 1)
    #expect(counts.keys.count == 2)
  }

  @Test("Medication counts handle nil medication")
  func medicationCountsWithNilMedication() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext

    let semaglutide = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")
    context.insert(semaglutide)

    let dose1 = Dose(amount: 1.0, timestamp: Date())
    dose1.medication = semaglutide
    context.insert(dose1)

    let dose2 = Dose(amount: 1.0, timestamp: Date())
    // No medication
    context.insert(dose2)

    try context.save()

    let doses = [dose1, dose2]
    let counts = doses.medicationCounts

    #expect(counts["semaglutide"] == 1)
    #expect(counts["Unknown"] == 1)
    #expect(counts.keys.count == 2)
  }

  @Test("Injection site counts work correctly")
  func testInjectionSiteCounts() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext
    let doses = self.createTestDoses(in: context)
    let counts = doses.injectionSiteCounts

    #expect(counts["Left arm"] == 2)
    #expect(counts["Right thigh"] == 1)
    #expect(counts["Abdomen"] == 1)
    #expect(counts.keys.count == 3)
  }

  @Test("Injection site counts handle nil site")
  func injectionSiteCountsWithNilSite() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext

    let dose1 = Dose(amount: 1.0, timestamp: Date())
    dose1.site = "Left arm"
    context.insert(dose1)

    let dose2 = Dose(amount: 1.0, timestamp: Date())
    // No site
    context.insert(dose2)

    try context.save()

    let doses = [dose1, dose2]
    let counts = doses.injectionSiteCounts

    #expect(counts["Left arm"] == 1)
    #expect(counts["Unknown"] == 1)
    #expect(counts.keys.count == 2)
  }

  // MARK: - Edge Cases

  @Test("Empty array filtering works correctly")
  func emptyArrayFiltering() throws {
    let emptyDoses: [Dose] = []

    let filtered = emptyDoses.filtered(searchText: "test")
    #expect(filtered.isEmpty)

    let sorted = emptyDoses.sortedByTimestamp()
    #expect(sorted.isEmpty)

    let grouped = emptyDoses.groupedByDate()
    #expect(grouped.isEmpty)

    let medicationCounts = emptyDoses.medicationCounts
    #expect(medicationCounts.isEmpty)

    let siteCounts = emptyDoses.injectionSiteCounts
    #expect(siteCounts.isEmpty)
  }

  @Test("Single dose array works correctly")
  func singleDoseArray() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext

    let dose = Dose(amount: 1.0, timestamp: Date())
    dose.site = "Left arm"
    context.insert(dose)
    try context.save()

    let singleDose = [dose]

    let filtered = singleDose.filtered(searchText: "arm")
    #expect(filtered.count == 1)

    let sorted = singleDose.sortedByTimestamp()
    #expect(sorted.count == 1)

    let grouped = singleDose.groupedByDate()
    #expect(grouped.count == 1)
    #expect(grouped.first?.1.count == 1)
  }
}
