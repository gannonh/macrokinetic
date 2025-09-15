//
//  DoseSearchServiceUnitTests.swift
//  JabTrackerTests
//
//  Unit tests for DoseSearchService implementation
//  Tests the actual implementation methods to ensure they work correctly
//

import Testing
import Foundation
import SwiftData
@testable import JabTracker

@MainActor
struct DoseSearchServiceUnitTests {
    
    // Create an in-memory model container for testing without CloudKit
    private var modelContainer: ModelContainer {
        let schema = Schema([
            User.self,
            Dose.self,
            MedicationProfile.self,
            DoseTitration.self
        ])
        
        // Disable CloudKit for testing - same logic as DataController
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Search Scope Implementation Tests
    
    @Test("Search scope .notes filters correctly")
    func testSearchScopeNotes() throws {
        // Given: Doses with various notes
        let morningDose = createTestDose(notes: "morning injection")
        let eveningDose = createTestDose(notes: "evening dose")  
        let noNotesDose = createTestDose(notes: nil)
        let emptyNotesDose = createTestDose(notes: "")
        
        let doses = [morningDose, eveningDose, noNotesDose, emptyNotesDose]
        
        // When: Searching in notes scope
        let morningResults = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "morning",
            scope: .notes
        )
        
        let injectionResults = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "injection",
            scope: .notes
        )
        
        // Then: Only doses with matching notes are returned
        #expect(morningResults.count == 1)
        #expect(morningResults[0].notes == "morning injection")
        
        #expect(injectionResults.count == 1)
        #expect(injectionResults[0].notes == "morning injection")
        
        // When: Searching for non-existent term
        let noResults = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "nonexistent",
            scope: .notes
        )
        
        // Then: No results returned
        #expect(noResults.isEmpty)
    }
    
    @Test("Search scope .amount works with numeric formatting")
    func testSearchScopeAmount() throws {
        // Given: Doses with different amounts
        let dose1_0 = createTestDose(amount: 1.0)
        let dose1_5 = createTestDose(amount: 1.5)
        let dose2_0 = createTestDose(amount: 2.0)
        let dose10_0 = createTestDose(amount: 10.0)
        
        let doses = [dose1_0, dose1_5, dose2_0, dose10_0]
        
        // When: Searching for exact amount
        let exactResults = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "1.0",
            scope: .amount
        )
        
        // Then: Exact match found
        #expect(exactResults.count == 1)
        #expect(exactResults[0].amount == 1.0)
        
        // When: Searching for partial match
        let partialResults = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "1",
            scope: .amount
        )
        
        // Then: Multiple matches found (1.0, 1.5, 10.0)
        #expect(partialResults.count == 3)
        let amounts = partialResults.map { $0.amount }.sorted()
        #expect(amounts == [1.0, 1.5, 10.0])
    }
    
    @Test("Search scope .date works with formatted dates")
    func testSearchScopeDate() throws {
        // Given: Doses with specific dates
        let calendar = Calendar.current
        let jan1 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 10))!
        let feb15 = calendar.date(from: DateComponents(year: 2024, month: 2, day: 15, hour: 14))!
        let dec31 = calendar.date(from: DateComponents(year: 2023, month: 12, day: 31, hour: 20))!
        
        let janDose = createTestDose(timestamp: jan1)
        let febDose = createTestDose(timestamp: feb15)
        let decDose = createTestDose(timestamp: dec31)
        
        let doses = [janDose, febDose, decDose]
        
        // When: Searching for year
        let year2024Results = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "2024",
            scope: .date
        )
        
        // Then: 2024 doses found
        #expect(year2024Results.count == 2)
        #expect(year2024Results.contains { $0.timestamp == jan1 })
        #expect(year2024Results.contains { $0.timestamp == feb15 })
        
        // When: Searching for month (this depends on locale, but "Feb" should work in English)
        let febResults = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "Feb",
            scope: .date
        )
        
        // Then: February dose found
        #expect(febResults.count == 1)
        #expect(febResults[0].timestamp == feb15)
    }
    
    // MARK: - Search Mode Implementation Tests
    
    @Test("Search mode .exact implementation works correctly")
    func testSearchModeExactImplementation() throws {
        // Given: Dose with specific content
        let dose = createTestDose(notes: "morning")
        let doses = [dose]
        
        // When: Exact match search
        let exactMatch = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "morning",
            mode: .exact
        )
        
        let partialMatch = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "morn",
            mode: .exact
        )
        
        let caseMatch = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "MORNING",
            mode: .exact
        )
        
        // Then: Only exact matches work (case insensitive by default)
        #expect(exactMatch.count == 1)
        #expect(partialMatch.isEmpty)
        #expect(caseMatch.count == 1) // Case insensitive
    }
    
    @Test("Search mode .startsWith implementation works correctly")
    func testSearchModeStartsWithImplementation() throws {
        // Given: Dose with specific content
        let dose = createTestDose(notes: "morning injection")
        let doses = [dose]
        
        // When: Starts with search
        let startsWithMatch = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "morn",
            mode: .startsWith
        )
        
        let middleMatch = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "ing",
            mode: .startsWith
        )
        
        let fullMatch = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "morning injection",
            mode: .startsWith
        )
        
        // Then: Only prefix matches work
        #expect(startsWithMatch.count == 1)
        #expect(middleMatch.isEmpty)
        #expect(fullMatch.count == 1)
    }
    
    @Test("Search mode .endsWith implementation works correctly")
    func testSearchModeEndsWithImplementation() throws {
        // Given: Dose with specific content
        let dose = createTestDose(notes: "morning injection")
        let doses = [dose]
        
        // When: Ends with search
        let endsWithMatch = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "tion",
            mode: .endsWith
        )
        
        let beginningMatch = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "morn",
            mode: .endsWith
        )
        
        let fullMatch = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "morning injection",
            mode: .endsWith
        )
        
        // Then: Only suffix matches work
        #expect(endsWithMatch.count == 1)
        #expect(beginningMatch.isEmpty)
        #expect(fullMatch.count == 1)
    }
    
    // MARK: - Case Sensitivity Implementation Tests
    
    @Test("Case sensitivity implementation works correctly")
    func testCaseSensitivityImplementation() throws {
        // Given: Dose with mixed case content
        let dose = createTestDose(notes: "Morning Injection")
        let doses = [dose]
        
        // When: Case insensitive search (default)
        let insensitiveResults = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "morning",
            caseSensitive: false
        )
        
        // Then: Match found regardless of case
        #expect(insensitiveResults.count == 1)
        
        // When: Case sensitive search
        let sensitiveMatch = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "Morning",
            caseSensitive: true
        )
        
        let sensitiveNoMatch = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "morning",
            caseSensitive: true
        )
        
        // Then: Only exact case matches work
        #expect(sensitiveMatch.count == 1)
        #expect(sensitiveNoMatch.isEmpty)
    }
    
    // MARK: - Multiple Terms Search Implementation Tests
    
    @Test("Multiple terms AND logic implementation works correctly")
    func testMultipleTermsANDImplementation() throws {
        // Given: Doses with various content
        let dose1 = createTestDose(notes: "morning injection thigh")
        let dose2 = createTestDose(notes: "morning dose abdomen")
        let dose3 = createTestDose(notes: "evening injection thigh")
        
        let doses = [dose1, dose2, dose3]
        
        // When: Searching with multiple terms (AND logic)
        let bothTermsResults = DoseSearchService.searchDosesWithMultipleTerms(
            doses: doses,
            searchTerms: ["morning", "thigh"]
        )
        
        let noMatchResults = DoseSearchService.searchDosesWithMultipleTerms(
            doses: doses,
            searchTerms: ["morning", "evening"] // No dose has both
        )
        
        let emptyTermsResults = DoseSearchService.searchDosesWithMultipleTerms(
            doses: doses,
            searchTerms: []
        )
        
        // Then: Only doses with all terms are returned
        #expect(bothTermsResults.count == 1)
        #expect(bothTermsResults[0].notes == "morning injection thigh")
        
        #expect(noMatchResults.isEmpty)
        #expect(emptyTermsResults.count == doses.count) // Empty terms return all
    }
    
    @Test("Multiple terms OR logic implementation works correctly")
    func testMultipleTermsORImplementation() throws {
        // Given: Doses with various content
        let dose1 = createTestDose(notes: "morning injection")
        let dose2 = createTestDose(notes: "evening dose")
        let dose3 = createTestDose(notes: "afternoon medication")
        
        let doses = [dose1, dose2, dose3]
        
        // When: Searching with multiple terms (OR logic)
        let eitherTermResults = DoseSearchService.searchDosesWithAnyTerm(
            doses: doses,
            searchTerms: ["morning", "evening"]
        )
        
        let noMatchResults = DoseSearchService.searchDosesWithAnyTerm(
            doses: doses,
            searchTerms: ["nonexistent", "missing"]
        )
        
        let emptyTermsResults = DoseSearchService.searchDosesWithAnyTerm(
            doses: doses,
            searchTerms: []
        )
        
        // Then: Doses with any term are returned
        #expect(eitherTermResults.count == 2)
        #expect(eitherTermResults.contains { $0.notes == "morning injection" })
        #expect(eitherTermResults.contains { $0.notes == "evening dose" })
        
        #expect(noMatchResults.isEmpty)
        #expect(emptyTermsResults.count == doses.count) // Empty terms return all
    }
    
    // MARK: - Advanced Query Parsing Tests
    
    @Test("Query tokenization implementation handles quotes correctly")
    func testQueryTokenizationImplementation() throws {
        // Given: Complex query string
        let query = "simple \"quoted string\" medication:test \"another quote\" final"
        
        // When: Parsing the query
        let searchQuery = DoseSearchService.parseAdvancedSearch(query)
        
        // Then: Components are parsed correctly
        #expect(searchQuery.exactPhrases.count == 2)
        #expect(searchQuery.exactPhrases.contains("quoted string"))
        #expect(searchQuery.exactPhrases.contains("another quote"))
        
        #expect(searchQuery.searchTerms.count == 2)
        #expect(searchQuery.searchTerms.contains("simple"))
        #expect(searchQuery.searchTerms.contains("final"))
        
        #expect(searchQuery.medicationFilter == "test")
    }
    
    @Test("Advanced search query application implementation works")
    func testAdvancedSearchQueryApplicationImplementation() throws {
        // Given: Doses with comprehensive data using model context
        let container = modelContainer
        let context = container.mainContext
        
        let semaglutideProfile = createTestMedicationProfile(
            genericName: "Semaglutide",
            brandName: "Ozempic"
        )
        
        let matchingDose = createTestDose(
            amount: 1.5,
            site: "Thigh",
            notes: "morning exact phrase"
        )
        
        let wrongAmountDose = createTestDose(
            amount: 0.5,
            site: "Thigh", 
            notes: "morning exact phrase"
        )
        
        let wrongSiteDose = createTestDose(
            amount: 1.5,
            site: "Abdomen",
            notes: "morning exact phrase"
        )
        
        context.insert(semaglutideProfile)
        context.insert(matchingDose)
        context.insert(wrongAmountDose)
        context.insert(wrongSiteDose)
        
        // Set relationships after insertion
        matchingDose.medication = semaglutideProfile
        wrongAmountDose.medication = semaglutideProfile
        wrongSiteDose.medication = semaglutideProfile
        
        try context.save()
        
        let doses = [matchingDose, wrongAmountDose, wrongSiteDose]
        
        // When: Creating and applying advanced query
        var searchQuery = SearchQuery()
        searchQuery.medicationFilter = "Semaglutide"
        searchQuery.injectionSiteFilter = "Thigh"
        searchQuery.amountFilter = .greaterThan(1.0)
        searchQuery.exactPhrases = ["exact phrase"]
        
        let results = DoseSearchService.searchWithAdvancedQuery(doses: doses, query: searchQuery)
        
        // Then: Only fully matching dose is returned
        #expect(results.count == 1, "Expected 1 result but got \(results.count). Medication names: \(doses.compactMap { $0.medication?.genericName })")
        
        if !results.isEmpty {
            #expect(results[0].amount == 1.5)
            #expect(results[0].site == "Thigh")
            #expect(results[0].notes?.contains("exact phrase") == true)
            #expect(results[0].medication?.genericName == "Semaglutide")
        }
    }
    
    // MARK: - Amount Filter Implementation Tests
    
    @Test("Amount filter comparison implementations work correctly")
    func testAmountFilterImplementations() throws {
        // Given: Various amount filters
        let equals = AmountFilter.equals(1.5)
        let greaterThan = AmountFilter.greaterThan(1.0)
        let lessThan = AmountFilter.lessThan(2.0)
        let greaterEqual = AmountFilter.greaterThanOrEqual(1.5)
        let lessEqual = AmountFilter.lessThanOrEqual(1.5)
        
        let testAmount = 1.5
        
        // Then: All filters work correctly
        #expect(equals.matches(testAmount) == true)
        #expect(equals.matches(1.5001) == true) // Within tolerance
        #expect(equals.matches(1.6) == false)
        
        #expect(greaterThan.matches(testAmount) == true)
        #expect(greaterThan.matches(1.0) == false)
        #expect(greaterThan.matches(0.9) == false)
        
        #expect(lessThan.matches(testAmount) == true)
        #expect(lessThan.matches(2.0) == false)
        #expect(lessThan.matches(2.1) == false)
        
        #expect(greaterEqual.matches(testAmount) == true)
        #expect(greaterEqual.matches(1.4999) == false)
        #expect(greaterEqual.matches(1.6) == true)
        
        #expect(lessEqual.matches(testAmount) == true)
        #expect(lessEqual.matches(1.5001) == true) // Within tolerance
        #expect(lessEqual.matches(1.6) == false)
    }
    
    @Test("Amount filter parsing implementation works correctly")
    func testAmountFilterParsingImplementation() throws {
        // When: Parsing different amount filter strings
        let query1 = DoseSearchService.parseAdvancedSearch("amount:>1.0")
        let query2 = DoseSearchService.parseAdvancedSearch("amount:<=2.5")
        let query3 = DoseSearchService.parseAdvancedSearch("amount:>=1.5")
        let query4 = DoseSearchService.parseAdvancedSearch("amount:<2.0")
        let query5 = DoseSearchService.parseAdvancedSearch("amount:1.0")
        
        // Then: Filters are parsed correctly
        if case .greaterThan(let value) = query1.amountFilter {
            #expect(value == 1.0)
        } else {
            Issue.record("Should parse >1.0 as greaterThan(1.0)")
        }
        
        if case .lessThanOrEqual(let value) = query2.amountFilter {
            #expect(value == 2.5)
        } else {
            Issue.record("Should parse <=2.5 as lessThanOrEqual(2.5)")
        }
        
        if case .greaterThanOrEqual(let value) = query3.amountFilter {
            #expect(value == 1.5)
        } else {
            Issue.record("Should parse >=1.5 as greaterThanOrEqual(1.5)")
        }
        
        if case .lessThan(let value) = query4.amountFilter {
            #expect(value == 2.0)
        } else {
            Issue.record("Should parse <2.0 as lessThan(2.0)")
        }
        
        if case .equals(let value) = query5.amountFilter {
            #expect(value == 1.0)
        } else {
            Issue.record("Should parse 1.0 as equals(1.0)")
        }
    }
    
    // MARK: - Edge Cases and Error Handling Tests
    
    @Test("Search handles nil values gracefully in implementation")
    func testSearchWithNilValuesImplementation() throws {
        // Given: Dose with all nil optional values
        let doseWithNils = createTestDose(
            site: nil,
            notes: nil
        )
        // medication relationship is also nil by default
        
        let doses = [doseWithNils]
        
        // When: Searching in fields that are nil
        let noteResults = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "anything",
            scope: .notes
        )
        
        let siteResults = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "anything",
            scope: .injectionSite
        )
        
        let medicationResults = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "anything",
            scope: .medication
        )
        
        // Then: No crashes and empty results
        #expect(noteResults.isEmpty)
        #expect(siteResults.isEmpty)
        #expect(medicationResults.isEmpty)
    }
    
    @Test("Empty and whitespace handling implementation works")
    func testEmptySearchHandlingImplementation() throws {
        // Given: Test doses
        let doses = createTestDoses()
        
        // When: Searching with empty and whitespace strings
        let emptyResults = DoseSearchService.searchDoses(
            doses: doses,
            searchText: ""
        )
        
        let whitespaceResults = DoseSearchService.searchDoses(
            doses: doses,
            searchText: "   \n\t  "
        )
        
        // Then: All doses returned (no filtering)
        #expect(emptyResults.count == doses.count)
        #expect(whitespaceResults.count == doses.count)
        #expect(emptyResults == doses)
        #expect(whitespaceResults == doses)
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
            skipped: skipped
        )
    }
    
    private func createTestMedicationProfile(
        genericName: String = "TestMedication",
        brandName: String = "TestBrand"
    ) -> MedicationProfile {
        MedicationProfile(
            genericName: genericName,
            brandName: brandName
        )
    }
    
    private func createTestDoses() -> [Dose] {
        [
            createTestDose(notes: "morning dose"),
            createTestDose(notes: "evening injection"),
            createTestDose(site: "Thigh"),
            createTestDose(amount: 1.5)
        ]
    }
}
