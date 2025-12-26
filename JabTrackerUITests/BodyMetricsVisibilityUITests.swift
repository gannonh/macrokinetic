import XCTest

/// E2E tests for Body Metrics Visibility settings UI
///
/// Tests the complete user workflow for managing body metrics visibility preferences:
/// - Navigation to Body Metrics Visibility from More tab
/// - Toggling metric visibility (waist, chest, hip, neck, etc.)
/// - Toggling photo type visibility (front, side, back)
/// - Persistence of preferences across navigation
/// - Accessibility compliance for VoiceOver users
///
/// Note: These are test stubs created for Phase 11-01. Implementation required.
final class BodyMetricsVisibilityUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        self.app = XCUIApplication()
        self.app.launchArguments = ["--ui-testing", "--reset-app-data"]
        self.app.launch()

        // Wait for app to be ready
        XCTAssertTrue(self.app.tabBars.firstMatch.waitForExistence(timeout: 5.0))
    }

    override func tearDown() {
        if testRun?.hasSucceeded == false {
            TestUtilities.captureFailureScreenshot(app, testName: name)
        }
        super.tearDown()
    }

    // MARK: - Test 1: Navigation

    /// Test 1: Navigate to Body Metrics Visibility screen
    ///
    /// GIVEN: User is on any tab
    /// WHEN: User taps More tab → Body Metrics Visibility
    /// THEN: Body Metrics Visibility screen is displayed
    func testNavigateToBodyMetricsVisibility() throws {
        // TODO: Implement
        // 1. Navigate to More tab
        // 2. Tap "Body Metrics Visibility" link
        // 3. Verify body-metrics-visibility-view is displayed
        // 4. Verify description section is visible
        // 5. Verify section headers are visible (Weight & Body Fat, Progress Photos, etc.)

        // Navigate to More tab
        let moreTab = self.app.tabBars.buttons["More"]
        XCTAssertTrue(moreTab.waitForExistence(timeout: 5.0), "More tab should exist")
        moreTab.tap()

        // Verify More view loaded
        let moreView = self.app.otherElements["more-view"]
        XCTAssertTrue(moreView.waitForExistence(timeout: 5.0), "More view should appear")

        // Tap Body Metrics Visibility link
        let metricsLink = self.app.buttons["body-metrics-visibility-link"]
        XCTAssertTrue(metricsLink.waitForExistence(timeout: 3.0), "Body Metrics Visibility link should exist")
        metricsLink.tap()

        // Verify Body Metrics Visibility view appears
        let visibilityView = self.app.otherElements["body-metrics-visibility-view"]
        XCTAssertTrue(
            visibilityView.waitForExistence(timeout: 5.0),
            "Body Metrics Visibility view should appear"
        )
    }

    // MARK: - Test 2: Toggle Metric Visibility

    /// Test 2: Toggle a body metric on and off
    ///
    /// GIVEN: User is on Body Metrics Visibility screen
    /// WHEN: User toggles a metric (e.g., Chest)
    /// THEN: Toggle state changes and persists
    func testToggleMetricVisibility() throws {
        // Navigate to More tab
        let moreTab = self.app.tabBars.buttons["More"]
        XCTAssertTrue(moreTab.waitForExistence(timeout: 5.0), "More tab should exist")
        moreTab.tap()

        // Verify More view loaded
        let moreView = self.app.otherElements["more-view"]
        XCTAssertTrue(moreView.waitForExistence(timeout: 5.0), "More view should appear")

        // Tap Body Metrics Visibility link
        let metricsLink = self.app.buttons["body-metrics-visibility-link"]
        XCTAssertTrue(metricsLink.waitForExistence(timeout: 3.0), "Body Metrics Visibility link should exist")
        metricsLink.tap()

        // Verify Body Metrics Visibility view appears
        let visibilityView = self.app.otherElements["body-metrics-visibility-view"]
        XCTAssertTrue(
            visibilityView.waitForExistence(timeout: 5.0),
            "Body Metrics Visibility view should appear"
        )

        // Scroll down to find Chest toggle (in Upper Body section)
        self.app.swipeUp()
        usleep(300_000)

        // Find the Chest toggle
        let chestToggle = self.app.switches["metric-toggle-chest"]
        XCTAssertTrue(chestToggle.waitForExistence(timeout: 3.0), "Chest toggle should exist")

        // Verify initial state is OFF (chest is not in default enabled metrics)
        XCTAssertEqual(
            chestToggle.value as? String,
            "0",
            "Chest toggle should initially be disabled (not in defaults)"
        )

        // Toggle ON using coordinate tap for reliability
        let toggleCoordinate = chestToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        toggleCoordinate.tap()

        // Wait for toggle value to update
        let onExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "1"),
            object: chestToggle
        )
        let onResult = XCTWaiter().wait(for: [onExpectation], timeout: 3.0)
        XCTAssertEqual(onResult, .completed, "Chest toggle should change to ON within 3 seconds")

        // Verify toggle is now ON
        XCTAssertEqual(
            chestToggle.value as? String,
            "1",
            "Chest toggle should be enabled after tapping"
        )

        // Toggle OFF
        toggleCoordinate.tap()

        // Wait for toggle value to update
        let offExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "0"),
            object: chestToggle
        )
        let offResult = XCTWaiter().wait(for: [offExpectation], timeout: 3.0)
        XCTAssertEqual(offResult, .completed, "Chest toggle should change to OFF within 3 seconds")

        // Verify toggle is now OFF
        XCTAssertEqual(
            chestToggle.value as? String,
            "0",
            "Chest toggle should be disabled after second tap"
        )
    }

    // MARK: - Test 3: Toggle Photo Type Visibility

    /// Test 3: Toggle a photo type on and off
    ///
    /// GIVEN: User is on Body Metrics Visibility screen
    /// WHEN: User toggles a photo type (e.g., Side Photo)
    /// THEN: Toggle state changes and persists
    func testTogglePhotoTypeVisibility() throws {
        // Navigate to More tab
        let moreTab = self.app.tabBars.buttons["More"]
        XCTAssertTrue(moreTab.waitForExistence(timeout: 5.0), "More tab should exist")
        moreTab.tap()

        // Verify More view loaded
        let moreView = self.app.otherElements["more-view"]
        XCTAssertTrue(moreView.waitForExistence(timeout: 5.0), "More view should appear")

        // Tap Body Metrics Visibility link
        let metricsLink = self.app.buttons["body-metrics-visibility-link"]
        XCTAssertTrue(metricsLink.waitForExistence(timeout: 3.0), "Body Metrics Visibility link should exist")
        metricsLink.tap()

        // Verify Body Metrics Visibility view appears
        let visibilityView = self.app.otherElements["body-metrics-visibility-view"]
        XCTAssertTrue(
            visibilityView.waitForExistence(timeout: 5.0),
            "Body Metrics Visibility view should appear"
        )

        // Find the Side Photo toggle (in Progress Photos section, near top)
        let sideToggle = self.app.switches["photo-toggle-side"]
        XCTAssertTrue(sideToggle.waitForExistence(timeout: 3.0), "Side Photo toggle should exist")

        // Verify initial state is OFF (side is not in default enabled photo types)
        XCTAssertEqual(
            sideToggle.value as? String,
            "0",
            "Side Photo toggle should initially be disabled (only front is default)"
        )

        // Toggle ON using coordinate tap for reliability
        let toggleCoordinate = sideToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        toggleCoordinate.tap()

        // Wait for toggle value to update
        let onExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "1"),
            object: sideToggle
        )
        let onResult = XCTWaiter().wait(for: [onExpectation], timeout: 3.0)
        XCTAssertEqual(onResult, .completed, "Side Photo toggle should change to ON within 3 seconds")

        // Verify toggle is now ON
        XCTAssertEqual(
            sideToggle.value as? String,
            "1",
            "Side Photo toggle should be enabled after tapping"
        )

        // Toggle OFF
        toggleCoordinate.tap()

        // Wait for toggle value to update
        let offExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "0"),
            object: sideToggle
        )
        let offResult = XCTWaiter().wait(for: [offExpectation], timeout: 3.0)
        XCTAssertEqual(offResult, .completed, "Side Photo toggle should change to OFF within 3 seconds")

        // Verify toggle is now OFF
        XCTAssertEqual(
            sideToggle.value as? String,
            "0",
            "Side Photo toggle should be disabled after second tap"
        )
    }

    // MARK: - Test 4: Preferences Persist After Navigation

    /// Test 4: Verify preferences persist after navigating away and back
    ///
    /// GIVEN: User has toggled some metrics on
    /// WHEN: User navigates away and returns
    /// THEN: Toggle states are preserved
    func testPreferencesPersistAfterNavigation() throws {
        // Navigate to More tab
        let moreTab = self.app.tabBars.buttons["More"]
        XCTAssertTrue(moreTab.waitForExistence(timeout: 5.0), "More tab should exist")
        moreTab.tap()

        // Verify More view loaded
        let moreView = self.app.otherElements["more-view"]
        XCTAssertTrue(moreView.waitForExistence(timeout: 5.0), "More view should appear")

        // Tap Body Metrics Visibility link
        let metricsLink = self.app.buttons["body-metrics-visibility-link"]
        XCTAssertTrue(metricsLink.waitForExistence(timeout: 3.0), "Body Metrics Visibility link should exist")
        metricsLink.tap()

        // Verify Body Metrics Visibility view appears
        let visibilityView = self.app.otherElements["body-metrics-visibility-view"]
        XCTAssertTrue(
            visibilityView.waitForExistence(timeout: 5.0),
            "Body Metrics Visibility view should appear"
        )

        // Scroll down to find Chest toggle
        self.app.swipeUp()
        usleep(300_000)

        // Find and toggle Chest ON
        let chestToggle = self.app.switches["metric-toggle-chest"]
        XCTAssertTrue(chestToggle.waitForExistence(timeout: 3.0), "Chest toggle should exist")

        // Toggle ON using coordinate tap
        let toggleCoordinate = chestToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        toggleCoordinate.tap()

        // Wait for toggle to turn ON
        let onExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "1"),
            object: chestToggle
        )
        let onResult = XCTWaiter().wait(for: [onExpectation], timeout: 3.0)
        XCTAssertEqual(onResult, .completed, "Chest toggle should change to ON")

        // Navigate back to More view using back button
        let backButton = self.app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 3.0), "Back button should exist")
        backButton.tap()

        // Verify we're back on More view
        XCTAssertTrue(
            moreView.waitForExistence(timeout: 5.0),
            "Should return to More view after tapping back"
        )

        // Navigate back to Body Metrics Visibility
        XCTAssertTrue(metricsLink.waitForExistence(timeout: 3.0), "Body Metrics Visibility link should exist")
        metricsLink.tap()

        // Verify Body Metrics Visibility view appears again
        XCTAssertTrue(
            visibilityView.waitForExistence(timeout: 5.0),
            "Body Metrics Visibility view should appear again"
        )

        // Scroll down to find Chest toggle again
        self.app.swipeUp()
        usleep(300_000)

        // Find Chest toggle and verify it's still ON
        let chestToggleAfterNav = self.app.switches["metric-toggle-chest"]
        XCTAssertTrue(chestToggleAfterNav.waitForExistence(timeout: 3.0), "Chest toggle should exist after navigation")

        // Verify toggle is still ON (preference persisted)
        XCTAssertEqual(
            chestToggleAfterNav.value as? String,
            "1",
            "Chest toggle should remain ON after navigating away and back (preference should persist)"
        )
    }

    // MARK: - Test 5: Default States

    /// Test 5: Verify default toggle states match expected defaults
    ///
    /// GIVEN: Fresh app install (--reset-app-data)
    /// WHEN: User opens Body Metrics Visibility
    /// THEN: Only Waist metric and Front photo are enabled by default
    func testDefaultToggleStates() throws {
        // Navigate to More tab
        let moreTab = self.app.tabBars.buttons["More"]
        XCTAssertTrue(moreTab.waitForExistence(timeout: 5.0), "More tab should exist")
        moreTab.tap()

        // Verify More view loaded
        let moreView = self.app.otherElements["more-view"]
        XCTAssertTrue(moreView.waitForExistence(timeout: 5.0), "More view should appear")

        // Tap Body Metrics Visibility link
        let metricsLink = self.app.buttons["body-metrics-visibility-link"]
        XCTAssertTrue(metricsLink.waitForExistence(timeout: 3.0), "Body Metrics Visibility link should exist")
        metricsLink.tap()

        // Verify Body Metrics Visibility view appears
        let visibilityView = self.app.otherElements["body-metrics-visibility-view"]
        XCTAssertTrue(
            visibilityView.waitForExistence(timeout: 5.0),
            "Body Metrics Visibility view should appear"
        )

        // Check Progress Photos section defaults (near top of list)
        // Front Photo should be ON by default
        let frontToggle = self.app.switches["photo-toggle-front"]
        XCTAssertTrue(frontToggle.waitForExistence(timeout: 3.0), "Front Photo toggle should exist")
        XCTAssertEqual(
            frontToggle.value as? String,
            "1",
            "Front Photo toggle should be ON by default"
        )

        // Side Photo should be OFF by default
        let sideToggle = self.app.switches["photo-toggle-side"]
        XCTAssertTrue(sideToggle.waitForExistence(timeout: 3.0), "Side Photo toggle should exist")
        XCTAssertEqual(
            sideToggle.value as? String,
            "0",
            "Side Photo toggle should be OFF by default"
        )

        // Back Photo should be OFF by default
        let backToggle = self.app.switches["photo-toggle-back"]
        XCTAssertTrue(backToggle.waitForExistence(timeout: 3.0), "Back Photo toggle should exist")
        XCTAssertEqual(
            backToggle.value as? String,
            "0",
            "Back Photo toggle should be OFF by default"
        )

        // Scroll down to Upper Body section
        self.app.swipeUp()
        usleep(300_000)

        // Waist should be ON by default (only metric enabled by default)
        let waistToggle = self.app.switches["metric-toggle-waist"]
        XCTAssertTrue(waistToggle.waitForExistence(timeout: 3.0), "Waist toggle should exist")
        XCTAssertEqual(
            waistToggle.value as? String,
            "1",
            "Waist toggle should be ON by default"
        )

        // Chest should be OFF by default
        let chestToggle = self.app.switches["metric-toggle-chest"]
        XCTAssertTrue(chestToggle.waitForExistence(timeout: 3.0), "Chest toggle should exist")
        XCTAssertEqual(
            chestToggle.value as? String,
            "0",
            "Chest toggle should be OFF by default"
        )

        // Neck should be OFF by default
        let neckToggle = self.app.switches["metric-toggle-neck"]
        XCTAssertTrue(neckToggle.waitForExistence(timeout: 3.0), "Neck toggle should exist")
        XCTAssertEqual(
            neckToggle.value as? String,
            "0",
            "Neck toggle should be OFF by default"
        )
    }

    // MARK: - Test 6: All Sections Visible

    /// Test 6: Verify all settings sections are visible and scrollable
    ///
    /// GIVEN: User is on Body Metrics Visibility screen
    /// WHEN: User scrolls through the list
    /// THEN: All sections are accessible (Weight & Body Fat, Progress Photos, Upper Body, Arms, Legs, Ratios)
    func testAllSectionsVisible() throws {
        // Navigate to More tab
        let moreTab = self.app.tabBars.buttons["More"]
        XCTAssertTrue(moreTab.waitForExistence(timeout: 5.0), "More tab should exist")
        moreTab.tap()

        // Verify More view loaded
        let moreView = self.app.otherElements["more-view"]
        XCTAssertTrue(moreView.waitForExistence(timeout: 5.0), "More view should appear")

        // Tap Body Metrics Visibility link
        let metricsLink = self.app.buttons["body-metrics-visibility-link"]
        XCTAssertTrue(metricsLink.waitForExistence(timeout: 3.0), "Body Metrics Visibility link should exist")
        metricsLink.tap()

        // Verify Body Metrics Visibility view appears
        let visibilityView = self.app.otherElements["body-metrics-visibility-view"]
        XCTAssertTrue(
            visibilityView.waitForExistence(timeout: 5.0),
            "Body Metrics Visibility view should appear"
        )

        // Verify Weight & Body Fat section header exists (uses "Weight & Body Fat" label)
        let weightSectionHeader = self.app.staticTexts["Weight & Body Fat"]
        XCTAssertTrue(
            weightSectionHeader.waitForExistence(timeout: 3.0),
            "Weight & Body Fat section header should exist"
        )

        // Verify Progress Photos section header exists
        let photosSectionHeader = self.app.staticTexts["Progress Photos"]
        XCTAssertTrue(
            photosSectionHeader.waitForExistence(timeout: 3.0),
            "Progress Photos section header should exist"
        )

        // Scroll down to reveal more sections
        self.app.swipeUp()
        usleep(300_000)

        // Verify Upper Body section header exists
        let upperBodyHeader = self.app.staticTexts["Upper Body"]
        XCTAssertTrue(
            upperBodyHeader.waitForExistence(timeout: 3.0),
            "Upper Body section header should exist"
        )

        // Scroll down more to reveal Arms section
        self.app.swipeUp()
        usleep(300_000)

        // Verify Arms section header exists
        let armsHeader = self.app.staticTexts["Arms"]
        XCTAssertTrue(
            armsHeader.waitForExistence(timeout: 3.0),
            "Arms section header should exist"
        )

        // Scroll down more to reveal Legs section
        self.app.swipeUp()
        usleep(300_000)

        // Verify Legs section header exists
        let legsHeader = self.app.staticTexts["Legs"]
        XCTAssertTrue(
            legsHeader.waitForExistence(timeout: 3.0),
            "Legs section header should exist"
        )

        // Scroll down more to reveal Ratios section
        self.app.swipeUp()
        usleep(300_000)

        // Verify Ratios section header exists
        let ratiosHeader = self.app.staticTexts["Ratios"]
        XCTAssertTrue(
            ratiosHeader.waitForExistence(timeout: 3.0),
            "Ratios section header should exist"
        )

        // Verify we can see a toggle from the Ratios section
        let waistToHeightToggle = self.app.switches["metric-toggle-waistToHeight"]
        XCTAssertTrue(
            waistToHeightToggle.waitForExistence(timeout: 3.0),
            "Waist to Height toggle should exist in Ratios section"
        )
    }

    // MARK: - Test 7: Description Text Displayed

    /// Test 7: Verify description text is displayed at the top
    ///
    /// GIVEN: User is on Body Metrics Visibility screen
    /// WHEN: Screen loads
    /// THEN: Description explaining toggle behavior is visible
    func testDescriptionTextDisplayed() throws {
        // Navigate to More tab
        let moreTab = self.app.tabBars.buttons["More"]
        XCTAssertTrue(moreTab.waitForExistence(timeout: 5.0), "More tab should exist")
        moreTab.tap()

        // Verify More view loaded
        let moreView = self.app.otherElements["more-view"]
        XCTAssertTrue(moreView.waitForExistence(timeout: 5.0), "More view should appear")

        // Tap Body Metrics Visibility link
        let metricsLink = self.app.buttons["body-metrics-visibility-link"]
        XCTAssertTrue(metricsLink.waitForExistence(timeout: 3.0), "Body Metrics Visibility link should exist")
        metricsLink.tap()

        // Verify Body Metrics Visibility view appears
        let visibilityView = self.app.otherElements["body-metrics-visibility-view"]
        XCTAssertTrue(
            visibilityView.waitForExistence(timeout: 5.0),
            "Body Metrics Visibility view should appear"
        )

        // The description text is at the top. Look for key phrases from the description.
        // The description says: "Toggling a body metric will control its visibility..."
        // We can search for staticTexts containing this key phrase
        let descriptionPredicate = NSPredicate(format: "label CONTAINS[c] %@", "Toggling a body metric")
        let descriptionText = self.app.staticTexts.matching(descriptionPredicate).firstMatch

        XCTAssertTrue(
            descriptionText.waitForExistence(timeout: 3.0),
            "Description text should be visible at the top of the screen"
        )

        // Also verify description contains information about historical data being preserved
        let historicalPredicate = NSPredicate(format: "label CONTAINS[c] %@", "historical data")
        let historicalText = self.app.staticTexts.matching(historicalPredicate).firstMatch

        XCTAssertTrue(
            historicalText.waitForExistence(timeout: 3.0),
            "Description should mention historical data preservation"
        )
    }
}
