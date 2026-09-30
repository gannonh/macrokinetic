import SwiftData
import Testing

@testable import JabTracker

@Suite("Release feature policy")
struct ReleasePolicyTests {
    @Test("Every unfinished release feature is disabled")
    func unfinishedFeaturesAreDisabled() {
        #expect(ReleaseFeature.allCases.count == 12)
        #expect(ReleasePolicy.isEnabled(.subscriptions) == false)
        #expect(ReleasePolicy.isEnabled(.aiFoodCapture) == false)
        #expect(ReleasePolicy.isEnabled(.recipes) == false)
        #expect(ReleasePolicy.isEnabled(.foodFavorites) == false)
        #expect(ReleasePolicy.isEnabled(.shortcutCustomization) == false)
        #expect(ReleasePolicy.isEnabled(.dashboardCustomization) == false)
        #expect(ReleasePolicy.isEnabled(.foodLogCustomization) == false)
        #expect(ReleasePolicy.isEnabled(.extendedBodyMetrics) == false)
        #expect(ReleasePolicy.isEnabled(.progressPhotos) == false)
        #expect(ReleasePolicy.isEnabled(.manualOnboarding) == false)
        #expect(ReleasePolicy.isEnabled(.helpCenter) == false)
        #expect(ReleasePolicy.isEnabled(.historicalTDEERecalculation) == false)
    }

    @Test("Filtering supported metrics preserves hidden preferences and calorie settings")
    @MainActor
    func filteringPreservesPreferences() {
        let user = User(
            enabledBodyMetrics: ["waist", "leftBicep", "waistToHip"],
            enabledPhotoTypes: ["front", "side"],
            addBurnedCaloriesEnabled: true,
            rolloverCaloriesEnabled: true,
            predictiveActivityEnabled: true
        )

        #expect(MetricKey.allCases.filter(\.isAvailableInRelease) == [.neck, .chest, .waist, .hip])
        #expect(user.enabledBodyMetrics == ["waist", "leftBicep", "waistToHip"])
        #expect(user.enabledPhotoTypes == ["front", "side"])
        #expect(user.addBurnedCaloriesEnabled == true)
        #expect(user.rolloverCaloriesEnabled == true)
        #expect(user.predictiveActivityEnabled == true)
    }
}

@Suite("Onboarding release policy")
struct OnboardingReleasePolicyTests {
    @Test("Onboarding offers Coached and Collaborative; the Strategy catalog retains Manual")
    @MainActor
    func availableStyles() {
        let controller = DataController(inMemory: true)
        let viewModel = OnboardingViewModel(
            dataController: controller,
            authManager: AuthenticationManager(dataController: controller)
        )
        #expect(viewModel.availableProgramStyles == [.coached, .collaborative])
        #expect(ProgramStyle.allCases == [.coached, .collaborative, .manual])
        viewModel.currentStep = .programStyle
        viewModel.programStyle = .manual
        #expect(viewModel.canProceedToNext == false)
        viewModel.programStyle = .coached
        #expect(viewModel.canProceedToNext == true)
        viewModel.programStyle = .collaborative
        #expect(viewModel.canProceedToNext == true)
    }

    @Test("A direct Manual request cannot write profile, weight, goals, programs, or completion")
    @MainActor
    func manualRequestRejectedBeforeWrites() async throws {
        let controller = DataController(inMemory: true)
        let context = controller.container.mainContext
        let user = User(name: "Original profile", heightCm: 173, gender: "Female", weight: 70)
        context.insert(user)
        try context.save()
        let authManager = AuthenticationManager(dataController: controller)
        authManager.currentUser = user
        let viewModel = OnboardingViewModel(dataController: controller, authManager: authManager)
        viewModel.programStyle = .manual
        viewModel.editHeightFeet = 6
        viewModel.editHeightInches = 2
        viewModel.editSex = "Male"
        viewModel.goalViewModel.currentWeightKg = 90
        viewModel.trainingLevel = .cardio

        do {
            try await viewModel.calculateTargets()
            Issue.record("Manual onboarding must reject target calculation")
        } catch OnboardingError.unsupportedProgramStyle {
        }
        let result = await viewModel.completeOnboarding()
        guard case .failed(let error) = result,
            let onboardingError = error as? OnboardingError,
            case .unsupportedProgramStyle = onboardingError
        else {
            Issue.record("Manual onboarding must reject completion")
            return
        }

        #expect(user.name == "Original profile")
        #expect(user.heightCm == 173)
        #expect(user.gender == "Female")
        #expect(user.weight == 70)
        #expect(user.hasCompletedOnboarding == false)
        #expect(user.onboardingCompletedAt == nil)
        #expect(context.hasChanges == false)
        #expect(try context.fetchCount(FetchDescriptor<WeightEntry>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<NutritionGoal>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<NutritionProgram>()) == 0)
    }
}
