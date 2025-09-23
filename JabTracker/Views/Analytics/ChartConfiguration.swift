//
//  ChartConfiguration.swift
//  JabTracker
//

import SwiftUI

/// Extension to ConcentrationChartConfiguration to support mutable operations for chart interactions
extension ConcentrationChartConfiguration {

  /// Creates a new configuration with updated time range
  /// - Parameter timeRange: New time range to apply
  /// - Returns: New configuration instance with updated time range
  func withTimeRange(_ timeRange: TimeRange) -> ConcentrationChartConfiguration {
    ConcentrationChartConfiguration(
      timeRange: timeRange,
      concentrationRange: self.concentrationRange,
      interpolationSettings: self.interpolationSettings,
      theme: self.theme,
      gridSettings: self.gridSettings,
      axisSettings: self.axisSettings,
      interactionSettings: self.interactionSettings,
      animationSettings: self.animationSettings
    )
  }

  /// Creates a new configuration with updated theme
  /// - Parameter theme: New chart theme to apply
  /// - Returns: New configuration instance with updated theme
  func withTheme(_ theme: ChartTheme) -> ConcentrationChartConfiguration {
    ConcentrationChartConfiguration(
      timeRange: self.timeRange,
      concentrationRange: self.concentrationRange,
      interpolationSettings: self.interpolationSettings,
      theme: theme,
      gridSettings: self.gridSettings,
      axisSettings: self.axisSettings,
      interactionSettings: self.interactionSettings,
      animationSettings: self.animationSettings
    )
  }

  /// Creates a new configuration with updated interaction settings
  /// - Parameter interactionSettings: New interaction settings to apply
  /// - Returns: New configuration instance with updated interaction settings
  func withInteractionSettings(_ interactionSettings: InteractionSettings)
    -> ConcentrationChartConfiguration
  {
    ConcentrationChartConfiguration(
      timeRange: self.timeRange,
      concentrationRange: self.concentrationRange,
      interpolationSettings: self.interpolationSettings,
      theme: self.theme,
      gridSettings: self.gridSettings,
      axisSettings: self.axisSettings,
      interactionSettings: interactionSettings,
      animationSettings: self.animationSettings
    )
  }
}

/// Chart styling utilities for consistent appearance across analytics views
enum ChartStyling {

  /// Standard color palette for concentration charts
  enum ConcentrationColors {
    static let primary = Color.blue
    static let secondary = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    static let background = Color(.systemBackground)
    static let grid = Color(.systemGray5)
  }

  /// Standard dimensions for chart elements
  enum Dimensions {
    static let chartHeight: CGFloat = 300
    static let markerSize: CGFloat = 8
    static let lineWidth: CGFloat = 2
    static let cornerRadius: CGFloat = 8
    static let padding: CGFloat = 16
  }

  /// Animation configurations for chart transitions
  enum Animations {
    static let standard = Animation.easeInOut(duration: 0.3)
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let slow = Animation.easeInOut(duration: 0.8)
  }
}

/// Factory methods for creating common chart configurations
extension ConcentrationChartConfiguration {

  /// Configuration optimized for medical professional use
  static let medical = ConcentrationChartConfiguration(
    timeRange: .lastMonth,
    concentrationRange: .automatic,
    interpolationSettings: .pharmacokinetic,
    theme: .medical,
    gridSettings: .default,
    axisSettings: .default,
    interactionSettings: .default,
    animationSettings: .smooth
  )

  /// Configuration optimized for consumer/patient use
  static let consumer = ConcentrationChartConfiguration(
    timeRange: .lastWeek,
    concentrationRange: .automatic,
    interpolationSettings: .pharmacokinetic,
    theme: .consumer,
    gridSettings: .minimal,
    axisSettings: .default,
    interactionSettings: .default,
    animationSettings: .fast
  )

  /// Configuration optimized for accessibility
  static let accessible = ConcentrationChartConfiguration(
    timeRange: .automatic,
    concentrationRange: .automatic,
    interpolationSettings: .linear,
    theme: .accessible,
    gridSettings: GridSettings(
      showHorizontalGrid: true,
      showVerticalGrid: true,
      gridLineStyle: .solid,
      gridColor: Color(.systemGray3),
      gridOpacity: 0.6
    ),
    axisSettings: .default,
    interactionSettings: .readOnly,
    animationSettings: .disabled
  )

  /// Configuration optimized for performance with large datasets
  static let performance = ConcentrationChartConfiguration(
    timeRange: .automatic,
    concentrationRange: .automatic,
    interpolationSettings: .performance,
    theme: .professional,
    gridSettings: .minimal,
    axisSettings: .default,
    interactionSettings: InteractionSettings(
      enableZoom: false,
      enablePan: false,
      enableSelection: false,
      showTooltips: false,
      highlightOnHover: false
    ),
    animationSettings: .disabled
  )
}

/// Utility functions for chart data formatting and display
enum ChartFormatting {

  /// Formats concentration values for display
  /// - Parameter concentration: Raw concentration value
  /// - Returns: Formatted string with appropriate units and precision
  static func formatConcentration(_ concentration: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 1
    return formatter.string(from: NSNumber(value: concentration)) ?? "0.0"
  }

  /// Formats time labels for chart axes
  /// - Parameters:
  ///   - date: Date to format
  ///   - timeRange: Current chart time range for context
  /// - Returns: Formatted time string appropriate for the time range
  static func formatTimeLabel(_ date: Date, for timeRange: TimeRange) -> String {
    let formatter = DateFormatter()

    switch timeRange {
    case .last24Hours:
      formatter.dateFormat = "HH:mm"
    case .lastWeek:
      formatter.dateFormat = "E"
    case .lastMonth, .lastQuarter:
      formatter.dateFormat = "MMM d"
    case .lastYear:
      formatter.dateFormat = "MMM"
    case .automatic, .custom:
      formatter.dateStyle = .short
      formatter.timeStyle = .none
    }

    return formatter.string(from: date)
  }

  /// Formats dose amounts for marker labels
  /// - Parameter amount: Dose amount value
  /// - Returns: Formatted dose string with units
  static func formatDoseAmount(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 1
    formatter.minimumFractionDigits = 0
    let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "0"
    return "\(formattedAmount) mg"
  }
}
