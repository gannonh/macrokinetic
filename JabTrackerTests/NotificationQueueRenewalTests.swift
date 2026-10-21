import Foundation
import SwiftData
import Testing
import UserNotifications

@testable import JabTracker

/// KAT-3601: the dose reminder queue fills the iOS 64-request budget, ends with an
/// "open the app" notice, and replaces stale reminders when a schedule changes.
@MainActor
struct NotificationQueueRenewalTests {
    private struct Fixture {
        let container: ModelContainer
        let scheduleService: ScheduleService
        let center: MockNotificationCenter
        let service: NotificationService
        let schedule: DoseSchedule
    }

    /// 2030-01-01 is a Tuesday. Doses are at 09:00; trigger times are wall-clock local.
    private let now = Self.date("2030-01-01 10:00")

    private nonisolated static func date(_ text: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: text)!
    }

    private nonisolated static func text(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    private nonisolated static func config(dayOfWeek: Int? = nil, interval: Int, amount: Double, hour: Int = 9)
        -> ScheduleConfiguration
    {
        ScheduleConfiguration(
            dayOfWeek: dayOfWeek,
            timeOfDay: TimeComponents(hour: hour, minute: 0),
            secondTimeOfDay: nil,
            interval: interval,
            doseAmount: amount,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )
    }

    private func makeFixture(
        pattern: SchedulePatternType = .daily,
        config: ScheduleConfiguration = NotificationQueueRenewalTests.config(interval: 1, amount: 0.25),
        startDate: Date = date("2029-12-31 00:00")
    ) throws -> Fixture {
        let container = try TestDataSeeding.createTestContainer()
        let context = container.mainContext
        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 0.5,
            preferredInjectionSites: ["Abdomen"]
        )
        context.insert(profile)
        try context.save()
        let scheduleService = ScheduleService(context: context)
        let schedule = try scheduleService.createSchedule(
            for: profile, pattern: pattern, startDate: startDate, baseSchedule: config)
        let center = MockNotificationCenter()
        let service = NotificationService(scheduleService: scheduleService, notificationCenter: center)
        return Fixture(
            container: container, scheduleService: scheduleService, center: center, service: service,
            schedule: schedule)
    }

    private func doseRequests(_ center: MockNotificationCenter) -> [UNNotificationRequest] {
        center.addedRequests.filter { $0.content.categoryIdentifier == "DOSE_REMINDER" }
    }

    private func triggerTimes(_ requests: [UNNotificationRequest]) -> [String] {
        requests.compactMap { ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() }
            .sorted()
            .map(Self.text)
    }

    private func renewalTime(_ center: MockNotificationCenter) -> String? {
        center.request(withIdentifier: NotificationService.renewalRequestIdentifier)
            .flatMap { ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() }
            .map(Self.text)
    }

    private func persistedDoses(_ fixture: Fixture) throws -> [ScheduledDose] {
        try fixture.container.mainContext.fetch(
            FetchDescriptor<ScheduledDose>(sortBy: [SortDescriptor(\.scheduledTime)]))
    }

    @Test("Daily schedule fills 63 reminder slots past day 30 and ends with a renewal notice")
    func dailyScheduleFillsTheRequestLimit() async throws {
        let fixture = try makeFixture()

        try await fixture.service.refreshNotificationQueue(now: now)

        let times = triggerTimes(doseRequests(fixture.center))
        #expect(times.count == 63)
        #expect(times.first == "2030-01-02 08:00")
        #expect(times.contains("2030-01-31 08:00"))  // day 30
        #expect(times.contains("2030-02-01 08:00"))  // day 31
        #expect(times.last == "2030-03-05 08:00")
        #expect(renewalTime(fixture.center) == "2030-03-05 09:00")
        #expect(fixture.center.addedRequests.count == 64)
    }

    @Test("Other pending reminders shrink the dose budget and survive a refresh")
    func otherRemindersShareTheLimit() async throws {
        let fixture = try makeFixture()
        try await fixture.center.add(
            UNNotificationRequest(
                identifier: "weigh-in-daily", content: UNMutableNotificationContent(),
                trigger: UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: 7), repeats: true)))

        try await fixture.service.refreshNotificationQueue(now: now)
        try await fixture.service.refreshNotificationQueue(now: now)

        let times = triggerTimes(doseRequests(fixture.center))
        #expect(times.count == 62)
        #expect(times.last == "2030-03-04 08:00")
        #expect(renewalTime(fixture.center) == "2030-03-04 09:00")
        #expect(fixture.center.request(withIdentifier: "weigh-in-daily") != nil)
        #expect(fixture.center.addedRequests.count == 64)
    }

    @Test("Repeated refreshes keep one persisted dose per reminder with a stable id")
    func refreshKeepsDoseRows() async throws {
        let fixture = try makeFixture()

        try await fixture.service.refreshNotificationQueue(now: now)
        let firstIds = Set(doseRequests(fixture.center).map(\.identifier))
        try await fixture.service.refreshNotificationQueue(now: now)

        #expect(Set(doseRequests(fixture.center).map(\.identifier)) == firstIds)
        #expect(try persistedDoses(fixture).count == 63)
    }

    @Test("Weekly schedule queues a year of reminders at the chosen lead time")
    func weeklyScheduleUsesLeadTime() async throws {
        let fixture = try makeFixture(pattern: .weekly, config: Self.config(dayOfWeek: 2, interval: 7, amount: 0.5))
        fixture.service.reminderMinutesBefore = 120

        try await fixture.service.refreshNotificationQueue(now: now)

        let times = triggerTimes(doseRequests(fixture.center))
        #expect(times.count == 52)
        #expect(Array(times.prefix(6)) == [
            "2030-01-07 07:00", "2030-01-14 07:00", "2030-01-21 07:00", "2030-01-28 07:00",
            "2030-02-04 07:00", "2030-02-11 07:00",
        ])
        #expect(times.last == "2030-12-30 07:00")
        #expect(renewalTime(fixture.center) == "2030-12-30 09:00")
        #expect(try persistedDoses(fixture).map(\.doseAmount) == Array(repeating: 0.5, count: 52))
    }

    @Test("Changing a schedule replaces its reminders, dates and amounts")
    func changedScheduleReplacesReminders() async throws {
        let fixture = try makeFixture()
        try await fixture.service.refreshNotificationQueue(now: now)

        try fixture.scheduleService.updateSchedule(
            fixture.schedule, newPattern: .daily, newBaseSchedule: Self.config(interval: 1, amount: 0.5, hour: 20))
        try await fixture.service.refreshNotificationQueue(now: now)

        let times = triggerTimes(doseRequests(fixture.center))
        #expect(times.count == 63)
        #expect(times.first == "2030-01-01 19:00")
        #expect(times.last == "2030-03-04 19:00")
        #expect(!times.contains { $0.hasSuffix("08:00") })
        let doses = try persistedDoses(fixture)
        #expect(doses.count == 63)
        #expect(Set(doses.map(\.doseAmount)) == [0.5])
    }

    @Test("Changing only the amount keeps reminder ids and updates their doses")
    func changedAmountUpdatesReusedDoses() async throws {
        let fixture = try makeFixture()
        try await fixture.service.refreshNotificationQueue(now: now)
        let firstIds = Set(doseRequests(fixture.center).map(\.identifier))

        try fixture.scheduleService.updateSchedule(
            fixture.schedule, newPattern: .daily, newBaseSchedule: Self.config(interval: 1, amount: 0.5))
        try await fixture.service.refreshNotificationQueue(now: now)

        #expect(Set(doseRequests(fixture.center).map(\.identifier)) == firstIds)
        let doses = try persistedDoses(fixture)
        #expect(doses.count == 63)
        #expect(Set(doses.map(\.doseAmount)) == [0.5])
    }

    @Test("A schedule change keeps the amount of a dose already acted on")
    func changedScheduleKeepsActedDose() async throws {
        let fixture = try makeFixture()
        try await fixture.service.refreshNotificationQueue(now: now)
        let skipped = try #require(try persistedDoses(fixture).first)
        skipped.skippedAt = now

        try fixture.scheduleService.updateSchedule(
            fixture.schedule, newPattern: .daily, newBaseSchedule: Self.config(interval: 1, amount: 0.5))
        try await fixture.service.refreshNotificationQueue(now: now)

        #expect(Self.text(skipped.scheduledTime) == "2030-01-02 09:00")
        #expect(skipped.doseAmount == 0.25)
        #expect(try persistedDoses(fixture).filter { $0.id != skipped.id }.allSatisfy { $0.doseAmount == 0.5 })
    }

    @Test("Split-dose reminders keep the schedule's cadence whenever the app refreshes")
    func splitDoseCadenceSurvivesRefresh() async throws {
        let fixture = try makeFixture(
            pattern: .splitDose,
            config: .splitDose(
                weeklyTotal: 0.5, timeOfDay: TimeComponents(hour: 9, minute: 0),
                windowMinutesBefore: 120, windowMinutesAfter: 120))

        try await fixture.service.refreshNotificationQueue(now: now)
        #expect(Array(triggerTimes(doseRequests(fixture.center)).prefix(3)) == [
            "2030-01-03 20:00", "2030-01-07 08:00", "2030-01-10 20:00",
        ])

        try await fixture.service.refreshNotificationQueue(now: Self.date("2030-01-02 07:00"))
        #expect(Array(triggerTimes(doseRequests(fixture.center)).prefix(3)) == [
            "2030-01-03 20:00", "2030-01-07 08:00", "2030-01-10 20:00",
        ])
    }

    @Test("A schedule change during a rebuild is applied after it, leaving no obsolete reminders")
    func overlappingRefreshesApplyTheLatestSchedule() async throws {
        let fixture = try makeFixture()
        var second: Task<Void, Error>?
        fixture.center.onAdd = {
            guard second == nil else { return }
            fixture.schedule.pausedAt = Self.date("2030-01-01 00:00")
            second = Task { try await fixture.service.refreshNotificationQueue(now: self.now) }
            for _ in 0..<20 { await Task.yield() }
        }

        try await fixture.service.refreshNotificationQueue(now: now)
        try await second?.value

        #expect(doseRequests(fixture.center).isEmpty)
        #expect(fixture.center.request(withIdentifier: NotificationService.renewalRequestIdentifier) == nil)
    }

    @Test("Turning reminders off during a rebuild leaves nothing pending")
    func disablingDuringRebuildLeavesNothingPending() async throws {
        let fixture = try makeFixture()
        fixture.service.notificationsEnabled = true
        var disabling: Task<Void, Never>?
        fixture.center.onAdd = {
            guard disabling == nil else { return }
            disabling = Task { await fixture.service.disable() }
            for _ in 0..<20 { await Task.yield() }
        }

        try await fixture.service.refreshNotificationQueue(now: now)
        await disabling?.value

        #expect(fixture.center.addedRequests.isEmpty)
        #expect(!fixture.service.notificationsEnabled)
    }

    @Test("Paused days get no reminders; an open-ended pause ends the queue")
    func pausedScheduleSkipsReminders() async throws {
        let fixture = try makeFixture()
        fixture.schedule.pausedAt = Self.date("2030-01-05 00:00")
        fixture.schedule.pausedUntil = Self.date("2030-01-08 00:00")

        try await fixture.service.refreshNotificationQueue(now: now)
        let times = triggerTimes(doseRequests(fixture.center))
        #expect(Array(times.prefix(5)) == [
            "2030-01-02 08:00", "2030-01-03 08:00", "2030-01-04 08:00", "2030-01-08 08:00", "2030-01-09 08:00",
        ])

        fixture.schedule.pausedUntil = nil
        try await fixture.service.refreshNotificationQueue(now: now)
        #expect(triggerTimes(doseRequests(fixture.center)) == [
            "2030-01-02 08:00", "2030-01-03 08:00", "2030-01-04 08:00",
        ])
        #expect(renewalTime(fixture.center) == "2030-01-04 09:00")
    }

    @Test("Canceling the schedule cancels its reminders and the renewal notice")
    func canceledScheduleClearsReminders() async throws {
        let fixture = try makeFixture()
        try await fixture.service.refreshNotificationQueue(now: now)

        try fixture.scheduleService.deleteSchedule(fixture.schedule)
        try await fixture.service.refreshNotificationQueue(now: now)

        #expect(fixture.center.addedRequests.isEmpty)
        #expect(try persistedDoses(fixture).isEmpty)
    }

    @Test("A schedule paused through another ScheduleService refreshes the queue on its own")
    func scheduleChangeFromAnotherServiceRefreshes() async throws {
        let fixture = try makeFixture(startDate: Date().addingTimeInterval(-86_400))
        fixture.service.notificationsEnabled = true
        try await fixture.service.refreshNotificationQueue()
        #expect(doseRequests(fixture.center).count == 63)

        let otherService = ScheduleService(context: fixture.container.mainContext)
        try otherService.pauseSchedule(fixture.schedule)

        for _ in 0..<100 where !doseRequests(fixture.center).isEmpty {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(doseRequests(fixture.center).isEmpty)
        #expect(fixture.center.request(withIdentifier: NotificationService.renewalRequestIdentifier) == nil)
    }

    @Test("Tapping a reminder opens the dose it reminds about")
    func tappingReminderOpensDose() async throws {
        let fixture = try makeFixture()
        try await fixture.service.refreshNotificationQueue(now: now)
        let request = try #require(
            doseRequests(fixture.center).first {
                ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() == Self.date("2030-01-02 08:00")
            })
        var openedId: UUID?
        let observer = NotificationCenter.default.addObserver(
            forName: .showQuickDoseSheet, object: nil, queue: nil
        ) { openedId = $0.userInfo?["scheduledDoseId"] as? UUID }
        defer { NotificationCenter.default.removeObserver(observer) }

        try await fixture.service.handleNotificationResponse(
            actionIdentifier: UNNotificationDefaultActionIdentifier, request: request)

        let id = try #require(openedId)
        #expect(id.uuidString == request.identifier)
        let dose = try #require(try persistedDoses(fixture).first { $0.id == id })
        #expect(Self.text(dose.scheduledTime) == "2030-01-02 09:00")
        #expect(dose.doseAmount == 0.25)
    }
}
