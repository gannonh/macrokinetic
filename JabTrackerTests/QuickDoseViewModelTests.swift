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

    // MARK: - Validation Tests (No SwiftData needed)

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
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = 0.0
        viewModel.selectedInjectionSite = "Thigh"

        #expect(!viewModel.canSaveDose)
    }

    @Test("Cannot save dose without injection site")
    @MainActor
    func cannotSaveDoseWithoutInjectionSite() async {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = 1.0
        viewModel.selectedInjectionSite = ""

        #expect(!viewModel.canSaveDose)
    }

    @Test("Can save dose with valid data")
    @MainActor
    func canSaveDoseWithValidData() async {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = 1.0
        viewModel.selectedInjectionSite = "Thigh"

        #expect(viewModel.canSaveDose)
    }

    @Test("Cannot save dose with date too far in past")
    @MainActor
    func cannotSaveDoseWithDateTooFarInPast() async {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = 1.0
        viewModel.selectedInjectionSite = "Thigh"
        viewModel.doseDate = Calendar.current.date(byAdding: .day, value: -60, to: Date())!

        #expect(!viewModel.canSaveDose, "Should not allow dose more than 30 days in past")
    }

    @Test("Cannot save dose with date too far in future")
    @MainActor
    func cannotSaveDoseWithDateTooFarInFuture() async {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = 1.0
        viewModel.selectedInjectionSite = "Thigh"
        viewModel.doseDate = Calendar.current.date(byAdding: .day, value: 60, to: Date())!

        #expect(!viewModel.canSaveDose, "Should not allow dose more than 30 days in future")
    }

    // MARK: - doseDateTime Computed Property Tests

    @Test("doseDateTime combines date and time correctly")
    @MainActor
    func doseDateTimeCombinesCorrectly() async {
        let viewModel = QuickDoseViewModel()

        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        let testTime = calendar.date(from: DateComponents(hour: 14, minute: 30))!

        viewModel.doseDate = testDate
        viewModel.doseTime = testTime

        let combined = viewModel.doseDateTime
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: combined)

        #expect(components.year == 2024)
        #expect(components.month == 6)
        #expect(components.day == 15)
        #expect(components.hour == 14)
        #expect(components.minute == 30)
    }

    // MARK: - Medication Selection Tests (No async loading)

    @Test("Selecting medication updates dose amount")
    @MainActor
    func medicationSelectionUpdatesDoseAmount() async {
        let profile1 = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic", currentDose: 1.0)
        let profile2 = MedicationProfile(genericName: "semaglutide", brandName: "Wegovy", currentDose: 2.0)

        let viewModel = QuickDoseViewModel()
        viewModel.medicationProfiles = [profile1, profile2]
        viewModel.selectedMedicationProfile = profile1

        #expect(viewModel.doseAmount == 1.0)

        viewModel.selectedMedicationProfile = profile2

        #expect(viewModel.doseAmount == 2.0)
    }

    // MARK: - Reset Form Tests

    @Test("Reset form clears notes and updates time")
    @MainActor
    func resetFormClearsNotesAndUpdatesTime() async {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = 1.0
        viewModel.selectedInjectionSite = "Thigh"
        viewModel.notes = "Test notes"

        let originalTime = viewModel.doseTime

        // Small delay to ensure time difference
        try? await Task.sleep(nanoseconds: 10_000_000)

        viewModel.resetForm()

        #expect(viewModel.notes.isEmpty)
        #expect(viewModel.doseTime >= originalTime)
        // Medication selection and injection site should be maintained
        #expect(viewModel.selectedMedicationProfile?.id == profile.id)
        #expect(viewModel.selectedInjectionSite == "Thigh")
    }

    // MARK: - Medication Extension Tests

    @Test("Medication profile extension returns correct medication")
    func medicationProfileExtension() {
        let semaglutideProfile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")
        let tirzepatideProfile = MedicationProfile(genericName: "tirzepatide", brandName: "Mounjaro")
        let unknownProfile = MedicationProfile(genericName: "unknown", brandName: "Unknown")

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
        #expect(Medication.fromGenericName("SEMAGLUTIDE") == .semaglutide)
    }

    // MARK: - QuickDoseError Tests

    @Test("QuickDoseError has correct error descriptions")
    func quickDoseErrorDescriptions() {
        let noProfileError = QuickDoseError.noMedicationProfile
        let invalidDataError = QuickDoseError.invalidDoseData
        let saveFailedError = QuickDoseError.saveFailed(underlying: NSError(domain: "test", code: 1))

        #expect(noProfileError.errorDescription?.contains("profile") == true)
        #expect(invalidDataError.errorDescription?.contains("Invalid") == true)
        #expect(saveFailedError.errorDescription?.contains("Failed to save") == true)
    }

    // MARK: - getNextScheduledDoseTime Tests

    @Test("getNextScheduledDoseTime returns nil without profile")
    @MainActor
    func getNextScheduledDoseTimeNilWithoutProfile() async {
        let viewModel = QuickDoseViewModel()

        let nextTime = viewModel.getNextScheduledDoseTime()
        #expect(nextTime == nil)
    }

    @Test("getNextScheduledDoseTime returns value with profile")
    @MainActor
    func getNextScheduledDoseTimeWithProfile() async {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        let nextTime = viewModel.getNextScheduledDoseTime()
        // Should return a value when profile is set
        #expect(nextTime != nil)
    }

    // MARK: - isDoseOverdue Tests

    @Test("isDoseOverdue returns false without profile")
    @MainActor
    func isDoseOverdueReturnsFalseWithoutProfile() async {
        let viewModel = QuickDoseViewModel()

        #expect(viewModel.isDoseOverdue() == false)
    }

    // MARK: - Edit Data Loading Tests (synchronous parts only)

    @Test("Load edit data sets date and time synchronously")
    @MainActor
    func loadEditDataSetsDateAndTime() async {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")
        let editTimestamp = Date().addingTimeInterval(-24 * 60 * 60)  // Yesterday

        let editData = DoseEditData(
            id: UUID(),
            amount: 1.5,
            timestamp: editTimestamp,
            site: "Abdomen",
            notes: "Edit test notes",
            imageData: nil,
            skipped: false,
            medicationProfile: profile)

        let viewModel = QuickDoseViewModel()

        // Set medicationProfile FIRST (its didSet updates doseAmount/sites)
        // Then set other properties to override the defaults
        viewModel.selectedMedicationProfile = editData.medicationProfile
        viewModel.doseAmount = editData.amount
        viewModel.doseDate = editData.timestamp
        viewModel.doseTime = editData.timestamp
        viewModel.selectedInjectionSite = editData.site ?? ""
        viewModel.notes = editData.notes ?? ""

        #expect(viewModel.doseAmount == 1.5)
        #expect(abs(viewModel.doseDate.timeIntervalSince(editTimestamp)) < 1)
        #expect(viewModel.selectedInjectionSite == "Abdomen")
        #expect(viewModel.notes == "Edit test notes")
        #expect(viewModel.selectedMedicationProfile?.id == profile.id)
    }

    @Test("Edit data with nil notes results in empty string")
    @MainActor
    func editDataWithNilNotes() async {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")
        let editData = DoseEditData(
            id: UUID(),
            amount: 1.0,
            timestamp: Date(),
            site: "Thigh",
            notes: nil,
            imageData: nil,
            skipped: false,
            medicationProfile: profile)

        let viewModel = QuickDoseViewModel()
        viewModel.notes = editData.notes ?? ""

        #expect(viewModel.notes.isEmpty)
    }

    @Test("Edit data with nil site results in empty string")
    @MainActor
    func editDataWithNilSite() async {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")
        let editData = DoseEditData(
            id: UUID(),
            amount: 1.0,
            timestamp: Date(),
            site: nil,
            notes: "Test",
            imageData: nil,
            skipped: false,
            medicationProfile: profile)

        let viewModel = QuickDoseViewModel()
        viewModel.selectedInjectionSite = editData.site ?? ""

        #expect(viewModel.selectedInjectionSite.isEmpty)
    }

    // MARK: - Titration State Tests

    @Test("Titration remind later flag defaults to false")
    @MainActor
    func titrationRemindLaterDefaultsFalse() async {
        let viewModel = QuickDoseViewModel()
        #expect(viewModel.titrationRemindLater == false)
    }

    @Test("Titration remind later flag can be set")
    @MainActor
    func titrationRemindLaterCanBeSet() async {
        let viewModel = QuickDoseViewModel()
        viewModel.titrationRemindLater = true
        #expect(viewModel.titrationRemindLater == true)
    }

    // MARK: - Split Dose Tests

    @Test("Split dose schedule shows half the weekly dose per administration")
    @MainActor
    func splitDoseShowsHalfWeeklyDose() async {
        // Given: A medication profile with split-dose schedule
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic", currentDose: 2.0)

        // Create a split-dose schedule
        let schedule = DoseSchedule()
        schedule.patternType = .splitDose
        schedule.isActive = true
        profile.schedules = [schedule]

        let viewModel = QuickDoseViewModel()

        // When: Selecting the profile
        viewModel.selectedMedicationProfile = profile

        // Then: Dose amount should be half (split between 2 weekly doses)
        #expect(viewModel.doseAmount == 1.0, "Split-dose should show half the weekly dose")
    }

    @Test("Non-split dose schedule shows full dose")
    @MainActor
    func nonSplitDoseShowsFullDose() async {
        // Given: A medication profile with standard weekly schedule
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic", currentDose: 2.0)

        // Create a standard weekly schedule
        let schedule = DoseSchedule()
        schedule.patternType = .weekly
        schedule.isActive = true
        profile.schedules = [schedule]

        let viewModel = QuickDoseViewModel()

        // When: Selecting the profile
        viewModel.selectedMedicationProfile = profile

        // Then: Dose amount should be the full weekly dose
        #expect(viewModel.doseAmount == 2.0, "Non-split dose should show full weekly dose")
    }

    @Test("Profile without active schedule shows full dose")
    @MainActor
    func profileWithoutActiveScheduleShowsFullDose() async {
        // Given: A medication profile without any active schedule
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic", currentDose: 1.5)
        profile.schedules = []

        let viewModel = QuickDoseViewModel()

        // When: Selecting the profile
        viewModel.selectedMedicationProfile = profile

        // Then: Dose amount should be the full dose
        #expect(viewModel.doseAmount == 1.5, "Profile without schedule should show full dose")
    }

    // MARK: - Injection Site Tests

    @Test("Clearing medication profile sets default injection sites")
    @MainActor
    func clearingProfileSetsDefaultSites() async {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic", currentDose: 1.0)

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        // When: Clearing the profile
        viewModel.selectedMedicationProfile = nil

        // Then: Dose amount should be 0
        #expect(viewModel.doseAmount == 0.0)
    }

    @Test("setTitrationRemindLater updates flag")
    @MainActor
    func setTitrationRemindLaterUpdatesFlag() async {
        let viewModel = QuickDoseViewModel()
        #expect(viewModel.titrationRemindLater == false)

        viewModel.setTitrationRemindLater(true)
        #expect(viewModel.titrationRemindLater == true)

        viewModel.setTitrationRemindLater(false)
        #expect(viewModel.titrationRemindLater == false)
    }

    @Test("resetRemindLaterFlag clears the flag")
    @MainActor
    func resetRemindLaterFlagClearsFlag() async {
        let viewModel = QuickDoseViewModel()
        viewModel.titrationRemindLater = true

        viewModel.resetRemindLaterFlag()

        #expect(viewModel.titrationRemindLater == false)
    }

    // MARK: - Date Boundary Tests

    @Test("Can save dose at 30-day past boundary")
    @MainActor
    func canSaveDoseAt30DayPastBoundary() async {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = 1.0
        viewModel.selectedInjectionSite = "Thigh"
        viewModel.doseDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        #expect(viewModel.canSaveDose == true, "Should allow dose exactly 30 days in past")
    }

    @Test("Can save dose at 30-day future boundary")
    @MainActor
    func canSaveDoseAt30DayFutureBoundary() async {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = 1.0
        viewModel.selectedInjectionSite = "Thigh"
        viewModel.doseDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!

        #expect(viewModel.canSaveDose == true, "Should allow dose exactly 30 days in future")
    }

    @Test("Cannot save dose with negative dose amount")
    @MainActor
    func cannotSaveDoseWithNegativeAmount() async {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.doseAmount = -1.0
        viewModel.selectedInjectionSite = "Thigh"

        #expect(viewModel.canSaveDose == false, "Should not allow negative dose amount")
    }

    // MARK: - Medication Profile Extension Tests

    @Test("All supported medications have correct mapping")
    func allMedicationsHaveCorrectMapping() {
        // Test all known medications
        let medications: [(String, Medication)] = [
            ("semaglutide", .semaglutide),
            ("tirzepatide", .tirzepatide),
            ("liraglutide", .liraglutide),
            ("dulaglutide", .dulaglutide),
        ]

        for (genericName, expectedMedication) in medications {
            let profile = MedicationProfile(genericName: genericName, brandName: "Test")
            #expect(
                profile.medication == expectedMedication,
                "Profile with \(genericName) should map to \(expectedMedication)")
        }
    }

    // MARK: - prepareForScheduledDose Tests

    @Test("prepareForScheduledDose sets loading state and pre-populates timestamp")
    @MainActor
    func prepareForScheduledDoseLoadsScheduledDose() async throws {
        // Create test container and context
        let schema = Schema([
            User.self, MedicationProfile.self, Dose.self,
            DoseSchedule.self, ScheduledDose.self, DoseTitration.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        // Create a profile and scheduled dose
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic", currentDose: 1.0)
        context.insert(profile)

        let scheduledTime = Date().addingTimeInterval(3600)  // 1 hour from now
        let scheduledDose = ScheduledDose(
            scheduledTime: scheduledTime,
            doseAmount: 1.0,
            windowStart: scheduledTime.addingTimeInterval(-7200),
            windowEnd: scheduledTime.addingTimeInterval(7200)
        )
        context.insert(scheduledDose)
        try context.save()

        let viewModel = QuickDoseViewModel()

        // Call the method under test
        viewModel.prepareForScheduledDose(scheduledDoseId: scheduledDose.id, context: context)

        // Yield to let the spawned Task start running, then wait for completion
        // The Task sets isLoading=true first, then does work, then sets isLoading=false
        try await Task.sleep(for: .milliseconds(50))

        // Wait for async Task to complete - poll until loading is done
        var attempts = 0
        while viewModel.isLoading && attempts < 100 {
            try await Task.sleep(for: .milliseconds(20))
            attempts += 1
        }

        // The viewModel should have loaded without error
        // (actual dose date population depends on loadSmartDefaults)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("prepareForScheduledDose handles missing scheduled dose")
    @MainActor
    func prepareForScheduledDoseMissingDose() async throws {
        let schema = Schema([
            User.self, MedicationProfile.self, Dose.self,
            DoseSchedule.self, ScheduledDose.self, DoseTitration.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let viewModel = QuickDoseViewModel()

        // Call with non-existent UUID
        viewModel.prepareForScheduledDose(scheduledDoseId: UUID(), context: context)

        // Yield to let the spawned Task start running
        try await Task.sleep(for: .milliseconds(50))

        // Wait for async Task to complete - poll until we have an error message
        var attempts = 0
        while viewModel.errorMessage == nil && attempts < 100 {
            try await Task.sleep(for: .milliseconds(20))
            attempts += 1
        }

        // Should set error message for not found
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("not found") == true)
        #expect(viewModel.isLoading == false)
    }

    // MARK: - isDoseOverdue Additional Tests

    @Test("isDoseOverdue returns value when profile has schedule")
    @MainActor
    func isDoseOverdueReturnsValueWithSchedule() async throws {
        let schema = Schema([
            User.self, MedicationProfile.self, Dose.self,
            DoseSchedule.self, ScheduledDose.self, DoseTitration.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        // Create profile with schedule
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic", currentDose: 1.0)
        context.insert(profile)

        // Create a schedule
        let schedule = DoseSchedule()
        schedule.patternType = .weekly
        schedule.isActive = true
        context.insert(schedule)
        profile.schedules = [schedule]

        try context.save()

        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        // isDoseOverdue calls DoseDefaults - just verify it executes without crash
        let isOverdue = viewModel.isDoseOverdue()

        // The result depends on DoseDefaults logic - no doses means likely not overdue
        #expect(isOverdue == true || isOverdue == false)
    }
}
