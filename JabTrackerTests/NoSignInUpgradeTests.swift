import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// KAT-3586: 1.0 has no accounts. Every upgrade state must open straight into the app with all records intact.
@MainActor
@Suite("No sign-in upgrade retention", .serialized)
struct NoSignInUpgradeTests {
    private struct Counts: Equatable {
        var users = 0
        var doses = 0
        var profiles = 0
        var goals = 0
        var weights = 0
        var foodEntries = 0
    }

    private func counts(_ context: ModelContext) throws -> Counts {
        Counts(
            users: try context.fetchCount(FetchDescriptor<User>()),
            doses: try context.fetchCount(FetchDescriptor<Dose>()),
            profiles: try context.fetchCount(FetchDescriptor<MedicationProfile>()),
            goals: try context.fetchCount(FetchDescriptor<NutritionGoal>()),
            weights: try context.fetchCount(FetchDescriptor<WeightEntry>()),
            foodEntries: try context.fetchCount(FetchDescriptor<FoodEntry>()))
    }

    /// Seeds what a TestFlight user has on disk. `user` is nil for the signed-out state, where the old
    /// logout deleted the User and left the records that have no User relationship behind.
    private func seed(_ context: ModelContext, appleUserId: String?, withUser: Bool = true) throws -> User? {
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        context.insert(WeightEntry(timestamp: day, weightKg: 91.5))
        context.insert(
            FoodEntry(
                foodName: "Oats", mealSection: .breakfast, loggedAt: day, servingGrams: 80,
                caloriesPer100g: 380, proteinPer100g: 13, carbsPer100g: 66, fatPer100g: 7))
        guard withUser else {
            try context.save()
            return nil
        }
        let user = User(email: "a@b.c", name: "Pat", gender: "male", weight: 200, appleUserId: appleUserId)
        user.hasCompletedOnboarding = true
        context.insert(user)
        let profile = MedicationProfile(
            genericName: "Semaglutide", brandName: "Ozempic", currentDose: 1.0, medicationType: "semaglutide")
        profile.user = user
        context.insert(profile)
        for week in 0..<3 {
            let dose = Dose(amount: 1.0, timestamp: day.addingTimeInterval(Double(week) * 7 * 86_400))
            dose.user = user
            dose.medication = profile
            context.insert(dose)
        }
        let goal = NutritionGoal(goalType: .weightLoss, startingWeightKg: 91.5, targetWeightKg: 80)
        goal.user = user
        context.insert(goal)
        try context.save()
        return user
    }

    /// Clears the onboarding UserDefaults keys (shared with the host app) and returns a closure that restores them.
    private func isolateOnboardingDefaults() -> () -> Void {
        let defaults = UserDefaults.standard
        let keys = ["hasCompletedOnboarding", "onboardingCompletedAt", "hasSkippedOnboarding", "onboardingSkippedAt"]
        let saved = keys.map { ($0, defaults.object(forKey: $0)) }
        keys.forEach { defaults.removeObject(forKey: $0) }
        return {
            for (key, value) in saved {
                if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
            }
        }
    }

    @Test("Signed-in user: every record kept, User and Apple ID untouched, no sign-in state")
    func signedInUpgrade() async throws {
        let dataController = DataController.testContainer()
        let context = dataController.container.mainContext
        let user = try #require(try seed(context, appleUserId: "001234.abc"))
        let before = try counts(context)
        let userId = user.id

        let manager = AuthenticationManager(dataController: dataController)
        await manager.checkAuthenticationStatus()

        #expect(manager.authenticationState == .authenticated)
        #expect(manager.currentUser?.id == userId)
        #expect(manager.currentUser?.appleUserId == "001234.abc")
        #expect(try counts(context) == before)
        #expect(before == Counts(users: 1, doses: 3, profiles: 1, goals: 1, weights: 1, foodEntries: 1))
        #expect(manager.currentUser?.doses?.count == 3)
        #expect(manager.currentUser?.medicationProfiles?.count == 1)
        #expect(manager.currentUser?.nutritionGoals?.count == 1)
    }

    @Test("Apple ID already erased: records visible straight away, nothing to claim")
    func erasedAppleIdUpgrade() async throws {
        let dataController = DataController.testContainer()
        let context = dataController.container.mainContext
        let user = try #require(try seed(context, appleUserId: nil))
        let before = try counts(context)

        let manager = AuthenticationManager(dataController: dataController)
        await manager.checkAuthenticationStatus()

        #expect(manager.authenticationState == .authenticated)
        #expect(manager.currentUser?.id == user.id)
        #expect(try counts(context) == before)
    }

    @Test("Signed-out user (User gone, records left): nothing deleted, blank local profile added")
    func signedOutUpgrade() async throws {
        let dataController = DataController.testContainer()
        let context = dataController.container.mainContext
        _ = try seed(context, appleUserId: nil, withUser: false)

        let manager = AuthenticationManager(dataController: dataController)
        await manager.checkAuthenticationStatus()

        #expect(manager.authenticationState == .authenticated)
        #expect(try counts(context) == Counts(users: 1, weights: 1, foodEntries: 1))
    }

    @Test("Fresh install: local profile created and onboarding is shown")
    func freshInstallReachesOnboarding() async throws {
        let restore = isolateOnboardingDefaults()
        defer { restore() }
        let dataController = DataController.testContainer()
        let manager = AuthenticationManager(dataController: dataController)
        await manager.checkAuthenticationStatus()

        #expect(manager.authenticationState == .authenticated)
        #expect(manager.currentUser?.hasCompletedOnboarding == false)
        let coordinator = OnboardingCoordinator(authManager: manager, dataController: dataController)
        coordinator.checkOnboardingStatus()
        #expect(coordinator.shouldShowOnboarding)
    }

    @Test("Finished onboarding never reappears, with or without the Apple ID or the User")
    func onboardingDoesNotReappear() async throws {
        let defaults = UserDefaults.standard
        let restore = isolateOnboardingDefaults()
        defer { restore() }

        // Upgrade with the User intact
        let kept = DataController.testContainer()
        _ = try seed(kept.container.mainContext, appleUserId: nil)
        let keptManager = AuthenticationManager(dataController: kept)
        await keptManager.checkAuthenticationStatus()
        let keptCoordinator = OnboardingCoordinator(authManager: keptManager, dataController: kept)
        keptCoordinator.checkOnboardingStatus()
        #expect(!keptCoordinator.shouldShowOnboarding)

        // Signed-out upgrade: User row is gone, the UserDefaults completion flag survives
        defaults.set(true, forKey: "hasCompletedOnboarding")
        let gone = DataController.testContainer()
        let goneManager = AuthenticationManager(dataController: gone)
        await goneManager.checkAuthenticationStatus()
        let goneCoordinator = OnboardingCoordinator(authManager: goneManager, dataController: gone)
        goneCoordinator.checkOnboardingStatus()
        #expect(!goneCoordinator.shouldShowOnboarding)
        #expect(goneManager.currentUser?.hasCompletedOnboarding == true)
    }

    @Test("Relaunching never adds a second User")
    func relaunchIsIdempotent() async throws {
        let dataController = DataController.testContainer()
        for _ in 0..<3 {
            await AuthenticationManager(dataController: dataController).checkAuthenticationStatus()
        }
        #expect(try dataController.container.mainContext.fetchCount(FetchDescriptor<User>()) == 1)
    }
}
