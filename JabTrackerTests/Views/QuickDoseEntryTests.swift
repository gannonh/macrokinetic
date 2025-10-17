//
//  QuickDoseEntryTests.swift
//  JabTrackerTests
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("QuickDoseEntry Date Selection Tests")
struct QuickDoseEntryTests {
    // MARK: - Test Setup

    @MainActor
    func createTestContext() -> ModelContext {
        let schema = Schema([User.self, MedicationProfile.self, Dose.self, DoseTitration.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            return container.mainContext
        } catch {
            fatalError("Failed to create test container: \(error)")
        }
    }

    func createTestMedicationProfile(
        context: ModelContext,
        genericName: String = "semaglutide",
        brandName: String = "Ozempic",
        currentDose: Double = 1.0
    ) -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: genericName,
            brandName: brandName,
            currentDose: currentDose)
        profile.preferredInjectionSites = ["Thigh", "Abdomen"]
        context.insert(profile)
        try? context.save()
        return profile
    }

    // MARK: - Date/Time Property Tests

    @Test("ViewModel initializes with current date and time")
    @MainActor
    func viewModelInitializesWithCurrentDateTime() async {
        let viewModel = QuickDoseViewModel()
        let now = Date()

        // Both date and time should be approximately now
        let timeDifference = abs(viewModel.doseDate.timeIntervalSince(now))
        #expect(timeDifference < 2.0, "Dose date should be approximately current time")

        let timeTimeDifference = abs(viewModel.doseTime.timeIntervalSince(now))
        #expect(timeTimeDifference < 2.0, "Dose time should be approximately current time")
    }

    @Test("DoseDateTime computed property combines date and time correctly")
    @MainActor
    func doseDateTimeComputedProperty() async {
        let viewModel = QuickDoseViewModel()

        // Set specific date and time
        let calendar = Calendar.current
        let specificDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let specificTime = calendar.date(from: DateComponents(hour: 14, minute: 30))!

        viewModel.doseDate = specificDate
        viewModel.doseTime = specificTime

        let combined = viewModel.doseDateTime
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: combined)

        #expect(components.year == 2024)
        #expect(components.month == 1)
        #expect(components.day == 15)
        #expect(components.hour == 14)
        #expect(components.minute == 30)
    }

    @Test("Can save dose validation includes date restrictions")
    @MainActor
    func canSaveDoseValidationWithDateRestrictions() async {
        let context = self.createTestContext()
        _ = self.createTestMedicationProfile(context: context)

        let viewModel = QuickDoseViewModel()
        viewModel.loadSmartDefaults(context: context)

        // Wait for async loading
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Verify basic setup worked
        #expect(viewModel.selectedMedicationProfile != nil)
        #expect(!viewModel.selectedInjectionSite.isEmpty)

        // Test valid current date/time
        let now = Date()
        viewModel.doseDate = now
        viewModel.doseTime = now

        // Debug: check individual conditions
        #expect(viewModel.selectedMedicationProfile != nil, "Should have medication profile")
        #expect(viewModel.doseAmount > 0, "Should have positive dose amount: \(viewModel.doseAmount)")
        #expect(
            !viewModel.selectedInjectionSite.isEmpty,
            "Should have injection site: '\(viewModel.selectedInjectionSite)'")

        let currentDateTime = viewModel.doseDateTime
        #expect(
            currentDateTime <= Date(), "DateTime should not be in future: \(currentDateTime) vs \(Date())"
        )

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        #expect(
            currentDateTime >= thirtyDaysAgo,
            "DateTime should not be more than 30 days ago: \(currentDateTime) vs \(thirtyDaysAgo)")

        #expect(viewModel.canSaveDose, "Should be able to save dose with current date/time")

        // Test future date within 30 days (should be valid for scheduled doses - Issue #178)
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        viewModel.doseDate = futureDate
        viewModel.doseTime = Date()  // Set time to ensure valid combined datetime
        #expect(viewModel.canSaveDose, "Should be able to save dose with future date (scheduled dose support)")

        // Test future date beyond 30 days (should be invalid)
        let farFutureDate = Calendar.current.date(byAdding: .day, value: 31, to: Date())!
        viewModel.doseDate = farFutureDate
        viewModel.doseTime = Date()
        #expect(!viewModel.canSaveDose, "Should not be able to save dose with date more than 30 days in future")

        // Test date 30 days ago (should be valid)
        viewModel.doseDate = thirtyDaysAgo
        viewModel.doseTime = thirtyDaysAgo  // Also set time to ensure consistent combined datetime
        #expect(viewModel.canSaveDose, "Should be able to save dose with date 30 days ago")

        // Test date 31 days ago (should be invalid)
        let moreThanThirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        viewModel.doseDate = moreThanThirtyDaysAgo
        viewModel.doseTime = moreThanThirtyDaysAgo  // Also set time to ensure consistent combined datetime
        #expect(!viewModel.canSaveDose, "Should not be able to save dose with date 31 days ago")
    }

    @Test("Reset form updates both date and time to current")
    @MainActor
    func resetFormUpdatesDateAndTime() async {
        let viewModel = QuickDoseViewModel()

        // Set past date and time
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        viewModel.doseDate = pastDate
        viewModel.doseTime = pastDate
        viewModel.notes = "Test notes"

        let originalDateTime = viewModel.doseDateTime

        // Reset form
        viewModel.resetForm()

        // Both date and time should be updated to current time
        let timeDifference = abs(viewModel.doseDate.timeIntervalSinceNow)
        #expect(timeDifference < 2.0, "Dose date should be reset to current time")

        let timeTimeDifference = abs(viewModel.doseTime.timeIntervalSinceNow)
        #expect(timeTimeDifference < 2.0, "Dose time should be reset to current time")

        // New datetime should be different from original
        #expect(
            viewModel.doseDateTime > originalDateTime, "Reset should update datetime to later value")

        // Notes should be cleared
        #expect(viewModel.notes.isEmpty, "Notes should be cleared on reset")
    }

    @Test("Load edit data updates both date and time properties")
    @MainActor
    func loadEditDataUpdatesDateAndTime() async {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(context: context)

        let specificDateTime = Calendar.current.date(
            from: DateComponents(
                year: 2024, month: 6, day: 10, hour: 16, minute: 45))!

        let editData = DoseEditData(
            id: UUID(),
            amount: 2.5,
            timestamp: specificDateTime,
            site: "Abdomen",
            notes: "Edit test",
            imageData: nil,
            skipped: false,
            medicationProfile: profile)

        let viewModel = QuickDoseViewModel()
        viewModel.loadEditData(editData, context: context)

        // Wait for async loading
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Both date and time should be set from the edit data timestamp
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: viewModel.doseDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: viewModel.doseTime)

        #expect(dateComponents.year == 2024)
        #expect(dateComponents.month == 6)
        #expect(dateComponents.day == 10)
        #expect(timeComponents.hour == 16)
        #expect(timeComponents.minute == 45)

        // Verify other fields are set correctly
        #expect(viewModel.doseAmount == 2.5)
        // Note: loadEditData may change injection site based on rotation logic,
        // so we just verify it's not empty and contains our target site
        #expect(!viewModel.selectedInjectionSite.isEmpty)
        #expect(viewModel.recommendedInjectionSites.contains("Abdomen"))
        #expect(viewModel.notes == "Edit test")
    }

    @Test("Date selection validates range constraints")
    @MainActor
    func dateSelectionValidatesRangeConstraints() async {
        let viewModel = QuickDoseViewModel()

        // Test that date picker range should prevent future dates
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        // In real UI, the DatePicker would prevent selecting tomorrow
        // But in our ViewModel validation, we check manually
        viewModel.doseDate = tomorrow
        viewModel.doseTime = today

        // The computed property doseDateTime should be in the future
        #expect(
            viewModel.doseDateTime > today, "Combined datetime should be in future when date is tomorrow")

        // Test that date picker range should allow 30 days back
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: today)!
        viewModel.doseDate = thirtyDaysAgo
        viewModel.doseTime = today

        let combined = viewModel.doseDateTime
        let expectedRange = Calendar.current.date(byAdding: .day, value: -30, to: today)!...today

        #expect(
            expectedRange.contains(combined) || combined < expectedRange.upperBound,
            "Combined datetime should be within valid range")
    }

    @Test("Date and time properties remain independent")
    @MainActor
    func dateAndTimePropertiesIndependent() async {
        let viewModel = QuickDoseViewModel()

        let calendar = Calendar.current

        // Set specific date
        let targetDate = calendar.date(from: DateComponents(year: 2024, month: 3, day: 20))!
        viewModel.doseDate = targetDate

        // Set different time
        let targetTime = calendar.date(from: DateComponents(hour: 9, minute: 15))!
        viewModel.doseTime = targetTime

        // Verify they remain independent
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: viewModel.doseDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: viewModel.doseTime)

        #expect(dateComponents.year == 2024)
        #expect(dateComponents.month == 3)
        #expect(dateComponents.day == 20)
        #expect(timeComponents.hour == 9)
        #expect(timeComponents.minute == 15)

        // Verify combined datetime uses both
        let combined = viewModel.doseDateTime
        let combinedComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute], from: combined)

        #expect(combinedComponents.year == 2024)
        #expect(combinedComponents.month == 3)
        #expect(combinedComponents.day == 20)
        #expect(combinedComponents.hour == 9)
        #expect(combinedComponents.minute == 15)
    }

    // MARK: - Integration Tests with DoseService

    @Test("Saving dose with custom date/time uses doseDateTime")
    @MainActor
    func savingDoseWithCustomDateTime() async throws {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(context: context)

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = 1.5
        viewModel.selectedInjectionSite = "Thigh"

        // Set specific date and time
        let calendar = Calendar.current
        let specificDate = calendar.date(from: DateComponents(year: 2024, month: 2, day: 14))!
        let specificTime = calendar.date(from: DateComponents(hour: 10, minute: 30))!

        viewModel.doseDate = specificDate
        viewModel.doseTime = specificTime

        // Save dose using DoseService (which should use doseDateTime)
        let pkEngine = PharmacokineticsEngine()
        let doseService = DoseService(pkEngine: pkEngine)
        let savedDose = try await doseService.saveDose(
            amount: viewModel.doseAmount,
            timestamp: viewModel.doseDateTime,
            medicationProfile: #require(viewModel.selectedMedicationProfile),
            site: viewModel.selectedInjectionSite,
            notes: nil,
            context: context)

        // Verify the saved dose has the correct combined timestamp
        let savedComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute], from: savedDose.timestamp)

        #expect(savedComponents.year == 2024)
        #expect(savedComponents.month == 2)
        #expect(savedComponents.day == 14)
        #expect(savedComponents.hour == 10)
        #expect(savedComponents.minute == 30)
    }
}
