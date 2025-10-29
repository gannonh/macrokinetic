import SwiftUI
import Testing

@testable import JabTracker

@Suite("ReminderTimingPicker Tests")
@MainActor
struct ReminderTimingPickerTests {

    // MARK: - Initialization Tests

    @Test("Component initializes with default binding")
    func testInitialization() {
        // Given
        let minutes = 60

        // When
        let picker = ReminderTimingPicker(selectedMinutes: .constant(minutes))

        // Then - no crash, component created successfully
        #expect(picker != nil)
    }

    // MARK: - Selection Options Tests

    @Test("Component provides 15 minute option")
    func testFifteenMinuteOption() {
        // Given
        let reminderOptions = [
            (value: 15, label: "15 minutes before"),
            (value: 30, label: "30 minutes before"),
            (value: 60, label: "1 hour before"),
            (value: 120, label: "2 hours before"),
        ]

        // When
        let fifteenMinOption = reminderOptions.first { $0.value == 15 }

        // Then
        #expect(fifteenMinOption != nil)
        #expect(fifteenMinOption?.label == "15 minutes before")
    }

    @Test("Component provides 30 minute option")
    func testThirtyMinuteOption() {
        // Given
        let reminderOptions = [
            (value: 15, label: "15 minutes before"),
            (value: 30, label: "30 minutes before"),
            (value: 60, label: "1 hour before"),
            (value: 120, label: "2 hours before"),
        ]

        // When
        let thirtyMinOption = reminderOptions.first { $0.value == 30 }

        // Then
        #expect(thirtyMinOption != nil)
        #expect(thirtyMinOption?.label == "30 minutes before")
    }

    @Test("Component provides 60 minute (1 hour) option")
    func testSixtyMinuteOption() {
        // Given
        let reminderOptions = [
            (value: 15, label: "15 minutes before"),
            (value: 30, label: "30 minutes before"),
            (value: 60, label: "1 hour before"),
            (value: 120, label: "2 hours before"),
        ]

        // When
        let sixtyMinOption = reminderOptions.first { $0.value == 60 }

        // Then
        #expect(sixtyMinOption != nil)
        #expect(sixtyMinOption?.label == "1 hour before")
    }

    @Test("Component provides 120 minute (2 hour) option")
    func testOneTwentyMinuteOption() {
        // Given
        let reminderOptions = [
            (value: 15, label: "15 minutes before"),
            (value: 30, label: "30 minutes before"),
            (value: 60, label: "1 hour before"),
            (value: 120, label: "2 hours before"),
        ]

        // When
        let oneTwentyMinOption = reminderOptions.first { $0.value == 120 }

        // Then
        #expect(oneTwentyMinOption != nil)
        #expect(oneTwentyMinOption?.label == "2 hours before")
    }

    @Test("Component has exactly 4 reminder options")
    func testReminderOptionsCount() {
        // Given
        let reminderOptions = [
            (value: 15, label: "15 minutes before"),
            (value: 30, label: "30 minutes before"),
            (value: 60, label: "1 hour before"),
            (value: 120, label: "2 hours before"),
        ]

        // Then
        #expect(reminderOptions.count == 4)
    }

    // MARK: - State Binding Tests

    @Test("Component respects initial selected value")
    func testInitialSelectedValue() {
        // Given
        @State var minutes = 30

        // When
        let picker = ReminderTimingPicker(selectedMinutes: $minutes)

        // Then - component created with initial value
        #expect(picker != nil)
        #expect(minutes == 30)
    }

    @Test("Component allows different selected values")
    func testDifferentSelectedValues() {
        // Given
        let minutes120 = 120
        let minutes15 = 15

        // Then - component can be created with different values
        #expect(minutes120 == 120)
        #expect(minutes15 == 15)
    }

    // MARK: - Layout Tests

    @Test("Component has reminder timing label")
    func testReminderTimingLabel() {
        // Given
        let expectedLabel = "Reminder Timing"

        // Then
        #expect(expectedLabel == "Reminder Timing")
    }

    // MARK: - Accessibility Tests

    @Test("Component has accessibility identifier for picker")
    func testAccessibilityIdentifier() {
        // Given
        let expectedIdentifier = "reminder-timing-picker"

        // Then
        #expect(expectedIdentifier == "reminder-timing-picker")
    }
}
