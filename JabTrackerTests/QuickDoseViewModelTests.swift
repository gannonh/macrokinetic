//
//  QuickDoseViewModelTests.swift
//  JabTrackerTests
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("QuickDoseViewModel Tests")
struct QuickDoseViewModelTests {
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

    func createTestDose(
        context: ModelContext,
        amount: Double = 1.0,
        site: String = "Thigh",
        medication: MedicationProfile
    ) -> Dose {
        let dose = Dose(
            amount: amount,
            timestamp: Date().addingTimeInterval(-7 * 24 * 60 * 60),  // 1 week ago
            site: site)
        context.insert(dose)

        // Set relationship after both objects are in context
        dose.medication = medication

        try? context.save()
        return dose
    }

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with default values")
    @MainActor
    func viewModelInitialization() async {
        let viewModel = QuickDoseViewModel()

        #expect(viewModel.medicationProfiles.isEmpty)
        #expect(viewModel.selectedMedicationProfile == nil)
        #expect(viewModel.doseAmount == 0.0)
        #expect(viewModel.selectedInjectionSite.isEmpty)
        #expect(viewModel.notes.isEmpty)
        #expect(viewModel.recommendedInjectionSites.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isLoading)
        #expect(!viewModel.canSaveDose)
    }

    // MARK: - Smart Defaults Loading Tests

    @Test("Loading smart defaults with medication profiles")
    @MainActor
    func loadSmartDefaultsWithProfiles() async {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(
            context: context,
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0)

        let viewModel = QuickDoseViewModel()

        viewModel.loadSmartDefaults(context: context)

        // Wait for async loading to complete
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

        #expect(viewModel.medicationProfiles.count == 1)
        #expect(viewModel.selectedMedicationProfile?.id == profile.id)
        #expect(viewModel.doseAmount == 1.0)
        #expect(!viewModel.selectedInjectionSite.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isLoading)
        #expect(viewModel.canSaveDose)
    }

    @Test("Loading smart defaults with no medication profiles shows error")
    @MainActor
    func loadSmartDefaultsWithNoProfiles() async {
        let context = self.createTestContext()
        let viewModel = QuickDoseViewModel()

        viewModel.loadSmartDefaults(context: context)

        // Wait for async loading to complete
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

        #expect(viewModel.medicationProfiles.isEmpty)
        #expect(viewModel.selectedMedicationProfile == nil)
        #expect(viewModel.errorMessage?.contains("No medication profiles found") == true)
        #expect(!viewModel.isLoading)
        #expect(!viewModel.canSaveDose)
    }

    @Test("Smart defaults include injection site rotation")
    @MainActor
    func smartDefaultsInjectionSiteRotation() async {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(context: context)

        // Create dose history with specific injection sites
        _ = self.createTestDose(context: context, site: "Thigh", medication: profile)
        _ = self.createTestDose(context: context, site: "Abdomen", medication: profile)

        let viewModel = QuickDoseViewModel()
        viewModel.loadSmartDefaults(context: context)

        // Wait for async loading to complete
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

        #expect(viewModel.recommendedInjectionSites.contains("Thigh"))
        #expect(viewModel.recommendedInjectionSites.contains("Abdomen"))
        #expect(!viewModel.selectedInjectionSite.isEmpty)
    }

    // MARK: - Medication Selection Tests

    @Test("Selecting medication updates dose amount")
    @MainActor
    func medicationSelectionUpdatesDoseAmount() async {
        let context = self.createTestContext()
        let profile1 = self.createTestMedicationProfile(context: context, currentDose: 1.0)
        let profile2 = self.createTestMedicationProfile(
            context: context, brandName: "Wegovy", currentDose: 2.0)

        let viewModel = QuickDoseViewModel()
        viewModel.loadSmartDefaults(context: context)

        // Wait for loading
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Initially should select first profile
        #expect(viewModel.doseAmount == profile1.currentDose)

        // Change to second profile
        viewModel.selectedMedicationProfile = profile2

        #expect(viewModel.doseAmount == 2.0)
    }

    @Test("Selecting medication updates recommended injection sites")
    @MainActor
    func medicationSelectionUpdatesInjectionSites() async {
        let context = self.createTestContext()
        let semaglutideProfile = self.createTestMedicationProfile(
            context: context,
            genericName: "semaglutide")
        let liraglutideProfile = self.createTestMedicationProfile(
            context: context,
            genericName: "liraglutide",
            brandName: "Victoza")

        let viewModel = QuickDoseViewModel()
        viewModel.loadSmartDefaults(context: context)

        // Wait for loading
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Select semaglutide profile
        viewModel.selectedMedicationProfile = semaglutideProfile

        #expect(viewModel.recommendedInjectionSites.contains("Thigh"))
        #expect(viewModel.recommendedInjectionSites.contains("Abdomen"))

        // Select liraglutide profile (daily medication with different site recommendations)
        viewModel.selectedMedicationProfile = liraglutideProfile

        #expect(viewModel.recommendedInjectionSites.contains("Thigh"))
        #expect(viewModel.recommendedInjectionSites.contains("Abdomen"))
    }

    // MARK: - Validation Tests

    @Test("Can save dose validation with valid data")
    @MainActor
    func canSaveDoseWithValidData() async {
        let context = self.createTestContext()
        _ = self.createTestMedicationProfile(context: context)

        let viewModel = QuickDoseViewModel()
        viewModel.loadSmartDefaults(context: context)

        // Wait for loading
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.canSaveDose)
    }

    @Test("Cannot save dose without medication profile")
    @MainActor
    func cannotSaveDoseWithoutMedicationProfile() async {
        let viewModel = QuickDoseViewModel()

        viewModel.doseAmount = 1.0
        viewModel.selectedInjectionSite = "Thigh"

        #expect(!viewModel.canSaveDose)
    }

    @Test("Cannot save dose with zero amount")
    @MainActor
    func cannotSaveDoseWithZeroAmount() async {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(context: context)

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = 0.0
        viewModel.selectedInjectionSite = "Thigh"

        #expect(!viewModel.canSaveDose)
    }

    @Test("Cannot save dose without injection site")
    @MainActor
    func cannotSaveDoseWithoutInjectionSite() async {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(context: context)

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = 1.0
        viewModel.selectedInjectionSite = ""

        #expect(!viewModel.canSaveDose)
    }

    // MARK: - Dose Saving Tests

    @Test("Saving dose creates new dose in context")
    @MainActor
    func savingDoseCreatesNewDose() async throws {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(context: context)

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = 1.5
        viewModel.selectedInjectionSite = "Abdomen"
        viewModel.notes = "Test dose"

        let initialDoseCount = try context.fetch(FetchDescriptor<Dose>()).count

        // Use DoseService for dose saving (with PK integration)
        let pkEngine = PharmacokineticsEngine()
        let doseService = DoseService(pkEngine: pkEngine)
        let savedDose = try await doseService.saveDose(
            amount: viewModel.doseAmount,
            timestamp: viewModel.doseTime,
            medicationProfile: #require(viewModel.selectedMedicationProfile),
            site: viewModel.selectedInjectionSite,
            notes: viewModel.notes.isEmpty ? nil : viewModel.notes,
            context: context)

        // Reset form after successful save
        viewModel.resetForm()

        let finalDoseCount = try context.fetch(FetchDescriptor<Dose>()).count

        #expect(
            finalDoseCount >= initialDoseCount + 1, "Should have at least one more dose after saving")

        // Verify the saved dose exists in context
        let allDoses = try context.fetch(FetchDescriptor<Dose>())
        let savedDoseInContext = allDoses.first { $0.id == savedDose.id }
        #expect(savedDoseInContext != nil, "Saved dose should exist in context")

        // Check the dose returned by DoseService instead of searching
        #expect(savedDose.amount == 1.5)
        #expect(savedDose.site == "Abdomen")
        #expect(savedDose.notes == "Test dose")
        #expect(savedDose.medication?.id == profile.id)
    }

    @Test("Saving dose with empty notes saves nil")
    @MainActor
    func savingDoseWithEmptyNotes() async throws {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(context: context)

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = 1.0
        viewModel.selectedInjectionSite = "Thigh"
        viewModel.notes = ""

        // Use DoseService for dose saving (with PK integration)
        let pkEngine = PharmacokineticsEngine()
        let doseService = DoseService(pkEngine: pkEngine)
        _ = try await doseService.saveDose(
            amount: viewModel.doseAmount,
            timestamp: viewModel.doseTime,
            medicationProfile: #require(viewModel.selectedMedicationProfile),
            site: viewModel.selectedInjectionSite,
            notes: viewModel.notes.isEmpty ? nil : viewModel.notes,
            context: context)

        let savedDoses = try context.fetch(FetchDescriptor<Dose>())
        let savedDose = savedDoses.last

        #expect(savedDose?.notes == nil)
    }

    @Test("Saving dose resets form fields")
    @MainActor
    func savingDoseResetsForm() async throws {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(context: context)

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = 1.0
        viewModel.selectedInjectionSite = "Thigh"
        viewModel.notes = "Test notes"

        let originalTime = viewModel.doseTime

        // Use DoseService for dose saving (with PK integration)
        let pkEngine = PharmacokineticsEngine()
        let doseService = DoseService(pkEngine: pkEngine)
        _ = try await doseService.saveDose(
            amount: viewModel.doseAmount,
            timestamp: viewModel.doseTime,
            medicationProfile: #require(viewModel.selectedMedicationProfile),
            site: viewModel.selectedInjectionSite,
            notes: viewModel.notes.isEmpty ? nil : viewModel.notes,
            context: context)

        // Reset form after successful save
        viewModel.resetForm()

        // Notes should be reset
        #expect(viewModel.notes.isEmpty)

        // Time should be updated to current time (approximately)
        #expect(viewModel.doseTime > originalTime)

        // Medication selection and injection site should be maintained for convenience
        #expect(viewModel.selectedMedicationProfile?.id == profile.id)
        #expect(viewModel.selectedInjectionSite == "Thigh")
    }

    @Test("Saving invalid dose throws error")
    @MainActor
    func savingInvalidDoseThrowsError() async {
        let context = self.createTestContext()
        let viewModel = QuickDoseViewModel()

        // Set invalid state (negative dose amount which DoseService should reject)
        let profile = self.createTestMedicationProfile(context: context)
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = -1.0  // Invalid: negative amount
        viewModel.selectedInjectionSite = "Thigh"

        do {
            // Try to use DoseService with invalid data (negative dose amount)
            let pkEngine = PharmacokineticsEngine()
            let doseService = DoseService(pkEngine: pkEngine)
            _ = try await doseService.saveDose(
                amount: viewModel.doseAmount,
                timestamp: viewModel.doseTime,
                medicationProfile: #require(viewModel.selectedMedicationProfile),
                site: viewModel.selectedInjectionSite,
                notes: nil as String?,
                context: context)
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            // Should catch DoseService validation error for negative amount
            #expect(error is DoseServiceError, "Should throw DoseServiceError for invalid dose amount")
        }
    }

    // MARK: - Convenience Method Tests

    @Test("Get next scheduled dose time for weekly medication")
    @MainActor
    func getNextScheduledDoseTimeWeekly() async {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(
            context: context,
            genericName: "semaglutide"  // weekly medication
        )

        // Add a dose from 1 week ago
        _ = self.createTestDose(context: context, medication: profile)

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        let nextDoseTime = viewModel.getNextScheduledDoseTime()

        #expect(nextDoseTime != nil, "Expected getNextScheduledDoseTime() to return a non-nil value")

        // Safe unwrapping to avoid crash
        guard let nextDoseTime else {
            #expect(Bool(false), "nextDoseTime was nil when it shouldn't be")
            return
        }

        // Next dose should be approximately now (since last dose was 1 week ago)
        let timeDifference = abs(nextDoseTime.timeIntervalSinceNow)
        #expect(
            timeDifference < 24 * 60 * 60,
            "Time difference should be within 24 hours, but was \(timeDifference / 3600) hours")
    }

    @Test("Is dose overdue detection")
    @MainActor
    func isDoseOverdueDetection() async {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(context: context)

        // Create a dose that's overdue (2 weeks ago for weekly medication)
        let overdueDose = Dose(
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-14 * 24 * 60 * 60)  // 2 weeks ago
        )
        context.insert(overdueDose)

        // Set relationship after both objects are in context
        overdueDose.medication = profile

        try? context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        let isOverdue = viewModel.isDoseOverdue()

        #expect(isOverdue)
    }

    // MARK: - Error Handling Tests

    @Test("Error message clears when loading succeeds")
    @MainActor
    func errorMessageClearsOnSuccessfulLoading() async {
        let context = self.createTestContext()
        let viewModel = QuickDoseViewModel()

        // First load with no profiles (should set error)
        viewModel.loadSmartDefaults(context: context)
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.errorMessage != nil)

        // Add a profile
        _ = self.createTestMedicationProfile(context: context)

        // Load again (should clear error)
        viewModel.loadSmartDefaults(context: context)
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Medication Extension Tests

    @Test("Medication profile extension returns correct medication")
    func medicationProfileExtension() {
        let semaglutideProfile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic")
        let tirzepatideProfile = MedicationProfile(
            genericName: "tirzepatide",
            brandName: "Mounjaro")
        let unknownProfile = MedicationProfile(
            genericName: "unknown",
            brandName: "Unknown")

        #expect(semaglutideProfile.medication == .semaglutide)
        #expect(tirzepatideProfile.medication == .tirzepatide)
        #expect(unknownProfile.medication == nil)
    }

    @Test("Medication from generic name helper")
    func medicationFromGenericName() {
        #expect(Medication.fromGenericName("semaglutide") == .semaglutide)
        #expect(Medication.fromGenericName("tirzepatide") == .tirzepatide)
        #expect(Medication.fromGenericName("liraglutide") == .liraglutide)
        #expect(Medication.fromGenericName("dulaglutide") == .dulaglutide)
        #expect(Medication.fromGenericName("unknown") == nil)
        #expect(Medication.fromGenericName("SEMAGLUTIDE") == .semaglutide)  // Case insensitive
    }

    // MARK: - Titration Detection Tests (Issue #286)

    @Test("shouldShowTitrationDialog returns false when no medication profile selected")
    @MainActor
    func titrationDialogNoProfile() async {
        let viewModel = QuickDoseViewModel()

        let shouldShow = viewModel.shouldShowTitrationDialog()

        #expect(!shouldShow, "Should not show dialog when no medication profile selected")
    }

    @Test("shouldShowTitrationDialog returns false when medication profile has no titration")
    @MainActor
    func titrationDialogNoTitration() async {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(
            context: context,
            genericName: "semaglutide",
            currentDose: 1.0)

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        let shouldShow = viewModel.shouldShowTitrationDialog()

        #expect(!shouldShow, "Should not show dialog when no titration exists")
    }

    @Test("shouldShowTitrationDialog returns false when titration is in the future")
    @MainActor
    func titrationDialogFutureTitration() async {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(
            context: context,
            genericName: "semaglutide",
            currentDose: 1.0)

        // Create titration scheduled for 7 days in future
        let futureTitration = DoseTitration(
            fromDose: 1.0,
            toDose: 2.0,
            scheduledDate: Date().addingTimeInterval(7 * 24 * 60 * 60),  // 7 days future
            isCompleted: false,
            medicationProfile: profile)
        context.insert(futureTitration)
        try? context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        let shouldShow = viewModel.shouldShowTitrationDialog()

        #expect(!shouldShow, "Should not show dialog when titration is in the future")
    }

    @Test("shouldShowTitrationDialog returns true when titration date is today")
    @MainActor
    func titrationDialogTodayTitration() async {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(
            context: context,
            genericName: "semaglutide",
            currentDose: 1.0)

        // Create titration scheduled for today
        let todayTitration = DoseTitration(
            fromDose: 1.0,
            toDose: 2.0,
            scheduledDate: Date(),  // Today
            isCompleted: false,
            medicationProfile: profile)
        context.insert(todayTitration)
        try? context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        let shouldShow = viewModel.shouldShowTitrationDialog()

        #expect(shouldShow, "Should show dialog when titration date is today")
    }

    @Test("shouldShowTitrationDialog returns true when titration date has passed")
    @MainActor
    func titrationDialogPastTitration() async {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(
            context: context,
            genericName: "semaglutide",
            currentDose: 1.0)

        // Create titration scheduled for 3 days ago
        let pastTitration = DoseTitration(
            fromDose: 1.0,
            toDose: 2.0,
            scheduledDate: Date().addingTimeInterval(-3 * 24 * 60 * 60),  // 3 days ago
            isCompleted: false,
            medicationProfile: profile)
        context.insert(pastTitration)
        try? context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        let shouldShow = viewModel.shouldShowTitrationDialog()

        #expect(shouldShow, "Should show dialog when titration date has passed")
    }

    @Test("shouldShowTitrationDialog returns false when titration is already completed")
    @MainActor
    func titrationDialogCompletedTitration() async {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(
            context: context,
            genericName: "semaglutide",
            currentDose: 1.0)

        // Create completed titration
        let completedTitration = DoseTitration(
            fromDose: 1.0,
            toDose: 2.0,
            scheduledDate: Date().addingTimeInterval(-3 * 24 * 60 * 60),  // 3 days ago
            isCompleted: true,  // Already completed
            completedDate: Date().addingTimeInterval(-2 * 24 * 60 * 60),  // Completed 2 days ago
            medicationProfile: profile)
        context.insert(completedTitration)
        try? context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        let shouldShow = viewModel.shouldShowTitrationDialog()

        #expect(!shouldShow, "Should not show dialog when titration is already completed")
    }

    @Test("shouldShowTitrationDialog returns false when remindLater flag is set")
    @MainActor
    func titrationDialogRemindLater() async {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(
            context: context,
            genericName: "semaglutide",
            currentDose: 1.0)

        // Create titration scheduled for today
        let todayTitration = DoseTitration(
            fromDose: 1.0,
            toDose: 2.0,
            scheduledDate: Date(),
            isCompleted: false,
            medicationProfile: profile)
        context.insert(todayTitration)
        try? context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        // User clicked "Remind Me Later"
        viewModel.setTitrationRemindLater(true)

        let shouldShow = viewModel.shouldShowTitrationDialog()

        #expect(!shouldShow, "Should not show dialog when user selected 'Remind Me Later'")
    }

    @Test("getPendingTitration returns correct titration")
    @MainActor
    func getPendingTitrationCorrect() async {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(
            context: context,
            genericName: "semaglutide",
            currentDose: 1.0)

        // Create titration scheduled for today
        let todayTitration = DoseTitration(
            fromDose: 1.0,
            toDose: 2.0,
            scheduledDate: Date(),
            isCompleted: false,
            medicationProfile: profile)
        context.insert(todayTitration)
        try? context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        let pendingTitration = viewModel.getPendingTitration()

        #expect(pendingTitration != nil, "Should return pending titration")
        #expect(pendingTitration?.fromDose == 1.0)
        #expect(pendingTitration?.toDose == 2.0)
    }

    @Test("getPendingTitration returns nil when no pending titration")
    @MainActor
    func getPendingTitrationNone() async {
        let context = self.createTestContext()
        let profile = self.createTestMedicationProfile(
            context: context,
            genericName: "semaglutide",
            currentDose: 1.0)

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        let pendingTitration = viewModel.getPendingTitration()

        #expect(pendingTitration == nil, "Should return nil when no pending titration")
    }

    @Test("resetRemindLaterFlag resets the flag after dose entry")
    @MainActor
    func resetRemindLaterFlag() async {
        let viewModel = QuickDoseViewModel()

        viewModel.setTitrationRemindLater(true)
        #expect(viewModel.titrationRemindLater == true)

        viewModel.resetRemindLaterFlag()
        #expect(viewModel.titrationRemindLater == false, "Should reset flag after dose entry")
    }
}
