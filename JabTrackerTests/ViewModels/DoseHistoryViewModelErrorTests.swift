//
//  DoseHistoryViewModelErrorTests.swift
//  JabTrackerTests
//
//  Unit tests for DoseHistoryViewModel error handling and edge cases
//  Focuses on invalid data scenarios, failure conditions, and boundary testing
//

import Foundation
import SwiftData
import Testing
import XCTest

@testable import JabTracker

@MainActor
struct DoseHistoryViewModelErrorTests {
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

  // MARK: - Error Handling and Edge Case Tests

  @Test("ViewModel handles empty data correctly")
  func loadDataWithNoDoses() async throws {
    // Given: No doses in database

    // When: ViewModel loads data
    self.viewModel.loadData(context: self.context)
    try await Task.sleep(nanoseconds: 100_000_000)

    // Then: Arrays are empty but no error occurs
    #expect(self.viewModel.filteredDoses.isEmpty)
    #expect(self.viewModel.isLoading == false)
  }

  @Test("Search with nil notes handles gracefully")
  func searchWithNilNotesHandling() async throws {
    // Given: Doses with nil notes
    let doseWithNotes = self.createTestDose(notes: "has notes")
    let doseWithoutNotes = self.createTestDose(notes: nil)
    let doseWithEmptyNotes = self.createTestDose(notes: "")

    self.context.insert(doseWithNotes)
    self.context.insert(doseWithoutNotes)
    self.context.insert(doseWithEmptyNotes)
    try self.context.save()

    self.viewModel.loadData(context: self.context)
    try await Task.sleep(nanoseconds: 100_000_000)

    // When: Searching with text
    self.viewModel.searchText = "notes"

    // Then: Only dose with matching notes is shown, nil notes don't crash
    #expect(self.viewModel.filteredDoses.count == 1)
    #expect(self.viewModel.filteredDoses[0].notes == "has notes")
  }

  @Test("Injection site filter with nil site handles gracefully")
  func injectionSiteFilterWithNilSiteHandling() async throws {
    // Given: Doses with and without injection sites
    let doseWithSite = self.createTestDose(site: "Thigh")
    let doseWithoutSite = self.createTestDose(site: nil)
    let doseWithEmptySite = self.createTestDose(site: "")

    self.context.insert(doseWithSite)
    self.context.insert(doseWithoutSite)
    self.context.insert(doseWithEmptySite)
    try self.context.save()

    self.viewModel.loadData(context: self.context)
    try await Task.sleep(nanoseconds: 100_000_000)

    // When: Filtering by injection site
    self.viewModel.selectedInjectionSiteFilter = "Thigh"

    // Then: Only dose with matching site is shown, nil site doesn't crash
    #expect(self.viewModel.filteredDoses.count == 1)
    #expect(self.viewModel.filteredDoses[0].site == "Thigh")
  }

  @Test("Available injection sites with duplicate names handles gracefully")
  func availableInjectionSitesWithDuplicateNamesHandling() async throws {
    // Given: Multiple doses with same injection site
    let dose1 = self.createTestDose(site: "Thigh")
    let dose2 = self.createTestDose(site: "Thigh")  // Duplicate site
    let dose3 = self.createTestDose(site: "Abdomen")
    let doseWithNilSite = self.createTestDose(site: nil)

    self.context.insert(dose1)
    self.context.insert(dose2)
    self.context.insert(dose3)
    self.context.insert(doseWithNilSite)
    try self.context.save()

    self.viewModel.loadData(context: self.context)
    try await Task.sleep(nanoseconds: 100_000_000)

    // When: Getting available injection sites
    let sites = self.viewModel.availableInjectionSites

    // Then: Should deduplicate names and handle nil gracefully
    #expect(sites.count == 2)  // Thigh (deduplicated) and Abdomen
    #expect(sites.contains("Thigh"))
    #expect(sites.contains("Abdomen"))
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
    medication: MedicationProfile? = nil
  ) -> Dose {
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
    currentDose: Double = 1.0
  ) -> MedicationProfile {
    MedicationProfile(
      genericName: genericName,
      brandName: brandName,
      currentDose: currentDose)
  }

  private func createTestUser(
    email: String = "test@example.com",
    name: String = "Test User"
  ) -> User {
    User(
      email: email,
      name: name)
  }
}
