import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
@Suite("Onboarding launch contracts", .serialized)
struct OnboardingLaunchContractTests {
    private let defaultsKeys = [
        "hasCompletedOnboarding", "onboardingCompletedAt", "hasSkippedOnboarding", "onboardingSkippedAt",
    ]

    @Test("Nutrition-only completion retains one profile, goal and program when managers are recreated")
    func completionRetainsNutritionSetup() async throws {
        let defaults = defaultsKeys.map { ($0, UserDefaults.standard.object(forKey: $0)) }
        defer { restoreDefaults(defaults) }
        defaultsKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        let controller = DataController(inMemory: true)
        let (auth, user) = try makeUser(controller: controller)
        let context = controller.container.mainContext
        let viewModel = OnboardingViewModel(dataController: controller, authManager: auth)
        configureNutrition(viewModel)

        try await viewModel.calculateTargets()
        let result = await viewModel.completeOnboarding()
        guard case .success = result else {
            Issue.record("Expected completion success")
            return
        }
        let goal = try #require(context.fetch(FetchDescriptor<NutritionGoal>()).first)
        let program = try #require(goal.program)
        let goalID = goal.id
        let programID = program.id
        let completedAt = try #require(user.onboardingCompletedAt)
        #expect(user.name == "Launch Nutrition User")
        #expect(user.gender == "male")
        #expect(user.heightCm == 170.18)
        #expect(user.dateOfBirth == Date(timeIntervalSince1970: 631_152_000))
        #expect(user.healthSyncEnabled == false)
        #expect(user.hasCompletedOnboarding == true)
        #expect(user.onboardingSkippedAt == nil)
        #expect(goal.goalType == .maintenance)
        #expect(goal.startingWeightKg == 80)
        #expect(goal.targetWeightKg == 80)
        #expect(goal.weeklyWeightChangePaceKg == 0)
        #expect(program.style == .coached)

        let restoredUser = try #require(context.fetch(FetchDescriptor<User>()).first)
        let restoredAuth = AuthenticationManager(dataController: controller)
        restoredAuth.currentUser = restoredUser
        restoredAuth.authenticationState = .authenticated
        let coordinator = OnboardingCoordinator(authManager: restoredAuth, dataController: controller)
        coordinator.checkOnboardingStatus()
        #expect(coordinator.shouldShowOnboarding == false)
        let restoredViewModel = OnboardingViewModel(dataController: controller, authManager: restoredAuth)
        let repeated = await restoredViewModel.completeOnboarding()
        guard case .alreadyCompleted = repeated else {
            Issue.record("Expected repeated completion to retain existing records")
            return
        }
        #expect(restoredUser.id == UUID(uuidString: "AEF081B7-DBAA-43C0-B4BD-2B5A607679EF"))
        #expect(restoredUser.onboardingCompletedAt == completedAt)
        #expect(try context.fetch(FetchDescriptor<User>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<NutritionGoal>()).map(\.id) == [goalID])
        #expect(try context.fetch(FetchDescriptor<NutritionProgram>()).map(\.id) == [programID])
        #expect(try context.fetch(FetchDescriptor<MedicationProfile>()).count == 0)
        #expect(try context.fetch(FetchDescriptor<Dose>()).count == 0)
    }

    @Test("Explicit skip retains the profile without creating nutrition or medication records")
    func skipRetainsProfileWithoutCreatingGoal() throws {
        let defaults = defaultsKeys.map { ($0, UserDefaults.standard.object(forKey: $0)) }
        defer { restoreDefaults(defaults) }
        defaultsKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        let controller = DataController(inMemory: true)
        let (auth, user) = try makeUser(controller: controller)
        let context = controller.container.mainContext
        let viewModel = OnboardingViewModel(dataController: controller, authManager: auth)
        viewModel.currentStep = .goalType
        #expect(viewModel.canSkip == true)
        viewModel.skipOnboarding()
        let skippedAt = try #require(user.onboardingSkippedAt)
        #expect(user.hasCompletedOnboarding == false)
        #expect(user.onboardingCompletedAt == nil)

        let restoredUser = try #require(context.fetch(FetchDescriptor<User>()).first)
        let restoredAuth = AuthenticationManager(dataController: controller)
        restoredAuth.currentUser = restoredUser
        restoredAuth.authenticationState = .authenticated
        let coordinator = OnboardingCoordinator(authManager: restoredAuth, dataController: controller)
        coordinator.checkOnboardingStatus()
        coordinator.checkOnboardingStatus()
        #expect(coordinator.shouldShowOnboarding == false)
        #expect(restoredUser.onboardingSkippedAt == skippedAt)
        #expect(restoredUser.hasCompletedOnboarding == false)
        #expect(restoredUser.name == "Launch Nutrition User")
        #expect(restoredUser.healthSyncEnabled == false)
        #expect(try context.fetch(FetchDescriptor<User>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<NutritionGoal>()).count == 0)
        #expect(try context.fetch(FetchDescriptor<NutritionProgram>()).count == 0)
        #expect(try context.fetch(FetchDescriptor<MedicationProfile>()).count == 0)
        #expect(try context.fetch(FetchDescriptor<Dose>()).count == 0)
    }

    private func makeUser(controller: DataController) throws -> (AuthenticationManager, User) {
        let user = User(email: "onboarding@example.invalid", name: "Launch Nutrition User")
        user.id = try #require(UUID(uuidString: "AEF081B7-DBAA-43C0-B4BD-2B5A607679EF"))
        controller.container.mainContext.insert(user)
        try controller.container.mainContext.save()
        let auth = AuthenticationManager(dataController: controller)
        auth.currentUser = user
        auth.authenticationState = .authenticated
        return (auth, user)
    }

    private func configureNutrition(_ viewModel: OnboardingViewModel) {
        viewModel.goalViewModel.goalType = .maintenance
        viewModel.goalViewModel.currentWeightKg = 80
        viewModel.goalViewModel.targetWeightKg = 80
        viewModel.editHeightFeet = 5
        viewModel.editHeightInches = 7
        viewModel.editSex = "male"
        viewModel.editBirthday = Date(timeIntervalSince1970: 631_152_000)
        viewModel.programStyle = .coached
        viewModel.dietPreference = .balanced
        viewModel.calorieFloorType = .standard
        viewModel.trainingLevel = TrainingLevel.none
        viewModel.weeklyDistributionMode = .even
        viewModel.proteinLevel = .moderate
    }

    private func restoreDefaults(_ values: [(String, Any?)]) {
        for (key, value) in values {
            if let value {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}
