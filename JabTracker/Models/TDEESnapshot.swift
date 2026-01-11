//
//  TDEESnapshot.swift
//  JabTracker
//
//  SwiftData model for storing TDEE calculations over time.
//  Enables historical expenditure tracking in ExpenditureDetailView.
//

import Foundation
import SwiftData

// MARK: - TDEESourceType Enum

/// Source type for TDEE calculations
enum TDEESourceType: String, Codable, CaseIterable {
    /// Initial estimate from Mifflin-St Jeor formula
    case initial

    /// Adaptive calculation from weight trend + intake data
    case adaptive

    /// Carried forward from previous value (insufficient data to recalculate)
    case holding

    /// User manual override
    case manual
}

// MARK: - TDEESnapshot Model

/// SwiftData model representing a TDEE calculation at a point in time.
///
/// TDEESnapshot captures daily TDEE values for historical tracking.
/// Used by ExpenditureDetailView to display real historical expenditure data
/// instead of synthetic values.
///
/// **CloudKit Compatibility:**
/// - All properties have non-optional defaults
/// - Follows WeightEntry pattern for time-series data
@Model
final class TDEESnapshot {

    // MARK: - Identity

    /// Unique identifier
    var id: UUID = UUID()

    // MARK: - Core Data

    /// Timestamp of the TDEE snapshot
    var timestamp: Date = Date()

    /// TDEE value in kcal
    var tdeeValue: Double = 2000.0

    /// Confidence score (0.0-1.0) for this calculation
    var confidence: Double = 0.5

    // MARK: - Source Tracking

    /// Source of the TDEE calculation stored as raw string
    /// Use `sourceType` computed property for type-safe access
    var source: String = TDEESourceType.initial.rawValue

    // MARK: - Timestamps

    /// When this snapshot was created
    var createdAt: Date = Date()

    // MARK: - Initialization

    /// Default initializer
    init() {}

    /// Initialize with custom values
    /// - Parameters:
    ///   - timestamp: When the TDEE was calculated
    ///   - tdeeValue: TDEE value in kcal
    ///   - confidence: Confidence score (0.0-1.0)
    ///   - source: Source type for the calculation
    init(
        timestamp: Date = Date(),
        tdeeValue: Double = 2000.0,
        confidence: Double = 0.5,
        source: TDEESourceType = .initial
    ) {
        self.timestamp = timestamp
        self.tdeeValue = tdeeValue
        self.confidence = confidence
        self.source = source.rawValue
        self.createdAt = Date()
    }
}

// MARK: - Computed Properties

extension TDEESnapshot {

    /// Type-safe accessor for source type
    var sourceType: TDEESourceType {
        get {
            TDEESourceType(rawValue: source) ?? .initial
        }
        set {
            source = newValue.rawValue
        }
    }

    /// Expenditure status derived from source type
    /// - `.initial` → `.fluxRange` (orange - initial estimate with uncertainty)
    /// - `.adaptive` → `.updating` (blue - actively refined with data)
    /// - `.holding` → `.holding` (gray - carried forward, insufficient data)
    /// - `.manual` → `.updating` (blue - user-specified value)
    var status: ExpenditureDetailViewModel.ExpenditureStatus {
        switch sourceType {
        case .initial:
            return .fluxRange
        case .adaptive:
            return .updating
        case .holding:
            return .holding
        case .manual:
            return .updating
        }
    }

    /// Flux margin (margin of error) based on confidence score
    /// Higher confidence = tighter margin
    /// - Returns: Margin in kcal (10-50 range)
    var fluxMargin: Int {
        // Formula: 50 - (confidence * 40)
        // confidence 1.0 → 10 kcal margin
        // confidence 0.5 → 30 kcal margin
        // confidence 0.0 → 50 kcal margin
        let margin = 50.0 - (confidence * 40.0)
        return Int(margin)
    }
}
