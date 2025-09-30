//
//  ConcentrationChartState.swift
//  JabTracker
//

import SwiftUI

/// State management for concentration timeline chart
/// Handles configuration changes and UI state
@Observable
class ConcentrationChartState {

    // MARK: - Properties

    /// Current chart configuration
    var currentConfiguration: ConcentrationChartConfiguration

    /// Original configuration for reset operations
    private let originalConfiguration: ConcentrationChartConfiguration

    // MARK: - Initialization

    /// Creates chart state with initial configuration
    /// - Parameter configuration: Initial chart configuration
    init(configuration: ConcentrationChartConfiguration) {
        self.currentConfiguration = configuration
        self.originalConfiguration = configuration
    }

    // MARK: - Configuration Methods

    /// Updates the time period while preserving other configuration settings
    /// - Parameter timeRange: New time range to display
    func updateTimePeriod(_ timeRange: TimeRange) {
        currentConfiguration = currentConfiguration.withTimeRange(timeRange)
    }

    /// Resets configuration to original values
    func resetConfiguration() {
        currentConfiguration = originalConfiguration
    }

    /// Updates the current configuration completely
    /// - Parameter newConfiguration: New configuration to apply
    func updateConfiguration(_ newConfiguration: ConcentrationChartConfiguration) {
        currentConfiguration = newConfiguration
    }
}
