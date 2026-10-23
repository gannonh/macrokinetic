import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// KAT-3613: split administrations stay at the chosen local time when a daylight-saving change falls between them.
@Suite("Split dosing keeps local times across daylight-saving changes")
@MainActor
struct SplitDoseDaylightSavingTests {
    private static let losAngeles = TimeZone(identifier: "America/Los_Angeles")!

    private func projectedLocalTimes(
        createdAt created: DateComponents, from start: DateComponents? = nil, days: Int
    ) throws -> (times: [String], amounts: [Double]) {
        let controller = DataController(inMemory: true)
        let context = controller.container.mainContext
        defer { withExtendedLifetime(controller) {} }
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Generic", currentDose: 5.0)
        context.insert(profile)
        let service = ScheduleService(context: context)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.losAngeles
        service.calendar = calendar

        let createdAt = try #require(calendar.date(from: created))
        let startDate = try #require(calendar.date(from: start ?? created))
        let config = ScheduleConfiguration.splitDose(
            weeklyTotal: 5.0, timeOfDay: TimeComponents(hour: 8, minute: 0),
            windowMinutesBefore: 120, windowMinutesAfter: 120
        )
        let schedule = try service.createSchedule(
            for: profile, pattern: .splitDose, startDate: createdAt, baseSchedule: config)
        let doses = service.generateScheduledDoses(
            for: schedule, from: startDate, to: startDate.addingTimeInterval(TimeInterval(days * 86_400))
        )

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Self.losAngeles
        formatter.dateFormat = "yyyy-MM-dd HH:mm zzz"
        return (doses.map { formatter.string(from: $0.scheduledTime) }, doses.map(\.doseAmount))
    }

    @Test("Fall back on 2026-11-01 keeps Monday 08:00 and Thursday 20:00")
    func fallBack() throws {
        let result = try projectedLocalTimes(
            createdAt: DateComponents(year: 2026, month: 10, day: 26, hour: 8), days: 14)
        #expect(
            result.times == [
                "2026-10-26 08:00 PDT", "2026-10-29 20:00 PDT",
                "2026-11-02 08:00 PST", "2026-11-05 20:00 PST",
            ])
        #expect(result.amounts == [2.5, 2.5, 2.5, 2.5])
    }

    @Test("Spring forward on 2026-03-08 keeps Monday 08:00 and Thursday 20:00")
    func springForward() throws {
        let result = try projectedLocalTimes(createdAt: DateComponents(year: 2026, month: 3, day: 2, hour: 8), days: 14)
        #expect(
            result.times == [
                "2026-03-02 08:00 PST", "2026-03-05 20:00 PST",
                "2026-03-09 08:00 PDT", "2026-03-12 20:00 PDT",
            ])
        #expect(result.amounts == [2.5, 2.5, 2.5, 2.5])
    }

    @Test("A projection that starts after the change keeps the same local cadence")
    func startsAfterTransition() throws {
        let result = try projectedLocalTimes(
            createdAt: DateComponents(year: 2026, month: 10, day: 26, hour: 8),
            from: DateComponents(year: 2026, month: 11, day: 3, hour: 12), days: 7
        )
        #expect(result.times == ["2026-11-05 20:00 PST", "2026-11-09 08:00 PST"])
    }
}
