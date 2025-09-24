//
//  ChartDataTypes.swift
//  JabTracker
//

import Foundation
import SwiftUI

// MARK: - Advanced Chart Point Types

/// Enhanced chart point with interpolation metadata for pharmacokinetic concentration curves
/// Supports Swift Charts LineMark with custom interpolation and styling capabilities
struct AdvancedConcentrationPoint: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let concentration: Double
    let isInterpolated: Bool
    let interpolationType: InterpolationType
    let confidenceInterval: ConfidenceInterval?

    /// Creates an advanced concentration point with interpolation metadata
    /// - Parameters:
    ///   - date: Timestamp for this concentration measurement
    ///   - concentration: Drug concentration value
    ///   - isInterpolated: Whether this point was generated through interpolation
    ///   - interpolationType: Type of interpolation used to generate this point
    ///   - confidenceInterval: Optional statistical confidence bounds
    init(
        date: Date,
        concentration: Double,
        isInterpolated: Bool = false,
        interpolationType: InterpolationType = .pharmacokinetic,
        confidenceInterval: ConfidenceInterval? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.concentration = concentration
        self.isInterpolated = isInterpolated
        self.interpolationType = interpolationType
        self.confidenceInterval = confidenceInterval
    }

    /// Convenience initializer from basic ConcentrationPoint
    init(from point: ConcentrationPoint, interpolated: Bool = false) {
        self.id = UUID()
        self.date = point.date
        self.concentration = point.concentration
        self.isInterpolated = interpolated
        self.interpolationType = .pharmacokinetic
        self.confidenceInterval = nil
    }
}

/// Statistical confidence interval for concentration predictions
struct ConfidenceInterval: Hashable {
    let lowerBound: Double
    let upperBound: Double
    let confidenceLevel: Double  // e.g., 0.95 for 95% confidence

    init(lowerBound: Double, upperBound: Double, confidenceLevel: Double = 0.95) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.confidenceLevel = confidenceLevel
    }
}

/// Types of interpolation algorithms available for concentration curves
public enum InterpolationType: String, CaseIterable {
    case linear
    case pharmacokinetic  // Exponential decay-based
    case spline  // Cubic spline interpolation
    case bezier  // Bezier curve interpolation

    var displayName: String {
        switch self {
        case .linear: return "Linear"
        case .pharmacokinetic: return "Pharmacokinetic"
        case .spline: return "Cubic Spline"
        case .bezier: return "Bezier Curve"
        }
    }

    var description: String {
        switch self {
        case .linear: return "Simple linear interpolation between points"
        case .pharmacokinetic: return "Exponential decay modeling based on drug half-life"
        case .spline: return "Smooth cubic spline interpolation"
        case .bezier: return "Bezier curve interpolation for smooth transitions"
        }
    }
}

// MARK: - Enhanced Dose Marker Types

/// Enhanced dose marker with additional visualization metadata for Swift Charts
/// Supports different marker styles, colors, and interaction states
struct AdvancedDoseMarker: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let amount: Double
    let isSkipped: Bool
    let markerStyle: DoseMarkerStyle
    let alertLevel: DoseAlertLevel
    let metadata: DoseMarkerMetadata

    /// Creates an advanced dose marker with enhanced visualization properties
    /// - Parameters:
    ///   - date: Timestamp when dose was administered or scheduled
    ///   - amount: Dose amount in appropriate units
    ///   - isSkipped: Whether this dose was skipped
    ///   - markerStyle: Visual style for chart marker
    ///   - alertLevel: Alert level for visual emphasis
    ///   - metadata: Additional metadata for chart interactions
    init(
        date: Date,
        amount: Double,
        isSkipped: Bool = false,
        markerStyle: DoseMarkerStyle = .standard,
        alertLevel: DoseAlertLevel = .normal,
        metadata: DoseMarkerMetadata = DoseMarkerMetadata()
    ) {
        self.id = UUID()
        self.date = date
        self.amount = amount
        self.isSkipped = isSkipped
        self.markerStyle = markerStyle
        self.alertLevel = alertLevel
        self.metadata = metadata
    }

    /// Convenience initializer from basic Dose with intelligent style detection
    init(from dose: Dose) {
        self.id = UUID()
        self.date = dose.timestamp
        self.amount = dose.amount
        self.isSkipped = dose.skipped

        // Intelligent style detection based on dose properties
        if dose.skipped {
            self.markerStyle = .skipped
            self.alertLevel = .warning
        } else if dose.site != nil {
            self.markerStyle = .withSite
            self.alertLevel = .normal
        } else {
            self.markerStyle = .standard
            self.alertLevel = .normal
        }

        self.metadata = DoseMarkerMetadata(
            site: dose.site,
            notes: dose.notes,
            hasPhoto: dose.imageData != nil
        )
    }
}

/// Additional metadata for dose markers enabling rich chart interactions
struct DoseMarkerMetadata: Hashable {
    let site: String?
    let notes: String?
    let hasPhoto: Bool
    let adherenceStatus: AdherenceStatus
    let timingAccuracy: TimingAccuracy

    init(
        site: String? = nil,
        notes: String? = nil,
        hasPhoto: Bool = false,
        adherenceStatus: AdherenceStatus = .onTime,
        timingAccuracy: TimingAccuracy = .exact
    ) {
        self.site = site
        self.notes = notes
        self.hasPhoto = hasPhoto
        self.adherenceStatus = adherenceStatus
        self.timingAccuracy = timingAccuracy
    }
}
