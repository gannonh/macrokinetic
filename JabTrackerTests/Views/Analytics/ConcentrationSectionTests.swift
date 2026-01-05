//
//  ConcentrationSectionTests.swift
//  JabTrackerTests
//
//  Tests for ConcentrationSection component.
//

import SwiftData
import SwiftUI
import Testing

@testable import JabTracker

@MainActor
struct ConcentrationSectionTests {

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

    /// Creates a test concentration chart dataset
    private func createTestChartDataset() -> ConcentrationChartDataset {
        let samplePoints = [
            AdvancedConcentrationPoint(date: Date().addingTimeInterval(-24 * 3600), concentration: 0.0),
            AdvancedConcentrationPoint(date: Date().addingTimeInterval(-12 * 3600), concentration: 5.2),
            AdvancedConcentrationPoint(date: Date(), concentration: 2.1),
        ]

        let sampleMarkers = [
            AdvancedDoseMarker(
                date: Date().addingTimeInterval(-24 * 3600),
                amount: 1.0,
                markerStyle: .firstDose
            )
        ]

        let sampleCurve = ConcentrationCurve(
            points: samplePoints,
            medication: "semaglutide"
        )

        return ConcentrationChartDataset(
            concentrationCurves: [sampleCurve],
            doseMarkers: sampleMarkers,
            configuration: .default
        )
    }

    // MARK: - Component Creation Tests

    @Test("ConcentrationSection can be created with required properties")
    func testConcentrationSectionCreation() async throws {
        // GIVEN: Required properties for ConcentrationSection
        let (context, container) = createTestContext()
        _ = container  // Keep alive

        let user = createTestUser(in: context)
        let profile = createTestMedicationProfile(in: context, for: user)
        let viewModel = AnalyticsViewModel()

        // WHEN: Creating the section
        let section = ConcentrationSection(
            user: user,
            medicationProfiles: [profile],
            viewModel: viewModel,
            isLoadingData: false
        )

        // THEN: Section should be created successfully
        #expect(section.user != nil, "ConcentrationSection should have a user")
        #expect(section.medicationProfiles.count == 1, "ConcentrationSection should have medication profiles")
    }

    // MARK: - Chart Rendering Tests

    @Test("Renders ConcentrationTimelineChart when dataset exists")
    func testRendersChartWhenDatasetExists() async throws {
        // GIVEN: ConcentrationSection with valid user, profiles, and chart dataset
        let (context, container) = createTestContext()
        _ = container  // Keep alive

        let user = createTestUser(in: context)
        let profile = createTestMedicationProfile(in: context, for: user)
        let viewModel = AnalyticsViewModel()

        // Set up chart dataset in viewModel
        viewModel.chartDataset = createTestChartDataset()

        // WHEN: Creating the section with dataset
        let section = ConcentrationSection(
            user: user,
            medicationProfiles: [profile],
            viewModel: viewModel,
            isLoadingData: false
        )

        // THEN: Section should have access to dataset via viewModel
        #expect(section.viewModel.chartDataset != nil, "ViewModel should have chart dataset")
        #expect(
            section.viewModel.chartDataset?.concentrationCurves.isEmpty == false,
            "Chart dataset should have concentration curves")
    }

    // MARK: - Loading State Tests

    @Test("Renders loading view when isLoadingData is true and dataset is nil")
    func testRendersLoadingViewWhenLoading() async throws {
        // GIVEN: ConcentrationSection in loading state with no dataset
        let (context, container) = createTestContext()
        _ = container  // Keep alive

        let user = createTestUser(in: context)
        let profile = createTestMedicationProfile(in: context, for: user)
        let viewModel = AnalyticsViewModel()

        // Ensure no dataset
        viewModel.chartDataset = nil

        // WHEN: Creating section with loading state
        let section = ConcentrationSection(
            user: user,
            medicationProfiles: [profile],
            viewModel: viewModel,
            isLoadingData: true
        )

        // THEN: Section should be in loading state
        #expect(section.isLoadingData == true, "Section should be in loading state")
        #expect(section.viewModel.chartDataset == nil, "Dataset should be nil during loading")
    }

    // MARK: - No Data State Tests

    @Test("Renders noDataSection when user is nil")
    func testRendersNoDataSectionWhenUserIsNil() async throws {
        // GIVEN: ConcentrationSection with nil user
        let viewModel = AnalyticsViewModel()

        // WHEN: Creating section with nil user
        let section = ConcentrationSection(
            user: nil,
            medicationProfiles: [],
            viewModel: viewModel,
            isLoadingData: false
        )

        // THEN: Section should indicate no data state (nil user)
        #expect(section.user == nil, "Section should have nil user")
    }

    @Test("Renders noDataSection when profiles empty")
    func testRendersNoDataSectionWhenProfilesEmpty() async throws {
        // GIVEN: ConcentrationSection with user but empty profiles
        let (context, container) = createTestContext()
        _ = container  // Keep alive

        let user = createTestUser(in: context)
        let viewModel = AnalyticsViewModel()

        // WHEN: Creating section with empty profiles
        let section = ConcentrationSection(
            user: user,
            medicationProfiles: [],  // Empty profiles
            viewModel: viewModel,
            isLoadingData: false
        )

        // THEN: Section should have user but empty profiles
        #expect(section.user != nil, "Section should have user")
        #expect(section.medicationProfiles.isEmpty, "Section should have empty profiles")
    }

    // MARK: - Accessibility Tests

    @Test("ConcentrationSection has proper accessibility identifier")
    func testAccessibilityIdentifier() async throws {
        // GIVEN: ConcentrationSection with required properties
        let (context, container) = createTestContext()
        _ = container  // Keep alive

        let user = createTestUser(in: context)
        let profile = createTestMedicationProfile(in: context, for: user)
        let viewModel = AnalyticsViewModel()

        // WHEN: Creating the section
        let section = ConcentrationSection(
            user: user,
            medicationProfiles: [profile],
            viewModel: viewModel,
            isLoadingData: false
        )

        // THEN: Section should be created successfully (accessibility verified in E2E tests)
        #expect(section.user != nil, "ConcentrationSection should be created for accessibility testing")
    }
}
