//
//  DoseHistoryViewModelTests.swift
//  JabTrackerTests
//
//  Base test file for DoseHistoryViewModel - functionality split across multiple files
//  See DoseHistoryViewModelDataTests, FilterTests, ComputedTests, ErrorTests for full coverage
//

import Foundation
@testable import JabTracker
import SwiftData
import Testing
import XCTest

@MainActor
struct DoseHistoryViewModelTests {
    var container: ModelContainer
    var context: ModelContext
    var viewModel: DoseHistoryViewModel

    init() throws {
        // Create in-memory container for testing
        let schema = Schema([User.self, Dose.self, MedicationProfile.self, DoseTitration.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none)
        self.container = try ModelContainer(for: schema, configurations: [configuration])
        self.context = self.container.mainContext
        self.viewModel = DoseHistoryViewModel()
    }

    // MARK: - Basic Initialization Test

    @Test("ViewModel initializes correctly")
    func viewModelInitialization() {
        // Given: New ViewModel instance
        // When: Initialized
        // Then: Should have proper default state
        #expect(self.viewModel.searchText.isEmpty)
        #expect(self.viewModel.selectedSiteFilter.isEmpty)
        #expect(self.viewModel.selectedMedicationFilter == nil)
        #expect(self.viewModel.filterStartDate == nil)
        #expect(self.viewModel.filterEndDate == nil)
        #expect(!self.viewModel.hasActiveFilters)
    }

    // MARK: - Test Helper Methods

    private func createTestDose(
        timestamp: Date = Date(),
        amount: Double = 1.0,
        site: String? = nil,
        notes: String? = nil,
        imageData: Data? = nil,
        skipped: Bool = false,
        user: User? = nil,
        medication: MedicationProfile? = nil) -> Dose
    {
        Dose(
            amount: amount,
            timestamp: timestamp,
            site: site,
            notes: notes,
            imageData: imageData,
            skipped: skipped,
            user: user,
            medication: medication)
    }

    private func createTestMedicationProfile(
        genericName: String = "TestMedication",
        brandName: String = "TestBrand",
        currentDose: Double = 1.0) -> MedicationProfile
    {
        MedicationProfile(
            genericName: genericName,
            brandName: brandName,
            currentDose: currentDose)
    }

    private func createTestUser(
        email: String = "test@example.com",
        name: String = "Test User") -> User
    {
        User(
            email: email,
            name: name)
    }
}
