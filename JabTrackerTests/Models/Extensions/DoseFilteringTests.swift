//
//  DoseFilteringTests.swift
//  JabTrackerTests
//

import Testing
import Foundation
import SwiftData
@testable import JabTracker

@MainActor
@Suite("Dose Filtering Tests")
struct DoseFilteringTests {

    // MARK: - Text Search Tests

    @Test("Text search matches notes")
    func testTextSearchInNotes() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let dose = Dose(amount: 1.0, timestamp: Date())
        dose.notes = "Injection felt smooth today"
        context.insert(dose)
        try context.save()

        #expect(dose.matches(searchText: "smooth"))
        #expect(dose.matches(searchText: "SMOOTH"))
        #expect(dose.matches(searchText: "injection"))
        #expect(!dose.matches(searchText: "painful"))
    }

    @Test("Text search matches injection site")
    func testTextSearchInSite() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let dose = Dose(amount: 1.0, timestamp: Date())
        dose.site = "Left arm"
        context.insert(dose)
        try context.save()

        #expect(dose.matches(searchText: "left"))
        #expect(dose.matches(searchText: "LEFT"))
        #expect(dose.matches(searchText: "arm"))
        #expect(!dose.matches(searchText: "thigh"))
    }

    @Test("Text search matches medication names")
    func testTextSearchInMedication() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let medication = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0
        )
        context.insert(medication)

        let dose = Dose(amount: 1.0, timestamp: Date())
        dose.medication = medication
        context.insert(dose)
        try context.save()

        #expect(dose.matches(searchText: "semaglutide"))
        #expect(dose.matches(searchText: "ozempic"))
        #expect(dose.matches(searchText: "SEMAGLUTIDE"))
        #expect(!dose.matches(searchText: "tirzepatide"))
    }

    @Test("Text search matches dose amount")
    func testTextSearchInAmount() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let dose = Dose(amount: 2.5, timestamp: Date())
        context.insert(dose)
        try context.save()

        #expect(dose.matches(searchText: "2.5"))
        #expect(dose.matches(searchText: "2"))
        #expect(!dose.matches(searchText: "1.0"))
    }

    @Test("Text search matches formatted date")
    func testTextSearchInDate() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let calendar = Calendar.current
        guard let january = calendar.date(
            from: DateComponents(year: 2024, month: 1, day: 15, hour: 10, minute: 30)
        ) else {
            Issue.record("Failed to create test date")
            return
        }
        let dose = Dose(amount: 1.0, timestamp: january)
        context.insert(dose)
        try context.save()

        #expect(dose.matches(searchText: "Jan"))
        #expect(dose.matches(searchText: "2024"))
        #expect(dose.matches(searchText: "10:30"))
    }

    @Test("Text search with nil medication")
    func testTextSearchWithNilMedication() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let dose = Dose(amount: 1.0, timestamp: Date())
        dose.notes = "test note"
        // No medication set
        context.insert(dose)
        try context.save()

        #expect(!dose.matches(searchText: "semaglutide"))
        #expect(dose.matches(searchText: "test"))
    }

    // MARK: - Date Filtering Tests

    @Test("Date range filtering works correctly")
    func testDateRangeFiltering() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let calendar = Calendar.current
        guard let baseDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15)),
              let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10)),
              let endDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 20)) else {
            Issue.record("Failed to create test dates")
            return
        }

        let dose = Dose(amount: 1.0, timestamp: baseDate)
        context.insert(dose)
        try context.save()

        #expect(dose.isWithinDateRange(start: startDate, end: endDate))
        #expect(dose.isWithinDateRange(start: startDate, end: nil))
        #expect(dose.isWithinDateRange(start: nil, end: endDate))
        #expect(dose.isWithinDateRange(start: nil, end: nil))

        // Test out of range
        guard let earlyDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 5)),
              let lateDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 25)) else {
            Issue.record("Failed to create test dates")
            return
        }

        #expect(!dose.isWithinDateRange(start: lateDate, end: nil))
        #expect(!dose.isWithinDateRange(start: nil, end: earlyDate))
    }

    @Test("Same date checking works correctly")
    func testSameDateChecking() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let calendar = Calendar.current
        guard let date = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 10)),
              let sameDay = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 18)),
              let differentDay = calendar.date(from: DateComponents(year: 2024, month: 1, day: 16)) else {
            Issue.record("Failed to create test dates")
            return
        }

        let dose = Dose(amount: 1.0, timestamp: date)
        context.insert(dose)
        try context.save()

        #expect(dose.isOnDate(date))
        #expect(dose.isOnDate(sameDay))
        #expect(!dose.isOnDate(differentDay))
    }

    @Test("Week filtering works correctly")
    func testWeekFiltering() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let calendar = Calendar.current
        guard let monday = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15)), // Monday
              let wednesday = calendar.date(from: DateComponents(year: 2024, month: 1, day: 17)), // Wednesday
              let nextWeek = calendar.date(from: DateComponents(year: 2024, month: 1, day: 22)) else { // Next Monday
            Issue.record("Failed to create test dates")
            return
        }

        let dose = Dose(amount: 1.0, timestamp: wednesday)
        context.insert(dose)
        try context.save()

        #expect(dose.isInWeek(containing: monday))
        #expect(dose.isInWeek(containing: wednesday))
        #expect(!dose.isInWeek(containing: nextWeek))
    }

    @Test("Month filtering works correctly")
    func testMonthFiltering() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let calendar = Calendar.current
        guard let january15 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15)),
              let january30 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 30)),
              let february1 = calendar.date(from: DateComponents(year: 2024, month: 2, day: 1)) else {
            Issue.record("Failed to create test dates")
            return
        }

        let dose = Dose(amount: 1.0, timestamp: january15)
        context.insert(dose)
        try context.save()

        #expect(dose.isInMonth(containing: january15))
        #expect(dose.isInMonth(containing: january30))
        #expect(!dose.isInMonth(containing: february1))
    }

    // MARK: - Medication Filtering Tests

    @Test("Medication type filtering works correctly")
    func testMedicationTypeFiltering() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let semaglutideMed = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")
        let tirzepatideMed = MedicationProfile(genericName: "tirzepatide", brandName: "Mounjaro")
        context.insert(semaglutideMed)
        context.insert(tirzepatideMed)

        let dose1 = Dose(amount: 1.0, timestamp: Date())
        dose1.medication = semaglutideMed
        context.insert(dose1)

        let dose2 = Dose(amount: 1.0, timestamp: Date())
        dose2.medication = tirzepatideMed
        context.insert(dose2)

        let dose3 = Dose(amount: 1.0, timestamp: Date())
        // No medication
        context.insert(dose3)

        try context.save()

        #expect(dose1.hasMedication("semaglutide"))
        #expect(!dose1.hasMedication("tirzepatide"))
        #expect(dose2.hasMedication("tirzepatide"))
        #expect(!dose2.hasMedication("semaglutide"))
        #expect(!dose3.hasMedication("semaglutide"))
    }

    @Test("Brand filtering works correctly")
    func testBrandFiltering() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let medication = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")
        context.insert(medication)

        let dose1 = Dose(amount: 1.0, timestamp: Date())
        dose1.medication = medication
        context.insert(dose1)

        let dose2 = Dose(amount: 1.0, timestamp: Date())
        // No medication
        context.insert(dose2)

        try context.save()

        #expect(dose1.hasBrand("Ozempic"))
        #expect(!dose1.hasBrand("Mounjaro"))
        #expect(!dose2.hasBrand("Ozempic"))
    }

    @Test("Multiple medication filtering works correctly")
    func testMultipleMedicationFiltering() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let semaglutideMed = MedicationProfile(genericName: "semaglutide", brandName: "Ozempic")
        let tirzepatideMed = MedicationProfile(genericName: "tirzepatide", brandName: "Mounjaro")
        let liraglutideMed = MedicationProfile(genericName: "liraglutide", brandName: "Victoza")
        context.insert(semaglutideMed)
        context.insert(tirzepatideMed)
        context.insert(liraglutideMed)

        let dose1 = Dose(amount: 1.0, timestamp: Date())
        dose1.medication = semaglutideMed
        context.insert(dose1)

        let dose2 = Dose(amount: 1.0, timestamp: Date())
        dose2.medication = tirzepatideMed
        context.insert(dose2)

        let dose3 = Dose(amount: 1.0, timestamp: Date())
        dose3.medication = liraglutideMed
        context.insert(dose3)

        let dose4 = Dose(amount: 1.0, timestamp: Date())
        // No medication
        context.insert(dose4)

        try context.save()

        let targetMedications = ["semaglutide", "tirzepatide"]

        #expect(dose1.hasMedicationIn(targetMedications))
        #expect(dose2.hasMedicationIn(targetMedications))
        #expect(!dose3.hasMedicationIn(targetMedications))
        #expect(!dose4.hasMedicationIn(targetMedications))
    }

    // MARK: - Site Filtering Tests

    @Test("Injection site filtering works correctly")
    func testInjectionSiteFiltering() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let dose1 = Dose(amount: 1.0, timestamp: Date())
        dose1.site = "Left arm"
        context.insert(dose1)

        let dose2 = Dose(amount: 1.0, timestamp: Date())
        dose2.site = "Right thigh"
        context.insert(dose2)

        let dose3 = Dose(amount: 1.0, timestamp: Date())
        // No site
        context.insert(dose3)

        try context.save()

        #expect(dose1.hasInjectionSite("Left arm"))
        #expect(!dose1.hasInjectionSite("Right arm"))
        #expect(dose2.hasInjectionSite("Right thigh"))
        #expect(!dose3.hasInjectionSite("Left arm"))
    }

    @Test("Multiple injection site filtering works correctly")
    func testMultipleInjectionSiteFiltering() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let dose1 = Dose(amount: 1.0, timestamp: Date())
        dose1.site = "Left arm"
        context.insert(dose1)

        let dose2 = Dose(amount: 1.0, timestamp: Date())
        dose2.site = "Right thigh"
        context.insert(dose2)

        let dose3 = Dose(amount: 1.0, timestamp: Date())
        dose3.site = "Abdomen"
        context.insert(dose3)

        let dose4 = Dose(amount: 1.0, timestamp: Date())
        // No site
        context.insert(dose4)

        try context.save()

        let targetSites = ["Left arm", "Right thigh"]

        #expect(dose1.hasInjectionSiteIn(targetSites))
        #expect(dose2.hasInjectionSiteIn(targetSites))
        #expect(!dose3.hasInjectionSiteIn(targetSites))
        #expect(!dose4.hasInjectionSiteIn(targetSites))
    }

    // MARK: - Dose Amount Filtering Tests

    @Test("Amount range filtering works correctly")
    func testAmountRangeFiltering() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let dose1 = Dose(amount: 1.0, timestamp: Date())
        let dose2 = Dose(amount: 2.5, timestamp: Date())
        let dose3 = Dose(amount: 0.5, timestamp: Date())
        context.insert(dose1)
        context.insert(dose2)
        context.insert(dose3)
        try context.save()

        #expect(dose1.amountIsInRange(min: 0.5, max: 2.0))
        #expect(dose1.amountIsInRange(min: nil, max: 2.0))
        #expect(dose1.amountIsInRange(min: 0.5, max: nil))
        #expect(dose1.amountIsInRange(min: nil, max: nil))

        #expect(!dose2.amountIsInRange(min: nil, max: 2.0))
        #expect(!dose3.amountIsInRange(min: 1.0, max: nil))
    }

    @Test("Amount equals with tolerance works correctly")
    func testAmountEqualsWithTolerance() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let dose = Dose(amount: 1.0, timestamp: Date())
        context.insert(dose)
        try context.save()

        #expect(dose.amountEquals(1.0))
        #expect(dose.amountEquals(1.0005, tolerance: 0.001))
        #expect(dose.amountEquals(0.9995, tolerance: 0.001))
        #expect(!dose.amountEquals(1.01, tolerance: 0.001))
        #expect(!dose.amountEquals(0.99, tolerance: 0.001))
    }

    // MARK: - Status Filtering Tests

    @Test("Completion status filtering works correctly")
    func testCompletionStatusFiltering() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let completedDose = Dose(amount: 1.0, timestamp: Date())
        completedDose.skipped = false
        context.insert(completedDose)

        let skippedDose = Dose(amount: 1.0, timestamp: Date())
        skippedDose.skipped = true
        context.insert(skippedDose)

        try context.save()

        #expect(completedDose.matchesCompletionStatus(completed: true))
        #expect(!completedDose.matchesCompletionStatus(completed: false))
        #expect(skippedDose.matchesCompletionStatus(completed: false))
        #expect(!skippedDose.matchesCompletionStatus(completed: true))
    }

    @Test("Photo attachment detection works correctly")
    func testPhotoAttachmentDetection() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let doseWithPhoto = Dose(amount: 1.0, timestamp: Date())
        doseWithPhoto.imageData = Data([1, 2, 3])
        context.insert(doseWithPhoto)

        let doseWithoutPhoto = Dose(amount: 1.0, timestamp: Date())
        context.insert(doseWithoutPhoto)

        try context.save()

        #expect(doseWithPhoto.hasPhotoAttachment)
        #expect(!doseWithoutPhoto.hasPhotoAttachment)
    }

    @Test("Notes detection works correctly")
    func testNotesDetection() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let doseWithNotes = Dose(amount: 1.0, timestamp: Date())
        doseWithNotes.notes = "Some notes"
        context.insert(doseWithNotes)

        let doseWithEmptyNotes = Dose(amount: 1.0, timestamp: Date())
        doseWithEmptyNotes.notes = ""
        context.insert(doseWithEmptyNotes)

        let doseWithoutNotes = Dose(amount: 1.0, timestamp: Date())
        context.insert(doseWithoutNotes)

        try context.save()

        #expect(doseWithNotes.hasNotes)
        #expect(!doseWithEmptyNotes.hasNotes)
        #expect(!doseWithoutNotes.hasNotes)
    }

    // MARK: - Time-based Filtering Tests

    @Test("Morning dose detection works correctly")
    func testMorningDoseDetection() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let calendar = Calendar.current
        guard let morningTime = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 8)),
              let afternoonTime = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 14)),
              let noonTime = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 12)) else {
            Issue.record("Failed to create test dates")
            return
        }

        let morningDose = Dose(amount: 1.0, timestamp: morningTime)
        let afternoonDose = Dose(amount: 1.0, timestamp: afternoonTime)
        let noonDose = Dose(amount: 1.0, timestamp: noonTime)
        context.insert(morningDose)
        context.insert(afternoonDose)
        context.insert(noonDose)
        try context.save()

        #expect(morningDose.isMorningDose)
        #expect(!afternoonDose.isMorningDose)
        #expect(!noonDose.isMorningDose)
    }

    @Test("Evening dose detection works correctly")
    func testEveningDoseDetection() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let calendar = Calendar.current
        guard let eveningTime = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 19)),
              let afternoonTime = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 14)),
              let sixPM = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 18)) else {
            Issue.record("Failed to create test dates")
            return
        }

        let eveningDose = Dose(amount: 1.0, timestamp: eveningTime)
        let afternoonDose = Dose(amount: 1.0, timestamp: afternoonTime)
        let sixPMDose = Dose(amount: 1.0, timestamp: sixPM)
        context.insert(eveningDose)
        context.insert(afternoonDose)
        context.insert(sixPMDose)
        try context.save()

        #expect(eveningDose.isEveningDose)
        #expect(!afternoonDose.isEveningDose)
        #expect(sixPMDose.isEveningDose)
    }

    @Test("Weekend dose detection works correctly")
    func testWeekendDoseDetection() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let calendar = Calendar.current
        // January 13, 2024 is a Saturday, January 14 is Sunday, January 15 is Monday
        guard let saturday = calendar.date(from: DateComponents(year: 2024, month: 1, day: 13)),
              let sunday = calendar.date(from: DateComponents(year: 2024, month: 1, day: 14)),
              let monday = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15)) else {
            Issue.record("Failed to create test dates")
            return
        }

        let saturdayDose = Dose(amount: 1.0, timestamp: saturday)
        let sundayDose = Dose(amount: 1.0, timestamp: sunday)
        let mondayDose = Dose(amount: 1.0, timestamp: monday)
        context.insert(saturdayDose)
        context.insert(sundayDose)
        context.insert(mondayDose)
        try context.save()

        #expect(saturdayDose.isWeekendDose)
        #expect(sundayDose.isWeekendDose)
        #expect(!mondayDose.isWeekendDose)
    }

    // MARK: - Computed Properties Tests

    @Test("Formatted amount includes unit")
    func testFormattedAmount() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let dose1 = Dose(amount: 1.0, timestamp: Date())
        let dose2 = Dose(amount: 2.5, timestamp: Date())
        let dose3 = Dose(amount: 0.25, timestamp: Date())
        context.insert(dose1)
        context.insert(dose2)
        context.insert(dose3)
        try context.save()

        #expect(dose1.formattedAmount == "1.00 mg")
        #expect(dose2.formattedAmount == "2.50 mg")
        #expect(dose3.formattedAmount == "0.25 mg")
    }

    @Test("Formatted timestamp includes date and time")
    func testFormattedTimestamp() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let calendar = Calendar.current
        guard let testDate = calendar.date(
            from: DateComponents(year: 2024, month: 1, day: 15, hour: 10, minute: 30)
        ) else {
            Issue.record("Failed to create test date")
            return
        }
        let dose = Dose(amount: 1.0, timestamp: testDate)
        context.insert(dose)
        try context.save()

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let expected = formatter.string(from: testDate)

        #expect(dose.formattedTimestamp == expected)
    }

    @Test("Date string excludes time")
    func testDateString() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let calendar = Calendar.current
        guard let testDate = calendar.date(
            from: DateComponents(year: 2024, month: 1, day: 15, hour: 10, minute: 30)
        ) else {
            Issue.record("Failed to create test date")
            return
        }
        let dose = Dose(amount: 1.0, timestamp: testDate)
        context.insert(dose)
        try context.save()

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let expected = formatter.string(from: testDate)

        #expect(dose.dateString == expected)
    }

    @Test("Time string excludes date")
    func testTimeString() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let calendar = Calendar.current
        guard let testDate = calendar.date(
            from: DateComponents(year: 2024, month: 1, day: 15, hour: 10, minute: 30)
        ) else {
            Issue.record("Failed to create test date")
            return
        }
        let dose = Dose(amount: 1.0, timestamp: testDate)
        context.insert(dose)
        try context.save()

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let expected = formatter.string(from: testDate)

        #expect(dose.timeString == expected)
    }
}
