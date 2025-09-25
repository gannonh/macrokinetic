//
//  ConcentrationChartState.swift
//  JabTracker
//

import SwiftUI

/// State management for concentration timeline chart
/// Handles configuration changes and UI state like export sheet presentation
@Observable
class ConcentrationChartState {

    // MARK: - Properties

    /// Current chart configuration
    var currentConfiguration: ConcentrationChartConfiguration

    /// Whether export sheet is currently presented
    var showingExportSheet = false

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

    // MARK: - Export Sheet Methods

    /// Shows the export sheet
    func showExportSheet() {
        showingExportSheet = true
    }

    /// Hides the export sheet
    func hideExportSheet() {
        showingExportSheet = false
    }

    /// Handles export result and dismisses sheet
    /// - Parameter result: Result of the export operation
    func handleExportResult<E: Error>(_ result: Result<URL, E>) {
        showingExportSheet = false
        switch result {
        case .success(let url):
            print("✅ Chart exported successfully to: \(url)")
        case .failure(let error):
            print("❌ Chart export failed: \(error)")
        }
    }
}
