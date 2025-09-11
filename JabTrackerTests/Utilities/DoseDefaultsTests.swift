//
//  DoseDefaultsTests.swift
//  JabTrackerTests
//

@testable import JabTracker
import Testing
import Foundation
import SwiftData

@Suite("DoseDefaults Business Logic Tests")
struct DoseDefaultsTests {
    
    // MARK: - Injection Site Recommendation Tests
    
    @Test("Recommended injection sites by medication type")
    func recommendedInjectionSitesByMedication() throws {
        // Semaglutide - weekly injection, 3 main sites
        let semaglutideSites = DoseDefaults.recommendedInjectionSites(for: .semaglutide)
        #expect(semaglutideSites == ["Thigh", "Abdomen", "Upper arm"])
        
        // Tirzepatide - weekly injection, 4 sites including larger areas
        let tirzepatideSites = DoseDefaults.recommendedInjectionSites(for: .tirzepatide)
        #expect(tirzepatideSites == ["Thigh", "Abdomen", "Upper arm", "Lower back"])
        
        // Liraglutide - daily injection, 2 easily accessible sites
        let liraglutideSites = DoseDefaults.recommendedInjectionSites(for: .liraglutide)
        #expect(liraglutideSites == ["Thigh", "Abdomen"])
        
        // Dulaglutide - weekly auto-injector, all 5 sites suitable
        let dulaglutideSites = DoseDefaults.recommendedInjectionSites(for: .dulaglutide)
        #expect(dulaglutideSites == ["Thigh", "Abdomen", "Upper arm", "Lower back", "Buttocks"])
    }
    
    @Test("Next recommended site with no recent doses")
    func nextRecommendedSiteWithNoDoses() throws {
        let medication = Medication.semaglutide
        let recentDoses: [Dose] = []
        
        let nextSite = DoseDefaults.nextRecommendedSite(
            for: medication,
            recentDoses: recentDoses
        )
        
        // Should return first in rotation when no recent doses
        #expect(nextSite == "Thigh")
    }
    
    @Test("Next recommended site with rotation logic")
    func nextRecommendedSiteWithRotation() throws {
        let medication = Medication.semaglutide
        
        // Create doses with recent injection sites
        let dose1 = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-604800), site: "Thigh") // 1 week ago
        let dose2 = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-86400), site: "Abdomen") // 1 day ago
        
        let nextSite = DoseDefaults.nextRecommendedSite(
            for: medication,
            recentDoses: [dose2, dose1] // Most recent first
        )
        
        // Should recommend Upper arm since Thigh and Abdomen were recently used
        #expect(nextSite == "Upper arm")
    }
    
    @Test("Next recommended site with all sites recently used")
    func nextRecommendedSiteAllSitesUsed() throws {
        let medication = Medication.semaglutide
        
        // Create doses covering all recommended sites
        let dose1 = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-1800), site: "Thigh") // 30 min ago
        let dose2 = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-3600), site: "Abdomen") // 1 hour ago  
        let dose3 = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-5400), site: "Upper arm") // 1.5 hours ago
        
        let nextSite = DoseDefaults.nextRecommendedSite(
            for: medication,
            recentDoses: [dose1, dose2, dose3]
        )
        
        // Should return first in rotation when all sites were recently used
        #expect(nextSite == "Thigh")
    }
    
    @Test("Next recommended site with preferred sites override")
    func nextRecommendedSiteWithPreferredSites() throws {
        let medication = Medication.semaglutide
        let preferredSites = ["Abdomen", "Thigh"] // Custom order
        
        let nextSite = DoseDefaults.nextRecommendedSite(
            for: medication,
            recentDoses: [],
            preferredSites: preferredSites
        )
        
        // Should use preferred sites order, not medication default
        #expect(nextSite == "Abdomen")
    }
    
    // MARK: - Dose Timing Tests
    
    @Test("Recommended dose timing by medication")
    func recommendedDoseTimingByMedication() throws {
        // Weekly medications should recommend Sunday 9 AM
        let semaglutideTime = DoseDefaults.recommendedDoseTime(for: .semaglutide)
        #expect(semaglutideTime.weekday == 1) // Sunday
        #expect(semaglutideTime.hour == 9)
        #expect(semaglutideTime.minute == 0)
        
        let tirzepatideTime = DoseDefaults.recommendedDoseTime(for: .tirzepatide)
        #expect(tirzepatideTime.weekday == 1) // Sunday
        #expect(tirzepatideTime.hour == 9)
        
        let dulaglutideTime = DoseDefaults.recommendedDoseTime(for: .dulaglutide)
        #expect(dulaglutideTime.weekday == 1) // Sunday
        #expect(dulaglutideTime.hour == 9)
        
        // Daily medication should recommend 8 AM daily
        let liraglutideTime = DoseDefaults.recommendedDoseTime(for: .liraglutide)
        #expect(liraglutideTime.weekday == nil) // No specific weekday
        #expect(liraglutideTime.hour == 8)
        #expect(liraglutideTime.minute == 0)
    }
    
    // MARK: - Dose Scheduling Tests
    
    @Test("Next scheduled dose for weekly medication")
    func nextScheduledDoseWeeklyMedication() throws {
        let profile = createTestMedicationProfile(
            medication: .semaglutide,
            startDate: Date().addingTimeInterval(-604800) // 1 week ago
        )
        
        // Add a dose from 3 days ago
        let lastDose = Dose(
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-259200) // 3 days ago
        )
        
        let nextDose = DoseDefaults.nextScheduledDose(for: profile, doses: [lastDose])
        
        #expect(nextDose != nil)
        
        // Should be 7 days after last dose (4 days from now)
        let expectedDate = Calendar.current.date(byAdding: .day, value: 7, to: lastDose.timestamp)!
        let timeDifference = abs(nextDose!.timeIntervalSince(expectedDate))
        #expect(timeDifference < 60) // Within 1 minute tolerance
    }
    
    @Test("Next scheduled dose for daily medication")
    func nextScheduledDoseDailyMedication() throws {
        let profile = createTestMedicationProfile(
            medication: .liraglutide,
            startDate: Date().addingTimeInterval(-86400) // 1 day ago
        )
        
        // Add a dose from yesterday
        let lastDose = Dose(
            amount: 1.2,
            timestamp: Date().addingTimeInterval(-86400) // 1 day ago
        )
        
        let nextDose = DoseDefaults.nextScheduledDose(for: profile, doses: [lastDose])
        
        #expect(nextDose != nil)
        
        // Should be 1 day after last dose (today)
        let expectedDate = Calendar.current.date(byAdding: .day, value: 1, to: lastDose.timestamp)!
        let timeDifference = abs(nextDose!.timeIntervalSince(expectedDate))
        #expect(timeDifference < 60) // Within 1 minute tolerance
    }
    
    @Test("Next scheduled dose with no previous doses")
    func nextScheduledDoseNoPreviousDoses() throws {
        let startDate = Date().addingTimeInterval(-172800) // 2 days ago
        let profile = createTestMedicationProfile(
            medication: .semaglutide,
            startDate: startDate
        )
        
        let nextDose = DoseDefaults.nextScheduledDose(for: profile, doses: [])
        
        #expect(nextDose != nil)
        
        // Should be 7 days after start date
        let expectedDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        let timeDifference = abs(nextDose!.timeIntervalSince(expectedDate))
        #expect(timeDifference < 60) // Within 1 minute tolerance
    }
    
    @Test("Next scheduled dose with invalid medication")
    func nextScheduledDoseInvalidMedication() throws {
        let profile = MedicationProfile(
            genericName: "Invalid",
            brandName: "Invalid"
        )
        // Don't set medicationType - should return nil
        
        let nextDose = DoseDefaults.nextScheduledDose(for: profile, doses: [])
        #expect(nextDose == nil)
    }
    
    // MARK: - Overdue Dose Tests
    
    @Test("Dose overdue detection for weekly medication")
    func doseOverdueWeeklyMedication() throws {
        let profile = createTestMedicationProfile(
            medication: .semaglutide,
            startDate: Date().addingTimeInterval(-604800 * 2) // 2 weeks ago
        )
        
        // Last dose was over a week ago (should be overdue)
        let lastDose = Dose(
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-604800 - 10800) // 1 week + 3 hours ago
        )
        
        let isOverdue = DoseDefaults.isDoseOverdue(for: profile, gracePeriodHours: 2, doses: [lastDose])
        #expect(isOverdue == true)
    }
    
    @Test("Dose not overdue within grace period")
    func doseNotOverdueWithinGracePeriod() throws {
        let profile = createTestMedicationProfile(
            medication: .semaglutide,
            startDate: Date().addingTimeInterval(-604800) // 1 week ago
        )
        
        // Last dose was exactly 1 week ago (within grace period)
        let lastDose = Dose(
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-604800) // Exactly 1 week ago
        )
        
        let isOverdue = DoseDefaults.isDoseOverdue(for: profile, gracePeriodHours: 2, doses: [lastDose])
        #expect(isOverdue == false)
    }
    
    @Test("Dose overdue for daily medication")
    func doseOverdueDailyMedication() throws {
        let profile = createTestMedicationProfile(
            medication: .liraglutide,
            startDate: Date().addingTimeInterval(-172800) // 2 days ago
        )
        
        // Last dose was over a day ago (should be overdue)
        let lastDose = Dose(
            amount: 1.2,
            timestamp: Date().addingTimeInterval(-86400 - 10800) // 1 day + 3 hours ago
        )
        
        let isOverdue = DoseDefaults.isDoseOverdue(for: profile, gracePeriodHours: 2, doses: [lastDose])
        #expect(isOverdue == true)
    }
    
    // MARK: - Adherence Calculation Tests
    
    @Test("Adherence calculation perfect adherence")
    func adherenceCalculationPerfect() throws {
        let profile = createTestMedicationProfile(
            medication: .semaglutide,
            startDate: Date().addingTimeInterval(-1209600) // 2 weeks ago
        )
        
        // Create doses for perfect adherence (2 weekly doses)
        let dose1 = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-604800)) // 1 week ago
        let dose2 = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-86400)) // 1 day ago
        
        let timeRange = DateInterval(
            start: Date().addingTimeInterval(-1209600), // 2 weeks ago
            end: Date()
        )
        
        let adherence = DoseDefaults.calculateAdherence(for: profile, in: timeRange, doses: [dose1, dose2])
        #expect(adherence == 1.0) // 100% adherence
    }
    
    @Test("Adherence calculation partial adherence")
    func adherenceCalculationPartial() throws {
        let profile = createTestMedicationProfile(
            medication: .semaglutide,
            startDate: Date().addingTimeInterval(-1814400) // 3 weeks ago
        )
        
        // Create doses for partial adherence (2 out of 3 weekly doses)
        let dose1 = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-1209600)) // 2 weeks ago
        let dose2 = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-86400)) // 1 day ago
        // Missing dose from 1 week ago
        
        let timeRange = DateInterval(
            start: Date().addingTimeInterval(-1814400), // 3 weeks ago
            end: Date()
        )
        
        let adherence = DoseDefaults.calculateAdherence(for: profile, in: timeRange, doses: [dose1, dose2])
        #expect(abs(adherence - 0.67) < 0.01) // ~67% adherence (2/3)
    }
    
    @Test("Adherence calculation with skipped doses")
    func adherenceCalculationWithSkippedDoses() throws {
        let profile = createTestMedicationProfile(
            medication: .liraglutide, // Daily medication
            startDate: Date().addingTimeInterval(-259200) // 3 days ago
        )
        
        // Create doses including skipped ones
        let dose1 = Dose(amount: 1.2, timestamp: Date().addingTimeInterval(-172800)) // 2 days ago
        let dose2 = Dose(amount: 0.0, timestamp: Date().addingTimeInterval(-86400), skipped: true) // Skipped yesterday
        let dose3 = Dose(amount: 1.2, timestamp: Date().addingTimeInterval(-3600)) // 1 hour ago
        
        let timeRange = DateInterval(
            start: Date().addingTimeInterval(-259200), // 3 days ago
            end: Date()
        )
        
        let adherence = DoseDefaults.calculateAdherence(for: profile, in: timeRange, doses: [dose1, dose2, dose3])
        #expect(abs(adherence - 0.67) < 0.01) // ~67% adherence (2/3, skipped dose not counted)
    }
    
    @Test("Adherence calculation zero expected doses")
    func adherenceCalculationZeroExpectedDoses() throws {
        let profile = createTestMedicationProfile(
            medication: .semaglutide,
            startDate: Date() // Just started
        )
        
        let timeRange = DateInterval(
            start: Date().addingTimeInterval(-3600), // 1 hour range
            end: Date()
        )
        
        let adherence = DoseDefaults.calculateAdherence(for: profile, in: timeRange, doses: [])
        #expect(adherence == 0.0)
    }
    
    // MARK: - Dose Streak Tests
    
    @Test("Dose streak calculation weekly medication")
    func doseStreakWeeklyMedication() throws {
        let profile = createTestMedicationProfile(
            medication: .semaglutide,
            startDate: Date().addingTimeInterval(-1814400) // 3 weeks ago
        )
        
        let calendar = Calendar.current
        let now = Date()
        
        // Create weekly doses for 3 weeks (perfect streak)
        let dose1 = Dose(amount: 1.0, timestamp: calendar.date(byAdding: .weekOfYear, value: -2, to: now)!) // 2 weeks ago
        let dose2 = Dose(amount: 1.0, timestamp: calendar.date(byAdding: .weekOfYear, value: -1, to: now)!) // 1 week ago
        let dose3 = Dose(amount: 1.0, timestamp: calendar.date(byAdding: .day, value: -1, to: now)!) // Yesterday (current week)
        
        let streak = DoseDefaults.calculateDoseStreak(for: profile, doses: [dose1, dose2, dose3])
        #expect(streak == 3) // 3-week streak
    }
    
    @Test("Dose streak calculation daily medication")
    func doseStreakDailyMedication() throws {
        let profile = createTestMedicationProfile(
            medication: .liraglutide,
            startDate: Date().addingTimeInterval(-259200) // 3 days ago
        )
        
        let calendar = Calendar.current
        let now = Date()
        
        // Create daily doses for 3 days
        let dose1 = Dose(amount: 1.2, timestamp: calendar.date(byAdding: .day, value: -2, to: now)!) // 2 days ago
        let dose2 = Dose(amount: 1.2, timestamp: calendar.date(byAdding: .day, value: -1, to: now)!) // Yesterday
        let dose3 = Dose(amount: 1.2, timestamp: calendar.date(byAdding: .hour, value: -2, to: now)!) // Today
        
        let streak = DoseDefaults.calculateDoseStreak(for: profile, doses: [dose1, dose2, dose3])
        #expect(streak == 3) // 3-day streak
    }
    
    @Test("Dose streak with missed dose")
    func doseStreakWithMissedDose() throws {
        let profile = createTestMedicationProfile(
            medication: .semaglutide,
            startDate: Date().addingTimeInterval(-1814400) // 3 weeks ago
        )
        
        let calendar = Calendar.current
        let now = Date()
        
        // Create doses with a gap (missed week)
        let dose1 = Dose(amount: 1.0, timestamp: calendar.date(byAdding: .weekOfYear, value: -2, to: now)!) // 2 weeks ago
        // Missing: 1 week ago
        let dose2 = Dose(amount: 1.0, timestamp: calendar.date(byAdding: .day, value: -1, to: now)!) // Yesterday (current week)
        
        let streak = DoseDefaults.calculateDoseStreak(for: profile, doses: [dose1, dose2])
        #expect(streak == 1) // Only current week counts
    }
    
    @Test("Dose streak with skipped doses")
    func doseStreakWithSkippedDoses() throws {
        let profile = createTestMedicationProfile(
            medication: .liraglutide,
            startDate: Date().addingTimeInterval(-259200) // 3 days ago
        )
        
        let calendar = Calendar.current
        let now = Date()
        
        // Create doses including skipped one
        let dose1 = Dose(amount: 1.2, timestamp: calendar.date(byAdding: .day, value: -2, to: now)!) // 2 days ago
        let dose2 = Dose(amount: 0.0, timestamp: calendar.date(byAdding: .day, value: -1, to: now)!, skipped: true) // Yesterday (skipped)
        let dose3 = Dose(amount: 1.2, timestamp: calendar.date(byAdding: .hour, value: -2, to: now)!) // Today
        
        let streak = DoseDefaults.calculateDoseStreak(for: profile, doses: [dose1, dose2, dose3])
        #expect(streak == 1) // Only today counts, yesterday was skipped
    }
    
    @Test("Dose streak with no doses")
    func doseStreakNoDoses() throws {
        let profile = createTestMedicationProfile(
            medication: .semaglutide,
            startDate: Date().addingTimeInterval(-604800) // 1 week ago
        )
        
        let streak = DoseDefaults.calculateDoseStreak(for: profile, doses: [])
        #expect(streak == 0)
    }
    
    // MARK: - Dose Summary Tests
    
    @Test("Dose summary comprehensive statistics")
    func doseSummaryComprehensiveStats() throws {
        let profile = createTestMedicationProfile(
            medication: .semaglutide,
            startDate: Date().addingTimeInterval(-1814400) // 3 weeks ago
        )
        
        // Create varied dose history
        let dose1 = Dose(amount: 0.5, timestamp: Date().addingTimeInterval(-1209600), site: "Thigh") // 2 weeks ago
        let dose2 = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-604800), site: "Abdomen") // 1 week ago
        let dose3 = Dose(amount: 0.0, timestamp: Date().addingTimeInterval(-604800 + 3600), skipped: true) // 1 week ago + 1 hour (skipped)
        let dose4 = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-3600), site: "Thigh") // 1 hour ago
        
        let summary = DoseDefaults.getDoseSummary(for: profile, doses: [dose1, dose2, dose3, dose4])
        
        // Verify basic counts
        #expect(summary.totalDoses == 4)
        #expect(summary.completedDoses == 3) // dose3 was skipped
        #expect(summary.skippedDoses == 1)
        
        // Verify average dose (only completed doses)
        let expectedAverage = (0.5 + 1.0 + 1.0) / 3.0
        #expect(abs(summary.averageDose - expectedAverage) < 0.01)
        
        // Verify completion and skip rates
        #expect(abs(summary.completionRate - 0.75) < 0.01) // 3/4
        #expect(abs(summary.skipRate - 0.25) < 0.01) // 1/4
        
        // Verify most used injection site
        #expect(summary.mostUsedInjectionSite == "Thigh") // Used twice
        
        // Verify streak (should be 3 since all weeks have at least one non-skipped dose)
        #expect(summary.currentStreak == 3)
    }
    
    @Test("Dose summary with time range filter")
    func doseSummaryWithTimeRangeFilter() throws {
        let profile = createTestMedicationProfile(
            medication: .semaglutide,
            startDate: Date().addingTimeInterval(-1814400) // 3 weeks ago
        )
        
        // Create doses spanning 3 weeks
        let dose1 = Dose(amount: 0.5, timestamp: Date().addingTimeInterval(-1814400), site: "Thigh") // 3 weeks ago
        let dose2 = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-1209600), site: "Abdomen") // 2 weeks ago
        let dose3 = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-604800), site: "Thigh") // 1 week ago
        let dose4 = Dose(amount: 1.0, timestamp: Date().addingTimeInterval(-86400), site: "Upper arm") // 1 day ago
        
        // Filter to last 2 weeks only (make start slightly earlier to include dose2)
        let twoWeeksAgo = Date().addingTimeInterval(-1209600 - 1) // 2 weeks ago minus 1 second
        let timeRange = DateInterval(start: twoWeeksAgo, end: Date())
        
        let summary = DoseDefaults.getDoseSummary(for: profile, in: timeRange, doses: [dose1, dose2, dose3, dose4])
        
        // Should only include dose2, dose3, and dose4
        #expect(summary.totalDoses == 3)
        #expect(summary.completedDoses == 3)
        #expect(summary.skippedDoses == 0)
        
        // Average should exclude dose1
        let expectedAverage = (1.0 + 1.0 + 1.0) / 3.0
        #expect(abs(summary.averageDose - expectedAverage) < 0.01)
    }
    
    @Test("Dose summary empty dose history")
    func doseSummaryEmptyHistory() throws {
        let profile = createTestMedicationProfile(
            medication: .semaglutide,
            startDate: Date().addingTimeInterval(-604800) // 1 week ago
        )
        
        let summary = DoseDefaults.getDoseSummary(for: profile, doses: [])
        
        #expect(summary.totalDoses == 0)
        #expect(summary.completedDoses == 0)
        #expect(summary.skippedDoses == 0)
        #expect(summary.averageDose == 0.0)
        #expect(summary.adherencePercentage == 0.0)
        #expect(summary.completionRate == 0.0)
        #expect(summary.skipRate == 0.0)
        #expect(summary.currentStreak == 0)
        #expect(summary.mostUsedInjectionSite == nil)
    }
    
    // MARK: - Medication Default Tests
    
    @Test("Default starting doses by medication")
    func defaultStartingDosesByMedication() throws {
        // Test each medication's starting dose
        let semaglutideStartingDose = DoseDefaults.defaultStartingDose(for: .semaglutide, brand: "Ozempic")
        #expect(semaglutideStartingDose == 0.25)
        
        let tirzepatideStartingDose = DoseDefaults.defaultStartingDose(for: .tirzepatide, brand: "Mounjaro")
        #expect(tirzepatideStartingDose == 2.5)
        
        let liraglutideStartingDose = DoseDefaults.defaultStartingDose(for: .liraglutide, brand: "Saxenda")
        #expect(liraglutideStartingDose == 0.6)
        
        let dulaglutideStartingDose = DoseDefaults.defaultStartingDose(for: .dulaglutide, brand: "Trulicity")
        #expect(dulaglutideStartingDose == 0.75)
    }
    
    @Test("Recommended escalation schedules")
    func recommendedEscalationSchedules() throws {
        // Test semaglutide escalation from starting dose
        let semaglutideSchedule = DoseDefaults.recommendedEscalationSchedule(
            for: .semaglutide,
            brand: "Ozempic",
            startingDose: 0.25
        )
        #expect(semaglutideSchedule == [0.25, 0.5, 1.0, 2.0])
        
        // Test tirzepatide escalation from mid-point
        let tirzepatideSchedule = DoseDefaults.recommendedEscalationSchedule(
            for: .tirzepatide,
            brand: "Mounjaro",
            startingDose: 5.0
        )
        #expect(tirzepatideSchedule == [5.0, 7.5, 10.0, 12.5, 15.0])
    }
    
    @Test("Escalation intervals by medication")
    func escalationIntervalsByMedication() throws {
        // Weekly medications should escalate every 4 weeks
        #expect(DoseDefaults.escalationInterval(for: .semaglutide) == 4)
        #expect(DoseDefaults.escalationInterval(for: .tirzepatide) == 4)
        #expect(DoseDefaults.escalationInterval(for: .dulaglutide) == 4)
        
        // Daily medication can escalate weekly
        #expect(DoseDefaults.escalationInterval(for: .liraglutide) == 1)
    }
    
    @Test("All injection sites constant")
    func allInjectionSitesConstant() throws {
        let expectedSites = ["Thigh", "Abdomen", "Upper arm", "Lower back", "Buttocks"]
        #expect(DoseDefaults.allInjectionSites == expectedSites)
    }
    
    // MARK: - Helper Methods
    
    private func createTestMedicationProfile(
        medication: Medication,
        startDate: Date,
        currentDose: Double = 1.0
    ) -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: medication.displayName,
            brandName: medication.brands.first ?? "",
            currentDose: currentDose,
            startDate: startDate,
            medicationType: medication.rawValue
        )
        // Initialize doses as empty array for testing without SwiftData context
        profile.doses = []
        return profile
    }
}
