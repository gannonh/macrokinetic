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
public struct ConcentrationChartConfiguration {
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
public enum TimeRange: Equatable {
  case automatic
  case custom(startDate: Date, endDate: Date)
  case last24Hours
  case lastWeek
  case lastMonth
  case lastQuarter
  case lastYear

  public func dateRange(relativeTo referenceDate: Date = Date()) -> (start: Date, end: Date) {
    let calendar = Calendar.current

    switch self {
    case .automatic:
      let startDate = calendar.date(byAdding: .day, value: -7, to: referenceDate) ?? referenceDate
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
    }
  }
}

/// Concentration range configuration for chart Y-axis
public enum ConcentrationRange {
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
public struct InterpolationSettings {
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
public enum ChartTheme: Equatable {
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

public enum GridLineStyle {
  case solid
  case dashed
  case dotted
}

/// Chart axis configuration and formatting
public struct AxisSettings {
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

public enum TimeAxisFormat {
  case adaptive  // Automatically choose based on time range
  case hourly
  case daily
  case weekly
  case monthly
}

public enum ConcentrationAxisFormat {
  case decimal
  case scientific
  case percentage
  case custom(formatter: NumberFormatter)
}

/// Chart interaction behavior settings
public struct InteractionSettings {
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
public struct AnimationSettings {
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

public enum AnimationType {
  case linear
  case spring
  case easeIn
  case easeOut
  case easeInOut
}

public enum EasingFunction {
  case linear
  case easeIn
  case easeOut
  case easeInOut
  case spring
}

// MARK: - Chart Data Collection Types

/// Complete dataset for rendering concentration timeline charts
/// Combines concentration curves, dose markers, and configuration
struct ConcentrationChartDataset {
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
}

/// Individual concentration curve with styling and metadata
struct ConcentrationCurve: Identifiable {
  let id = UUID()
  let points: [AdvancedConcentrationPoint]
  let medication: String
  let curveStyle: CurveStyle
  let isVisible: Bool

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
enum CurveStyle {
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
struct ChartMetadata {
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
