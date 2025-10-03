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
        let viewModel = AnalyticsViewModel()
        let user = self.createTestUser()

        let trendData = viewModel.generateTrendData(for: user)

        #expect(trendData.count == 4, "Should generate 4 weeks of trend data")

        // Verify trend data is sorted by date
        for index in 0..<(trendData.count - 1) {
            #expect(
                trendData[index].date < trendData[index + 1].date, "Trend data should be sorted by date")
        }

        // Verify adherence rates are within expected range
        for point in trendData {
            #expect(
                point.adherenceRate >= 0.6 && point.adherenceRate <= 0.95,
                "Adherence rate should be between 0.6 and 0.95")
        }
    }

    @Test("generateMissedDosePatterns creates weekend patterns")
    @MainActor func generateMissedDosePatternsCreatesWeekendPatterns() throws {
        let viewModel = AnalyticsViewModel()
        let user = self.createTestUser()

        let patterns = viewModel.generateMissedDosePatterns(for: user)

        #expect(patterns.count == 2, "Should generate 2 missed dose patterns")

        let daysOfWeek = patterns.map { $0.dayOfWeek }
        #expect(daysOfWeek.contains("Saturday"), "Should include Saturday pattern")
        #expect(daysOfWeek.contains("Sunday"), "Should include Sunday pattern")

        // Verify missed counts are reasonable
        for pattern in patterns {
            #expect(pattern.missedCount > 0, "Missed count should be positive")
        }
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
