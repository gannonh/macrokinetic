//
//  DoseDataService.swift
//  JabTracker
//
//  Service for efficient dose data fetching with database-level filtering
//  Replaces @Query with manual FetchDescriptor for large dataset performance
//

import Foundation
import Observation
import SwiftData

/// Service responsible for efficient dose data fetching with date range filtering
/// Uses manual FetchDescriptor to avoid eager loading of all relationships
@Observable
final class DoseDataService {

    // MARK: - Initialization

    init() {}

    // MARK: - Helper Methods

    /// Calculate cutoff date for a time period
    private func cutoffDate(for period: ChartDataProcessor.TimePeriod) -> Date? {
        guard let days = period.days else { return nil }
        return Calendar.current.date(byAdding: .day, value: -days, to: Date())
    }

    // MARK: - Predicate Factories

    /// Creates a predicate for filtering doses by user ID
    private func userPredicate(userId: UUID) -> Predicate<Dose> {
        #Predicate<Dose> { dose in
            if let doseUser = dose.user {
                doseUser.id == userId
            } else {
                false
            }
        }
    }

    /// Creates a predicate for filtering doses by user ID within a date range
    private func userDateRangePredicate(
        userId: UUID,
        startDate: Date,
        endDate: Date
    ) -> Predicate<Dose> {
        #Predicate<Dose> { dose in
            if let doseUser = dose.user {
                doseUser.id == userId && dose.timestamp >= startDate && dose.timestamp <= endDate
            } else {
                false
            }
        }
    }

    /// Creates a predicate for filtering doses by medication profile ID
    private func profilePredicate(profileId: UUID) -> Predicate<Dose> {
        #Predicate<Dose> { dose in
            if let doseMedication = dose.medication {
                doseMedication.id == profileId
            } else {
                false
            }
        }
    }

    /// Creates a predicate for filtering doses by profile ID within a date range
    private func profileDateRangePredicate(
        profileId: UUID,
        startDate: Date,
        endDate: Date
    ) -> Predicate<Dose> {
        #Predicate<Dose> { dose in
            if let doseMedication = dose.medication {
                doseMedication.id == profileId && dose.timestamp >= startDate && dose.timestamp <= endDate
            } else {
                false
            }
        }
    }

    // MARK: - Dose Fetching Methods

    /// Fetch doses for a user within a specific time period
    /// Uses database-level filtering for optimal performance
    /// - Parameters:
    ///   - user: The user whose doses to fetch
    ///   - timePeriod: Time period filter
    ///   - context: SwiftData ModelContext
    /// - Returns: Array of doses within the time period, sorted by timestamp descending
    @MainActor
    func fetchDoses(
        for user: User,
        within timePeriod: ChartDataProcessor.TimePeriod,
        context: ModelContext
    ) -> [Dose] {
        guard let cutoff = cutoffDate(for: timePeriod) else {
            // All time - fetch everything (still filtered by user)
            return fetchAllDoses(for: user, context: context)
        }

        // Fetch with date range filter
        return fetchDoses(for: user, from: cutoff, to: Date(), context: context)
    }

    /// Fetch doses for a user within a specific date range
    /// Uses database-level filtering for optimal performance
    /// - Parameters:
    ///   - user: The user whose doses to fetch
    ///   - startDate: Start date (inclusive)
    ///   - endDate: End date (inclusive)
    ///   - context: SwiftData ModelContext
    /// - Returns: Array of doses within the date range, sorted by timestamp descending
    func fetchDoses(
        for user: User,
        from startDate: Date,
        to endDate: Date,
        context: ModelContext
    ) -> [Dose] {
        let predicate = userDateRangePredicate(
            userId: user.id,
            startDate: startDate,
            endDate: endDate
        )

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch all doses for a user (no date filtering)
    /// - Parameters:
    ///   - user: The user whose doses to fetch
    ///   - context: SwiftData ModelContext
    /// - Returns: Array of all doses, sorted by timestamp descending
    private func fetchAllDoses(
        for user: User,
        context: ModelContext
    ) -> [Dose] {
        let predicate = userPredicate(userId: user.id)

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch recent doses for a user (last N doses)
    /// Useful for dashboard displays
    /// - Parameters:
    ///   - user: The user whose doses to fetch
    ///   - limit: Maximum number of doses to return
    ///   - context: SwiftData ModelContext
    /// - Returns: Array of most recent doses, sorted by timestamp descending
    func fetchRecentDoses(
        for user: User,
        limit: Int,
        context: ModelContext
    ) -> [Dose] {
        let predicate = userPredicate(userId: user.id)

        var descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch doses for a medication profile within a time period
    /// - Parameters:
    ///   - profile: The medication profile
    ///   - timePeriod: Time period filter
    ///   - context: SwiftData ModelContext
    /// - Returns: Array of doses for the profile within the time period
    @MainActor
    func fetchDoses(
        for profile: MedicationProfile,
        within timePeriod: ChartDataProcessor.TimePeriod,
        context: ModelContext
    ) -> [Dose] {
        guard let cutoff = cutoffDate(for: timePeriod) else {
            // All time
            return fetchAllDoses(for: profile, context: context)
        }

        let predicate = profileDateRangePredicate(
            profileId: profile.id,
            startDate: cutoff,
            endDate: Date()
        )

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch all doses for a medication profile
    /// - Parameters:
    ///   - profile: The medication profile
    ///   - context: SwiftData ModelContext
    /// - Returns: Array of all doses for the profile
    private func fetchAllDoses(
        for profile: MedicationProfile,
        context: ModelContext
    ) -> [Dose] {
        let predicate = profilePredicate(profileId: profile.id)

        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }
}
