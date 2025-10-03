import Foundation
import Testing

@testable import JabTracker

/// Comprehensive tests for ConcentrationChartState configuration management
@Suite("ConcentrationChartState Tests")
struct ConcentrationChartStateTests {

    @Test("Initialization with default configuration")
    func initializationWithDefaultConfiguration() {
        let config = ConcentrationChartConfiguration.default
        let state = ConcentrationChartState(configuration: config)

        #expect(state.currentConfiguration.timeRange == .automatic)
    }

    @Test("Initialization with medical configuration")
    func initializationWithMedicalConfiguration() {
        let config = ConcentrationChartConfiguration.medical
        let state = ConcentrationChartState(configuration: config)

        #expect(state.currentConfiguration.timeRange == .lastMonth)
        #expect(state.currentConfiguration.theme == .medical)
    }

    @Test("updateTimePeriod changes time range")
    func updateTimePeriodChangesTimeRange() {
        let initialConfig = ConcentrationChartConfiguration.default
        let state = ConcentrationChartState(configuration: initialConfig)

        // Update time period
        state.updateTimePeriod(.lastWeek)

        // Verify time range changed
        #expect(state.currentConfiguration.timeRange == .lastWeek)
    }

    @Test("updateTimePeriod with all time ranges")
    func updateTimePeriodWithAllTimeRanges() {
        let initialConfig = ConcentrationChartConfiguration.default
        let state = ConcentrationChartState(configuration: initialConfig)

        // Test all time range values
        let timeRanges: [TimeRange] = [
            .last24Hours, .lastWeek, .lastMonth, .lastQuarter, .lastYear, .all,
        ]

        for timeRange in timeRanges {
            state.updateTimePeriod(timeRange)
            #expect(
                state.currentConfiguration.timeRange == timeRange,
                "Should update to \(timeRange)")
        }
    }

    @Test("resetConfiguration restores original")
    func resetConfigurationRestoresOriginal() {
        let originalConfig = ConcentrationChartConfiguration.medical
        let state = ConcentrationChartState(configuration: originalConfig)

        // Modify configuration
        state.updateTimePeriod(.lastYear)

        // Verify modified
        #expect(state.currentConfiguration.timeRange == .lastYear)

        // Reset
        state.resetConfiguration()

        // Verify restored to original
        #expect(state.currentConfiguration.timeRange == .lastMonth)
        #expect(state.currentConfiguration.theme == .medical)
    }

    @Test("updateConfiguration replaces entire configuration")
    func updateConfigurationReplacesEntire() {
        let initialConfig = ConcentrationChartConfiguration.medical
        let state = ConcentrationChartState(configuration: initialConfig)

        let newConfig = ConcentrationChartConfiguration.consumer

        state.updateConfiguration(newConfig)

        #expect(state.currentConfiguration.timeRange == .lastWeek)
        #expect(state.currentConfiguration.theme == .consumer)
    }

    @Test("resetConfiguration after multiple updates")
    func resetConfigurationAfterMultipleUpdates() {
        let originalConfig = ConcentrationChartConfiguration.default
        let state = ConcentrationChartState(configuration: originalConfig)

        // Make multiple changes
        state.updateTimePeriod(.lastWeek)
        state.updateTimePeriod(.lastQuarter)
        state.updateTimePeriod(.lastYear)

        // Reset should go back to original default
        state.resetConfiguration()

        #expect(state.currentConfiguration.timeRange == .automatic)
    }

    @Test("updateTimePeriod preserves other settings")
    func updateTimePeriodPreservesOtherSettings() {
        let originalConfig = ConcentrationChartConfiguration.accessible
        let state = ConcentrationChartState(configuration: originalConfig)

        let originalTheme = state.currentConfiguration.theme

        // Update time period
        state.updateTimePeriod(.lastMonth)

        // Should have new time period but original theme
        #expect(state.currentConfiguration.timeRange == .lastMonth)
        #expect(state.currentConfiguration.theme == originalTheme)
    }

    @Test("updateTimePeriod after reset")
    func updateTimePeriodAfterReset() {
        let originalConfig = ConcentrationChartConfiguration.medical
        let state = ConcentrationChartState(configuration: originalConfig)

        // Change and reset
        state.updateTimePeriod(.lastYear)
        state.resetConfiguration()

        // Update after reset
        state.updateTimePeriod(.lastWeek)

        // Should have new time period but original theme
        #expect(state.currentConfiguration.timeRange == .lastWeek)
        #expect(state.currentConfiguration.theme == .medical)
    }

    @Test("State management with performance configuration")
    func stateManagementWithPerformanceConfiguration() {
        let state = ConcentrationChartState(configuration: .performance)

        // Verify performance settings
        #expect(state.currentConfiguration.interactionSettings.enableZoom == false)

        // Update and verify
        state.updateTimePeriod(.lastMonth)
        #expect(state.currentConfiguration.timeRange == .lastMonth)

        // Reset to performance default
        state.resetConfiguration()
        #expect(state.currentConfiguration.interactionSettings.enableZoom == false)
    }

    @Test("updateConfiguration followed by reset")
    func updateConfigurationFollowedByReset() {
        let originalConfig = ConcentrationChartConfiguration.medical
        let state = ConcentrationChartState(configuration: originalConfig)

        // Replace entire configuration
        state.updateConfiguration(.consumer)
        #expect(state.currentConfiguration.theme == .consumer)

        // Reset should restore original medical config
        state.resetConfiguration()
        #expect(state.currentConfiguration.theme == .medical)
    }
}
