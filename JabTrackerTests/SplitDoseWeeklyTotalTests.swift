import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// KAT-3600: a profile's `currentDose` is the weekly total. A split schedule records the amount of ONE
/// administration, so the schedule must hold half of the weekly total and the two administrations must add back
/// up to exactly the prescribed weekly amount.
@Suite("Split dosing keeps the weekly total literal")
struct SplitDoseWeeklyTotalTests {
    private let morning = TimeComponents(hour: 8, minute: 0)

    // MARK: - Configuration contract

    @Test("A 5 mg weekly total splits into two 2.5 mg administrations")
    func splitConfigurationHoldsAdministrationAmount() {
        let config = ScheduleConfiguration.splitDose(
            weeklyTotal: 5.0, timeOfDay: morning, windowMinutesBefore: 120, windowMinutesAfter: 90
        )
        #expect(config.doseAmount == 2.5)
        #expect(config.splitDoseCount == 2)
        #expect(config.splitIntervalMinutes == 5040)
        #expect(config.interval == 7)
        #expect(config.timeOfDay == morning)
        #expect(config.windowMinutesBefore == 120)
        #expect(config.windowMinutesAfter == 90)
        #expect(config.splitSummary == SplitDoseSummary(perAdministration: 2.5, administrations: 2, weeklyTotal: 5.0))
    }

    @Test("The summary reports the recorded amounts literally, including an old split saved at the full amount")
    func summaryReadsRecordedValues() {
        let halved = ScheduleConfiguration.splitDose(
            weeklyTotal: 0.375, timeOfDay: morning, windowMinutesBefore: 120, windowMinutesAfter: 120
        )
        #expect(halved.splitSummary == SplitDoseSummary(perAdministration: 0.1875, administrations: 2, weeklyTotal: 0.375))

        let legacy = ScheduleConfiguration(
            dayOfWeek: nil, timeOfDay: morning, secondTimeOfDay: nil, interval: 7, doseAmount: 5.0,
            windowMinutesBefore: 120, windowMinutesAfter: 120, splitDoseCount: nil,
            splitIntervalMinutes: 5040, customRecurrence: nil
        )
        #expect(legacy.splitSummary == SplitDoseSummary(perAdministration: 5.0, administrations: 2, weeklyTotal: 10.0))

        let weekly = ScheduleConfiguration(
            dayOfWeek: 1, timeOfDay: morning, secondTimeOfDay: nil, interval: 7, doseAmount: 5.0,
            windowMinutesBefore: 120, windowMinutesAfter: 120, splitDoseCount: nil,
            splitIntervalMinutes: nil, customRecurrence: nil
        )
        #expect(weekly.splitSummary == nil)
    }

    // MARK: - Projection

    @Test("A 5 mg weekly total projects 2.5 mg administrations that add up to 5 mg per week")
    @MainActor
    func projectedAdministrationsTotalWeeklyAmount() throws {
        let controller = DataController(inMemory: true)
        let context = controller.container.mainContext
        defer { withExtendedLifetime(controller) {} }
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Generic", currentDose: 5.0)
        context.insert(profile)
        let service = ScheduleService(context: context)
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        let config = ScheduleConfiguration.splitDose(
            weeklyTotal: profile.currentDose, timeOfDay: morning, windowMinutesBefore: 120, windowMinutesAfter: 120
        )
        let schedule = try service.createSchedule(
            for: profile, pattern: .splitDose, startDate: start, baseSchedule: config
        )

        // 28 days minus a few hours: dose slots every 84 hours at +0h, +84h, ... +588h. The window ends before +672h.
        let end = start.addingTimeInterval(27 * 86_400)
        let doses = service.generateScheduledDoses(for: schedule, from: start, to: end)
        let amounts = doses.map(\.doseAmount)
        #expect(amounts.count >= 7)
        #expect(amounts.allSatisfy { $0 == 2.5 })
        for (earlier, later) in zip(doses, doses.dropFirst()) {
            #expect(later.scheduledTime.timeIntervalSince(earlier.scheduledTime) == 84 * 3_600)
        }
        let uniqueTimes = Set(doses.map(\.scheduledTime))
        #expect(uniqueTimes.count == doses.count)

        // Every two consecutive administrations are exactly one week of the 5 mg weekly total.
        let firstWeek = Array(doses.prefix(2)).map(\.doseAmount).reduce(0, +)
        #expect(firstWeek == 5.0)
    }

    @Test("Reverting a split schedule to weekly projects one administration of the weekly total")
    @MainActor
    func revertingToWeeklyRestoresTheWeeklyAmount() throws {
        let controller = DataController(inMemory: true)
        let context = controller.container.mainContext
        defer { withExtendedLifetime(controller) {} }
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Generic", currentDose: 5.0)
        context.insert(profile)
        let service = ScheduleService(context: context)
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        let split = ScheduleConfiguration.splitDose(
            weeklyTotal: 5.0, timeOfDay: morning, windowMinutesBefore: 120, windowMinutesAfter: 120
        )
        let schedule = try service.createSchedule(for: profile, pattern: .splitDose, startDate: start, baseSchedule: split)

        let weekly = DoseScheduleEditView(
            medicationProfile: profile, existingSchedule: schedule, onSave: { _, _ in }
        )
        let reverted = try #require(weekly.configuration(for: .weekly))
        #expect(reverted.doseAmount == 5.0)
        #expect(reverted.splitDoseCount == nil)
        #expect(reverted.splitIntervalMinutes == nil)
        try service.updateSchedule(schedule, newPattern: .weekly, newBaseSchedule: reverted)

        let doses = service.generateScheduledDoses(for: schedule, from: start, to: start.addingTimeInterval(13 * 86_400))
        #expect(doses.map(\.doseAmount) == [5.0, 5.0])
    }

    // MARK: - Editor (launch build: split cannot be newly chosen)

    @Test("A weekly 5 mg schedule cannot be switched to split in the launch build and keeps its 5 mg")
    @MainActor
    func weeklyScheduleCannotBeSwitchedToSplit() throws {
        let controller = DataController(inMemory: true)
        let context = controller.container.mainContext
        defer { withExtendedLifetime(controller) {} }
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Generic", currentDose: 5.0)
        context.insert(profile)
        let weeklyConfig = ScheduleConfiguration(
            dayOfWeek: 1, timeOfDay: morning, secondTimeOfDay: nil, interval: 7, doseAmount: 5.0,
            windowMinutesBefore: 120, windowMinutesAfter: 120, splitDoseCount: nil,
            splitIntervalMinutes: nil, customRecurrence: nil
        )
        let schedule = DoseSchedule(
            medicationProfile: profile, patternType: .weekly, baseSchedule: try JSONEncoder().encode(weeklyConfig)
        )
        let editor = DoseScheduleEditView(medicationProfile: profile, existingSchedule: schedule, onSave: { _, _ in })

        #expect(editor.configuration(for: .splitDose) == nil)
        #expect(editor.configuration(for: .weekly)?.doseAmount == 5.0)
        #expect(editor.splitSummary == nil)
    }

    @Test("An existing split schedule states the administration amount and the weekly total")
    @MainActor
    func existingSplitScheduleStatesBothAmounts() throws {
        let controller = DataController(inMemory: true)
        let context = controller.container.mainContext
        defer { withExtendedLifetime(controller) {} }
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Generic", currentDose: 5.0)
        context.insert(profile)
        let split = ScheduleConfiguration.splitDose(
            weeklyTotal: 5.0, timeOfDay: morning, windowMinutesBefore: 120, windowMinutesAfter: 120
        )
        let schedule = DoseSchedule(
            medicationProfile: profile, patternType: .splitDose, baseSchedule: try JSONEncoder().encode(split)
        )
        let editor = DoseScheduleEditView(medicationProfile: profile, existingSchedule: schedule, onSave: { _, _ in })

        #expect(editor.splitSummary == SplitDoseSummary(perAdministration: 2.5, administrations: 2, weeklyTotal: 5.0))
        #expect(editor.configuration(for: .splitDose)?.doseAmount == 2.5)
        let us = Locale(identifier: "en_US")
        let summary = SplitDoseSummary(perAdministration: 2.5, administrations: 2, weeklyTotal: 5.0)
        #expect(summary.administrationText(locale: us) == "2 administrations of 2.50 mg")
        #expect(summary.weeklyTotalText(locale: us) == "5.00 mg per week")
        // Reverting to weekly returns the weekly total, not one administration.
        #expect(editor.configuration(for: .weekly)?.doseAmount == 5.0)
    }
}
