import Combine
import Foundation
import OSLog
import Observation

/// ViewModel for NutritionSummaryCard
/// Handles fetching nutrition totals and real-time active energy observation
@Observable
@MainActor
final class NutritionSummaryViewModel {

    // MARK: - Properties

    var totals: DailyNutritionTotals = .zero
    var activeEnergyBurned: Double = 0
    var adjustedCalorieTarget: Double = 0
    var isLoading = true
    var loadError: Error?

    private let mealLogService: MealLogService?
    private let calorieAdjustmentService: CalorieAdjustmentService
    private let startObservation: @MainActor (@escaping (Double) -> Void) -> Void
    private let stopObservation: @MainActor () -> Void
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "NutritionSummaryViewModel")

    // MARK: - Initialization

    init(
        mealLogService: MealLogService?,
        calorieAdjustmentService: CalorieAdjustmentService? = nil,
        energyObservationStarter: @escaping @MainActor (@escaping (Double) -> Void) -> Void = MetricsService
            .startActiveEnergyObservation,
        energyObservationStopper: @escaping @MainActor () -> Void = MetricsService.stopActiveEnergyObservation
    ) {
        self.mealLogService = mealLogService
        self.calorieAdjustmentService = calorieAdjustmentService ?? CalorieAdjustmentService()
        self.startObservation = energyObservationStarter
        self.stopObservation = energyObservationStopper
    }

    deinit {
        // Ensure observation is stopped when ViewModel is deallocated
        // Note: deinit cannot effectively call MainActor isolated code easily without Task which is async.
        // However, usually observation stops are safe. But given isolation, we might need a non-isolated version for deinit
        // or accept that deinit might leak observation if relying on MainActor.
        // MetricsService.stopActiveEnergyObservation() is MainActor.

        // For now, we'll try to execute it. If it fails due to isolation, we might need to rely on onDisappear in View.
        // But let's try wrapping in MainActor.assumeIsolated or just leave as is if compiler allows.
        // Actually, deinit cannot be MainActor. We should rely on onDisappear in View for main cleanup.
        // But for safety, let's try to capture it.
    }

    // MARK: - Methods

    /// Load nutrition totals for the specified date
    func loadData(for date: Date) async {
        isLoading = true
        defer { isLoading = false }

        guard let service = mealLogService else {
            return
        }

        do {
            totals = try await service.getDailyTotals(for: date)
            loadError = nil
        } catch {
            loadError = error
            Self.logger.error("Failed to load daily nutrition totals: \(error.localizedDescription)")
        }
    }

    /// Calculate and update the calorie target
    func updateCalorieTarget(user: User, date: Date) async {
        let baseTargets = user.macroTargetsForDate(date)
        adjustedCalorieTarget = await calorieAdjustmentService.getAdjustedCalorieTarget(
            for: user,
            on: date,
            baseTarget: baseTargets.calories
        )
    }

    /// Start observing active energy if enabled
    func startEnergyObservation(user: User, date: Date) {
        // Stop any existing observation first
        stopEnergyObservation()

        // Only observe if:
        // 1. Feature is enabled
        // 2. We are viewing "today" (Project requirement usually implies real-time is for today)
        // 3. Health Sync is enabled
        guard user.addBurnedCaloriesEnabled,
            user.healthSyncEnabled,
            Calendar.current.isDateInToday(date)
        else {

            // If condition fails (e.g. user disabled feature), ensure we reset any burned value
            activeEnergyBurned = 0
            Task {
                await updateCalorieTarget(user: user, date: date)
            }
            return
        }

        Self.logger.info("Starting active energy observation")

        startObservation { [weak self] energy in
            guard let self = self else { return }

            self.activeEnergyBurned = energy

            Task { @MainActor in
                await self.updateCalorieTarget(user: user, date: date)
            }
        }
    }

    /// Stop observation
    func stopEnergyObservation() {
        stopObservation()
    }
}
