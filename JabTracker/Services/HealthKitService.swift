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

/// Service for reading biometric data from HealthKit.
///
/// Provides methods to:
/// - Request read authorization for biometric data types
/// - Fetch height, biological sex, date of birth from HealthKit
/// - Populate User model with fetched biometric data
@MainActor
@Observable
final class HealthKitService {
    /// Shared HealthKit store for biometric queries
    private nonisolated static let healthStore = HKHealthStore()

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

    // MARK: - Initialization

    /// Initialize the HealthKit service
    init() {}

    // MARK: - Public Properties

    /// Check if HealthKit is available on this device
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    /// Check if we have authorization to read a specific data type
    /// - Parameter type: The HealthKit object type to check
    /// - Returns: True if authorized to read, false otherwise
    func isAuthorized(for type: HKObjectType) -> Bool {
        let status = Self.healthStore.authorizationStatus(for: type)
        return status == .sharingAuthorized
    }

    /// Check if we have authorization for any of our read types
    /// - Returns: True if at least one type is authorized
    func hasAnyAuthorization() -> Bool {
        Self.readTypes.contains { isAuthorized(for: $0) }
    }

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
        try await fetchLatestQuantitySample(
            type: HKQuantityType(.height),
            unit: .meterUnit(with: .centi),
            logName: "height"
        )
    }

    /// Fetch biological sex from HealthKit
    /// - Returns: "male", "female", or empty string if not set or other
    func fetchBiologicalSex() async throws -> String? {
        guard isAvailable else { return nil }

        do {
            let biologicalSex = try Self.healthStore.biologicalSex().biologicalSex
            let result: String
            switch biologicalSex {
            case .male:
                result = "male"
            case .female:
                result = "female"
            case .other, .notSet:
                result = ""
            @unknown default:
                result = ""
            }
            Self.logger.debug("Fetched biological sex from HealthKit: \(result.isEmpty ? "not set" : result)")
            return result
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
            Self.logger.debug("Fetched date of birth from HealthKit")
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
        try await fetchLatestQuantitySample(
            type: HKQuantityType(.bodyMass),
            unit: .gramUnit(with: .kilo),
            logName: "weight"
        )
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

    // MARK: - Private Helpers

    /// Generic helper to fetch the latest quantity sample from HealthKit
    /// - Parameters:
    ///   - type: The quantity type to fetch
    ///   - unit: The unit to convert the result to
    ///   - logName: Name for logging purposes
    /// - Returns: The value in the specified unit, or nil if not available
    private func fetchLatestQuantitySample(
        type: HKQuantityType,
        unit: HKUnit,
        logName: String
    ) async throws -> Double? {
        guard isAvailable else { return nil }

        let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortByDate]
            ) { _, samples, error in
                if let error {
                    Self.logger.error("Failed to fetch \(logName): \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    Self.logger.debug("No \(logName) samples found in HealthKit")
                    continuation.resume(returning: nil)
                    return
                }

                let value = sample.quantity.doubleValue(for: unit)
                Self.logger.debug("Fetched \(logName) from HealthKit: \(value)")
                continuation.resume(returning: value)
            }
            Self.healthStore.execute(query)
        }
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
