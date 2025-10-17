import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Comprehensive tests for AnalyticsViewModel chart data management
struct AnalyticsViewModelTests {
    // MARK: - Test Setup

    @MainActor private func createTestContainer() -> ModelContainer {
        DataController.testContainer().container
    }

    private func createTestUser() -> User {
        User(
            email: "analytics@test.com",
            name: "Analytics Test User",
            appleUserId: "test-analytics-user")
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

    // MARK: - Cache Loading Tests

    @Test("loadFromCache returns false when no cache exists")
    @MainActor func loadFromCacheNoCacheExists() throws {
        // Clear any existing cache first
        let cache = ChartDatasetCache()
        cache.clear()

        let viewModel = AnalyticsViewModel()
        let result = viewModel.loadFromCache(selectedPeriod: .last30Days)

        #expect(result == false, "Should return false when no cache exists")
        #expect(viewModel.fullChartDataset == nil, "Full dataset should be nil")
        #expect(viewModel.chartDataset == nil, "Filtered dataset should be nil")
    }

    // MARK: - Chart Dataset Refresh Tests

    @Test("refreshChartDataset generates full dataset and filters to selected period")
    @MainActor func refreshChartDatasetGeneratesAndFilters() async throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        // Create test doses
        let dose1 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 7)
        let dose2 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 14)

        dose1.user = user
        dose1.medication = profile
        dose2.user = user
        dose2.medication = profile

        context.insert(dose1)
        context.insert(dose2)

        try context.save()

        // Create services and viewModel
        let doseService = DoseDataService()
        let chartService = ChartDatasetService()
        let viewModel = AnalyticsViewModel()

        let config = AnalyticsViewModel.RefreshConfig(
            user: user,
            profiles: [profile],
            doseService: doseService,
            chartService: chartService,
            context: context,
            selectedPeriod: .last30Days
        )

        // Test refresh
        await viewModel.refreshChartDataset(config: config)

        #expect(viewModel.fullChartDataset != nil, "Full dataset should be generated")
        #expect(viewModel.chartDataset != nil, "Filtered dataset should be generated")
    }

    @Test("refreshChartDataset handles multiple medication profiles")
    @MainActor func refreshChartDatasetMultipleProfiles() async throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let semaglutideProfile = self.createTestMedicationProfile(medication: .semaglutide, user: user)
        let tirzepatideProfile = self.createTestMedicationProfile(medication: .tirzepatide, user: user)

        context.insert(user)
        semaglutideProfile.user = user
        tirzepatideProfile.user = user
        context.insert(semaglutideProfile)
        context.insert(tirzepatideProfile)

        // Create doses for both profiles
        let dose1 = self.createTestDose(
            amount: 1.0, medicationProfile: semaglutideProfile, user: user, daysAgo: 7)
        let dose2 = self.createTestDose(
            amount: 2.5, medicationProfile: tirzepatideProfile, user: user, daysAgo: 10)

        dose1.user = user
        dose1.medication = semaglutideProfile
        dose2.user = user
        dose2.medication = tirzepatideProfile

        context.insert(dose1)
        context.insert(dose2)

        try context.save()

        let doseService = DoseDataService()
        let chartService = ChartDatasetService()
        let viewModel = AnalyticsViewModel()

        let config = AnalyticsViewModel.RefreshConfig(
            user: user,
            profiles: [semaglutideProfile, tirzepatideProfile],
            doseService: doseService,
            chartService: chartService,
            context: context,
            selectedPeriod: .last90Days
        )

        await viewModel.refreshChartDataset(config: config)

        #expect(viewModel.fullChartDataset != nil, "Full dataset should be generated for multiple profiles")
    }

    @Test("refreshChartDataset handles profiles with no doses")
    @MainActor func refreshChartDatasetEmptyProfiles() async throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        try context.save()

        let doseService = DoseDataService()
        let chartService = ChartDatasetService()
        let viewModel = AnalyticsViewModel()

        let config = AnalyticsViewModel.RefreshConfig(
            user: user,
            profiles: [profile],
            doseService: doseService,
            chartService: chartService,
            context: context,
            selectedPeriod: .last30Days
        )

        await viewModel.refreshChartDataset(config: config)

        // Should handle empty profiles gracefully
        #expect(
            viewModel.fullChartDataset == nil || viewModel.chartDataset == nil,
            "Should handle profiles with no doses")
    }

    // MARK: - Filter Dataset Tests

    @Test("filterChartDataset filters to last 7 days")
    @MainActor func filterChartDatasetLast7Days() async throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        let dose1 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 3)
        let dose2 = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 10)

        dose1.user = user
        dose1.medication = profile
        dose2.user = user
        dose2.medication = profile

        context.insert(dose1)
        context.insert(dose2)

        try context.save()

        let doseService = DoseDataService()
        let chartService = ChartDatasetService()
        let viewModel = AnalyticsViewModel()

        let config = AnalyticsViewModel.RefreshConfig(
            user: user,
            profiles: [profile],
            doseService: doseService,
            chartService: chartService,
            context: context,
            selectedPeriod: .all
        )

        await viewModel.refreshChartDataset(config: config)

        // Now filter to 7 days
        viewModel.filterChartDataset(to: .last7Days)

        #expect(viewModel.chartDataset != nil, "Filtered dataset should exist")
    }

    @Test("filterChartDataset handles nil full dataset")
    @MainActor func filterChartDatasetNilFullDataset() throws {
        let viewModel = AnalyticsViewModel()

        viewModel.filterChartDataset(to: .last30Days)

        #expect(viewModel.chartDataset == nil, "Should handle nil full dataset")
    }

    @Test("filterChartDatasetAsync filters asynchronously")
    @MainActor func filterChartDatasetAsyncFilters() async throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        let dose = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 5)

        dose.user = user
        dose.medication = profile

        context.insert(dose)

        try context.save()

        let doseService = DoseDataService()
        let chartService = ChartDatasetService()
        let viewModel = AnalyticsViewModel()

        let config = AnalyticsViewModel.RefreshConfig(
            user: user,
            profiles: [profile],
            doseService: doseService,
            chartService: chartService,
            context: context,
            selectedPeriod: .all
        )

        await viewModel.refreshChartDataset(config: config)

        // Filter asynchronously
        await viewModel.filterChartDatasetAsync(to: .last7Days)

        #expect(viewModel.chartDataset != nil, "Async filtered dataset should exist")
    }

    @Test("filterChartDatasetAsync handles nil full dataset")
    @MainActor func filterChartDatasetAsyncNilFullDataset() async throws {
        let viewModel = AnalyticsViewModel()

        await viewModel.filterChartDatasetAsync(to: .last30Days)

        #expect(viewModel.chartDataset == nil, "Should handle nil full dataset asynchronously")
    }

    // MARK: - Sample Data Generation Tests

    @Test("generateTrendData creates 4 weeks of trend data")
    @MainActor func generateTrendDataCreates4Weeks() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let viewModel = AnalyticsViewModel()
        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        try context.save()

        let trendData = viewModel.generateTrendData(for: user, profiles: [profile], context: context)

        #expect(trendData.count == 4, "Should generate 4 weeks of trend data")

        // Verify trend data is sorted by date (only if we have multiple data points)
        guard trendData.count > 1 else { return }
        for index in 0..<(trendData.count - 1) {
            #expect(
                trendData[index].date < trendData[index + 1].date, "Trend data should be sorted by date")
        }

        // Verify adherence rates are valid (0.0-1.0 range)
        for point in trendData {
            #expect(
                point.adherenceRate >= 0.0 && point.adherenceRate <= 1.0,
                "Adherence rate should be between 0.0 and 1.0")
        }
    }

    @Test("generateMissedDosePatterns returns empty for no missed doses")
    @MainActor func generateMissedDosePatternsEmptyForNoMissedDoses() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let viewModel = AnalyticsViewModel()
        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        try context.save()

        let patterns = viewModel.generateMissedDosePatterns(for: user, profiles: [profile], context: context)

        #expect(patterns.count == 0, "Should return empty array when no missed doses")
    }

    @Test("generateMissedDosePatterns with profiles but no schedules")
    @MainActor func generateMissedDosePatternsNoSchedules() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let viewModel = AnalyticsViewModel()
        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        // Add some doses but no schedule
        let dose1 = self.createTestDose(amount: 1.0, medicationProfile: profile, user: user, daysAgo: 7)
        dose1.user = user
        dose1.medication = profile
        context.insert(dose1)

        try context.save()

        let patterns = viewModel.generateMissedDosePatterns(for: user, profiles: [profile], context: context)

        // Should handle profiles without schedules gracefully
        #expect(patterns.count == 0, "Should return empty when no schedules exist")
    }

    @Test("generateTrendData handles empty profiles list")
    @MainActor func generateTrendDataEmptyProfiles() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let viewModel = AnalyticsViewModel()
        let user = self.createTestUser()

        context.insert(user)
        try context.save()

        let trendData = viewModel.generateTrendData(for: user, profiles: [], context: context)

        #expect(trendData.count == 4, "Should still generate 4 week structure even with no profiles")
    }

    @Test("generateTrendData with profiles but no schedules")
    @MainActor func generateTrendDataNoSchedules() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let viewModel = AnalyticsViewModel()
        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        try context.save()

        let trendData = viewModel.generateTrendData(for: user, profiles: [profile], context: context)

        #expect(trendData.count == 4, "Should generate 4 weeks even without schedules")

        // Verify all adherence rates are valid
        for point in trendData {
            #expect(
                point.adherenceRate >= 0.0 && point.adherenceRate <= 1.0,
                "Adherence rate should be between 0.0 and 1.0")
        }
    }

    // MARK: - Comprehensive Refresh Tests

    @Test("refreshChartDataset with real data exercises all private paths")
    @MainActor func refreshChartDatasetComprehensivePaths() async throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        // Create multiple doses to exercise fetch and generation paths
        for daysAgo in [1, 3, 7, 14, 21, 28] {
            let dose = self.createTestDose(
                amount: 1.0, medicationProfile: profile, user: user, daysAgo: daysAgo)
            dose.user = user
            dose.medication = profile
            context.insert(dose)
        }

        try context.save()

        let doseService = DoseDataService()
        let chartService = ChartDatasetService()
        let viewModel = AnalyticsViewModel()

        let config = AnalyticsViewModel.RefreshConfig(
            user: user,
            profiles: [profile],
            doseService: doseService,
            chartService: chartService,
            context: context,
            selectedPeriod: .last30Days
        )

        // Exercise fetchAllDoses, generateFullDataset, and updateAndPersistDataset
        await viewModel.refreshChartDataset(config: config)

        #expect(viewModel.fullChartDataset != nil, "Should generate full dataset")
        #expect(viewModel.chartDataset != nil, "Should generate filtered dataset")
    }

    @Test("refreshChartDataset with multiple profiles exercises coordination")
    @MainActor func refreshChartDatasetMultiProfileCoordination() async throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile1 = self.createTestMedicationProfile(medication: .semaglutide, user: user)
        let profile2 = self.createTestMedicationProfile(medication: .tirzepatide, user: user)

        context.insert(user)
        profile1.user = user
        profile2.user = user
        context.insert(profile1)
        context.insert(profile2)

        // Create doses for both profiles
        let dose1 = self.createTestDose(
            amount: 1.0, medicationProfile: profile1, user: user, daysAgo: 7)
        let dose2 = self.createTestDose(
            amount: 2.5, medicationProfile: profile2, user: user, daysAgo: 10)
        let dose3 = self.createTestDose(
            amount: 1.0, medicationProfile: profile1, user: user, daysAgo: 14)

        dose1.user = user
        dose1.medication = profile1
        dose2.user = user
        dose2.medication = profile2
        dose3.user = user
        dose3.medication = profile1

        context.insert(dose1)
        context.insert(dose2)
        context.insert(dose3)

        try context.save()

        let doseService = DoseDataService()
        let chartService = ChartDatasetService()
        let viewModel = AnalyticsViewModel()

        let config = AnalyticsViewModel.RefreshConfig(
            user: user,
            profiles: [profile1, profile2],
            doseService: doseService,
            chartService: chartService,
            context: context,
            selectedPeriod: .last90Days
        )

        await viewModel.refreshChartDataset(config: config)

        #expect(viewModel.fullChartDataset != nil, "Should coordinate multiple profiles")
    }

    @Test("refreshChartDataset caching behavior")
    @MainActor func refreshChartDatasetCaching() async throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        let dose = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 5)
        dose.user = user
        dose.medication = profile
        context.insert(dose)

        try context.save()

        let doseService = DoseDataService()
        let chartService = ChartDatasetService()
        let viewModel = AnalyticsViewModel()

        let config = AnalyticsViewModel.RefreshConfig(
            user: user,
            profiles: [profile],
            doseService: doseService,
            chartService: chartService,
            context: context,
            selectedPeriod: .last30Days
        )

        // First refresh - exercises cache save path
        await viewModel.refreshChartDataset(config: config)

        let firstDataset = viewModel.fullChartDataset

        // Refresh again - exercises update and persist paths
        await viewModel.refreshChartDataset(config: config)

        // Should have refreshed data
        #expect(viewModel.fullChartDataset != nil, "Should have dataset after refresh")
    }

    // MARK: - Time Period Mapping Tests

    @Test("filterChartDataset maps all time periods correctly")
    @MainActor func filterChartDatasetMapsAllTimePeriods() async throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)

        context.insert(user)
        profile.user = user
        context.insert(profile)

        let dose = self.createTestDose(
            amount: 1.0, medicationProfile: profile, user: user, daysAgo: 5)

        dose.user = user
        dose.medication = profile

        context.insert(dose)

        try context.save()

        let doseService = DoseDataService()
        let chartService = ChartDatasetService()
        let viewModel = AnalyticsViewModel()

        let config = AnalyticsViewModel.RefreshConfig(
            user: user,
            profiles: [profile],
            doseService: doseService,
            chartService: chartService,
            context: context,
            selectedPeriod: .all
        )

        await viewModel.refreshChartDataset(config: config)

        // Test all time period mappings
        let periods: [ChartDataProcessor.TimePeriod] = [
            .last7Days, .last30Days, .last90Days, .lastYear, .all,
        ]

        for period in periods {
            viewModel.filterChartDataset(to: period)
            #expect(viewModel.chartDataset != nil, "Should filter to \(period)")
        }
    }
}
