import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("Medication recording in the launch release")
struct MedicalReleasePolicyTests {
    @Test("Prescribed amounts remain exact without drug defaults or compounding calculations")
    @MainActor
    func prescribedProfileAmounts() throws {
        let controller = DataController(inMemory: true)
        let context = controller.container.mainContext
        let user = User(name: "Medication recorder")
        context.insert(user)
        let manager = MedicationManager(modelContext: context)
        let profile = try manager.createProfile(
            for: user, medication: .semaglutide, brandName: "Generic",
            currentDose: 1.375, isCompounded: true
        )

        #expect(profile.currentDose == 1.375)
        #expect(profile.isCompounded == true)
        #expect(profile.vialStrength == nil)
        #expect(profile.reconstitutionVolume == nil)
        #expect(profile.concentration == nil)
        #expect(profile.unitsPerDose == nil)
        #expect(try context.fetchCount(FetchDescriptor<DoseSchedule>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ScheduledDose>()) == 0)

        try manager.updateProfile(profile, currentDose: 3.125)
        let reloaded = try #require(context.fetch(FetchDescriptor<MedicationProfile>()).first)
        #expect(reloaded.currentDose == 3.125)
        #expect(reloaded.user?.id == user.id)
    }

    @Test("Invalid numeric amounts fail before changing profile data")
    @MainActor
    func numericValidationBeforeWrites() throws {
        let controller = DataController(inMemory: true)
        let context = controller.container.mainContext
        let user = User(name: "Medication recorder")
        context.insert(user)
        let manager = MedicationManager(modelContext: context)
        let profile = try manager.createProfile(
            for: user, medication: .semaglutide, brandName: "Ozempic", currentDose: 1.375
        )

        for invalidAmount in [0, -1, Double.nan, Double.infinity, -Double.infinity] {
            #expect(throws: MedicationManager.MedicationError.invalidDose) {
                try manager.updateProfile(
                    profile, medication: .tirzepatide, brandName: "Changed",
                    currentDose: invalidAmount, notes: "Changed"
                )
            }
            #expect(throws: MedicationManager.MedicationError.invalidDose) {
                _ = try manager.createProfile(
                    for: user, medication: .semaglutide, brandName: "Ozempic", currentDose: invalidAmount
                )
            }
        }

        #expect(profile.currentDose == 1.375)
        #expect(profile.medicationType == "semaglutide")
        #expect(profile.brandName == "Ozempic")
        #expect(profile.notes == "")
        #expect(context.hasChanges == false)
        #expect(try context.fetchCount(FetchDescriptor<MedicationProfile>()) == 1)
    }

    @Test("Editing a legacy compounded profile preserves hidden recorded fields")
    @MainActor
    func existingCompoundingDataIsPreserved() throws {
        let controller = DataController(inMemory: true)
        let context = controller.container.mainContext
        let profile = MedicationProfile(
            genericName: "semaglutide", brandName: "Generic", currentDose: 1.375,
            isCompounded: true, vialStrength: 10, reconstitutionVolume: 2,
            concentration: 5, unitsPerDose: 27.5
        )
        context.insert(profile)
        try context.save()
        let manager = MedicationManager(modelContext: context)
        try manager.updateProfile(profile, currentDose: 1.625, notes: "Prescribed amount recorded")

        #expect(profile.currentDose == 1.625)
        #expect(profile.vialStrength == 10)
        #expect(profile.reconstitutionVolume == 2)
        #expect(profile.concentration == 5)
        #expect(profile.unitsPerDose == 27.5)
        #expect(profile.isCompounded == true)
    }

    @Test("Quick Dose requires an explicit split amount and never clamps it to a drug range")
    @MainActor
    func quickDosePreservesExplicitAmount() {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic", currentDose: 1.375)
        let schedule = DoseSchedule(medicationProfile: profile, patternType: .splitDose)
        profile.schedules = [schedule]
        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        #expect(viewModel.doseAmount == 0)
        #expect(viewModel.canSaveDose == false)
        #expect(viewModel.doseAmountRange == 0...0)
        #expect(viewModel.doseAmountStep == 0)
        viewModel.doseAmount = 3.125
        viewModel.selectedInjectionSite = "Thigh"
        #expect(viewModel.canSaveDose == true)
        #expect(viewModel.clampDoseAmount(3.125) == 3.125)
        #expect(viewModel.doseAmount == 3.125)
        viewModel.doseAmount = .infinity
        #expect(viewModel.canSaveDose == false)
        viewModel.doseAmount = .nan
        #expect(viewModel.canSaveDose == false)
    }

    @Test("A scheduled amount and profile override Quick Dose defaults exactly")
    @MainActor
    func scheduledDoseLoadsRecordedValues() async throws {
        let controller = DataController(inMemory: true)
        let context = controller.container.mainContext
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Generic", currentDose: 1.375)
        let schedule = DoseSchedule(medicationProfile: profile, patternType: .splitDose)
        let timestamp = Calendar.current.date(bySettingHour: 8, minute: 15, second: 0, of: Date())!
        let scheduled = ScheduledDose(scheduledTime: timestamp, doseAmount: 0.375)
        context.insert(profile)
        context.insert(schedule)
        context.insert(scheduled)
        scheduled.schedule = schedule
        profile.schedules = [schedule]
        try context.save()
        let viewModel = QuickDoseViewModel()
        await viewModel.prepareForScheduledDose(scheduledDoseId: scheduled.id, context: context).value

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.selectedMedicationProfile?.id == profile.id)
        #expect(viewModel.doseAmount == 0.375)
        #expect(viewModel.doseDateTime == timestamp)
        #expect(profile.currentDose == 1.375)
        #expect(scheduled.doseAmount == 0.375)
    }

    @Test("Dose edit and persistence retain the exact recorded amount")
    @MainActor
    func editAndPersistDose() async throws {
        let controller = DataController(inMemory: true)
        let context = controller.container.mainContext
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Generic", currentDose: 1.375)
        context.insert(profile)
        try context.save()
        let service = DoseService(pkEngine: PharmacokineticsEngine())
        let timestamp = Calendar.current.date(bySettingHour: 8, minute: 15, second: 0, of: Date())!
        let dose = try await service.saveDose(
            amount: 0.375, timestamp: timestamp, medicationProfile: profile, site: "Thigh", context: context
        )
        let edit = DoseEditData(
            id: dose.id, amount: 0.625, timestamp: timestamp, site: "Thigh",
            notes: "Recorded", imageData: nil, skipped: false, medicationProfile: profile
        )
        let viewModel = QuickDoseViewModel()
        await viewModel.loadEditData(edit, context: context).value
        #expect(viewModel.doseAmount == 0.625)
        #expect(viewModel.doseDateTime == timestamp)
        try await service.updateDose(with: edit, context: context)
        let reloaded = try #require(context.fetch(FetchDescriptor<Dose>()).first)
        #expect(reloaded.amount == 0.625)
        #expect(reloaded.timestamp == timestamp)
        #expect(reloaded.notes == "Recorded")
        #expect(profile.currentDose == 1.375)
    }

    @Test("Recording accepts finite values without calculator eligibility and rejects invalid input before writes")
    @MainActor
    func recordingBoundaryValidation() async throws {
        let controller = DataController(inMemory: true)
        let context = controller.container.mainContext
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Generic", currentDose: 1.375)
        context.insert(profile)
        try context.save()
        let service = DoseService(pkEngine: PharmacokineticsEngine())
        let timestamp = Date()
        let recorded = try await service.saveDose(
            amount: 1001.375, timestamp: timestamp, medicationProfile: profile, context: context
        )
        #expect(recorded.amount == 1001.375)
        for invalidAmount in [0, -1, Double.nan, Double.infinity, -Double.infinity] {
            do {
                _ = try await service.saveDose(
                    amount: invalidAmount, timestamp: timestamp, medicationProfile: profile, context: context
                )
                Issue.record("Invalid numeric input must fail before insertion")
            } catch let error as DoseServiceError {
                guard case .invalidDoseAmount = error else {
                    Issue.record("Expected numeric validation error, received \(error)")
                    return
                }
            }
        }
        #expect(try context.fetchCount(FetchDescriptor<Dose>()) == 1)
        #expect(context.hasChanges == false)
        let skipped = try await service.saveDose(
            amount: 0, timestamp: timestamp, medicationProfile: profile, skipped: true, context: context
        )
        #expect(skipped.amount == 0)
        #expect(skipped.skipped == true)
    }

    @Test("Direct titration actions fail without changing existing records")
    @MainActor
    func titrationActionsAreUnavailable() throws {
        let controller = DataController(inMemory: true)
        let context = controller.container.mainContext
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic", currentDose: 1.375)
        let recordedDate = Date(timeIntervalSince1970: 1_780_000_000)
        let titration = DoseTitration(
            fromDose: 1.375, toDose: 2, scheduledDate: recordedDate, medicationProfile: profile
        )
        context.insert(profile)
        context.insert(titration)
        profile.doseTitrations = [titration]
        try context.save()
        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile

        #expect(viewModel.shouldShowTitrationDialog() == false)
        #expect(viewModel.getPendingTitration() == nil)
        #expect(throws: MedicationManager.MedicationError.medicalCalculatorsUnavailable) {
            try viewModel.completeTitration(titration, context: context)
        }
        #expect(throws: MedicationManager.MedicationError.medicalCalculatorsUnavailable) {
            try viewModel.rescheduleTitration(titration, to: Date(), context: context)
        }
        #expect(profile.currentDose == 1.375)
        #expect(titration.scheduledDate == recordedDate)
        #expect(titration.isCompleted == false)
        #expect(titration.completedDate == nil)
        #expect(context.hasChanges == false)
    }

    @Test("The medication analytics catalogs offer only Adherence and History")
    @MainActor
    func availableAnalytics() {
        #expect(GLP1ProgramsView.ShotsSection.allCases.filter(\.isEnabled) == [.adherence, .history])
        #expect(ShotsView.ShotsSection.allCases.filter(\.isEnabled) == [.adherence, .history])
        #expect(GLP1ProgramsView.ShotsSection.concentration.rawValue == "Concentration")
        #expect(ShotsView.ShotsSection.concentration.rawValue == "Concentration")
    }

    @Test("Manually chosen daily and weekly schedules retain the prescribed amount and start")
    @MainActor
    func manualSchedulesRemainSupported() throws {
        let controller = DataController(inMemory: true)
        let context = controller.container.mainContext
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Generic", currentDose: 1.375)
        context.insert(profile)
        try context.save()
        let service = ScheduleService(context: context)
        let start = Date(timeIntervalSince1970: 1_780_000_000)

        for (pattern, interval) in [(SchedulePatternType.daily, 1), (.weekly, 7)] {
            let config = ScheduleConfiguration(
                dayOfWeek: pattern == .weekly ? 1 : nil, timeOfDay: TimeComponents(hour: 8, minute: 15),
                secondTimeOfDay: nil, interval: interval, doseAmount: 1.375,
                windowMinutesBefore: 120, windowMinutesAfter: 120,
                splitDoseCount: nil, splitIntervalMinutes: nil, customRecurrence: nil
            )
            let schedule = try service.createSchedule(
                for: profile, pattern: pattern, startDate: start, baseSchedule: config
            )
            let stored = try JSONDecoder().decode(ScheduleConfiguration.self, from: schedule.baseSchedule)
            #expect(schedule.patternType == pattern)
            #expect(schedule.createdAt == start)
            #expect(stored.doseAmount == 1.375)
            #expect(stored.interval == interval)
            #expect(stored.timeOfDay == TimeComponents(hour: 8, minute: 15))
        }
    }

    @Test("The existing split schedule editor keeps the recorded split configuration and amount")
    @MainActor
    func existingSplitScheduleIsPreserved() throws {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Generic", currentDose: 1.375)
        let config = recordedConfiguration(interval: 7, amount: 0.375)
        let schedule = DoseSchedule(
            medicationProfile: profile, patternType: .splitDose, baseSchedule: try JSONEncoder().encode(config)
        )
        let editor = DoseScheduleEditView(medicationProfile: profile, existingSchedule: schedule, onSave: { _, _ in })
        let preserved = try #require(editor.scheduleConfiguration)
        #expect(editor.recordedDoseAmount == 0.375)
        #expect(preserved.doseAmount == 0.375)
        #expect(preserved.interval == 7)
        #expect(preserved.secondTimeOfDay == TimeComponents(hour: 18, minute: 30))
        #expect(preserved.splitDoseCount == 2)
        #expect(preserved.splitIntervalMinutes == 5040)
        #expect(preserved.customRecurrence == CustomRecurrence(
            frequency: .weekly, intervalDays: 7, daysOfWeek: [1, 4], monthlyPattern: nil
        ))
        #expect(profile.currentDose == 1.375)
    }

    private func recordedConfiguration(interval: Int, amount: Double) -> ScheduleConfiguration {
        ScheduleConfiguration(
            dayOfWeek: 1, timeOfDay: TimeComponents(hour: 8, minute: 15),
            secondTimeOfDay: TimeComponents(hour: 18, minute: 30), interval: interval, doseAmount: amount,
            windowMinutesBefore: 120, windowMinutesAfter: 120, splitDoseCount: 2, splitIntervalMinutes: 5040,
            customRecurrence: CustomRecurrence(
                frequency: .weekly, intervalDays: 7, daysOfWeek: [1, 4], monthlyPattern: nil
            )
        )
    }
}
