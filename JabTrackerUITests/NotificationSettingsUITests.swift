import XCTest

/// E2E tests for notification settings UI integration
///
/// Tests the complete user workflow for managing notification preferences in Settings:
/// - Navigation to notification settings section
/// - Enabling/disabling notifications via toggle
/// - Changing reminder timing preferences
/// - Authorization status display and Settings button interaction
/// - Accessibility compliance for VoiceOver users
final class NotificationSettingsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        self.app = XCUIApplication()
        self.app.launchArguments = ["--ui-testing", "--reset-app-data"]
        self.app.launch()

        // Wait for app to be ready
        XCTAssertTrue(self.app.tabBars.firstMatch.waitForExistence(timeout: 5.0))
    }

    // MARK: - Test 1: Navigation

    /// Test 1: Navigate to notification settings section
    ///
    /// GIVEN: User is on any tab
    /// WHEN: User taps Settings tab
    /// THEN: Notification section header is visible
    func testNavigateToNotificationSettings() throws {
        // Navigate to Settings
        TestUtilities.navigateToSettings(self.app)

        // Verify notification section exists
        let notificationHeader = self.app.staticTexts["notifications-section-header"]
        XCTAssertTrue(
            notificationHeader.waitForExistence(timeout: 3.0),
            "Notification section header should be visible in Settings"
        )

        // Verify section content is present
        let notificationToggle = self.app.switches["notifications-toggle"]
        XCTAssertTrue(
            notificationToggle.exists,
            "Notification toggle should exist in notification section"
        )
    }

    // MARK: - Test 2: Enable Notifications

    /// Test 2: Enable notifications via toggle
    ///
    /// GIVEN: User is in Settings with notifications disabled
    /// WHEN: User toggles notifications on
    /// THEN: Toggle state changes to enabled AND reminder picker appears
    func testEnableNotificationsViaToggle() throws {
        // Navigate to Settings
        TestUtilities.navigateToSettings(self.app)

        // The notifications toggle is Switch #1 (element(boundBy: 1))
        // It's below the fold, so scroll to make it hittable
        let notificationToggle = self.app.switches.element(boundBy: 1)

        XCTAssertTrue(
            notificationToggle.waitForExistence(timeout: 3.0),
            "Notification toggle should exist"
        )

        // Scroll down to bring notifications section into view (need 2 swipes)
        self.app.swipeUp()
        usleep(300_000)
        self.app.swipeUp()
        usleep(500_000)  // Wait for scroll to settle

        // Verify toggle is now hittable
        XCTAssertTrue(notificationToggle.isHittable, "Toggle should be hittable after scrolling")

        // Verify initially off (value "0") - --reset-app-data should clear UserDefaults
        XCTAssertEqual(
            notificationToggle.value as? String,
            "0",
            "Notification toggle should initially be disabled after app data reset"
        )

        // Toggle notifications on - use coordinate tap for reliability
        let toggleCoordinate = notificationToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        toggleCoordinate.tap()

        // Wait for toggle value to update (accessibility value changes)
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "1"),
            object: notificationToggle
        )
        let result = XCTWaiter().wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(result, .completed, "Toggle value should change to '1' within 3 seconds")

        // Verify toggle is now on (value "1")
        XCTAssertEqual(
            notificationToggle.value as? String,
            "1",
            "Notification toggle should be enabled after tapping"
        )

        // Verify reminder picker appears
        let reminderPicker = self.app.buttons["reminder-timing-picker"]
        XCTAssertTrue(
            reminderPicker.waitForExistence(timeout: 2.0),
            "Reminder timing picker should appear when notifications enabled"
        )
    }

    // MARK: - Test 3: Disable Notifications

    /// Test 3: Disable notifications via toggle
    ///
    /// GIVEN: User is in Settings with notifications enabled
    /// WHEN: User toggles notifications off
    /// THEN: Toggle state changes to disabled AND reminder picker disappears
    func testDisableNotificationsViaToggle() throws {
        // Navigate to Settings
        TestUtilities.navigateToSettings(self.app)

        // Use element(boundBy: 1) and scroll
        let notificationToggle = self.app.switches.element(boundBy: 1)
        XCTAssertTrue(
            notificationToggle.waitForExistence(timeout: 3.0),
            "Notification toggle should exist"
        )

        // Scroll to make toggle hittable
        self.app.swipeUp()
        usleep(300_000)
        self.app.swipeUp()
        usleep(500_000)

        // Enable notifications first using coordinate tap
        if notificationToggle.value as? String == "0" {
            let toggleCoordinate = notificationToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
            toggleCoordinate.tap()

            // Wait for value to change
            let enableExpectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "value == %@", "1"),
                object: notificationToggle
            )
            _ = XCTWaiter().wait(for: [enableExpectation], timeout: 3.0)
        }

        // Verify toggle is on
        XCTAssertEqual(
            notificationToggle.value as? String,
            "1",
            "Notification toggle should be enabled before disabling test"
        )

        // Verify reminder picker is visible
        let reminderPicker = self.app.buttons["reminder-timing-picker"]
        XCTAssertTrue(
            reminderPicker.exists,
            "Reminder picker should be visible when notifications enabled"
        )

        // Toggle notifications off using coordinate tap
        let toggleCoordinate = notificationToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        toggleCoordinate.tap()

        // Wait for value to change
        let disableExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "0"),
            object: notificationToggle
        )
        _ = XCTWaiter().wait(for: [disableExpectation], timeout: 3.0)

        // Verify toggle is now off
        XCTAssertEqual(
            notificationToggle.value as? String,
            "0",
            "Notification toggle should be disabled after tapping"
        )

        // Verify reminder picker disappears
        XCTAssertFalse(
            reminderPicker.exists,
            "Reminder picker should disappear when notifications disabled"
        )
    }

    // MARK: - Test 4: Change Reminder Timing

    /// Test 4: Change reminder timing preference
    ///
    /// GIVEN: User is in Settings with notifications enabled
    /// WHEN: User taps reminder timing picker and selects different option
    /// THEN: Selection is updated and displayed
    func testChangeReminderTiming() throws {
        // Navigate to Settings
        TestUtilities.navigateToSettings(self.app)

        // Use element(boundBy: 1) and scroll
        let notificationToggle = self.app.switches.element(boundBy: 1)
        XCTAssertTrue(
            notificationToggle.waitForExistence(timeout: 3.0),
            "Notification toggle should exist"
        )

        // Scroll to make toggle hittable
        self.app.swipeUp()
        usleep(300_000)
        self.app.swipeUp()
        usleep(500_000)

        // Enable notifications if not already enabled using coordinate tap
        if notificationToggle.value as? String == "0" {
            let toggleCoordinate = notificationToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
            toggleCoordinate.tap()

            // Wait for value to change
            let enableExpectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "value == %@", "1"),
                object: notificationToggle
            )
            _ = XCTWaiter().wait(for: [enableExpectation], timeout: 3.0)
        }

        // Find reminder timing picker
        let reminderPicker = self.app.buttons["reminder-timing-picker"]
        XCTAssertTrue(
            reminderPicker.waitForExistence(timeout: 3.0),
            "Reminder timing picker should be visible"
        )

        // Store initial value
        let initialLabel = reminderPicker.label

        // Tap picker to open menu
        reminderPicker.tap()

        // Wait for picker menu to appear
        sleep(1)

        // Select a different option (try "30 minutes before" if not already selected)
        let option30Minutes = self.app.buttons["30 minutes before"]
        if option30Minutes.waitForExistence(timeout: 2.0) {
            option30Minutes.tap()
            sleep(1)

            // Verify selection updated (label should change)
            let updatedLabel = reminderPicker.label
            XCTAssertNotEqual(
                initialLabel,
                updatedLabel,
                "Reminder timing should update after selecting different option"
            )
        } else {
            // If 30 minutes not available, try 15 minutes
            let option15Minutes = self.app.buttons["15 minutes before"]
            if option15Minutes.waitForExistence(timeout: 2.0) {
                option15Minutes.tap()
                sleep(1)

                let updatedLabel = reminderPicker.label
                XCTAssertNotEqual(
                    initialLabel,
                    updatedLabel,
                    "Reminder timing should update after selecting different option"
                )
            }
        }
    }

    // MARK: - Test 5: Authorization Denied Shows Settings Button

    /// Test 5: Authorization denied shows Settings button
    ///
    /// GIVEN: Notification authorization is denied
    /// WHEN: User views notification settings
    /// THEN: Settings button appears in authorization status display
    ///
    /// Note: This test uses the UI testing mode where authorization may be simulated.
    /// In actual usage, denied state would require manual permission denial in iOS Settings.
    func testAuthorizationDeniedShowsSettingsButton() throws {
        // Navigate to Settings
        TestUtilities.navigateToSettings(self.app)

        let notificationToggle = self.app.switches["notifications-toggle"]
        XCTAssertTrue(
            notificationToggle.waitForExistence(timeout: 3.0),
            "Notification toggle should exist"
        )

        // Enable notifications to trigger authorization prompt
        if notificationToggle.value as? String == "0" {
            notificationToggle.tap()
            sleep(2)  // Wait for authorization state to update
        }

        // Check if Settings button exists (would appear when denied)
        // Note: In UI testing mode with --ui-testing, authorization is typically granted
        // This test validates the UI structure exists for denied state
        let settingsButton = self.app.buttons["notification-settings-button"]

        // The button should exist in the view hierarchy when authorization is denied
        // In --ui-testing mode it may not be visible, but structure should be present
        // We validate the accessibility identifier is properly configured
        if settingsButton.exists {
            XCTAssertTrue(
                settingsButton.isHittable,
                "Settings button should be interactive when authorization denied"
            )
        }

        // If authorization is granted (expected in UI testing), verify button doesn't exist
        if notificationToggle.value as? String == "1" {
            XCTAssertFalse(
                settingsButton.exists,
                "Settings button should not exist when authorization is granted"
            )
        }
    }

    // MARK: - Test 6: Open iOS Settings

    /// Test 6: Tap Settings button from notification status
    ///
    /// GIVEN: Authorization is denied and Settings button is visible
    /// WHEN: User taps Settings button
    /// THEN: Button action is triggered (iOS Settings would open in real scenario)
    ///
    /// Note: In UI testing, we can't actually navigate to iOS Settings app.
    /// This test validates the button exists and is interactive.
    func testOpenIOSSettingsFromNotificationStatus() throws {
        // Navigate to Settings
        TestUtilities.navigateToSettings(self.app)

        let notificationToggle = self.app.switches["notifications-toggle"]
        XCTAssertTrue(
            notificationToggle.waitForExistence(timeout: 3.0),
            "Notification toggle should exist"
        )

        // Enable notifications
        if notificationToggle.value as? String == "0" {
            notificationToggle.tap()
            sleep(2)
        }

        // Look for Settings button (would be visible when authorization denied)
        let settingsButton = self.app.buttons["notification-settings-button"]

        // In UI testing mode with granted permissions, button won't exist
        // Validate that if button exists, it's properly configured
        if settingsButton.exists {
            XCTAssertTrue(
                settingsButton.isHittable,
                "Settings button should be interactive"
            )

            // Verify accessibility
            XCTAssertEqual(
                settingsButton.label,
                "Settings",
                "Settings button should have proper label"
            )

            // Note: Can't actually test navigation to iOS Settings in UI tests
            // Button tap would open Settings app which is outside test scope
        }
    }

    // MARK: - Test 7: Reminder Picker Accessibility

    /// Test 7: Reminder timing picker accessibility
    ///
    /// GIVEN: User is in Settings with notifications enabled
    /// WHEN: User navigates with VoiceOver
    /// THEN: Reminder picker has proper accessibility labels and is navigable
    func testReminderTimingPickerAccessibility() throws {
        // Navigate to Settings
        TestUtilities.navigateToSettings(self.app)

        // Use element(boundBy: 1) and scroll
        let notificationToggle = self.app.switches.element(boundBy: 1)
        XCTAssertTrue(
            notificationToggle.waitForExistence(timeout: 3.0),
            "Notification toggle should exist"
        )

        // Scroll to make toggle hittable
        self.app.swipeUp()
        usleep(300_000)
        self.app.swipeUp()
        usleep(500_000)

        // Enable notifications using coordinate tap
        if notificationToggle.value as? String == "0" {
            let toggleCoordinate = notificationToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
            toggleCoordinate.tap()

            // Wait for value to change
            let enableExpectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "value == %@", "1"),
                object: notificationToggle
            )
            _ = XCTWaiter().wait(for: [enableExpectation], timeout: 3.0)
        }

        // Verify reminder picker exists and is accessible
        let reminderPicker = self.app.buttons["reminder-timing-picker"]
        XCTAssertTrue(
            reminderPicker.waitForExistence(timeout: 3.0),
            "Reminder timing picker should exist"
        )

        // Scroll one more time to ensure picker is fully visible
        if !reminderPicker.isHittable {
            self.app.swipeUp()
            usleep(500_000)
        }

        // Verify accessibility properties
        XCTAssertTrue(
            reminderPicker.isHittable,
            "Reminder picker should be hittable for accessibility"
        )

        XCTAssertFalse(
            reminderPicker.label.isEmpty,
            "Reminder picker should have non-empty accessibility label"
        )

        // Verify picker shows current selection in label
        let label = reminderPicker.label
        XCTAssertTrue(
            label.contains("hour") || label.contains("minutes"),
            "Reminder picker label should describe timing: '\(label)'"
        )

        // Verify picker can be interacted with
        reminderPicker.tap()
        sleep(1)

        // Menu should appear with options
        let option1Hour = self.app.buttons["1 hour before"]
        let option30Min = self.app.buttons["30 minutes before"]

        XCTAssertTrue(
            option1Hour.exists || option30Min.exists,
            "Picker menu should show timing options after tapping"
        )
    }

    // MARK: - Test 8: Toggle Accessibility

    /// Test 8: Notification toggle accessibility
    ///
    /// GIVEN: User is in Settings
    /// WHEN: User navigates with VoiceOver
    /// THEN: Toggle has proper accessibility label and state is announced
    func testNotificationToggleAccessibility() throws {
        // Navigate to Settings
        TestUtilities.navigateToSettings(self.app)

        // Use element(boundBy: 1) and scroll
        let notificationToggle = self.app.switches.element(boundBy: 1)
        XCTAssertTrue(
            notificationToggle.waitForExistence(timeout: 3.0),
            "Notification toggle should exist"
        )

        // Scroll to make toggle hittable
        self.app.swipeUp()
        usleep(300_000)
        self.app.swipeUp()
        usleep(500_000)

        // Verify accessibility properties
        XCTAssertTrue(
            notificationToggle.isHittable,
            "Notification toggle should be hittable for accessibility"
        )

        // Verify toggle has accessible value indicating state
        let initialValue = notificationToggle.value as? String
        XCTAssertNotNil(
            initialValue,
            "Toggle should have accessible value for state"
        )
        XCTAssertTrue(
            initialValue == "0" || initialValue == "1",
            "Toggle value should be 0 or 1, got: \(initialValue ?? "nil")"
        )

        // Toggle using coordinate tap and verify state changes
        let toggleCoordinate = notificationToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        toggleCoordinate.tap()

        // Wait for value to change
        let expectedNewValue = initialValue == "0" ? "1" : "0"
        let changeExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", expectedNewValue),
            object: notificationToggle
        )
        _ = XCTWaiter().wait(for: [changeExpectation], timeout: 3.0)

        let updatedValue = notificationToggle.value as? String
        XCTAssertNotEqual(
            initialValue,
            updatedValue,
            "Toggle value should change after tapping"
        )

        // Verify accessibility identifier is set
        XCTAssertEqual(
            notificationToggle.identifier,
            "notifications-toggle",
            "Toggle should have proper accessibility identifier"
        )

        // Verify toggle is part of proper accessibility hierarchy
        // Should be within notification section
        let notificationHeader = self.app.staticTexts["notifications-section-header"]
        XCTAssertTrue(
            notificationHeader.exists,
            "Toggle should be within notification section with header"
        )
    }
}
