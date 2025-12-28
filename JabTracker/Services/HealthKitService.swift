//
//  HealthKitService.swift
//  JabTracker
//
//  HealthKit integration for reading biometric data (height, biological sex, DOB).
//  Used to populate User profile for TDEE calculations.
//

import Foundation
import HealthKit
import OSLog
import SwiftData

/// Service for reading biometric data from HealthKit.
///
/// Provides methods to:
/// - Request read authorization for biometric data types
/// - Fetch height, biological sex, date of birth from HealthKit
/// - Populate User model with fetched biometric data
@MainActor
final class HealthKitService {
    /// Shared HealthKit store for biometric queries
    private static let healthStore = HKHealthStore()

    /// Logger for HealthKit operations - nonisolated for use in HealthKit callbacks
    private nonisolated static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "HealthKitService"
    )

    /// HealthKit object types we need read access to
    private static let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        types.insert(HKCharacteristicType(.biologicalSex))
        types.insert(HKCharacteristicType(.dateOfBirth))
        types.insert(HKQuantityType(.height))
        types.insert(HKQuantityType(.bodyMass))
        return types
    }()

    /// ModelContext for database operations
    private let context: ModelContext

    // MARK: - Initialization

    /// Initialize with a ModelContext for database access
    /// - Parameter context: SwiftData ModelContext
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Public Properties

    /// Check if HealthKit is available on this device
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    /// Request read authorization for biometric data types
    /// - Returns: True if authorization request completed successfully
    /// - Throws: Error if authorization request fails
    func requestReadAuthorization() async throws -> Bool {
        guard isAvailable else {
            Self.logger.info("HealthKit not available on this device")
            throw HealthKitServiceError.notAvailable
        }

        do {
            // Request read-only access (empty toShare set)
            try await Self.healthStore.requestAuthorization(toShare: [], read: Self.readTypes)
            Self.logger.info("HealthKit read authorization requested successfully")
            return true
        } catch {
            Self.logger.error("Failed to request HealthKit authorization: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Fetch Methods

    /// Fetch height from HealthKit
    /// - Returns: Height in centimeters, or nil if not available
    func fetchHeight() async throws -> Double? {
        guard isAvailable else { return nil }

        let heightType = HKQuantityType(.height)
        let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortByDate]
            ) { _, samples, error in
                if let error {
                    Self.logger.error("Failed to fetch height: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    Self.logger.debug("No height samples found in HealthKit")
                    continuation.resume(returning: nil)
                    return
                }

                let heightCm = sample.quantity.doubleValue(for: .meterUnit(with: .centi))
                Self.logger.info("Fetched height from HealthKit: \(heightCm) cm")
                continuation.resume(returning: heightCm)
            }
            Self.healthStore.execute(query)
        }
    }

    /// Fetch biological sex from HealthKit
    /// - Returns: "male", "female", or empty string if not set or other
    func fetchBiologicalSex() async throws -> String? {
        guard isAvailable else { return nil }

        do {
            let biologicalSex = try Self.healthStore.biologicalSex().biologicalSex
            switch biologicalSex {
            case .male:
                Self.logger.info("Fetched biological sex from HealthKit: male")
                return "male"
            case .female:
                Self.logger.info("Fetched biological sex from HealthKit: female")
                return "female"
            case .other, .notSet:
                Self.logger.debug("Biological sex not set or other in HealthKit")
                return ""
            @unknown default:
                Self.logger.debug("Unknown biological sex value in HealthKit")
                return ""
            }
        } catch {
            // Authorization denied returns an error, treat as not available
            Self.logger.debug("Could not fetch biological sex: \(error.localizedDescription)")
            return nil
        }
    }

    /// Fetch date of birth from HealthKit
    /// - Returns: Date of birth, or nil if not available
    func fetchDateOfBirth() async throws -> Date? {
        guard isAvailable else { return nil }

        do {
            let dateOfBirthComponents = try Self.healthStore.dateOfBirthComponents()
            guard let date = Calendar.current.date(from: dateOfBirthComponents) else {
                Self.logger.debug("Could not convert DOB components to Date")
                return nil
            }
            Self.logger.info("Fetched date of birth from HealthKit")
            return date
        } catch {
            // Authorization denied returns an error, treat as not available
            Self.logger.debug("Could not fetch date of birth: \(error.localizedDescription)")
            return nil
        }
    }

    /// Fetch latest weight from HealthKit
    /// - Returns: Weight in kilograms, or nil if not available
    func fetchLatestWeight() async throws -> Double? {
        guard isAvailable else { return nil }

        let weightType = HKQuantityType(.bodyMass)
        let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortByDate]
            ) { _, samples, error in
                if let error {
                    Self.logger.error("Failed to fetch weight: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    Self.logger.debug("No weight samples found in HealthKit")
                    continuation.resume(returning: nil)
                    return
                }

                let weightKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                Self.logger.info("Fetched weight from HealthKit: \(weightKg) kg")
                continuation.resume(returning: weightKg)
            }
            Self.healthStore.execute(query)
        }
    }

    // MARK: - Profile Population

    /// Fetch biometric data from HealthKit and populate the User model
    ///
    /// Only populates fields that are currently nil or empty.
    /// Weight is handled separately by WeightService.
    ///
    /// - Parameter user: The User model to populate
    func fetchAndPopulateUserProfile(user: User) async throws {
        Self.logger.info("Starting HealthKit profile sync")

        // Only fetch height if not already set
        if user.heightCm == nil {
            if let height = try await fetchHeight() {
                user.heightCm = height
                Self.logger.info("Populated user height: \(height) cm")
            }
        }

        // Only fetch gender if empty
        if user.gender.isEmpty {
            if let gender = try await fetchBiologicalSex(), !gender.isEmpty {
                user.gender = gender
                Self.logger.info("Populated user gender: \(gender)")
            }
        }

        // Only fetch DOB if not already set
        if user.dateOfBirth == nil {
            if let dob = try await fetchDateOfBirth() {
                user.dateOfBirth = dob
                Self.logger.info("Populated user date of birth")
            }
        }

        Self.logger.info("HealthKit profile sync completed")
    }
}

// MARK: - Errors

/// Errors that can occur during HealthKit operations
enum HealthKitServiceError: LocalizedError {
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        }
    }
}
