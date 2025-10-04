//
//  ChartData.swift
//  JabTracker
//
// swiftlint:disable file_length

import Foundation
import SwiftUI

// MARK: - Chart Configuration and Layout

/// Comprehensive chart configuration for concentration timeline visualization
/// Encapsulates all chart appearance, behavior, and interaction settings
public struct ConcentrationChartConfiguration: Codable {
    // Timeline and scale settings
    public let timeRange: TimeRange
    public let concentrationRange: ConcentrationRange
    public let interpolationSettings: InterpolationSettings

    // Visual appearance
    public let theme: ChartTheme
    public let gridSettings: GridSettings
    public let axisSettings: AxisSettings

    // Interaction and animation
    public let interactionSettings: InteractionSettings
    public let animationSettings: AnimationSettings

    /// Default configuration optimized for pharmacokinetic visualization
    public static let `default` = ConcentrationChartConfiguration(
        timeRange: TimeRange.automatic,
        concentrationRange: ConcentrationRange.automatic,
        interpolationSettings: InterpolationSettings.pharmacokinetic,
        theme: ChartTheme.medical,
        gridSettings: GridSettings.default,
        axisSettings: AxisSettings.default,
        interactionSettings: InteractionSettings.default,
        animationSettings: AnimationSettings.smooth
    )

    public init(
        timeRange: TimeRange,
        concentrationRange: ConcentrationRange,
        interpolationSettings: InterpolationSettings,
        theme: ChartTheme,
        gridSettings: GridSettings,
        axisSettings: AxisSettings,
        interactionSettings: InteractionSettings,
        animationSettings: AnimationSettings
    ) {
        self.timeRange = timeRange
        self.concentrationRange = concentrationRange
        self.interpolationSettings = interpolationSettings
        self.theme = theme
        self.gridSettings = gridSettings
        self.axisSettings = axisSettings
        self.interactionSettings = interactionSettings
        self.animationSettings = animationSettings
    }
}

/// Time range configuration for chart X-axis
public enum TimeRange: Equatable, Codable {
    case automatic
    case custom(startDate: Date, endDate: Date)
    case last24Hours
    case lastWeek
    case lastMonth
    case lastQuarter
    case lastYear
    case all  // Full time range (all available data)

    public func dateRange(relativeTo referenceDate: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current

        switch self {
        case .automatic:
            // Default to 30 days for weekly GLP-1 medications to show multiple dose cycles
            let startDate = calendar.date(byAdding: .day, value: -30, to: referenceDate) ?? referenceDate
            return (startDate, referenceDate)
        case .custom(let start, let end):
            return (start, end)
        case .last24Hours:
            let startDate = calendar.date(byAdding: .hour, value: -24, to: referenceDate) ?? referenceDate
            return (startDate, referenceDate)
        case .lastWeek:
            let startDate = calendar.date(byAdding: .day, value: -7, to: referenceDate) ?? referenceDate
            return (startDate, referenceDate)
        case .lastMonth:
            let startDate = calendar.date(byAdding: .month, value: -1, to: referenceDate) ?? referenceDate
            return (startDate, referenceDate)
        case .lastQuarter:
            let startDate = calendar.date(byAdding: .month, value: -3, to: referenceDate) ?? referenceDate
            return (startDate, referenceDate)
        case .lastYear:
            let startDate = calendar.date(byAdding: .year, value: -1, to: referenceDate) ?? referenceDate
            return (startDate, referenceDate)
        case .all:
            // Return maximum possible range for full dataset generation
            // Use 10 years ago as a reasonable maximum (no user will have more data)
            let startDate = calendar.date(byAdding: .year, value: -10, to: referenceDate) ?? referenceDate
            return (startDate, referenceDate)
        }
    }

    /// User-friendly display name for the time range
    public var displayName: String {
        switch self {
        case .automatic:
            return "Automatic"
        case .custom:
            return "Custom Range"
        case .last24Hours:
            return "Last 24 Hours"
        case .lastWeek:
            return "Last Week"
        case .lastMonth:
            return "Last Month"
        case .lastQuarter:
            return "Last Quarter"
        case .lastYear:
            return "Last Year"
        case .all:
            return "All Time"
        }
    }
}

/// Concentration range configuration for chart Y-axis
public enum ConcentrationRange: Equatable, Codable {
    case automatic
    case custom(min: Double, max: Double)
    case therapeuticWindow(min: Double, max: Double, optimal: Double)
    case fixedScale(max: Double)

    func range(for concentrations: [Double]) -> (min: Double, max: Double) {
        switch self {
        case .automatic:
            let minValue = concentrations.min() ?? 0
            let maxValue = concentrations.max() ?? 10
            let padding = (maxValue - minValue) * 0.1
            return (max(0, minValue - padding), maxValue + padding)
        case .custom(let min, let max):
            return (min, max)
        case .therapeuticWindow(let min, let max, _):
            return (min * 0.9, max * 1.1)  // Add 10% padding around therapeutic window
        case .fixedScale(let max):
            return (0, max)
        }
    }
}

/// Interpolation algorithm settings for smooth curve generation
public struct InterpolationSettings: Codable {
    let type: InterpolationType
    let intervalHours: Double
    let smoothingFactor: Double
    let confidenceIntervals: Bool

    /// Pharmacokinetic-optimized interpolation settings
    static let pharmacokinetic = InterpolationSettings(
        type: .pharmacokinetic,
        intervalHours: 2.0,
        smoothingFactor: 0.8,
        confidenceIntervals: false
    )

    /// High-resolution interpolation for detailed visualization
    static let highResolution = InterpolationSettings(
        type: .spline,
        intervalHours: 0.5,
        smoothingFactor: 0.9,
        confidenceIntervals: true
    )

    /// Simple linear interpolation settings
    static let linear = InterpolationSettings(
        type: .linear,
        intervalHours: 4.0,
        smoothingFactor: 0.5,
        confidenceIntervals: false
    )

    /// Performance-optimized settings for large datasets
    static let performance = InterpolationSettings(
        type: .linear,
        intervalHours: 6.0,
        smoothingFactor: 0.5,
        confidenceIntervals: false
    )
}

/// Chart visual theme configurations
public enum ChartTheme: Equatable, Codable {
    case medical
    case consumer
    case professional
    case accessible

    var primaryColor: Color {
        switch self {
        case .medical: return .blue
        case .consumer: return .green
        case .professional: return .gray
        case .accessible: return .primary
        }
    }

    var backgroundColor: Color {
        switch self {
        case .medical: return Color(.systemBackground)
        case .consumer: return Color(.systemGroupedBackground)
        case .professional: return .white
        case .accessible: return Color(.systemBackground)
        }
    }

    var gridColor: Color {
        switch self {
        case .medical: return Color(.systemGray5)
        case .consumer: return Color(.systemGray6)
        case .professional: return Color(.systemGray4)
        case .accessible: return Color(.systemGray3)
        }
    }
}

/// Grid line configuration for chart background
public struct GridSettings {
    let showHorizontalGrid: Bool
    let showVerticalGrid: Bool
    let gridLineStyle: GridLineStyle
    let gridColor: Color
    let gridOpacity: Double

    static let `default` = GridSettings(
        showHorizontalGrid: true,
        showVerticalGrid: true,
        gridLineStyle: .solid,
        gridColor: Color(.systemGray5),
        gridOpacity: 0.3
    )

    static let minimal = GridSettings(
        showHorizontalGrid: true,
        showVerticalGrid: false,
        gridLineStyle: .dashed,
        gridColor: Color(.systemGray6),
        gridOpacity: 0.2
    )
}

// MARK: - GridSettings Codable Conformance
extension GridSettings: Codable {
    enum CodingKeys: String, CodingKey {
        case showHorizontalGrid
        case showVerticalGrid
        case gridLineStyle
        case gridColorComponents
        case gridOpacity
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(showHorizontalGrid, forKey: .showHorizontalGrid)
        try container.encode(showVerticalGrid, forKey: .showVerticalGrid)
        try container.encode(gridLineStyle, forKey: .gridLineStyle)

        // Encode Color as RGBA components
        let components = gridColor.cgColor?.components ?? [0, 0, 0, 1]
        try container.encode(components, forKey: .gridColorComponents)

        try container.encode(gridOpacity, forKey: .gridOpacity)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        showHorizontalGrid = try container.decode(Bool.self, forKey: .showHorizontalGrid)
        showVerticalGrid = try container.decode(Bool.self, forKey: .showVerticalGrid)
        gridLineStyle = try container.decode(GridLineStyle.self, forKey: .gridLineStyle)

        // Decode Color from RGBA components
        let components = try container.decode([CGFloat].self, forKey: .gridColorComponents)
        gridColor = Color(
            red: components.count > 0 ? components[0] : 0,
            green: components.count > 1 ? components[1] : 0,
            blue: components.count > 2 ? components[2] : 0,
            opacity: components.count > 3 ? components[3] : 1
        )

        gridOpacity = try container.decode(Double.self, forKey: .gridOpacity)
    }
}

public enum GridLineStyle: Codable {
    case solid
    case dashed
    case dotted
}

/// Chart axis configuration and formatting
public struct AxisSettings: Codable {
    let timeAxisFormat: TimeAxisFormat
    let concentrationAxisFormat: ConcentrationAxisFormat
    let showAxisLabels: Bool
    let showAxisTitles: Bool
    let axisLabelRotation: Double

    static let `default` = AxisSettings(
        timeAxisFormat: .adaptive,
        concentrationAxisFormat: .decimal,
        showAxisLabels: true,
        showAxisTitles: true,
        axisLabelRotation: 0
    )
}

public enum TimeAxisFormat: Codable {
    case adaptive  // Automatically choose based on time range
    case hourly
    case daily
    case weekly
    case monthly
}

public enum ConcentrationAxisFormat: Codable {
    case decimal
    case scientific
    case percentage
    // Note: custom(formatter: NumberFormatter) removed for Codable conformance
    // Can be re-added with custom Codable implementation if needed
}

/// Chart interaction behavior settings
public struct InteractionSettings: Codable {
    let enableZoom: Bool
    let enablePan: Bool
    let enableSelection: Bool
    let showTooltips: Bool
    let highlightOnHover: Bool

    static let `default` = InteractionSettings(
        enableZoom: true,
        enablePan: true,
        enableSelection: true,
        showTooltips: true,
        highlightOnHover: true
    )

    static let readOnly = InteractionSettings(
        enableZoom: false,
        enablePan: false,
        enableSelection: false,
        showTooltips: true,
        highlightOnHover: false
    )
}

/// Animation behavior for chart transitions and updates
public struct AnimationSettings: Codable {
    let enableAnimations: Bool
    let duration: Double
    let animationType: AnimationType
    let easingFunction: EasingFunction

    static let smooth = AnimationSettings(
        enableAnimations: true,
        duration: 0.8,
        animationType: .spring,
        easingFunction: .easeInOut
    )

    static let fast = AnimationSettings(
        enableAnimations: true,
        duration: 0.3,
        animationType: .linear,
        easingFunction: .linear
    )

    static let disabled = AnimationSettings(
        enableAnimations: false,
        duration: 0,
        animationType: .linear,
        easingFunction: .linear
    )
}

public enum AnimationType: Codable {
    case linear
    case spring
    case easeIn
    case easeOut
    case easeInOut
}

public enum EasingFunction: Codable {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case spring
}

// MARK: - Chart Data Collection Types

/// Complete dataset for rendering concentration timeline charts
/// Combines concentration curves, dose markers, and configuration
struct ConcentrationChartDataset: Codable {
    let concentrationCurves: [ConcentrationCurve]
    let doseMarkers: [AdvancedDoseMarker]
    let configuration: ConcentrationChartConfiguration
    let metadata: ChartMetadata

    init(
        concentrationCurves: [ConcentrationCurve],
        doseMarkers: [AdvancedDoseMarker],
        configuration: ConcentrationChartConfiguration = .default,
        metadata: ChartMetadata = ChartMetadata()
    ) {
        self.concentrationCurves = concentrationCurves
        self.doseMarkers = doseMarkers
        self.configuration = configuration
        self.metadata = metadata
    }

    /// Filter dataset to specific time range (instant - no regeneration)
    /// Used for time period switching without recomputing concentration curves
    func filtered(to timeRange: TimeRange) -> ConcentrationChartDataset {
        let (startDate, _) = timeRange.dateRange()

        // Filter concentration curves to only include points within time range
        let filteredCurves = concentrationCurves.map { curve in
            let filteredPoints = curve.points.filter { $0.date >= startDate }
            return ConcentrationCurve(
                points: filteredPoints,
                medication: curve.medication,
                curveStyle: curve.curveStyle,
                isVisible: curve.isVisible
            )
        }

        // Filter dose markers to only include doses within time range
        let filteredMarkers = doseMarkers.filter { $0.date >= startDate }

        // Create new configuration with updated time range
        var newConfiguration = configuration
        newConfiguration = ConcentrationChartConfiguration(
            timeRange: timeRange,
            concentrationRange: configuration.concentrationRange,
            interpolationSettings: configuration.interpolationSettings,
            theme: configuration.theme,
            gridSettings: configuration.gridSettings,
            axisSettings: configuration.axisSettings,
            interactionSettings: configuration.interactionSettings,
            animationSettings: configuration.animationSettings
        )

        return ConcentrationChartDataset(
            concentrationCurves: filteredCurves,
            doseMarkers: filteredMarkers,
            configuration: newConfiguration,
            metadata: metadata
        )
    }
}

/// Individual concentration curve with styling and metadata
struct ConcentrationCurve: Identifiable, Codable {
    let id = UUID()
    let points: [AdvancedConcentrationPoint]
    let medication: String
    let curveStyle: CurveStyle
    let isVisible: Bool

    enum CodingKeys: String, CodingKey {
        case points
        case medication
        case curveStyle
        case isVisible
    }

    init(
        points: [AdvancedConcentrationPoint],
        medication: String,
        curveStyle: CurveStyle = .smooth,
        isVisible: Bool = true
    ) {
        self.points = points
        self.medication = medication
        self.curveStyle = curveStyle
        self.isVisible = isVisible
    }
}

/// Visual styling options for concentration curves
enum CurveStyle: Codable {
    case smooth
    case angular
    case dashed
    case dotted
    case gradient

    var strokeStyle: StrokeStyle {
        switch self {
        case .smooth: return StrokeStyle(lineWidth: 2)
        case .angular: return StrokeStyle(lineWidth: 2, lineCap: .square, lineJoin: .miter)
        case .dashed: return StrokeStyle(lineWidth: 2, dash: [5, 3])
        case .dotted: return StrokeStyle(lineWidth: 2, dash: [1, 3])
        case .gradient: return StrokeStyle(lineWidth: 3)
        }
    }
}

/// Metadata for chart context and documentation
struct ChartMetadata: Codable {
    let title: String
    let subtitle: String?
    let generatedAt: Date
    let dataSource: String
    let version: String

    init(
        title: String = "Concentration Timeline",
        subtitle: String? = nil,
        generatedAt: Date = Date(),
        dataSource: String = "JabTracker",
        version: String = "1.0"
    ) {
        self.title = title
        self.subtitle = subtitle
        self.generatedAt = generatedAt
        self.dataSource = dataSource
        self.version = version
    }
}
