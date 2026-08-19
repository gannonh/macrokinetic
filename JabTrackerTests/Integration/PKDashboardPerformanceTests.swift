import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("PK Dashboard Performance Tests")
@MainActor
struct PKDashboardPerformanceTests {
    let container: ModelContainer
    let context: ModelContext
    let pkEngine: PharmacokineticsEngine

    init() throws {
        let schema = Schema([User.self, MedicationProfile.self, Dose.self, DoseTitration.self])
        let config = InMemoryTestStore.configuration(schema: schema)
        self.container = try ModelContainer(for: schema, configurations: [config])
        self.context = self.container.mainContext
        self.pkEngine = PharmacokineticsEngine()
    }

    private func createTestUser() -> User {
        let uniqueId = UUID().uuidString
        return User(
            email: "test-\(uniqueId)@pkintegration.com",
            name: "PK Integration Test User \(uniqueId)",
            appleUserId: "test-user-pk-integration-\(uniqueId)")
    }

    private func createTestMedicationProfile(user: User) -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            startDate: Date().addingTimeInterval(-14 * 24 * 3600),
            medicationType: "semaglutide")
        profile.user = user
        return profile
    }

    @Test("Dashboard calculation performance with large dose history")
    func dashboardPerformanceWithLargeDoseHistory() async throws {
        let user = self.createTestUser()
        let medicationProfile = self.createTestMedicationProfile(user: user)

        self.context.insert(user)
        self.context.insert(medicationProfile)
        try self.context.save()

        let doseService = DoseService(pkEngine: pkEngine)

        let numberOfDoses = 100
        for index in 0..<numberOfDoses {
            let daysAgo = Double(numberOfDoses - index)
            _ = try await doseService.saveDose(
                amount: 1.0,
                timestamp: Date().addingTimeInterval(-daysAgo * 24 * 3600),
                medicationProfile: medicationProfile,
                site: index % 2 == 0 ? "Abdomen" : "Thigh",
                notes: "Dose \(index + 1)",
                context: self.context)
        }

        let loadedDoses = medicationProfile.doses ?? []
        #expect(loadedDoses.count >= numberOfDoses)

        let startTime = Date()

        let concentration = self.pkEngine.calculateCurrentConcentration(
            for: user,
            medication: medicationProfile)
        _ = self.pkEngine.calculateTroughLevel(for: medicationProfile)
        _ = self.pkEngine.calculateSteadyStateProgress(for: medicationProfile)

        let calculationTime = Date().timeIntervalSince(startTime)

        // Allow normal scheduler jitter around the 50ms product target in CI.
        #expect(
            calculationTime < 0.06,
            "Calculations should complete within the 50ms target, actual: \(calculationTime * 1000)ms")
        #expect(concentration > 0.0, "Concentration should be positive with large dose history")

        let allDoses = try context.fetch(FetchDescriptor<Dose>())
        let profileDoses = allDoses.filter { $0.medication?.id == medicationProfile.id }
        #expect(
            profileDoses.count >= numberOfDoses,
            "Should have at least the expected number of doses for this profile in isolated test container"
        )
    }
}
