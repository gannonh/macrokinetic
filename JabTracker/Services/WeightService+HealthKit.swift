//
//  WeightService+HealthKit.swift
//  JabTracker
//
//  HealthKit integration for syncing weight and body fat data.
//

import HealthKit
import OSLog

extension WeightService {
    /// Shared HealthKit store for weight operations
    private static let healthStore = HKHealthStore()

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "WeightService+HealthKit"
    )

    /// Check if HealthKit is available on this device
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Sync a weight entry to HealthKit
    /// - Parameter entry: The weight entry to sync
    /// - Throws: Error if sync fails (authorization denied logs warning instead of throwing)
    func syncToHealthKit(_ entry: WeightEntry) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            Self.logger.info("HealthKit not available on this device, skipping sync")
            return
        }

        // Write weight sample
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            Self.logger.error("Failed to get bodyMass quantity type")
            return
        }

        let weightQuantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: entry.weightKg)
        let weightSample = HKQuantitySample(
            type: weightType,
            quantity: weightQuantity,
            start: entry.timestamp,
            end: entry.timestamp
        )

        do {
            try await Self.healthStore.save(weightSample)
            Self.logger.info("Synced weight \(entry.weightKg) kg to HealthKit")
        } catch {
            // Check if authorization was denied
            if let hkError = error as? HKError, hkError.code == .errorAuthorizationDenied {
                Self.logger.warning("HealthKit authorization denied for weight, skipping sync")
                return
            }
            throw error
        }

        // Write body fat sample if present
        if let bodyFat = entry.bodyFatPercentage {
            guard let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else {
                Self.logger.error("Failed to get bodyFatPercentage quantity type")
                return
            }

            // HealthKit expects body fat as a ratio (0-1), not percentage (0-100)
            let bodyFatQuantity = HKQuantity(unit: .percent(), doubleValue: bodyFat / 100.0)
            let bodyFatSample = HKQuantitySample(
                type: bodyFatType,
                quantity: bodyFatQuantity,
                start: entry.timestamp,
                end: entry.timestamp
            )

            do {
                try await Self.healthStore.save(bodyFatSample)
                Self.logger.info("Synced body fat \(bodyFat)% to HealthKit")
            } catch {
                // Check if authorization was denied
                if let hkError = error as? HKError, hkError.code == .errorAuthorizationDenied {
                    Self.logger.warning("HealthKit authorization denied for body fat, skipping sync")
                    return
                }
                throw error
            }
        }
    }

    /// Request HealthKit authorization for weight and body fat
    /// - Returns: True if write authorization was granted for weight
    func requestHealthKitAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            Self.logger.info("HealthKit not available on this device")
            return false
        }

        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass),
            let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)
        else {
            Self.logger.error("Failed to create HealthKit quantity types")
            return false
        }

        let typesToShare: Set<HKSampleType> = [weightType, bodyFatType]
        let typesToRead: Set<HKObjectType> = [weightType, bodyFatType]

        do {
            try await Self.healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)

            // Check actual authorization status after request
            let status = Self.healthStore.authorizationStatus(for: weightType)
            let authorized = status == .sharingAuthorized

            Self.logger.info("HealthKit authorization \(authorized ? "granted" : "not granted") for weight")
            return authorized
        } catch {
            Self.logger.error("Failed to request HealthKit authorization: \(error.localizedDescription)")
            throw error
        }
    }

    /// Check current authorization status for weight writing
    func getAuthorizationStatus() -> HKAuthorizationStatus {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return .notDetermined
        }
        return Self.healthStore.authorizationStatus(for: weightType)
    }
}
