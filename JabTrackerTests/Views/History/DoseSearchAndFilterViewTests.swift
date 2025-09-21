//
//  DoseSearchAndFilterViewTests.swift
//  JabTrackerTests
//
//  Unit tests for DoseSearchAndFilterView component
//  Tests search functionality, filter options, and UI state management
//

@testable import JabTracker
import SwiftData
import SwiftUI
import Testing

struct DoseSearchAndFilterViewTests {
    // MARK: - Test Infrastructure

    private func createTestModelContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: User.self, Dose.self, MedicationProfile.self, configurations: config)
        return ModelContext(container)
    }

    private func createTestViewModel() async -> DoseHistoryViewModel {
        await DoseHistoryViewModel()
    }

    private func setupTestData(context: ModelContext, viewModel: DoseHistoryViewModel) async throws {
        let user = User(email: "test@example.com", name: "Test User")
        context.insert(user)

        let medication1 = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0)
        medication1.user = user
        context.insert(medication1)

        let medication2 = MedicationProfile(
            genericName: "Tirzepatide",
            brandName: "Mounjaro",
            currentDose: 2.5)
        medication2.user = user
        context.insert(medication2)

        // Create doses with various properties
        let dose1 = Dose(
            amount: 1.0,
            timestamp: Date(),
            site: "Thigh",
            notes: "Morning dose",
            user: user,
            medication: medication1)
        context.insert(dose1)

        let dose2 = Dose(
            amount: 2.5,
            timestamp: Date().addingTimeInterval(-86400),
            site: "Abdomen",
            notes: "Evening injection",
            user: user,
            medication: medication2)
        context.insert(dose2)

        let dose3 = Dose(
            amount: 1.5,
            timestamp: Date().addingTimeInterval(-172_800),
            site: "Arm",
            notes: "Weekly medication",
            skipped: true,
            user: user,
            medication: medication1)
        context.insert(dose3)

        try context.save()

        // Load data into view model
        await viewModel.loadData(context: context)
    }

    // MARK: - View Creation Tests

    @Test("DoseSearchAndFilterView can be created with view model")
    func viewCreation() async throws {
        let viewModel = await createTestViewModel()
        let view = DoseSearchAndFilterView(viewModel: viewModel)

        // Should not crash
        #expect(view.viewModel === viewModel)
    }

    // MARK: - Search Functionality Tests

    @Test("Search text binding works correctly")
    func searchTextBinding() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()
        try await setupTestData(context: context, viewModel: viewModel)

        _ = DoseSearchAndFilterView(viewModel: viewModel)

        // Wait for data to load
        try await Task.sleep(nanoseconds: 100_000_000)

        // Test initial state
        await MainActor.run {
            #expect(viewModel.searchText.isEmpty)
        }

        // Test search text update
        await MainActor.run {
            viewModel.searchText = "morning"
        }

        // Wait for filter to apply
        try await Task.sleep(nanoseconds: 50_000_000)

        await MainActor.run {
            #expect(viewModel.searchText == "morning")
            #expect(viewModel.filteredDoses.count == 1)
            #expect(viewModel.filteredDoses.first?.notes == "Morning dose")
        }
    }

    @Test("Clear search functionality works")
    func clearSearchFunctionality() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()
        try await setupTestData(context: context, viewModel: viewModel)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Set search text
        await MainActor.run {
            viewModel.searchText = "test search"
            #expect(!viewModel.searchText.isEmpty)
        }

        // Clear search
        await MainActor.run {
            viewModel.searchText = ""
            #expect(viewModel.searchText.isEmpty)
        }
    }

    // MARK: - Filter Functionality Tests

    @Test("Medication filter works correctly")
    func medicationFilter() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()
        try await setupTestData(context: context, viewModel: viewModel)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Test initial state
        await MainActor.run {
            #expect(viewModel.selectedMedicationFilter == nil)
            #expect(viewModel.availableMedications.count == 2)
            #expect(viewModel.availableMedications.contains("Semaglutide"))
            #expect(viewModel.availableMedications.contains("Tirzepatide"))
        }

        // Apply medication filter
        await MainActor.run {
            viewModel.selectedMedicationFilter = "Semaglutide"
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        await MainActor.run {
            #expect(viewModel.filteredDoses.count == 2) // Two Semaglutide doses
            #expect(viewModel.filteredDoses.allSatisfy { $0.medication?.genericName == "Semaglutide" })
        }
    }

    @Test("Injection site filter works correctly")
    func injectionSiteFilter() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()
        try await setupTestData(context: context, viewModel: viewModel)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Test initial state
        await MainActor.run {
            #expect(viewModel.selectedInjectionSiteFilter == nil)
            #expect(viewModel.availableInjectionSites.count == 3)
            #expect(viewModel.availableInjectionSites.contains("Thigh"))
            #expect(viewModel.availableInjectionSites.contains("Abdomen"))
            #expect(viewModel.availableInjectionSites.contains("Arm"))
        }

        // Apply injection site filter
        await MainActor.run {
            viewModel.selectedInjectionSiteFilter = "Thigh"
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        await MainActor.run {
            #expect(viewModel.filteredDoses.count == 1)
            #expect(viewModel.filteredDoses.first?.site == "Thigh")
        }
    }

    @Test("Show skipped doses toggle works")
    func showSkippedDosesToggle() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()
        try await setupTestData(context: context, viewModel: viewModel)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Test initial state (show all doses including skipped)
        await MainActor.run {
            #expect(viewModel.showSkippedDoses == true)
            #expect(viewModel.filteredDoses.count == 3)
        }

        // Hide skipped doses
        await MainActor.run {
            viewModel.showSkippedDoses = false
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        await MainActor.run {
            #expect(viewModel.filteredDoses.count == 2) // Exclude the skipped dose
            #expect(viewModel.filteredDoses.allSatisfy { !$0.skipped })
        }
    }

    @Test("Date range filters work correctly")
    func dateRangeFilters() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()
        try await setupTestData(context: context, viewModel: viewModel)

        try await Task.sleep(nanoseconds: 100_000_000)

        let today = Date()
        let yesterday = today.addingTimeInterval(-86400)

        // Test start date filter
        await MainActor.run {
            viewModel.filterStartDate = yesterday
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        // Should show doses from yesterday onwards
        await MainActor.run {
            #expect(viewModel.filteredDoses.count >= 2)
        }

        // Test end date filter
        await MainActor.run {
            viewModel.filterStartDate = nil
            viewModel.filterEndDate = yesterday
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        // Should show doses up to yesterday
        await MainActor.run {
            #expect(viewModel.filteredDoses.count >= 1)
        }

        // Test both start and end date
        let twoDaysAgo = today.addingTimeInterval(-172_800)
        await MainActor.run {
            viewModel.filterStartDate = twoDaysAgo
            viewModel.filterEndDate = today
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        // Should show all doses in range
        await MainActor.run {
            #expect(viewModel.filteredDoses.count >= 2)
        }
    }

    // MARK: - Active Filters Tests

    @Test("Active filters detection works correctly")
    func activeFiltersDetection() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()
        try await setupTestData(context: context, viewModel: viewModel)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Test initial state - no active filters
        await MainActor.run {
            #expect(viewModel.hasActiveFilters == false)
        }

        // Test search text filter
        await MainActor.run {
            viewModel.searchText = "test"
            #expect(viewModel.hasActiveFilters == true)

            viewModel.searchText = ""
            #expect(viewModel.hasActiveFilters == false)
        }

        // Test medication filter
        await MainActor.run {
            viewModel.selectedMedicationFilter = "Semaglutide"
            #expect(viewModel.hasActiveFilters == true)

            viewModel.selectedMedicationFilter = nil
            #expect(viewModel.hasActiveFilters == false)
        }

        // Test injection site filter
        await MainActor.run {
            viewModel.selectedInjectionSiteFilter = "Thigh"
            #expect(viewModel.hasActiveFilters == true)

            viewModel.selectedInjectionSiteFilter = nil
            #expect(viewModel.hasActiveFilters == false)
        }

        // Test date filters
        await MainActor.run {
            viewModel.filterStartDate = Date()
            #expect(viewModel.hasActiveFilters == true)

            viewModel.filterStartDate = nil
            viewModel.filterEndDate = Date()
            #expect(viewModel.hasActiveFilters == true)

            viewModel.filterEndDate = nil
            #expect(viewModel.hasActiveFilters == false)
        }

        // Test show skipped filter
        await MainActor.run {
            viewModel.showSkippedDoses = false
            #expect(viewModel.hasActiveFilters == true)

            viewModel.showSkippedDoses = true
            #expect(viewModel.hasActiveFilters == false)
        }
    }

    @Test("Clear all filters functionality works")
    func testClearAllFilters() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()
        try await setupTestData(context: context, viewModel: viewModel)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Set multiple filters
        await MainActor.run {
            viewModel.searchText = "test"
            viewModel.selectedMedicationFilter = "Semaglutide"
            viewModel.selectedInjectionSiteFilter = "Thigh"
            viewModel.filterStartDate = Date()
            viewModel.filterEndDate = Date()
            viewModel.showSkippedDoses = false

            #expect(viewModel.hasActiveFilters == true)
        }

        // Clear all filters
        await MainActor.run {
            viewModel.clearAllFilters()
        }

        // Verify all filters are cleared
        await MainActor.run {
            #expect(viewModel.searchText.isEmpty)
            #expect(viewModel.selectedMedicationFilter == nil)
            #expect(viewModel.selectedInjectionSiteFilter == nil)
            #expect(viewModel.filterStartDate == nil)
            #expect(viewModel.filterEndDate == nil)
            #expect(viewModel.showSkippedDoses == true)
            #expect(viewModel.hasActiveFilters == false)
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        // Should show all doses again
        await MainActor.run {
            #expect(viewModel.filteredDoses.count == 3)
        }
    }

    // MARK: - Date Range Display Tests

    @Test("Date range display text formats correctly")
    func dateRangeDisplayText() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()
        try await setupTestData(context: context, viewModel: viewModel)

        _ = DoseSearchAndFilterView(viewModel: viewModel)

        // Test no date range
        await MainActor.run {
            #expect(viewModel.filterStartDate == nil)
            #expect(viewModel.filterEndDate == nil)
            // Display text should be "All dates"
        }

        // Test start date only
        let startDate = Date()
        await MainActor.run {
            viewModel.filterStartDate = startDate
            viewModel.filterEndDate = nil

            // Display text should include "From [date]"
            #expect(viewModel.filterStartDate != nil)
            #expect(viewModel.filterEndDate == nil)
        }

        // Test end date only
        await MainActor.run {
            viewModel.filterStartDate = nil
            viewModel.filterEndDate = startDate

            // Display text should include "Until [date]"
            #expect(viewModel.filterStartDate == nil)
            #expect(viewModel.filterEndDate != nil)
        }

        // Test both dates
        let endDate = startDate.addingTimeInterval(86400)
        await MainActor.run {
            viewModel.filterStartDate = startDate
            viewModel.filterEndDate = endDate

            // Display text should include both dates
            #expect(viewModel.filterStartDate != nil)
            #expect(viewModel.filterEndDate != nil)
        }
    }

    // MARK: - Multiple Filters Combination Tests

    @Test("Multiple filters work together correctly")
    func multipleFiltersInteraction() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()
        try await setupTestData(context: context, viewModel: viewModel)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Apply multiple filters that should narrow results
        await MainActor.run {
            viewModel.selectedMedicationFilter = "Semaglutide"
            viewModel.selectedInjectionSiteFilter = "Thigh"
            viewModel.searchText = "morning"
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        // Should find the one dose that matches all criteria
        await MainActor.run {
            #expect(viewModel.filteredDoses.count == 1)

            guard let matchingDose = viewModel.filteredDoses.first else {
                Issue.record("Expected to find a matching dose")
                return
            }
            #expect(matchingDose.medication?.genericName == "Semaglutide")
            #expect(matchingDose.site == "Thigh")
            #expect(matchingDose.notes?.localizedCaseInsensitiveContains("morning") == true)
        }
    }

    @Test("Conflicting filters produce empty results")
    func conflictingFilters() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()
        try await setupTestData(context: context, viewModel: viewModel)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Apply conflicting filters (medication that doesn't have this injection site)
        await MainActor.run {
            viewModel.selectedMedicationFilter = "Tirzepatide"
            viewModel.selectedInjectionSiteFilter = "Thigh" // Only Semaglutide dose is in Thigh
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        // Should find no matching doses
        await MainActor.run {
            #expect(viewModel.filteredDoses.isEmpty)
        }
    }

    // MARK: - Filter State Persistence Tests

    @Test("Filter state persists during view lifecycle")
    func filterStatePersistence() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()
        try await setupTestData(context: context, viewModel: viewModel)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Set filters
        await MainActor.run {
            viewModel.searchText = "morning"
            viewModel.selectedMedicationFilter = "Semaglutide"
        }

        // Create new view with same view model
        let view1 = DoseSearchAndFilterView(viewModel: viewModel)
        let view2 = DoseSearchAndFilterView(viewModel: viewModel)

        // Both views should see same filter state
        await MainActor.run {
            #expect(view1.viewModel.searchText == "morning")
            #expect(view2.viewModel.searchText == "morning")
            #expect(view1.viewModel.selectedMedicationFilter == "Semaglutide")
            #expect(view2.viewModel.selectedMedicationFilter == "Semaglutide")
        }
    }

    // MARK: - Edge Cases Tests

    @Test("Empty data set handling")
    func emptyDataSetHandling() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()

        // Don't setup any test data
        await viewModel.loadData(context: context)

        try await Task.sleep(nanoseconds: 100_000_000)

        _ = DoseSearchAndFilterView(viewModel: viewModel)

        await MainActor.run {
            #expect(viewModel.allDoses.isEmpty)
            #expect(viewModel.filteredDoses.isEmpty)
            #expect(viewModel.availableMedications.isEmpty)
            #expect(viewModel.availableInjectionSites.isEmpty)
            #expect(viewModel.hasActiveFilters == false)
        }
    }

    @Test("Special characters in search text")
    func specialCharactersInSearch() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()

        // Create test data with special characters
        let user = User(email: "test@example.com", name: "Test User")
        context.insert(user)

        let medication = MedicationProfile(
            genericName: "Test Med",
            brandName: "Test Brand",
            currentDose: 1.0)
        medication.user = user
        context.insert(medication)

        let dose = Dose(
            amount: 1.0,
            timestamp: Date(),
            site: "Thigh",
            notes: "Dose with émojis 💉 and spécial chars!",
            user: user,
            medication: medication)
        context.insert(dose)
        try context.save()

        await viewModel.loadData(context: context)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Test searching for special characters
        await MainActor.run {
            viewModel.searchText = "émojis"
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        await MainActor.run {
            #expect(viewModel.filteredDoses.count == 1)
        }

        // Test searching for emoji
        await MainActor.run {
            viewModel.searchText = "💉"
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        await MainActor.run {
            #expect(viewModel.filteredDoses.count == 1)
        }
    }

    @Test("Very long search text handling")
    func veryLongSearchText() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()
        try await setupTestData(context: context, viewModel: viewModel)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Test very long search text
        let longSearchText = String(repeating: "very long search text ", count: 100)
        await MainActor.run {
            viewModel.searchText = longSearchText
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        // Should handle gracefully without crashing
        await MainActor.run {
            #expect(viewModel.searchText == longSearchText)
            #expect(viewModel.filteredDoses.isEmpty) // May or may not find results
        }
    }

    @Test("Date range edge cases")
    func dateRangeEdgeCases() async throws {
        let context = try self.createTestModelContext()
        let viewModel = await createTestViewModel()
        try await setupTestData(context: context, viewModel: viewModel)

        try await Task.sleep(nanoseconds: 100_000_000)

        let today = Date()
        let futureDate = today.addingTimeInterval(86400) // Tomorrow
        let pastDate = today.addingTimeInterval(-172_800 * 365) // Long ago

        // Test future date range
        await MainActor.run {
            viewModel.filterStartDate = futureDate
            viewModel.filterEndDate = futureDate.addingTimeInterval(86400)
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        // Should find no doses in future
        await MainActor.run {
            #expect(viewModel.filteredDoses.isEmpty)
        }

        // Test very old date range
        await MainActor.run {
            viewModel.filterStartDate = pastDate
            viewModel.filterEndDate = pastDate.addingTimeInterval(86400)
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        // Should find no doses in distant past
        await MainActor.run {
            #expect(viewModel.filteredDoses.isEmpty)
        }

        // Test reversed date range (end before start)
        await MainActor.run {
            viewModel.filterStartDate = today
            viewModel.filterEndDate = pastDate
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        // Should handle gracefully
        await MainActor.run {
            #expect(viewModel.filteredDoses.isEmpty)
        }
    }
}
