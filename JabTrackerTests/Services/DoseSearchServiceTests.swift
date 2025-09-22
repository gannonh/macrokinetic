//
//  DoseSearchServiceTests.swift
//  JabTrackerTests
//
//  Unit tests for DoseSearchService search algorithm
//  Defines contracts for search functionality, advanced queries, and filtering
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
struct DoseSearchServiceTests {
  // Create an in-memory model container for testing without CloudKit
  private var modelContainer: ModelContainer {
    let schema = Schema([
      User.self,
      Dose.self,
      MedicationProfile.self,
      DoseTitration.self,
    ])

    // Disable CloudKit for testing - same logic as DataController
    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: true,
      cloudKitDatabase: .none)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }

  // MARK: - Basic Search Tests

  @Test("Search returns empty array for empty input")
  func searchWithEmptyInput() throws {
    // Given: Doses and empty search text
    let doses = self.createTestDoses()

    // When: Searching with empty text
    let results = DoseSearchService.searchDoses(doses: doses, searchText: "")

    // Then: All doses are returned (no filtering applied)
    #expect(results.count == doses.count)
    #expect(results == doses)
  }

  @Test("Search filters doses by notes content")
  func searchInNotes() throws {
    // Given: Doses with different notes
    let morningDose = self.createTestDose(notes: "morning injection")
    let eveningDose = self.createTestDose(notes: "evening dose")
    let noNotesDose = self.createTestDose(notes: nil)

    let doses = [morningDose, eveningDose, noNotesDose]

    // When: Searching for "morning"
    let results = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "morning",
      scope: .notes)

    // Then: Only matching dose is returned
    #expect(results.count == 1)
    #expect(results[0].notes == "morning injection")
  }

  @Test("Search filters doses by medication name")
  func searchInMedication() throws {
    // Given: Doses with different medications using model context
    let container = self.modelContainer
    let context = container.mainContext

    let semaglutideProfile = self.createTestMedicationProfile(
      genericName: "Semaglutide",
      brandName: "Ozempic")
    let tirzepatideProfile = self.createTestMedicationProfile(
      genericName: "Tirzepatide",
      brandName: "Mounjaro")

    let semaglutideDose = self.createTestDose(amount: 1.0)
    let tirzepatideDose = self.createTestDose(amount: 2.0)
    let noMedicationDose = self.createTestDose(amount: 3.0)

    context.insert(semaglutideProfile)
    context.insert(tirzepatideProfile)
    context.insert(semaglutideDose)
    context.insert(tirzepatideDose)
    context.insert(noMedicationDose)

    // Set relationships after insertion
    semaglutideDose.medication = semaglutideProfile
    tirzepatideDose.medication = tirzepatideProfile

    try context.save()

    let doses = [semaglutideDose, tirzepatideDose, noMedicationDose]

    // When: Searching for generic name
    let genericResults = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "Semaglutide",
      scope: .medication)

    // Then: Only semaglutide dose is returned
    #expect(genericResults.count == 1)
    #expect(genericResults[0].medication?.genericName == "Semaglutide")

    // When: Searching for brand name
    let brandResults = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "Ozempic",
      scope: .medication)

    // Then: Only ozempic dose is returned
    #expect(brandResults.count == 1)
    #expect(brandResults[0].medication?.brandName == "Ozempic")
  }

  @Test("Search filters doses by injection site")
  func searchInInjectionSite() throws {
    // Given: Doses with different injection sites
    let thighDose = self.createTestDose(site: "Thigh")
    let abdomenDose = self.createTestDose(site: "Abdomen")
    let upperArmDose = self.createTestDose(site: "Upper Arm")
    let noSiteDose = self.createTestDose(site: nil)

    let doses = [thighDose, abdomenDose, upperArmDose, noSiteDose]

    // When: Searching for "Thigh"
    let results = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "Thigh",
      scope: .injectionSite)

    // Then: Only thigh dose is returned
    #expect(results.count == 1)
    #expect(results[0].site == "Thigh")
  }

  @Test("Search filters doses by amount")
  func searchInAmount() throws {
    // Given: Doses with different amounts
    let dose1 = self.createTestDose(amount: 1.0)
    let doseOnePointFive = self.createTestDose(amount: 1.5)
    let dose2 = self.createTestDose(amount: 2.0)

    let doses = [dose1, doseOnePointFive, dose2]

    // When: Searching for "1.0"
    let exactResults = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "1.0",
      scope: .amount)

    // Then: Only 1.0 dose is returned
    #expect(exactResults.count == 1)
    #expect(exactResults[0].amount == 1.0)

    // When: Searching for partial match "1."
    let partialResults = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "1.",
      scope: .amount)

    // Then: Both 1.0 and 1.5 doses are returned
    #expect(partialResults.count == 2)
    #expect(partialResults.contains(where: { $0.amount == 1.0 }))
    #expect(partialResults.contains(where: { $0.amount == 1.5 }))
  }

  @Test("Search filters doses by date")
  func searchInDate() throws {
    // Given: Doses with different dates
    let calendar = Calendar.current
    let today = Date()
    let january1 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
    let december31 = calendar.date(from: DateComponents(year: 2024, month: 12, day: 31))!

    let todayDose = self.createTestDose(timestamp: today)
    let januaryDose = self.createTestDose(timestamp: january1)
    let decemberDose = self.createTestDose(timestamp: december31)

    let doses = [todayDose, januaryDose, decemberDose]

    // When: Searching for year "2024"
    let yearResults = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "2024",
      scope: .date)

    // Then: 2024 doses are returned
    #expect(yearResults.count >= 1)  // At least the 2024 doses
    #expect(yearResults.contains(where: { $0.timestamp == january1 }))
    #expect(yearResults.contains(where: { $0.timestamp == december31 }))

    // When: Searching for month "1"
    let monthResults = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "1",
      scope: .date)

    // Then: January dose is included
    #expect(monthResults.contains(where: { $0.timestamp == january1 }))
  }

  @Test("Search works across all fields when scope is .all")
  func searchInAllFields() throws {
    // Given: Doses with data in different fields using model context
    let container = self.modelContainer
    let context = container.mainContext

    let medicationProfile = self.createTestMedicationProfile(genericName: "Semaglutide")

    let notesDose = self.createTestDose(notes: "morning injection")
    let siteDose = self.createTestDose(site: "Thigh")
    let medicationDose = self.createTestDose(amount: 1.0)

    context.insert(medicationProfile)
    context.insert(notesDose)
    context.insert(siteDose)
    context.insert(medicationDose)

    // Set relationships after insertion
    medicationDose.medication = medicationProfile

    try context.save()

    let doses = [notesDose, siteDose, medicationDose]

    // When: Searching across all fields
    let morningResults = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "morning",
      scope: .all)

    let thighResults = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "Thigh",
      scope: .all)

    let semaglutideResults = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "Semaglutide",
      scope: .all)

    // Then: Each search finds its respective dose
    #expect(morningResults.count == 1)
    #expect(morningResults[0].notes == "morning injection")

    #expect(thighResults.count == 1)
    #expect(thighResults[0].site == "Thigh")

    #expect(semaglutideResults.count == 1)
    #expect(semaglutideResults[0].medication?.genericName == "Semaglutide")
  }

  // MARK: - Search Mode Tests

  @Test("Search mode .contains works correctly")
  func searchModeContains() throws {
    // Given: Dose with partial content
    let dose = self.createTestDose(notes: "morning injection")
    let doses = [dose]

    // When: Searching with contains mode
    let results = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "orn",
      mode: .contains)

    // Then: Dose is found
    #expect(results.count == 1)
    #expect(results[0].notes == "morning injection")
  }

  @Test("Search mode .exact works correctly")
  func searchModeExact() throws {
    // Given: Dose with specific content
    let dose = self.createTestDose(notes: "morning")
    let doses = [dose]

    // When: Searching with exact mode
    let exactMatch = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "morning",
      mode: .exact)

    let partialMatch = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "morn",
      mode: .exact)

    // Then: Only exact match is found
    #expect(exactMatch.count == 1)
    #expect(partialMatch.isEmpty)
  }

  @Test("Search mode .startsWith works correctly")
  func searchModeStartsWith() throws {
    // Given: Dose with specific content
    let dose = self.createTestDose(notes: "morning injection")
    let doses = [dose]

    // When: Searching with startsWith mode
    let startsWithMatch = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "morn",
      mode: .startsWith)

    let middleMatch = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "orn",
      mode: .startsWith)

    // Then: Only prefix match is found
    #expect(startsWithMatch.count == 1)
    #expect(middleMatch.isEmpty)
  }

  @Test("Search mode .endsWith works correctly")
  func searchModeEndsWith() throws {
    // Given: Dose with specific content
    let dose = self.createTestDose(notes: "morning injection")
    let doses = [dose]

    // When: Searching with endsWith mode
    let endsWithMatch = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "tion",
      mode: .endsWith)

    let beginningMatch = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "morn",
      mode: .endsWith)

    // Then: Only suffix match is found
    #expect(endsWithMatch.count == 1)
    #expect(beginningMatch.isEmpty)
  }

  @Test("Case sensitivity works correctly")
  func caseSensitivity() throws {
    // Given: Dose with mixed case content
    let dose = self.createTestDose(notes: "Morning Injection")
    let doses = [dose]

    // When: Case insensitive search (default)
    let caseInsensitiveResults = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "morning",
      caseSensitive: false)

    // Then: Match is found
    #expect(caseInsensitiveResults.count == 1)

    // When: Case sensitive search
    let caseSensitiveMatch = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "Morning",
      caseSensitive: true)

    let caseSensitiveNoMatch = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "morning",
      caseSensitive: true)

    // Then: Only exact case match is found
    #expect(caseSensitiveMatch.count == 1)
    #expect(caseSensitiveNoMatch.isEmpty)
  }

  // MARK: - Multiple Term Search Tests

  @Test("Multiple terms search with AND logic")
  func multipleTermsANDLogic() throws {
    // Given: Doses with various content
    let dose1 = self.createTestDose(notes: "morning injection thigh")
    let dose2 = self.createTestDose(notes: "morning dose abdomen")
    let dose3 = self.createTestDose(notes: "evening injection thigh")

    let doses = [dose1, dose2, dose3]

    // When: Searching with multiple terms (AND logic)
    let results = DoseSearchService.searchDosesWithMultipleTerms(
      doses: doses,
      searchTerms: ["morning", "thigh"])

    // Then: Only dose with both terms is returned
    #expect(results.count == 1)
    #expect(results[0].notes == "morning injection thigh")
  }

  @Test("Multiple terms search with OR logic")
  func multipleTermsORLogic() throws {
    // Given: Doses with various content
    let dose1 = self.createTestDose(notes: "morning injection")
    let dose2 = self.createTestDose(notes: "evening dose")
    let dose3 = self.createTestDose(notes: "afternoon medication")

    let doses = [dose1, dose2, dose3]

    // When: Searching with multiple terms (OR logic)
    let results = DoseSearchService.searchDosesWithAnyTerm(
      doses: doses,
      searchTerms: ["morning", "evening"])

    // Then: Doses with either term are returned
    #expect(results.count == 2)
    #expect(results.contains(where: { $0.notes == "morning injection" }))
    #expect(results.contains(where: { $0.notes == "evening dose" }))
  }

  // MARK: - Advanced Search Query Parsing Tests

  @Test("Parse advanced search with field-specific queries")
  func testParseAdvancedSearch() throws {
    // Given: Complex search query
    let query = "medication:semaglutide site:thigh amount:>1.0 \"exact phrase\" general term"

    // When: Parsing advanced search
    let searchQuery = DoseSearchService.parseAdvancedSearch(query)

    // Then: Query components are parsed correctly
    #expect(searchQuery.medicationFilter == "semaglutide")
    #expect(searchQuery.injectionSiteFilter == "thigh")
    #expect(searchQuery.exactPhrases.count == 1)
    #expect(searchQuery.exactPhrases[0] == "exact phrase")
    #expect(searchQuery.searchTerms.count == 2)
    #expect(searchQuery.searchTerms.contains("general"))
    #expect(searchQuery.searchTerms.contains("term"))

    // Amount filter
    if case let .greaterThan(amount) = searchQuery.amountFilter {
      #expect(amount == 1.0)
    } else {
      Issue.record("Amount filter should be .greaterThan(1.0)")
    }
  }

  @Test("Apply advanced search query to doses")
  func advancedSearchQueryApplication() throws {
    // Given: Doses with various data using model context
    let container = self.modelContainer
    let context = container.mainContext

    let semaglutideProfile = self.createTestMedicationProfile(genericName: "Semaglutide")
    let tirzepatideProfile = self.createTestMedicationProfile(genericName: "Tirzepatide")

    let matchingDose = self.createTestDose(
      amount: 1.5,
      site: "Thigh",
      notes: "morning exact phrase")

    let nonMatchingDose1 = self.createTestDose(
      amount: 0.5,  // Too low amount
      site: "Thigh",
      notes: "morning exact phrase")

    let nonMatchingDose2 = self.createTestDose(
      amount: 1.5,
      site: "Abdomen",  // Wrong site
      notes: "morning exact phrase")

    context.insert(semaglutideProfile)
    context.insert(tirzepatideProfile)
    context.insert(matchingDose)
    context.insert(nonMatchingDose1)
    context.insert(nonMatchingDose2)

    // Set relationships after insertion
    matchingDose.medication = semaglutideProfile
    nonMatchingDose1.medication = semaglutideProfile
    nonMatchingDose2.medication = semaglutideProfile

    try context.save()

    let doses = [matchingDose, nonMatchingDose1, nonMatchingDose2]

    // When: Creating and applying advanced query
    var searchQuery = SearchQuery()
    searchQuery.medicationFilter = "Semaglutide"
    searchQuery.injectionSiteFilter = "Thigh"
    searchQuery.amountFilter = .greaterThan(1.0)
    searchQuery.exactPhrases = ["exact phrase"]

    let results = DoseSearchService.searchWithAdvancedQuery(doses: doses, query: searchQuery)

    // Then: Only fully matching dose is returned
    #expect(
      results.count == 1,
      "Expected 1 result but got \(results.count). Medication names: \(doses.compactMap { $0.medication?.genericName })"
    )

    if !results.isEmpty {
      #expect(results[0].amount == 1.5)
      #expect(results[0].site == "Thigh")
      #expect(results[0].notes?.contains("exact phrase") == true)
      #expect(results[0].medication?.genericName == "Semaglutide")
    }
  }

  // MARK: - Amount Filter Tests

  @Test("Amount filter .equals works correctly")
  func amountFilterEquals() throws {
    // Given: Amount filter
    let filter = AmountFilter.equals(1.5)

    // Then: Exact match and tolerance match work
    #expect(filter.matches(1.5) == true)
    #expect(filter.matches(1.5001) == true)  // Within tolerance
    #expect(filter.matches(1.6) == false)
    #expect(filter.matches(1.0) == false)
  }

  @Test("Amount filter comparison operators work correctly")
  func amountFilterComparisons() throws {
    // Given: Various amount filters
    let greaterThan = AmountFilter.greaterThan(1.0)
    let lessThan = AmountFilter.lessThan(2.0)
    let greaterThanOrEqual = AmountFilter.greaterThanOrEqual(1.5)
    let lessThanOrEqual = AmountFilter.lessThanOrEqual(1.5)

    let testAmount = 1.5

    // Then: Comparisons work correctly
    #expect(greaterThan.matches(testAmount) == true)
    #expect(lessThan.matches(testAmount) == true)
    #expect(greaterThanOrEqual.matches(testAmount) == true)
    #expect(lessThanOrEqual.matches(testAmount) == true)

    // Edge cases
    #expect(greaterThan.matches(1.0) == false)
    #expect(lessThan.matches(2.0) == false)
    #expect(greaterThanOrEqual.matches(1.4999) == false)  // Just outside tolerance
    #expect(lessThanOrEqual.matches(1.5001) == true)  // Within tolerance
  }

  // MARK: - Date Filter Parsing Tests

  @Test("Date filter parsing handles various formats")
  func dateFilterParsing() throws {
    // This tests the private parseDateFilter method indirectly through parseAdvancedSearch

    // When: Parsing different date formats
    let yearQuery = DoseSearchService.parseAdvancedSearch("date:2024")
    let monthQuery = DoseSearchService.parseAdvancedSearch("date:2024-01")
    let dayQuery = DoseSearchService.parseAdvancedSearch("date:2024-01-15")

    // Then: Date filters are created appropriately
    #expect(yearQuery.dateFilter != nil)
    #expect(monthQuery.dateFilter != nil)
    #expect(dayQuery.dateFilter != nil)

    // Verify date intervals cover appropriate ranges
    if let yearInterval = yearQuery.dateFilter {
      let duration = yearInterval.duration
      #expect(duration > 300 * 24 * 3600)  // More than 300 days (approximate year)
    }

    if let monthInterval = monthQuery.dateFilter {
      let duration = monthInterval.duration
      #expect(duration < 32 * 24 * 3600)  // Less than 32 days (approximate month)
      #expect(duration > 27 * 24 * 3600)  // More than 27 days
    }

    if let dayInterval = dayQuery.dateFilter {
      let duration = dayInterval.duration
      #expect(duration == 24 * 3600)  // Exactly one day
    }
  }

  // MARK: - Query Tokenization Tests

  @Test("Query tokenization handles quoted strings correctly")
  func queryTokenization() throws {
    // Given: Complex query with quoted strings
    let query = "simple \"quoted string\" medication:test \"another quote\" final"

    // When: Parsing the query
    let searchQuery = DoseSearchService.parseAdvancedSearch(query)

    // Then: Quoted strings are preserved and other tokens are separate
    #expect(searchQuery.exactPhrases.count == 2)
    #expect(searchQuery.exactPhrases.contains("quoted string"))
    #expect(searchQuery.exactPhrases.contains("another quote"))

    #expect(searchQuery.searchTerms.count == 2)
    #expect(searchQuery.searchTerms.contains("simple"))
    #expect(searchQuery.searchTerms.contains("final"))

    #expect(searchQuery.medicationFilter == "test")
  }

  @Test("Empty and whitespace search terms are handled correctly")
  func emptySearchTermHandling() throws {
    // Given: Doses to search
    let doses = self.createTestDoses()

    // When: Searching with whitespace-only text
    let whitespaceResults = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "   ",
      scope: .all)

    let emptyResults = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "",
      scope: .all)

    // Then: All doses are returned (no filtering applied)
    #expect(whitespaceResults.count == doses.count)
    #expect(emptyResults.count == doses.count)
  }

  // MARK: - Performance and Edge Case Tests

  @Test("Search performance with large dataset")
  func searchPerformance() throws {
    // Given: Large number of doses
    var largeDoseSet: [Dose] = []
    for index in 0..<1000 {
      let dose = self.createTestDose(
        amount: Double(index % 10),
        site: index % 2 == 0 ? "Thigh" : "Abdomen",
        notes: "Dose number \(index)")
      largeDoseSet.append(dose)
    }

    // When: Performing search on large dataset
    let startTime = CFAbsoluteTimeGetCurrent()

    let results = DoseSearchService.searchDoses(
      doses: largeDoseSet,
      searchText: "500",
      scope: .all)

    let endTime = CFAbsoluteTimeGetCurrent()
    let elapsedTime = endTime - startTime

    // Then: Search completes in reasonable time and returns correct results
    #expect(elapsedTime < 1.0)  // Should complete in less than 1 second
    #expect(!results.isEmpty)  // Should find matching doses
    #expect(
      results.allSatisfy { dose in
        dose.notes?.contains("500") == true || String(dose.amount).contains("500")
      })
  }

  @Test("Search handles nil values gracefully")
  func searchWithNilValues() throws {
    // Given: Doses with nil values
    let doseWithNils = self.createTestDose(
      site: nil,
      notes: nil)
    // medication relationship is also nil

    let doses = [doseWithNils]

    // When: Searching in fields that might be nil
    let noteResults = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "anything",
      scope: .notes)

    let siteResults = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "anything",
      scope: .injectionSite)

    let medicationResults = DoseSearchService.searchDoses(
      doses: doses,
      searchText: "anything",
      scope: .medication)

    // Then: No crashes occur and empty results are returned
    #expect(noteResults.isEmpty)
    #expect(siteResults.isEmpty)
    #expect(medicationResults.isEmpty)
  }

  // MARK: - Test Helper Methods

  private func createTestDose(
    timestamp: Date = Date(),
    amount: Double = 1.0,
    site: String? = nil,
    notes: String? = nil,
    skipped: Bool = false
  ) -> Dose {
    Dose(
      amount: amount,
      timestamp: timestamp,
      site: site,
      notes: notes,
      skipped: skipped)
  }

  private func createTestMedicationProfile(
    genericName: String = "TestMedication",
    brandName: String = "TestBrand"
  ) -> MedicationProfile {
    MedicationProfile(
      genericName: genericName,
      brandName: brandName)
  }

  private func createTestDoses() -> [Dose] {
    [
      self.createTestDose(notes: "morning dose"),
      self.createTestDose(notes: "evening injection"),
      self.createTestDose(site: "Thigh"),
      self.createTestDose(amount: 1.5),
    ]
  }
}
