//
//  ConcentrationChartStateTests.swift
//  JabTrackerTests
//

import SwiftUI
import Testing

@testable import JabTracker

/// Comprehensive tests for ConcentrationChartState
/// Tests state management, configuration handling, and export sheet operations
@Suite("ConcentrationChartState Tests")
@MainActor
struct ConcentrationChartStateTests {

    // MARK: - Initialization Tests

    @Test("ConcentrationChartState initializes with provided configuration")
    func testInitializationWithConfiguration() {
        let config = ConcentrationChartConfiguration.medical
        let state = ConcentrationChartState(configuration: config)

        #expect(state.currentConfiguration.timeRange == .lastMonth)
        #expect(state.currentConfiguration.theme == .medical)
        #expect(state.showingExportSheet == false)
    }

    @Test("ConcentrationChartState stores original configuration for reset operations")
    func testOriginalConfigurationStorage() {
        let originalConfig = ConcentrationChartConfiguration.consumer
        let state = ConcentrationChartState(configuration: originalConfig)

        // Modify current configuration
        state.updateTimePeriod(.lastYear)
        #expect(state.currentConfiguration.timeRange == .lastYear)

        // Reset should restore original
        state.resetConfiguration()
        #expect(state.currentConfiguration.timeRange == .lastWeek)  // consumer default
        #expect(state.currentConfiguration.theme == .consumer)
    }

    // MARK: - Time Period Update Tests

    @Test("updateTimePeriod changes time range while preserving other settings")
    func testUpdateTimePeriod() {
        let initialConfig = ConcentrationChartConfiguration.medical
        let state = ConcentrationChartState(configuration: initialConfig)

        // Verify initial state
        #expect(state.currentConfiguration.timeRange == .lastMonth)
        #expect(state.currentConfiguration.theme == .medical)

        // Update time period
        state.updateTimePeriod(.lastWeek)

        // Verify time range changed but other settings preserved
        #expect(state.currentConfiguration.timeRange == .lastWeek)
        #expect(state.currentConfiguration.theme == .medical)  // Should remain unchanged
        #expect(state.currentConfiguration.interpolationSettings.type == .pharmacokinetic)  // Should remain unchanged
    }

    @Test("updateTimePeriod works with all time range values")
    func testUpdateTimePeriodAllValues() {
        let state = ConcentrationChartState(configuration: .medical)

        let timeRanges: [TimeRange] = [
            .automatic,
            .last24Hours,
            .lastWeek,
            .lastMonth,
            .lastQuarter,
            .lastYear,
            .custom(startDate: Date().addingTimeInterval(-86400), endDate: Date()),
        ]

        for timeRange in timeRanges {
            state.updateTimePeriod(timeRange)
            #expect(state.currentConfiguration.timeRange == timeRange, "Time range should be updated to \(timeRange)")
        }
    }

    // MARK: - Configuration Reset Tests

    @Test("resetConfiguration restores original settings")
    func testResetConfiguration() {
        let originalConfig = ConcentrationChartConfiguration.accessible
        let state = ConcentrationChartState(configuration: originalConfig)

        // Verify initial state
        #expect(state.currentConfiguration.theme == .accessible)
        #expect(state.currentConfiguration.timeRange == .automatic)

        // Modify configuration multiple times
        state.updateTimePeriod(.lastMonth)
        state.updateConfiguration(.performance)

        // Verify changes took effect
        #expect(state.currentConfiguration.timeRange == .automatic)  // performance default
        #expect(state.currentConfiguration.theme == .professional)  // performance default

        // Reset should restore original
        state.resetConfiguration()
        #expect(state.currentConfiguration.theme == .accessible)
        #expect(state.currentConfiguration.timeRange == .automatic)
        #expect(state.currentConfiguration.interactionSettings.enableZoom == false)  // accessible uses .readOnly
    }

    // MARK: - Full Configuration Update Tests

    @Test("updateConfiguration replaces entire configuration")
    func testUpdateConfiguration() {
        let initialConfig = ConcentrationChartConfiguration.consumer
        let state = ConcentrationChartState(configuration: initialConfig)

        // Verify initial state
        #expect(state.currentConfiguration.theme == .consumer)
        #expect(state.currentConfiguration.timeRange == .lastWeek)

        // Update to completely different configuration
        let newConfig = ConcentrationChartConfiguration.medical
        state.updateConfiguration(newConfig)

        // Verify all settings changed
        #expect(state.currentConfiguration.theme == .medical)
        #expect(state.currentConfiguration.timeRange == .lastMonth)
        #expect(state.currentConfiguration.interpolationSettings.type == .pharmacokinetic)
    }

    @Test("updateConfiguration preserves original for reset")
    func testUpdateConfigurationPreservesOriginal() {
        let originalConfig = ConcentrationChartConfiguration.consumer
        let state = ConcentrationChartState(configuration: originalConfig)

        // Update configuration
        state.updateConfiguration(.performance)
        #expect(state.currentConfiguration.theme == .professional)

        // Reset should still restore original, not the updated one
        state.resetConfiguration()
        #expect(state.currentConfiguration.theme == .consumer)
        #expect(state.currentConfiguration.timeRange == .lastWeek)
    }

    // MARK: - Export Sheet State Tests

    @Test("Export sheet state initializes as false")
    func testExportSheetInitialState() {
        let state = ConcentrationChartState(configuration: .default)
        #expect(state.showingExportSheet == false)
    }

    @Test("showExportSheet sets state to true")
    func testShowExportSheet() {
        let state = ConcentrationChartState(configuration: .default)

        state.showExportSheet()
        #expect(state.showingExportSheet == true)
    }

    @Test("hideExportSheet sets state to false")
    func testHideExportSheet() {
        let state = ConcentrationChartState(configuration: .default)

        // First show the sheet
        state.showExportSheet()
        #expect(state.showingExportSheet == true)

        // Then hide it
        state.hideExportSheet()
        #expect(state.showingExportSheet == false)
    }

    @Test("Multiple export sheet toggles work correctly")
    func testMultipleExportSheetToggles() {
        let state = ConcentrationChartState(configuration: .default)

        // Test multiple show/hide cycles
        for _ in 0..<3 {
            state.showExportSheet()
            #expect(state.showingExportSheet == true)

            state.hideExportSheet()
            #expect(state.showingExportSheet == false)
        }
    }

    // MARK: - Export Result Handling Tests

    @Test("handleExportResult with success dismisses sheet")
    func testHandleExportResultSuccess() {
        let state = ConcentrationChartState(configuration: .default)

        // Show sheet first
        state.showExportSheet()
        #expect(state.showingExportSheet == true)

        // Handle success result
        let testURL = URL(fileURLWithPath: "/tmp/test.pdf")
        let result: Result<URL, NSError> = .success(testURL)
        state.handleExportResult(result)

        #expect(state.showingExportSheet == false)
    }

    @Test("handleExportResult with failure dismisses sheet")
    func testHandleExportResultFailure() {
        let state = ConcentrationChartState(configuration: .default)

        // Show sheet first
        state.showExportSheet()
        #expect(state.showingExportSheet == true)

        // Handle failure result
        let error = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test export failure"])
        let result: Result<URL, NSError> = .failure(error)
        state.handleExportResult(result)

        #expect(state.showingExportSheet == false)
    }

    @Test("handleExportResult works with different error types")
    func testHandleExportResultDifferentErrorTypes() {
        let state = ConcentrationChartState(configuration: .default)

        // Test with custom error enum
        enum TestError: Error {
            case exportFailed
            case fileNotFound
        }

        state.showExportSheet()
        let result: Result<URL, TestError> = .failure(.exportFailed)
        state.handleExportResult(result)
        #expect(state.showingExportSheet == false)

        // Test with another custom error type
        struct CustomError: Error {
            let message: String
        }

        state.showExportSheet()
        let customError = CustomError(message: "Custom export error")
        let customResult: Result<URL, CustomError> = .failure(customError)
        state.handleExportResult(customResult)
        #expect(state.showingExportSheet == false)
    }

    // MARK: - State Interaction Tests

    @Test("Configuration changes don't affect export sheet state")
    func testConfigurationChangesIndependentOfExportState() {
        let state = ConcentrationChartState(configuration: .consumer)

        // Show export sheet
        state.showExportSheet()
        #expect(state.showingExportSheet == true)

        // Make configuration changes
        state.updateTimePeriod(.lastYear)
        state.updateConfiguration(.medical)
        state.resetConfiguration()

        // Export sheet state should remain unchanged
        #expect(state.showingExportSheet == true)
    }

    @Test("Export sheet changes don't affect configuration")
    func testExportSheetChangesIndependentOfConfiguration() {
        let originalConfig = ConcentrationChartConfiguration.accessible
        let state = ConcentrationChartState(configuration: originalConfig)

        // Store initial configuration details
        let initialTimeRange = state.currentConfiguration.timeRange
        let initialTheme = state.currentConfiguration.theme

        // Toggle export sheet multiple times
        state.showExportSheet()
        state.hideExportSheet()
        state.showExportSheet()

        // Configuration should remain unchanged
        #expect(state.currentConfiguration.timeRange == initialTimeRange)
        #expect(state.currentConfiguration.theme == initialTheme)
    }

    // MARK: - Edge Case Tests

    @Test("Resetting configuration multiple times works correctly")
    func testMultipleConfigurationResets() {
        let originalConfig = ConcentrationChartConfiguration.performance
        let state = ConcentrationChartState(configuration: originalConfig)

        // Make changes and reset multiple times
        for _ in 0..<5 {
            state.updateTimePeriod(.lastWeek)
            state.updateConfiguration(.medical)
            state.resetConfiguration()

            // Should always return to original
            #expect(state.currentConfiguration.theme == .professional)  // performance theme
            #expect(state.currentConfiguration.interactionSettings.enableZoom == false)  // performance setting
        }
    }

    @Test("State remains consistent after multiple operations")
    func testStateConsistencyAfterMultipleOperations() {
        let state = ConcentrationChartState(configuration: .medical)

        // Perform various operations in mixed order
        state.showExportSheet()
        state.updateTimePeriod(.lastWeek)
        let testURL = URL(fileURLWithPath: "/tmp/test.pdf")
        state.handleExportResult(Result<URL, NSError>.success(testURL))
        state.updateConfiguration(.consumer)
        state.showExportSheet()
        state.resetConfiguration()
        state.hideExportSheet()

        // Verify final state
        #expect(state.showingExportSheet == false)
        #expect(state.currentConfiguration.theme == .medical)  // Should be reset to original
        #expect(state.currentConfiguration.timeRange == .lastMonth)  // medical default
    }
}
