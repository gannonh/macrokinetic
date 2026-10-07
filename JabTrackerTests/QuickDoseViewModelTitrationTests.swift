//
//  QuickDoseViewModelTitrationTests.swift
//  JabTrackerTests
//
//  Titration-specific tests for QuickDoseViewModel

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("QuickDoseViewModel Titration Tests", .serialized)
struct QuickDoseViewModelTitrationTests {
    // MARK: - Test Setup

    @MainActor
    func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([User.self, MedicationProfile.self, Dose.self, DoseTitration.self])
        let config = InMemoryTestStore.configuration(schema: schema)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            return (container.mainContext, container)
        } catch {
            fatalError("Failed to create test container: \(error)")
        }
    }

    func createTestMedicationProfile(
        context: ModelContext,
        genericName: String = "semaglutide",
        brandName: String = "Ozempic",
        currentDose: Double = 1.0
    ) throws -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: genericName,
            brandName: brandName,
            currentDose: currentDose)
        profile.preferredInjectionSites = ["Thigh", "Abdomen"]
        context.insert(profile)
        try context.save()
        return profile
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
    func titrationDialogNoTitration() async throws {
        let (context, container) = self.createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = try self.createTestMedicationProfile(
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
    func titrationDialogFutureTitration() async throws {
        let (context, container) = self.createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = try self.createTestMedicationProfile(
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
        try context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        let shouldShow = viewModel.shouldShowTitrationDialog()

        #expect(!shouldShow, "Should not show dialog when titration is in the future")
    }

    @Test("Launch does not offer today's recorded titration as dosing advice")
    @MainActor
    func todayTitrationDialogIsUnavailable() async throws {
        let (context, container) = self.createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = try self.createTestMedicationProfile(
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
        try context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        let shouldShow = viewModel.shouldShowTitrationDialog()

        #expect(shouldShow == false)
        #expect(viewModel.getPendingTitration() == nil)
        #expect(profile.doseTitrations?.count == 1)
        #expect(profile.currentDose == 1.0)
        #expect(context.hasChanges == false)
    }

    @Test("Launch does not offer a past recorded titration as dosing advice")
    @MainActor
    func pastTitrationDialogIsUnavailable() async throws {
        let (context, container) = self.createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = try self.createTestMedicationProfile(
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
        try context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        let shouldShow = viewModel.shouldShowTitrationDialog()

        #expect(shouldShow == false)
        #expect(viewModel.getPendingTitration() == nil)
        #expect(profile.doseTitrations?.count == 1)
        #expect(profile.currentDose == 1.0)
        #expect(context.hasChanges == false)
    }

    @Test("shouldShowTitrationDialog returns false when titration is already completed")
    @MainActor
    func titrationDialogCompletedTitration() async throws {
        let (context, container) = self.createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = try self.createTestMedicationProfile(
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
        try context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        let shouldShow = viewModel.shouldShowTitrationDialog()

        #expect(!shouldShow, "Should not show dialog when titration is already completed")
    }

    @Test("shouldShowTitrationDialog returns false when remindLater flag is set")
    @MainActor
    func titrationDialogRemindLater() async throws {
        let (context, container) = self.createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = try self.createTestMedicationProfile(
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
        try context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        // User clicked "Remind Me Later"
        viewModel.setTitrationRemindLater(true)

        let shouldShow = viewModel.shouldShowTitrationDialog()

        #expect(!shouldShow, "Should not show dialog when user selected 'Remind Me Later'")
    }

    @Test("Recorded titration data stays stored without being offered as launch advice")
    @MainActor
    func recordedTitrationAdviceIsUnavailable() async throws {
        let (context, container) = self.createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = try self.createTestMedicationProfile(
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
        try context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        let pendingTitration = viewModel.getPendingTitration()

        #expect(pendingTitration == nil)
        #expect(todayTitration.fromDose == 1.0)
        #expect(todayTitration.toDose == 2.0)
        #expect(todayTitration.isCompleted == false)
        #expect(profile.doseTitrations?.count == 1)
        #expect(context.hasChanges == false)
    }

    @Test("getPendingTitration returns nil when no pending titration")
    @MainActor
    func getPendingTitrationNone() async throws {
        let (context, container) = self.createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = try self.createTestMedicationProfile(
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

    // MARK: - Titration Action Tests (Business Logic)

    @Test("Disabled completion rejects before changing the recorded titration or profile")
    @MainActor
    func completionRejectsBeforeMutation() async throws {
        let (context, container) = self.createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = try self.createTestMedicationProfile(
            context: context,
            genericName: "semaglutide",
            currentDose: 1.0)

        // Create pending titration
        let titration = DoseTitration(
            fromDose: 1.0,
            toDose: 2.0,
            scheduledDate: Date(),
            isCompleted: false,
            medicationProfile: profile)
        context.insert(titration)
        try context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        #expect(throws: MedicationManager.MedicationError.medicalCalculatorsUnavailable) {
            try viewModel.completeTitration(titration, context: context)
        }
        #expect(titration.isCompleted == false)
        #expect(titration.completedDate == nil)
        #expect(profile.currentDose == 1.0)
        #expect(viewModel.doseAmount == 1.0)
        #expect(context.hasChanges == false)
    }

    @Test("Disabled completion leaves persisted titration and prescribed amount unchanged")
    @MainActor
    func completionPreservesStoredRecords() async throws {
        let (context, container) = self.createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = try self.createTestMedicationProfile(context: context, currentDose: 1.0)

        let titration = DoseTitration(
            fromDose: 1.0,
            toDose: 2.0,
            scheduledDate: Date(),
            isCompleted: false,
            medicationProfile: profile)
        context.insert(titration)
        try context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        #expect(throws: MedicationManager.MedicationError.medicalCalculatorsUnavailable) {
            try viewModel.completeTitration(titration, context: context)
        }
        let reloadedContext = ModelContext(container)
        let reloadedTitration = try #require(reloadedContext.fetch(FetchDescriptor<DoseTitration>()).first)
        let reloadedProfile = try #require(reloadedContext.fetch(FetchDescriptor<MedicationProfile>()).first)
        #expect(reloadedTitration.isCompleted == false)
        #expect(reloadedTitration.completedDate == nil)
        #expect(reloadedTitration.fromDose == 1.0)
        #expect(reloadedTitration.toDose == 2.0)
        #expect(reloadedProfile.currentDose == 1.0)
    }

    @Test("Disabled rescheduling preserves the recorded date and audit timestamp")
    @MainActor
    func rescheduleRejectsBeforeMutation() async throws {
        let (context, container) = self.createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = try self.createTestMedicationProfile(context: context, currentDose: 1.0)

        let originalDate = Date(timeIntervalSince1970: 1_780_000_000)
        let titration = DoseTitration(
            fromDose: 1.0,
            toDose: 2.0,
            scheduledDate: originalDate,
            isCompleted: false,
            medicationProfile: profile)
        titration.updatedAt = Date(timeIntervalSince1970: 1_780_000_001)
        context.insert(titration)
        try context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        #expect(throws: MedicationManager.MedicationError.medicalCalculatorsUnavailable) {
            try viewModel.rescheduleTitration(
                titration, to: Date(timeIntervalSince1970: 1_780_604_800), context: context
            )
        }
        #expect(titration.scheduledDate == Date(timeIntervalSince1970: 1_780_000_000))
        #expect(titration.updatedAt == Date(timeIntervalSince1970: 1_780_000_001))
        #expect(titration.isCompleted == false)
        #expect(context.hasChanges == false)
    }

    @Test("Disabled rescheduling leaves the persisted schedule date unchanged")
    @MainActor
    func reschedulePreservesStoredDate() async throws {
        let (context, container) = self.createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = try self.createTestMedicationProfile(context: context, currentDose: 1.0)

        let titration = DoseTitration(
            fromDose: 1.0,
            toDose: 2.0,
            scheduledDate: Date(timeIntervalSince1970: 1_780_000_000),
            isCompleted: false,
            medicationProfile: profile)
        context.insert(titration)
        try context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        #expect(throws: MedicationManager.MedicationError.medicalCalculatorsUnavailable) {
            try viewModel.rescheduleTitration(
                titration, to: Date(timeIntervalSince1970: 1_780_604_800), context: context
            )
        }
        let reloadedContext = ModelContext(container)
        let reloadedTitration = try #require(reloadedContext.fetch(FetchDescriptor<DoseTitration>()).first)
        #expect(reloadedTitration.scheduledDate == Date(timeIntervalSince1970: 1_780_000_000))
        #expect(reloadedTitration.isCompleted == false)
        #expect(reloadedTitration.completedDate == nil)
    }
}
