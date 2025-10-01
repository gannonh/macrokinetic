//
//  AnalyticsViewModel.swift
//  JabTracker
//
//  ViewModel for analytics view with helper methods for data generation
//

import Foundation

@Observable
class AnalyticsViewModel {

    /// Generate sample trend data for adherence visualization
    /// - Parameter user: User to generate trend data for
    /// - Returns: Array of adherence trend points for the last 4 weeks
    func generateTrendData(for user: User) -> [AdherenceTrendPoint] {
        let calendar = Calendar.current
        let now = Date()
        var trendData: [AdherenceTrendPoint] = []

        for weekOffset in 0..<4 {
            if let weekDate = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) {
                let adherenceRate = Double.random(in: 0.6...0.95)
                trendData.append(
                    AdherenceTrendPoint(
                        date: weekDate,
                        adherenceRate: adherenceRate,
                        period: "Week \(4 - weekOffset)"
                    ))
            }
        }

        return trendData.sorted { $0.date < $1.date }
    }

    /// Generate sample missed dose patterns for visualization
    /// - Parameter user: User to generate missed dose patterns for
    /// - Returns: Array of missed dose patterns
    func generateMissedDosePatterns(for user: User) -> [MissedDosePattern] {
        let calendar = Calendar.current
        let now = Date()

        return [
            MissedDosePattern(
                date: calendar.date(byAdding: .day, value: -6, to: now) ?? now,
                dayOfWeek: "Saturday",
                missedCount: 2
            ),
            MissedDosePattern(
                date: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                dayOfWeek: "Sunday",
                missedCount: 3
            ),
        ]
    }
}
