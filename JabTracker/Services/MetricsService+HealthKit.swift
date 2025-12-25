//
//  MetricsService+HealthKit.swift
//  JabTracker
//
//  HealthKit integration for syncing body metrics data.
//

import HealthKit
import OSLog

extension MetricsService {
    /// Shared HealthKit store for metrics operations
    private static let healthStore = HKHealthStore()

    private static let healthKitLogger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "MetricsService+HealthKit"
    )

    /// Check if HealthKit is available on this device
    static var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
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

        // Log warning for unsupported measurements
        if entry.hipCm != nil {
            Self.healthKitLogger.warning("Hip circumference is not supported by HealthKit, cannot sync")
        }
        if entry.chestCm != nil {
            Self.healthKitLogger.warning("Chest circumference is not supported by HealthKit, cannot sync")
        }
        if entry.neckCm != nil {
            Self.healthKitLogger.warning("Neck circumference is not supported by HealthKit, cannot sync")
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

    /// Request HealthKit authorization for body metrics
    /// - Returns: True if write authorization was granted for waist circumference
    func requestHealthKitAuthorization() async throws -> Bool {
        guard Self.isHealthKitAvailable else {
            Self.healthKitLogger.info("HealthKit not available on this device")
            return false
        }

        guard let waistType = HKQuantityType.quantityType(forIdentifier: .waistCircumference) else {
            Self.healthKitLogger.error("Failed to create HealthKit quantity types")
            return false
        }

        let typesToShare: Set<HKSampleType> = [waistType]
        let typesToRead: Set<HKObjectType> = [waistType]

        do {
            try await Self.healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)

            // Check actual authorization status after request
            let status = Self.healthStore.authorizationStatus(for: waistType)
            let authorized = status == .sharingAuthorized

            let statusText = authorized ? "granted" : "not granted"
            Self.healthKitLogger.info("HealthKit authorization \(statusText) for waist circumference")
            return authorized
        } catch {
            Self.healthKitLogger.error("Failed to request HealthKit authorization: \(error.localizedDescription)")
            throw error
        }
    }

    /// Check current authorization status for waist circumference writing
    func getAuthorizationStatus() -> HKAuthorizationStatus {
        guard let waistType = HKQuantityType.quantityType(forIdentifier: .waistCircumference) else {
            return .notDetermined
        }
        return Self.healthStore.authorizationStatus(for: waistType)
    }
}
