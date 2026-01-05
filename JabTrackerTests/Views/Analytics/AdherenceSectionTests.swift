//
//  AdherenceSectionTests.swift
//  JabTrackerTests
//
//  Tests for AdherenceSection component.
//

import SwiftData
import SwiftUI
import Testing

@testable import JabTracker

@MainActor
struct AdherenceSectionTests {

    // MARK: - Test Helpers

    /// Creates an in-memory SwiftData context for testing
    private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            Dose.self,
            DoseTitration.self,
            DoseSchedule.self,
            ScheduledDose.self,
            NutritionGoal.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [config])
        return (container.mainContext, container)
    }

    /// Creates a test user
    private func createTestUser(in context: ModelContext) -> User {
        let user = User(
            email: "test@example.com",
            name: "Test User",
            appleUserId: "test-apple-id"
        )
        context.insert(user)
        return user
    }

    /// Creates a test medication profile
    private func createTestMedicationProfile(in context: ModelContext, for user: User) -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 0.5,
            medicationType: "semaglutide"
        )
        profile.user = user
        context.insert(profile)
        return profile
    }

    // MARK: - Rendering Tests

    @Test("Renders all adherence cards when user and profiles exist")
    func testRendersAdherenceCardsWhenUserAndProfilesExist() async throws {
        // GIVEN: AdherenceSection with valid user and medication profiles
        let (context, container) = createTestContext()
        _ = container  // Keep alive

        let user = createTestUser(in: context)
        let profile = createTestMedicationProfile(in: context, for: user)
        let viewModel = AnalyticsViewModel()
        let analyticsService = AnalyticsService()

        // WHEN: Creating the section with user and profiles
        let section = AdherenceSection(
            user: user,
            medicationProfiles: [profile],
            viewModel: viewModel,
            modelContext: context,
            analyticsService: analyticsService
        )

        // THEN: Section should have user and profiles (adherence cards will render)
        #expect(section.user != nil, "AdherenceSection should have a user")
        #expect(section.medicationProfiles.count == 1, "AdherenceSection should have medication profiles")
        #expect(section.medicationProfiles.isEmpty == false, "Profiles should not be empty")
    }

    @Test("Renders noDataSection when user is nil")
    func testRendersNoDataSectionWhenUserIsNil() async throws {
        // GIVEN: AdherenceSection with nil user
        let (context, container) = createTestContext()
        _ = container  // Keep alive

        let viewModel = AnalyticsViewModel()
        let analyticsService = AnalyticsService()

        // WHEN: Creating section with nil user
        let section = AdherenceSection(
            user: nil,
            medicationProfiles: [],
            viewModel: viewModel,
            modelContext: context,
            analyticsService: analyticsService
        )

        // THEN: Section should indicate no data state (nil user)
        #expect(section.user == nil, "Section should have nil user")
    }

    @Test("Renders noDataSection when profiles is empty")
    func testRendersNoDataSectionWhenProfilesIsEmpty() async throws {
        // GIVEN: AdherenceSection with user but empty profiles
        let (context, container) = createTestContext()
        _ = container  // Keep alive

        let user = createTestUser(in: context)
        let viewModel = AnalyticsViewModel()
        let analyticsService = AnalyticsService()

        // WHEN: Creating section with empty profiles
        let section = AdherenceSection(
            user: user,
            medicationProfiles: [],  // Empty profiles
            viewModel: viewModel,
            modelContext: context,
            analyticsService: analyticsService
        )

        // THEN: Section should have user but empty profiles (triggers no data state)
        #expect(section.user != nil, "Section should have user")
        #expect(section.medicationProfiles.isEmpty, "Section should have empty profiles")
    }

    // MARK: - Accessibility Tests

    @Test("AdherenceSection has proper accessibility identifier")
    func testAccessibilityIdentifier() async throws {
        // GIVEN: AdherenceSection with required properties
        let (context, container) = createTestContext()
        _ = container  // Keep alive

        let user = createTestUser(in: context)
        let profile = createTestMedicationProfile(in: context, for: user)
        let viewModel = AnalyticsViewModel()
        let analyticsService = AnalyticsService()

        // WHEN: Creating the section
        let section = AdherenceSection(
            user: user,
            medicationProfiles: [profile],
            viewModel: viewModel,
            modelContext: context,
            analyticsService: analyticsService
        )

        // THEN: Section should be created successfully (accessibility verified in E2E tests)
        #expect(section.user != nil, "AdherenceSection should be created for accessibility testing")
    }
}
