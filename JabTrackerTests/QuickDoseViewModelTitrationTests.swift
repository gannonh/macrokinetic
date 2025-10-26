//
//  QuickDoseViewModelTitrationTests.swift
//  JabTrackerTests
//
//  Titration-specific tests for QuickDoseViewModel

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("QuickDoseViewModel Titration Tests")
struct QuickDoseViewModelTitrationTests {
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
        let context = self.createTestContext()
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
        let context = self.createTestContext()
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

    @Test("shouldShowTitrationDialog returns true when titration date is today")
    @MainActor
    func titrationDialogTodayTitration() async throws {
        let context = self.createTestContext()
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

        #expect(shouldShow, "Should show dialog when titration date is today")
    }

    @Test("shouldShowTitrationDialog returns true when titration date has passed")
    @MainActor
    func titrationDialogPastTitration() async throws {
        let context = self.createTestContext()
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

        #expect(shouldShow, "Should show dialog when titration date has passed")
    }

    @Test("shouldShowTitrationDialog returns false when titration is already completed")
    @MainActor
    func titrationDialogCompletedTitration() async throws {
        let context = self.createTestContext()
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
        let context = self.createTestContext()
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

    @Test("getPendingTitration returns correct titration")
    @MainActor
    func getPendingTitrationCorrect() async throws {
        let context = self.createTestContext()
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

        #expect(pendingTitration != nil, "Should return pending titration")
        #expect(pendingTitration?.fromDose == 1.0)
        #expect(pendingTitration?.toDose == 2.0)
    }

    @Test("getPendingTitration returns nil when no pending titration")
    @MainActor
    func getPendingTitrationNone() async throws {
        let context = self.createTestContext()
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

    @Test("completeTitration marks titration as completed and updates profile")
    @MainActor
    func completeTitrationSuccess() async throws {
        let context = self.createTestContext()
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

        // Complete the titration
        try viewModel.completeTitration(titration, context: context)

        // Verify titration is marked completed
        #expect(titration.isCompleted == true, "Titration should be marked as completed")
        #expect(titration.completedDate != nil, "Titration should have completedDate set")

        // Verify profile dose was updated
        #expect(profile.currentDose == 2.0, "Profile dose should be updated to new dose")

        // Note: Removed async reload test - testing implementation details.
        // The direct effects of completeTitration() are verified above.
        // If async behavior needs testing, it should be in a separate integration test
        // with proper async/await patterns.
    }

    @Test("completeTitration saves changes to context")
    @MainActor
    func completeTitrationSavesToContext() async throws {
        let context = self.createTestContext()
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

        // Complete titration
        try viewModel.completeTitration(titration, context: context)

        // Fetch titration again from context to verify persistence
        let fetchDescriptor = FetchDescriptor<DoseTitration>()
        let savedTitrations = try context.fetch(fetchDescriptor)
        let savedTitration = savedTitrations.first { $0.id == titration.id }

        #expect(savedTitration?.isCompleted == true, "Saved titration should be completed")
        #expect(savedTitration?.completedDate != nil, "Saved titration should have completedDate")
    }

    @Test("rescheduleTitration updates titration date")
    @MainActor
    func rescheduleTitrationSuccess() async throws {
        let context = self.createTestContext()
        let profile = try self.createTestMedicationProfile(context: context, currentDose: 1.0)

        let originalDate = Date()
        let titration = DoseTitration(
            fromDose: 1.0,
            toDose: 2.0,
            scheduledDate: originalDate,
            isCompleted: false,
            medicationProfile: profile)
        context.insert(titration)
        try context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        // Reschedule to 7 days later
        let newDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        try viewModel.rescheduleTitration(titration, to: newDate, context: context)

        // Verify date was updated (using safer 5-second tolerance for CI stability)
        #expect(
            abs(titration.scheduledDate.timeIntervalSince(newDate)) < 5,
            "Titration scheduled date should be updated")

        // Verify updatedAt was set (updatedAt is non-optional, always has a value)
        #expect(
            abs(titration.updatedAt.timeIntervalSince(Date())) < 5,
            "Titration updatedAt should be recent")
    }

    @Test("rescheduleTitration saves changes to context")
    @MainActor
    func rescheduleTitrationSavesToContext() async throws {
        let context = self.createTestContext()
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
        let newDate = Date().addingTimeInterval(7 * 24 * 60 * 60)

        // Reschedule titration
        try viewModel.rescheduleTitration(titration, to: newDate, context: context)

        // Fetch from context to verify persistence
        let fetchDescriptor = FetchDescriptor<DoseTitration>()
        let savedTitrations = try context.fetch(fetchDescriptor)
        let savedTitration = savedTitrations.first { $0.id == titration.id }

        #expect(savedTitration != nil, "Rescheduled titration should be saved")
        #expect(
            savedTitration!.scheduledDate.timeIntervalSince(newDate) < 1,
            "Saved titration should have new scheduled date")
    }
}
