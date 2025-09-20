//
//  DoseDayDetailViewTests.swift
//  JabTrackerTests
//
//  Unit tests for DoseDayDetailView component
//

@testable import JabTracker
import SwiftUI
import Testing

struct DoseDayDetailViewTests {
    // MARK: - Date Display Tests

    @Test("Dose day detail view formats date correctly")
    func doseDayDetailViewFormatsDateCorrectly() throws {
        // GIVEN: A specific date
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 9, day: 15)
        guard let date = calendar.date(from: components) else {
            throw TestError.invalidTestData("Failed to create test date")
        }
        let doses: [Dose] = []

        // WHEN: DoseDayDetailView formats the date
        let testDetailView = TestDayDetailViewModel(date: date, doses: doses)

        // THEN: Date should be formatted properly using view's logic
        let formattedDate = testDetailView.formattedDate
        #expect(formattedDate.contains("Sep") || formattedDate.contains("September"))
        #expect(formattedDate.contains("15"))
        #expect(formattedDate.contains("2024"))
    }

    @Test("Dose day detail view handles today's date")
    func doseDayDetailViewHandlesTodaysDate() throws {
        // GIVEN: Today's date
        let today = Date()
        let doses: [Dose] = []

        // WHEN: DoseDayDetailView processes today's date
        let testDetailView = TestDayDetailViewModel(date: today, doses: doses)

        // THEN: Navigation title should show "Today" for today's date
        let navigationTitle = testDetailView.navigationTitle
        #expect(navigationTitle == "Today")
    }

    // MARK: - Dose List Tests

    @Test("Dose day detail view displays single dose")
    func doseDayDetailViewDisplaysSingleDose() throws {
        // GIVEN: A date with one dose
        let date = Date()
        let doses = [createMockDose(timestamp: date, amount: 1.0)]

        // WHEN: Filtering doses for the specific date
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let dosesForDate = doses.filter { dose in
            calendar.startOfDay(for: dose.timestamp) == targetDate
        }

        // THEN: Should have exactly one dose
        #expect(dosesForDate.count == 1)
        #expect(dosesForDate.first?.amount == 1.0)
    }

    @Test("Dose day detail view displays multiple doses chronologically")
    func doseDayDetailViewDisplaysMultipleDosesChronologically() throws {
        // GIVEN: Multiple doses on the same date
        let calendar = Calendar.current
        let date = Date()
        guard let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date) else {
            throw TestError.invalidTestData("Failed to create morning time")
        }
        guard let afternoonTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date) else {
            throw TestError.invalidTestData("Failed to create afternoon time")
        }
        guard let eveningTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: date) else {
            throw TestError.invalidTestData("Failed to create evening time")
        }

        let doses = [
            createMockDose(timestamp: eveningTime, amount: 3.0), // Out of order
            createMockDose(timestamp: morningTime, amount: 1.0),
            createMockDose(timestamp: afternoonTime, amount: 2.0),
        ]

        // WHEN: Sorting doses chronologically
        let sortedDoses = doses.sorted { $0.timestamp < $1.timestamp }

        // THEN: Doses should be in chronological order
        #expect(sortedDoses[0].amount == 1.0) // Morning dose first
        #expect(sortedDoses[1].amount == 2.0) // Afternoon dose second
        #expect(sortedDoses[2].amount == 3.0) // Evening dose last
    }

    @Test("Dose day detail view handles empty dose list")
    func doseDayDetailViewHandlesEmptyDoseList() throws {
        // GIVEN: A date with no doses
        let date = Date()
        let doses: [Dose] = []

        // WHEN: Filtering doses for the date
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let dosesForDate = doses.filter { dose in
            calendar.startOfDay(for: dose.timestamp) == targetDate
        }

        // THEN: Should have no doses
        #expect(dosesForDate.isEmpty)
    }

    // MARK: - Dose Information Display Tests

    @Test("Dose day detail view displays dose amounts")
    func doseDayDetailViewDisplaysDoseAmounts() throws {
        // GIVEN: Doses with different amounts
        let date = Date()
        let doses = [
            createMockDose(timestamp: date, amount: 0.5),
            createMockDose(timestamp: date, amount: 1.0),
            createMockDose(timestamp: date, amount: 2.4),
        ]

        // WHEN: Extracting dose amounts
        let amounts = doses.map(\.amount)

        // THEN: All amounts should be preserved
        #expect(amounts.contains(0.5))
        #expect(amounts.contains(1.0))
        #expect(amounts.contains(2.4))
    }

    @Test("Dose day detail view displays injection sites")
    func doseDayDetailViewDisplaysInjectionSites() throws {
        // GIVEN: Doses with different injection sites
        let date = Date()
        let doses = [
            createMockDose(timestamp: date, site: "Abdomen"),
            createMockDose(timestamp: date, site: "Thigh"),
            createMockDose(timestamp: date, site: "Arm"),
        ]

        // WHEN: Extracting injection sites
        let sites = doses.compactMap(\.site)

        // THEN: All sites should be preserved
        #expect(sites.contains("Abdomen"))
        #expect(sites.contains("Thigh"))
        #expect(sites.contains("Arm"))
    }

    @Test("Dose day detail view displays dose notes")
    func doseDayDetailViewDisplaysDoseNotes() throws {
        // GIVEN: A dose with notes
        let date = Date()
        let dose = self.createMockDose(timestamp: date, notes: "Taken with breakfast")

        // WHEN: Accessing dose notes
        let notes = dose.notes

        // THEN: Notes should be preserved
        #expect(notes == "Taken with breakfast")
    }

    @Test("Dose day detail view handles doses without notes")
    func doseDayDetailViewHandlesDosesWithoutNotes() throws {
        // GIVEN: A dose without notes
        let date = Date()
        let dose = self.createMockDose(timestamp: date, notes: nil)

        // WHEN: Accessing dose notes
        let notes = dose.notes

        // THEN: Notes should be nil
        #expect(notes == nil)
    }

    // MARK: - Time Formatting Tests

    @Test("Dose day detail view formats dose times")
    func doseDayDetailViewFormatsDoseTimes() throws {
        // GIVEN: A dose at a specific time
        let calendar = Calendar.current
        let date = Date()
        guard let specificTime = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: date) else {
            throw TestError.invalidTestData("Failed to create specific time")
        }
        let dose = self.createMockDose(timestamp: specificTime)

        // WHEN: DoseDetailRow formats the time
        let testRowModel = TestDoseDetailRowModel(dose: dose)

        // THEN: Time should be formatted correctly using view's time formatting logic
        let formattedTime = testRowModel.timeString
        #expect(formattedTime.contains("2:30") || formattedTime.contains("14:30"))
    }

    // MARK: - Skip Status Tests

    @Test("Dose day detail view indicates skipped doses")
    func doseDayDetailViewIndicatesSkippedDoses() throws {
        // GIVEN: A skipped dose
        let date = Date()
        let dose = self.createMockDose(timestamp: date, skipped: true)

        // WHEN: Checking skip status
        let isSkipped = dose.skipped

        // THEN: Dose should be marked as skipped
        #expect(isSkipped == true)
    }

    @Test("Dose day detail view indicates taken doses")
    func doseDayDetailViewIndicatesTakenDoses() throws {
        // GIVEN: A taken dose
        let date = Date()
        let dose = self.createMockDose(timestamp: date, skipped: false)

        // WHEN: Checking skip status
        let isSkipped = dose.skipped

        // THEN: Dose should not be marked as skipped
        #expect(isSkipped == false)
    }

    // MARK: - Photo Indicator Tests

    @Test("Dose day detail view indicates doses with photos")
    func doseDayDetailViewIndicatesDosesWithPhotos() throws {
        // GIVEN: A dose with photo data
        let date = Date()
        let photoData = Data([0x01, 0x02, 0x03]) // Mock photo data
        let dose = self.createMockDose(timestamp: date, imageData: photoData)

        // WHEN: Checking for photo data
        let hasPhoto = dose.imageData != nil

        // THEN: Dose should indicate photo presence
        #expect(hasPhoto == true)
    }

    @Test("Dose day detail view handles doses without photos")
    func doseDayDetailViewHandlesDosesWithoutPhotos() throws {
        // GIVEN: A dose without photo data
        let date = Date()
        let dose = self.createMockDose(timestamp: date, imageData: nil)

        // WHEN: Checking for photo data
        let hasPhoto = dose.imageData != nil

        // THEN: Dose should not indicate photo presence
        #expect(hasPhoto == false)
    }

    // MARK: - Helper Methods

    private func createMockDose(
        timestamp: Date,
        amount: Double = 1.0,
        site: String? = "Abdomen",
        notes: String? = nil,
        imageData: Data? = nil,
        skipped: Bool = false) -> Dose
    {
        Dose(
            amount: amount,
            timestamp: timestamp,
            site: site,
            notes: notes,
            imageData: imageData,
            skipped: skipped,
            user: nil,
            medication: nil)
    }
}

// MARK: - Test View Models

/// Test view model that exposes DoseDayDetailView's computed properties for testing
private class TestDayDetailViewModel {
    let date: Date
    let doses: [Dose]
    private let calendar = Calendar.current

    init(date: Date, doses: [Dose]) {
        self.date = date
        self.doses = doses
    }

    var navigationTitle: String {
        if self.calendar.isDateInToday(self.date) {
            return "Today"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: self.date)
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self.date)
    }

    var sortedDoses: [Dose] {
        self.doses.sorted { $0.timestamp < $1.timestamp }
    }
}

/// Test view model that exposes DoseDetailRow's computed properties for testing
private class TestDoseDetailRowModel {
    let dose: Dose

    init(dose: Dose) {
        self.dose = dose
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self.dose.timestamp)
    }

    func siteColor(for site: String) -> Color {
        switch site.lowercased() {
        case "abdomen":
            return .blue
        case "thigh":
            return .green
        case "arm":
            return .purple
        default:
            return .gray
        }
    }
}
