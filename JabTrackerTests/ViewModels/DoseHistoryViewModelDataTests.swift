//
//  DoseHistoryViewModelDataTests.swift
//  JabTrackerTests
//
//  Data loading and state management tests for DoseHistoryViewModel
//

import Foundation
import SwiftData
import Testing
import XCTest

@testable import JabTracker

@MainActor
struct DoseHistoryViewModelDataTests {
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

  // MARK: - Data Loading Tests

  @Test("ViewModel loads doses in reverse chronological order")
  func loadDataSortsInReverseChronologicalOrder() async throws {
    // Given: Multiple doses with different timestamps
    let olderDate = Date().addingTimeInterval(-86400)  // 1 day ago
    let newerDate = Date()

    let olderDose = self.createTestDose(timestamp: olderDate, amount: 1.0)
    let newerDose = self.createTestDose(timestamp: newerDate, amount: 2.0)

    self.context.insert(olderDose)
    self.context.insert(newerDose)
    try self.context.save()

    // When: ViewModel loads data
    self.viewModel.loadData(context: self.context)
    try await Task.sleep(nanoseconds: 100_000_000)

    // Then: Newer dose should be first (reverse chronological)
    #expect(self.viewModel.filteredDoses.count == 2)
    #expect(self.viewModel.filteredDoses.first?.amount == 2.0)
    #expect(self.viewModel.filteredDoses.last?.amount == 1.0)
  }

  @Test("ViewModel loads data asynchronously")
  func loadDataAsynchronously() async throws {
    // Given: Dose in context
    let dose = self.createTestDose(timestamp: Date(), amount: 1.0)
    self.context.insert(dose)
    try self.context.save()

    // When: ViewModel loads data
    self.viewModel.loadData(context: self.context)

    // Then: Data should be loaded
    try await Task.sleep(nanoseconds: 100_000_000)
    #expect(self.viewModel.filteredDoses.count == 1)
    #expect(self.viewModel.filteredDoses.first?.amount == 1.0)
  }

  @Test("ViewModel handles empty data gracefully")
  func loadDataHandlesEmptyData() async throws {
    // Given: Empty context
    // When: ViewModel loads data
    self.viewModel.loadData(context: self.context)
    try await Task.sleep(nanoseconds: 100_000_000)

    // Then: Should handle empty data gracefully
    #expect(self.viewModel.filteredDoses.isEmpty)
  }

  @Test("ViewModel refreshes data correctly")
  func refreshData() async throws {
    // Given: Initial dose
    let initialDose = self.createTestDose(timestamp: Date(), amount: 1.0)
    self.context.insert(initialDose)
    try self.context.save()

    self.viewModel.loadData(context: self.context)
    try await Task.sleep(nanoseconds: 100_000_000)
    #expect(self.viewModel.filteredDoses.count == 1)

    // When: Add another dose and refresh
    let newDose = self.createTestDose(timestamp: Date().addingTimeInterval(3600), amount: 2.0)
    self.context.insert(newDose)
    try self.context.save()

    await self.viewModel.refreshData(context: self.context)
    try await Task.sleep(nanoseconds: 100_000_000)

    // Then: Should have both doses
    #expect(self.viewModel.filteredDoses.count == 2)
  }

  @Test("ViewModel manages loading state")
  func manageLoadingState() async throws {
    // Given: Dose in context
    let dose = self.createTestDose(timestamp: Date(), amount: 1.0)
    self.context.insert(dose)
    try self.context.save()

    // When: ViewModel starts loading
    #expect(self.viewModel.isLoading == false)
    self.viewModel.loadData(context: self.context)

    // Then: Loading state should be managed appropriately
    try await Task.sleep(nanoseconds: 100_000_000)
    #expect(self.viewModel.filteredDoses.count == 1)
  }

  @Test("ViewModel updates when dose is added")
  func updateWhenDoseAdded() async throws {
    // Given: Initial empty state
    self.viewModel.loadData(context: self.context)
    try await Task.sleep(nanoseconds: 100_000_000)
    #expect(self.viewModel.filteredDoses.isEmpty)

    // When: Dose is added
    let dose = self.createTestDose(timestamp: Date(), amount: 1.0)
    self.context.insert(dose)
    try self.context.save()
    await self.viewModel.refreshData(context: self.context)
    try await Task.sleep(nanoseconds: 100_000_000)

    // Then: ViewModel should update
    #expect(self.viewModel.filteredDoses.count == 1)
    #expect(self.viewModel.filteredDoses.first?.amount == 1.0)
  }

  // MARK: - Helper Methods

  private func createTestDose(timestamp: Date, amount: Double) -> Dose {
    let medicationProfile = self.createTestMedicationProfile()
    self.context.insert(medicationProfile)

    return Dose(
      amount: amount,
      timestamp: timestamp,
      site: "Thigh",
      notes: "Test dose",
      medication: medicationProfile)
  }

  private func createTestMedicationProfile(
    medication: Medication = .semaglutide,
    currentDose: Double = 1.0
  ) -> MedicationProfile {
    MedicationProfile(
      genericName: medication.rawValue,
      brandName: "Test Brand",
      currentDose: currentDose,
      startDate: Date(),
      medicationType: medication.rawValue)
  }

  private func createTestUser(name: String = "Test User", email: String = "test@example.com")
    -> User
  {
    User(
      email: email,
      name: name,
      appleUserId: "test-apple-id")
  }
}
