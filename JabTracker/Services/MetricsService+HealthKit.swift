//
//  MetricsService+HealthKit.swift
//  JabTracker
//
//  HealthKit integration for syncing body metrics data.
//  Provides bidirectional sync for weight, height, body fat, and waist circumference.
//  Also provides active energy query methods for calorie tracking.
//

import HealthKit
import OSLog
import SwiftData

// MARK: - Active Energy Data Source Protocol

/// Protocol for active energy data retrieval, enabling testability via dependency injection
protocol ActiveEnergyDataSource: Sendable {
    /// Get today's cumulative active energy burned in kilocalories
    func getTodayActiveEnergy() async -> Double?

    /// Get active energy burned for a specific date in kilocalories
    func getActiveEnergyForDate(_ date: Date) async -> Double?

    /// Get daily active energy totals for the past N days
    func getActiveEnergyHistory(days: Int) async -> [Date: Double]
}

extension MetricsService {
    /// Shared HealthKit store for metrics operations
    private static let healthStore = HKHealthStore()

    nonisolated private static let healthKitLogger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "MetricsService+HealthKit"
    )

    /// Flag to log unsupported measurement warnings only once per session
    private static var hasLoggedUnsupportedMeasurements = false

    // MARK: - HealthKit Types

    // Quantity types (read + write)
    private static let weightType = HKQuantityType(.bodyMass)
    private static let heightType = HKQuantityType(.height)
    private static let bodyFatType = HKQuantityType(.bodyFatPercentage)
    private static let waistType = HKQuantityType(.waistCircumference)

    // Quantity types (read-only)
    private static let activeEnergyType = HKQuantityType(.activeEnergyBurned)

    // Characteristic types (read-only, needed for TDEE calculation)
    private static let biologicalSexType = HKCharacteristicType(.biologicalSex)
    private static let dateOfBirthType = HKCharacteristicType(.dateOfBirth)

    // All types for authorization - includes characteristics for TDEE
    private static let allReadTypes: Set<HKObjectType> = [
        weightType, heightType, bodyFatType, waistType,
        activeEnergyType,
        biologicalSexType, dateOfBirthType,
    ]
    private static let allWriteTypes: Set<HKSampleType> = [weightType, heightType, bodyFatType, waistType]

    /// Check if HealthKit is available on this device
    static var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    #if DEBUG
        /// Test accessor: Returns the set of HealthKit types requested for read authorization
        /// Used to verify authorization configuration includes all required types
        static var testableReadTypes: Set<HKObjectType> {
            allReadTypes
        }

        /// Test accessor: Returns the active energy burned type for verification
        static var testableActiveEnergyType: HKQuantityType {
            activeEnergyType
        }
    #endif

    // MARK: - Authorization

    /// Request HealthKit authorization for all body metrics (read and write)
    /// - Returns: True if authorization was granted
    func requestFullHealthKitAuthorization() async throws -> Bool {
        guard Self.isHealthKitAvailable else {
            Self.healthKitLogger.info("HealthKit not available on this device")
            return false
        }

        do {
            try await Self.healthStore.requestAuthorization(toShare: Self.allWriteTypes, read: Self.allReadTypes)
            let status = Self.healthStore.authorizationStatus(for: Self.weightType)
            let authorized = status == .sharingAuthorized
            Self.healthKitLogger.info("HealthKit authorization \(authorized ? "granted" : "not granted")")
            return authorized
        } catch {
            Self.healthKitLogger.error("Failed to request HealthKit authorization: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Weight (Read from HealthKit)

    /// Get current weight - reads from HealthKit if sync enabled, otherwise from User profile
    /// - Parameter user: The user to check sync status and get local value from
    /// - Returns: Weight in kg
    func getCurrentWeight(for user: User) async -> Double {
        if user.healthSyncEnabled {
            if let hkWeight = await readWeightFromHealthKit() {
                return hkWeight
            }
            Self.healthKitLogger.debug(
                "HealthKit weight unavailable, falling back to user profile: \(user.weight) kg"
            )
        }
        return user.weight
    }

    // MARK: - Height (Read/Write)

    /// Get current height - reads from HealthKit if sync enabled, otherwise local
    /// - Parameter user: The user to check sync status and get local value from
    /// - Returns: Height in cm, or nil if not set
    func getCurrentHeight(for user: User) async -> Double? {
        if user.healthSyncEnabled {
            if let hkHeight = await readHeightFromHealthKit() {
                return hkHeight
            }
            if let localHeight = user.heightCm {
                Self.healthKitLogger.debug(
                    "HealthKit height unavailable, falling back to user profile: \(localHeight) cm"
                )
            }
        }
        return user.heightCm
    }

    // MARK: - Gender (Read-only from HealthKit)

    /// Get current gender - reads from HealthKit if sync enabled, otherwise local
    /// - Parameter user: The user to check sync status and get local value from
    /// - Returns: Gender string ("male" or "female"), or empty string if not set
    func getCurrentGender(for user: User) async -> String {
        if user.healthSyncEnabled {
            if let hkGender = await fetchBiologicalSex() {
                return hkGender
            }
        }
        return user.gender
    }

    // MARK: - Date of Birth (Read-only from HealthKit)

    /// Get current date of birth - reads from HealthKit if sync enabled, otherwise local
    /// - Parameter user: The user to check sync status and get local value from
    /// - Returns: Date of birth, or nil if not set
    func getCurrentDateOfBirth(for user: User) async -> Date? {
        if user.healthSyncEnabled {
            if let hkDOB = await fetchDateOfBirth() {
                return hkDOB
            }
        }
        return user.dateOfBirth
    }

    /// Save height - writes to HealthKit if sync enabled, always saves locally
    /// - Parameters:
    ///   - heightCm: Height in centimeters
    ///   - user: The user to save to
    ///   - timestamp: When the measurement was taken
    func saveHeight(_ heightCm: Double, for user: User, timestamp: Date = Date()) async throws {
        // Always save locally
        user.heightCm = heightCm
        user.updatedAt = Date()
        try context.save()

        // Write to HealthKit if sync enabled
        if user.healthSyncEnabled {
            await writeHeightToHealthKit(heightCm, timestamp: timestamp)
        }

        Self.healthKitLogger.info("Saved height: \(heightCm) cm (HealthKit: \(user.healthSyncEnabled))")
    }

    /// Write height to HealthKit only (no local save)
    /// Use this when local save is handled separately to avoid double context.save() calls
    func writeHeightToHealthKitIfEnabled(_ heightCm: Double, for user: User, timestamp: Date = Date()) async {
        guard user.healthSyncEnabled else { return }
        await writeHeightToHealthKit(heightCm, timestamp: timestamp)
    }

    // MARK: - Health Sync Toggle

    /// Enable or disable HealthKit sync for the user
    /// When enabling, requests authorization if needed
    /// - Parameters:
    ///   - enabled: Whether to enable sync
    ///   - user: The user to update
    /// - Returns: True if sync was successfully enabled/disabled
    func setHealthSyncEnabled(_ enabled: Bool, for user: User) async throws -> Bool {
        if enabled {
            let authorized = try await requestFullHealthKitAuthorization()
            if authorized {
                user.healthSyncEnabled = true
                try context.save()
                Self.healthKitLogger.info("HealthKit sync enabled")
                return true
            } else {
                Self.healthKitLogger.info("HealthKit authorization denied")
                return false
            }
        } else {
            user.healthSyncEnabled = false
            try context.save()
            Self.healthKitLogger.info("HealthKit sync disabled")
            return true
        }
    }

    // MARK: - HealthKit Read Helpers

    private func readWeightFromHealthKit() async -> Double? {
        await readLatestQuantity(type: Self.weightType, unit: .gramUnit(with: .kilo))
    }

    private func readHeightFromHealthKit() async -> Double? {
        await readLatestQuantity(type: Self.heightType, unit: .meterUnit(with: .centi))
    }

    private func readLatestQuantity(type: HKQuantityType, unit: HKUnit) async -> Double? {
        guard Self.isHealthKitAvailable else { return nil }

        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    Self.healthKitLogger.error("Failed to read \(type.identifier): \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let value = sample.quantity.doubleValue(for: unit)
                Self.healthKitLogger.debug("Read \(type.identifier) from HealthKit: \(value)")
                continuation.resume(returning: value)
            }
            Self.healthStore.execute(query)
        }
    }

    // MARK: - HealthKit Current Value Reads (Body Fat, Waist)

    /// Get current body fat percentage from HealthKit
    /// - Returns: Body fat percentage (0-100), or nil if not available
    func getCurrentBodyFatFromHealthKit() async -> Double? {
        guard Self.isHealthKitAvailable else { return nil }
        guard let ratio = await readLatestQuantity(type: Self.bodyFatType, unit: .percent()) else {
            return nil
        }
        // Convert from ratio (0-1) to percentage (0-100)
        return ratio * 100.0
    }

    /// Get current waist circumference from HealthKit
    /// - Returns: Waist circumference in cm, or nil if not available
    func getCurrentWaistFromHealthKit() async -> Double? {
        guard Self.isHealthKitAvailable else { return nil }
        return await readLatestQuantity(type: Self.waistType, unit: .meterUnit(with: .centi))
    }

    // MARK: - HealthKit Characteristic Reads

    /// Fetch biological sex from HealthKit
    /// - Returns: "male", "female", or nil if not set/authorized
    func fetchBiologicalSex() async -> String? {
        guard Self.isHealthKitAvailable else { return nil }

        do {
            let biologicalSex = try Self.healthStore.biologicalSex().biologicalSex
            switch biologicalSex {
            case .male:
                Self.healthKitLogger.debug("Fetched biological sex from HealthKit: male")
                return "male"
            case .female:
                Self.healthKitLogger.debug("Fetched biological sex from HealthKit: female")
                return "female"
            case .other, .notSet:
                Self.healthKitLogger.debug("Biological sex not set in HealthKit")
                return nil
            @unknown default:
                return nil
            }
        } catch {
            Self.healthKitLogger.debug("Could not fetch biological sex: \(error.localizedDescription)")
            return nil
        }
    }

    /// Fetch date of birth from HealthKit
    /// - Returns: Date of birth, or nil if not set/authorized
    func fetchDateOfBirth() async -> Date? {
        guard Self.isHealthKitAvailable else { return nil }

        do {
            let components = try Self.healthStore.dateOfBirthComponents()
            guard let date = Calendar.current.date(from: components) else {
                Self.healthKitLogger.debug("Could not convert DOB components to Date")
                return nil
            }
            Self.healthKitLogger.debug("Fetched date of birth from HealthKit")
            return date
        } catch {
            Self.healthKitLogger.debug("Could not fetch date of birth: \(error.localizedDescription)")
            return nil
        }
    }

    /// Populate User profile with HealthKit biometric data (height, sex, DOB)
    /// Only populates fields that are currently nil or empty.
    /// - Parameter user: The User model to populate
    func populateUserProfileFromHealthKit(user: User) async {
        Self.healthKitLogger.info("Starting HealthKit profile sync")

        // Only fetch height if not already set
        if user.heightCm == nil {
            if let height = await getCurrentHeight(for: user) {
                user.heightCm = height
                Self.healthKitLogger.info("Populated user height: \(height) cm")
            }
        }

        // Only fetch gender if empty
        if user.gender.isEmpty {
            if let gender = await fetchBiologicalSex() {
                user.gender = gender
                Self.healthKitLogger.info("Populated user gender: \(gender)")
            }
        }

        // Only fetch DOB if not already set
        if user.dateOfBirth == nil {
            if let dob = await fetchDateOfBirth() {
                user.dateOfBirth = dob
                Self.healthKitLogger.info("Populated user date of birth")
            }
        }

        Self.healthKitLogger.info("HealthKit profile sync completed")
    }

    // MARK: - HealthKit Write Helpers

    /// Sync a weight entry to HealthKit (weight and optional body fat)
    func syncWeightToHealthKit(_ entry: WeightEntry) async {
        guard Self.isHealthKitAvailable else {
            Self.healthKitLogger.info("HealthKit not available, skipping weight sync")
            return
        }

        // Write weight
        await writeWeightToHealthKit(entry.weightKg, timestamp: entry.timestamp)

        // Write body fat if present
        if let bodyFat = entry.bodyFatPercentage {
            await writeBodyFatToHealthKit(bodyFat, timestamp: entry.timestamp)
        }
    }

    private func writeWeightToHealthKit(_ weightKg: Double, timestamp: Date) async {
        Self.healthKitLogger.debug("Writing weight to HealthKit: \(weightKg) kg")
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
        await writeQuantity(quantity, type: Self.weightType, timestamp: timestamp)
    }

    private func writeHeightToHealthKit(_ heightCm: Double, timestamp: Date) async {
        let quantity = HKQuantity(unit: .meterUnit(with: .centi), doubleValue: heightCm)
        await writeQuantity(quantity, type: Self.heightType, timestamp: timestamp)
    }

    private func writeBodyFatToHealthKit(_ bodyFatPercentage: Double, timestamp: Date) async {
        // HealthKit expects body fat as a ratio (0-1), not percentage (0-100)
        let bodyFatRatio = bodyFatPercentage / 100.0
        let quantity = HKQuantity(unit: .percent(), doubleValue: bodyFatRatio)
        await writeQuantity(quantity, type: Self.bodyFatType, timestamp: timestamp)
    }

    private func writeQuantity(_ quantity: HKQuantity, type: HKQuantityType, timestamp: Date) async {
        guard Self.isHealthKitAvailable else { return }

        let sample = HKQuantitySample(type: type, quantity: quantity, start: timestamp, end: timestamp)

        do {
            try await Self.healthStore.save(sample)
            Self.healthKitLogger.info("Wrote \(type.identifier) to HealthKit")
        } catch {
            if let hkError = error as? HKError, hkError.code == .errorAuthorizationDenied {
                Self.healthKitLogger.warning("HealthKit write denied for \(type.identifier)")
            } else {
                Self.healthKitLogger.error("Failed to write \(type.identifier): \(error.localizedDescription)")
            }
        }
    }

    /// Sync a metrics entry to HealthKit
    /// - Parameter entry: The metrics entry to sync
    /// - Throws: Error if sync fails (authorization denied logs warning instead of throwing)
    func syncToHealthKit(_ entry: MetricsEntry) async throws {
        guard Self.isHealthKitAvailable else {
            Self.healthKitLogger.info("HealthKit not available on this device, skipping sync")
            return
        }

        // Sync waist circumference (only supported circumference in Apple Health)
        if let waistCm = entry.waistCm {
            try await syncWaistCircumference(waistCm, timestamp: entry.timestamp)
        }

        // Log warning for unsupported measurements (once per session to avoid log noise)
        if !Self.hasLoggedUnsupportedMeasurements {
            var unsupportedMeasurements: [String] = []
            if entry.hipCm != nil { unsupportedMeasurements.append("hip") }
            if entry.chestCm != nil { unsupportedMeasurements.append("chest") }
            if entry.neckCm != nil { unsupportedMeasurements.append("neck") }

            if !unsupportedMeasurements.isEmpty {
                let measurementList = unsupportedMeasurements.joined(separator: ", ")
                Self.healthKitLogger.warning(
                    "These measurements are not supported by HealthKit: \(measurementList)"
                )
                Self.hasLoggedUnsupportedMeasurements = true
            }
        }
    }

    /// Sync waist circumference to HealthKit
    private func syncWaistCircumference(_ waistCm: Double, timestamp: Date) async throws {
        guard let waistType = HKQuantityType.quantityType(forIdentifier: .waistCircumference) else {
            Self.healthKitLogger.error("Failed to get waistCircumference quantity type")
            return
        }

        let waistQuantity = HKQuantity(unit: .meterUnit(with: .centi), doubleValue: waistCm)
        let waistSample = HKQuantitySample(
            type: waistType,
            quantity: waistQuantity,
            start: timestamp,
            end: timestamp
        )

        do {
            try await Self.healthStore.save(waistSample)
            Self.healthKitLogger.info("Synced waist circumference \(waistCm) cm to HealthKit")
        } catch {
            // Check if authorization was denied
            if let hkError = error as? HKError, hkError.code == .errorAuthorizationDenied {
                Self.healthKitLogger.warning("HealthKit authorization denied for waist circumference, skipping sync")
                return
            }
            throw error
        }
    }

    /// Check current authorization status for weight writing
    func getAuthorizationStatus() -> HKAuthorizationStatus {
        Self.healthStore.authorizationStatus(for: Self.weightType)
    }

    /// Sync entry to HealthKit with automatic authorization handling
    /// Requests full authorization if not yet granted, then syncs the entry
    /// - Parameter entry: The metrics entry to sync
    func syncToHealthKitWithAuth(_ entry: MetricsEntry) async {
        guard Self.isHealthKitAvailable else {
            Self.healthKitLogger.info("HealthKit not available, skipping sync")
            return
        }

        // Request authorization if not yet determined
        let status = getAuthorizationStatus()
        if status == .notDetermined {
            do {
                _ = try await requestFullHealthKitAuthorization()
            } catch {
                Self.healthKitLogger.warning("HealthKit authorization request failed: \(error.localizedDescription)")
            }
        }

        // Sync entry (handles auth denial gracefully)
        do {
            try await syncToHealthKit(entry)
            Self.healthKitLogger.info("Synced metrics entry to HealthKit")
        } catch {
            Self.healthKitLogger.error("Failed to sync metrics to HealthKit: \(error.localizedDescription)")
        }
    }

    // MARK: - Active Energy Observation

    /// Stored reference to the active HKObserverQuery for energy observation
    private static var activeEnergyObserverQuery: HKObserverQuery?

    /// Handler closure stored for observation updates
    private static var activeEnergyHandler: ((Double) -> Void)?

    #if DEBUG
        /// Test accessor: Check if an active energy observer query is currently running
        static var isActiveEnergyObserverRunning: Bool {
            activeEnergyObserverQuery != nil
        }
    #endif

    /// Start observing real-time active energy updates from HealthKit
    /// When HealthKit notifies of changes, fetches fresh cumulative total and invokes handler
    /// - Parameter handler: Closure called with updated active energy value in kcal
    static func startActiveEnergyObservation(handler: @escaping (Double) -> Void) {
        guard isHealthKitAvailable else {
            healthKitLogger.info("HealthKit not available, cannot start energy observation")
            return
        }

        // Stop any existing observation first
        stopActiveEnergyObservation()

        // Store the handler for use in the query callback
        activeEnergyHandler = handler

        // Create observer query for active energy changes
        let query = HKObserverQuery(
            sampleType: activeEnergyType,
            predicate: nil
        ) { _, completionHandler, error in
            if let error {
                healthKitLogger.error("Active energy observer error: \(error.localizedDescription)")
                completionHandler()
                return
            }

            // Fetch fresh cumulative total and invoke handler
            Task {
                if let energy = await getTodayActiveEnergy() {
                    await MainActor.run {
                        activeEnergyHandler?(energy)
                    }
                }
                completionHandler()
            }
        }

        // Store the query reference
        activeEnergyObserverQuery = query

        // Execute the query
        healthStore.execute(query)

        // Enable background delivery for real-time updates
        healthStore.enableBackgroundDelivery(
            for: activeEnergyType,
            frequency: .immediate
        ) { success, error in
            if success {
                healthKitLogger.info("Background delivery enabled for active energy")
            } else if let error {
                healthKitLogger.error("Failed to enable background delivery: \(error.localizedDescription)")
            }
        }

        // Trigger immediate update to ensure UI reflects current state (real or mock)
        Task {
            if let energy = await getTodayActiveEnergy() {
                await MainActor.run {
                    activeEnergyHandler?(energy)
                }
            }
        }

        healthKitLogger.info("Started active energy observation")
    }

    /// Stop observing active energy updates from HealthKit
    /// Cleans up the observer query and clears stored references
    static func stopActiveEnergyObservation() {
        if let query = activeEnergyObserverQuery {
            healthStore.stop(query)
            healthKitLogger.info("Stopped active energy observation")
        }

        activeEnergyObserverQuery = nil
        activeEnergyHandler = nil
    }

    // MARK: - Active Energy Query Methods

    /// Get today's cumulative active energy burned in kilocalories
    /// - Returns: Active energy in kcal, or nil if unavailable
    static func getTodayActiveEnergy() async -> Double? {
        await getTodayActiveEnergy(dataSource: nil)
    }

    /// Get today's cumulative active energy burned (testable version)
    /// - Parameter dataSource: Optional mock data source for testing
    /// - Returns: Active energy in kcal, or nil if unavailable
    static func getTodayActiveEnergy(dataSource: ActiveEnergyDataSource?) async -> Double? {
        if let dataSource {
            return await dataSource.getTodayActiveEnergy()
        }
        return await getActiveEnergyForDate(Date(), dataSource: nil)
    }

    /// Get active energy burned for a specific date in kilocalories
    /// - Parameter date: The date to query
    /// - Returns: Active energy in kcal, or nil if unavailable
    static func getActiveEnergyForDate(_ date: Date) async -> Double? {
        await getActiveEnergyForDate(date, dataSource: nil)
    }

    /// Get active energy burned for a specific date (testable version)
    /// - Parameters:
    ///   - date: The date to query
    ///   - dataSource: Optional mock data source for testing
    /// - Returns: Active energy in kcal, or nil if unavailable
    static func getActiveEnergyForDate(_ date: Date, dataSource: ActiveEnergyDataSource?) async -> Double? {
        if let dataSource {
            return await dataSource.getActiveEnergyForDate(date)
        }

        // Check for launch argument mock first
        if let mockValue = mockActiveEnergy {
            healthKitLogger.debug("Using mock active energy: \(mockValue)")
            return mockValue
        }

        guard isHealthKitAvailable else {
            healthKitLogger.info("HealthKit not available for active energy query")
            return nil
        }

        return await queryActiveEnergyForDate(date)
    }

    /// Helper to specificy mock energy via launch arguments
    private static var mockActiveEnergy: Double? {
        guard let arg = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--mock-active-energy=") }) else {
            return nil
        }
        return Double(arg.replacingOccurrences(of: "--mock-active-energy=", with: ""))
    }

    /// Get daily active energy totals for the past N days
    /// - Parameter days: Number of days to retrieve (including today)
    /// - Returns: Dictionary with date keys (normalized to midnight) and kcal values
    static func getActiveEnergyHistory(days: Int) async -> [Date: Double] {
        await getActiveEnergyHistory(days: days, dataSource: nil)
    }

    /// Get daily active energy totals for the past N days (testable version)
    /// - Parameters:
    ///   - days: Number of days to retrieve (including today)
    ///   - dataSource: Optional mock data source for testing
    /// - Returns: Dictionary with date keys (normalized to midnight) and kcal values
    static func getActiveEnergyHistory(days: Int, dataSource: ActiveEnergyDataSource?) async -> [Date: Double] {
        if let dataSource {
            return await dataSource.getActiveEnergyHistory(days: days)
        }

        guard days > 0 else { return [:] }

        guard isHealthKitAvailable else {
            healthKitLogger.info("HealthKit not available for active energy history query")
            return [:]
        }

        return await queryActiveEnergyHistory(days: days)
    }

    // MARK: - Private Active Energy Query Helpers

    /// Query HealthKit for active energy on a specific date using HKStatisticsQuery
    private static func queryActiveEnergyForDate(_ date: Date) async -> Double? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    healthKitLogger.error("Active energy query failed: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let sum = statistics?.sumQuantity() else {
                    healthKitLogger.debug("No active energy data for \(startOfDay)")
                    continuation.resume(returning: nil)
                    return
                }

                let kcal = sum.doubleValue(for: .kilocalorie())
                healthKitLogger.debug("Active energy for \(startOfDay): \(kcal) kcal")
                continuation.resume(returning: kcal)
            }
            healthStore.execute(query)
        }
    }

    /// Query HealthKit for active energy history using HKStatisticsCollectionQuery
    private static func queryActiveEnergyHistory(days: Int) async -> [Date: Double] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: endDate) else {
            return [:]
        }
        guard let queryEndDate = calendar.date(byAdding: .day, value: 1, to: endDate) else {
            return [:]
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: queryEndDate,
            options: .strictStartDate
        )

        // Anchor at midnight, interval of 1 day
        var anchorComponents = calendar.dateComponents([.day, .month, .year], from: startDate)
        anchorComponents.hour = 0
        anchorComponents.minute = 0
        anchorComponents.second = 0
        guard let anchorDate = calendar.date(from: anchorComponents) else {
            return [:]
        }

        let interval = DateComponents(day: 1)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, error in
                if let error {
                    healthKitLogger.error("Active energy history query failed: \(error.localizedDescription)")
                    continuation.resume(returning: [:])
                    return
                }

                guard let results else {
                    healthKitLogger.debug("No active energy history results")
                    continuation.resume(returning: [:])
                    return
                }

                var history: [Date: Double] = [:]
                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let date = statistics.startDate
                    if let sum = statistics.sumQuantity() {
                        let kcal = sum.doubleValue(for: .kilocalorie())
                        history[date] = kcal
                    }
                }

                healthKitLogger.debug("Retrieved active energy history for \(history.count) days")
                continuation.resume(returning: history)
            }

            healthStore.execute(query)
        }
    }
}
