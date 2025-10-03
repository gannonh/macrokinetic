import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Comprehensive tests for DoseDataService dose fetching functionality
struct DoseDataServiceTests {
    // MARK: - Test Setup

    @MainActor private func createTestContainer() -> ModelContainer {
        DataController.testContainer().container
    }

    private func createTestUser() -> User {
        User(
            email: "doseservice@test.com",
            name: "Dose Service Test User",
            appleUserId: "test-dose-service-user")
    }

    private func createTestMedicationProfile(medication: Medication, user _: User)
        -> MedicationProfile
    {
        let profile = MedicationProfile(
            genericName: medication.displayName,
            brandName: medication.displayName,
            currentDose: 1.0)
        profile.medication = medication
        return profile
    }

    private func createTestDose(
        amount: Double, medicationProfile _: MedicationProfile, user _: User, daysAgo: Int = 0
    ) -> Dose {
        let timestamp = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let dose = Dose(
            amount: amount,
            timestamp: timestamp,
            site: "abdomen",
            notes: "Test dose")
        return dose
    }

    // MARK: - TimePeriod Fetching Tests

    @Test("fetchDoses returns doses within last 7 days")
    @MainActor func fetchDosesLast7Days() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        // Create doses at different time points
        let dose1 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 3)  // Within 7 days
        let dose2 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 10)  // Outside 7 days

        dose1.user = user
        dose1.medication = profile
        dose2.user = user
        dose2.medication = profile

        context.insert(dose1)
        context.insert(dose2)

        try context.save()

        let doseService = DoseDataService()
        let doses = doseService.fetchDoses(
            for: user,
            within: .last7Days,
            context: context
        )

        #expect(doses.count == 1, "Should return only dose within last 7 days")
        #expect(doses.first?.id == dose1.id, "Should return the dose from 3 days ago")
    }

    @Test("fetchDoses returns doses within last 30 days")
    @MainActor func fetchDosesLast30Days() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        let dose1 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 15)
        let dose2 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 40)

        dose1.user = user
        dose1.medication = profile
        dose2.user = user
        dose2.medication = profile

        context.insert(dose1)
        context.insert(dose2)

        try context.save()

        let doseService = DoseDataService()
        let doses = doseService.fetchDoses(
            for: user,
            within: .last30Days,
            context: context
        )

        #expect(doses.count == 1, "Should return only dose within last 30 days")
        #expect(doses.first?.id == dose1.id, "Should return the dose from 15 days ago")
    }

    @Test("fetchDoses returns doses within last 90 days")
    @MainActor func fetchDosesLast90Days() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        let dose1 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 45)
        let dose2 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 100)

        dose1.user = user
        dose1.medication = profile
        dose2.user = user
        dose2.medication = profile

        context.insert(dose1)
        context.insert(dose2)

        try context.save()

        let doseService = DoseDataService()
        let doses = doseService.fetchDoses(
            for: user,
            within: .last90Days,
            context: context
        )

        #expect(doses.count == 1, "Should return only dose within last 90 days")
    }

    @Test("fetchDoses returns doses within last year")
    @MainActor func fetchDosesLastYear() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        let dose1 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 200)
        let dose2 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 400)

        dose1.user = user
        dose1.medication = profile
        dose2.user = user
        dose2.medication = profile

        context.insert(dose1)
        context.insert(dose2)

        try context.save()

        let doseService = DoseDataService()
        let doses = doseService.fetchDoses(
            for: user,
            within: .lastYear,
            context: context
        )

        #expect(doses.count == 1, "Should return only dose within last year")
    }

    @Test("fetchDoses with .all returns all doses")
    @MainActor func fetchDosesAll() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        let dose1 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 10)
        let dose2 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 400)

        dose1.user = user
        dose1.medication = profile
        dose2.user = user
        dose2.medication = profile

        context.insert(dose1)
        context.insert(dose2)

        try context.save()

        let doseService = DoseDataService()
        let doses = doseService.fetchDoses(
            for: user,
            within: .all,
            context: context
        )

        #expect(doses.count == 2, "Should return all doses regardless of date")
    }

    // MARK: - Date Range Fetching Tests

    @Test("fetchDoses with date range filters correctly")
    @MainActor func fetchDosesDateRange() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        let dose1 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 5)
        let dose2 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 15)
        let dose3 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 25)

        dose1.user = user
        dose1.medication = profile
        dose2.user = user
        dose2.medication = profile
        dose3.user = user
        dose3.medication = profile

        context.insert(dose1)
        context.insert(dose2)
        context.insert(dose3)

        try context.save()

        let startDate =
            Calendar.current.date(byAdding: .day, value: -20, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()

        let doseService = DoseDataService()
        let doses = doseService.fetchDoses(
            for: user,
            from: startDate,
            to: endDate,
            context: context
        )

        #expect(doses.count == 1, "Should return only dose within date range")
        #expect(doses.first?.id == dose2.id, "Should return dose from 15 days ago")
    }

    // MARK: - All Doses Fetching Tests

    @Test("fetchAllDoses returns all doses for user")
    @MainActor func fetchAllDoses() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        let dose1 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 1)
        let dose2 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 100)
        let dose3 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 500)

        dose1.user = user
        dose1.medication = profile
        dose2.user = user
        dose2.medication = profile
        dose3.user = user
        dose3.medication = profile

        context.insert(dose1)
        context.insert(dose2)
        context.insert(dose3)

        try context.save()

        let doseService = DoseDataService()
        let doses = doseService.fetchDoses(
            for: user,
            within: .all,
            context: context
        )

        #expect(doses.count == 3, "Should return all doses")
    }

    // MARK: - Recent Doses Fetching Tests

    @Test("fetchRecentDoses returns limited number of doses")
    @MainActor func fetchRecentDosesLimit() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        // Create 5 doses
        for daysAgo in 1...5 {
            let dose = self.createTestDose(
                amount: 1.0, medicationProfile: profile, user: user, daysAgo: daysAgo)
            dose.user = user
            dose.medication = profile
            context.insert(dose)
        }

        try context.save()

        let doseService = DoseDataService()
        let doses = doseService.fetchRecentDoses(
            for: user,
            limit: 3,
            context: context
        )

        #expect(doses.count == 3, "Should return only 3 most recent doses")
    }

    @Test("fetchRecentDoses returns doses sorted by timestamp descending")
    @MainActor func fetchRecentDosesSorting() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        let dose1 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 1)
        let dose2 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 3)
        let dose3 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 2)

        dose1.user = user
        dose1.medication = profile
        dose2.user = user
        dose2.medication = profile
        dose3.user = user
        dose3.medication = profile

        context.insert(dose1)
        context.insert(dose2)
        context.insert(dose3)

        try context.save()

        let doseService = DoseDataService()
        let doses = doseService.fetchRecentDoses(
            for: user,
            limit: 10,
            context: context
        )

        #expect(doses.count == 3, "Should return all 3 doses")
        #expect(
            doses[0].timestamp > doses[1].timestamp, "First dose should be most recent")
        #expect(
            doses[1].timestamp > doses[2].timestamp, "Second dose should be more recent than third")
    }

    // MARK: - Medication Profile Fetching Tests

    @Test("fetchDoses for medication profile filters correctly")
    @MainActor func fetchDosesForProfile() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let semaglutideProfile = self.createTestMedicationProfile(
            medication: .semaglutide, user: user)
        let tirzepatideProfile = self.createTestMedicationProfile(
            medication: .tirzepatide, user: user)

        context.insert(user)
        semaglutideProfile.user = user
        tirzepatideProfile.user = user
        context.insert(semaglutideProfile)
        context.insert(tirzepatideProfile)

        let dose1 = self.createTestDose(
            amount: 1.0, medicationProfile: semaglutideProfile, user: user, daysAgo: 5)
        let dose2 = self.createTestDose(
            amount: 2.5, medicationProfile: tirzepatideProfile, user: user, daysAgo: 5)

        dose1.user = user
        dose1.medication = semaglutideProfile
        dose2.user = user
        dose2.medication = tirzepatideProfile

        context.insert(dose1)
        context.insert(dose2)

        try context.save()

        let doseService = DoseDataService()
        let doses = doseService.fetchDoses(
            for: semaglutideProfile,
            within: .last30Days,
            context: context
        )

        #expect(doses.count == 1, "Should return only semaglutide doses")
        #expect(doses.first?.amount == 1.0, "Should be semaglutide dose with 1.0mg amount")
    }

    // MARK: - Empty Results Tests

    @Test("fetchDoses returns empty array when no doses exist")
    @MainActor func fetchDosesEmptyResults() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        try context.save()

        let doseService = DoseDataService()
        let doses = doseService.fetchDoses(
            for: user,
            within: .last30Days,
            context: context
        )

        #expect(doses.isEmpty, "Should return empty array when no doses exist")
    }

    @Test("fetchRecentDoses returns empty array when no doses exist")
    @MainActor func fetchRecentDosesEmpty() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()

        context.insert(user)

        try context.save()

        let doseService = DoseDataService()
        let doses = doseService.fetchRecentDoses(
            for: user,
            limit: 5,
            context: context
        )

        #expect(doses.isEmpty, "Should return empty array when no doses exist")
    }
}
