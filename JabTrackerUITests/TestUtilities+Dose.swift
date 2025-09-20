//
//  TestUtilities+Dose.swift
//  JabTrackerUITests
//
//  Extension for dose-related test utilities
//

import XCTest

extension TestUtilities {
    /// Creates multiple doses through the UI for testing dose history functionality
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - count: Number of doses to create (default: 3)
    ///   - delay: Delay between doses for different timestamps (default: 1.0 seconds)
    /// - Note: Includes small delays between doses to ensure different timestamps
    static func createMultipleDoses(in app: XCUIApplication, count: Int = 3, delay: TimeInterval = 1.0) {
        let addTab = app.tabBars.element.buttons["Add"]
        let medicationPicker = app.buttons["quick-dose-medication-picker"]
        let saveButton = app.buttons["quick-dose-save-button"]
        let successIndicator = app.staticTexts["dose-logged-success"]

        for index in 0 ..< count {
            // Navigate to Add tab
            addTab.tap()

            // Wait for medication picker and save button
            XCTAssertTrue(medicationPicker.waitForExistence(timeout: 3),
                          "Medication picker should exist for dose \(index + 1)")
            XCTAssertTrue(saveButton.exists && saveButton.isEnabled,
                          "Save button should be enabled for dose \(index + 1)")

            // Save the dose
            saveButton.tap()

            // Wait for success indicator and dismissal
            XCTAssertTrue(successIndicator.waitForExistence(timeout: 3),
                          "Success indicator should appear for dose \(index + 1)")
            XCTAssertTrue(successIndicator.waitForNonExistence(timeout: 3),
                          "Success indicator should dismiss for dose \(index + 1)")

            // Add delay between doses for different timestamps (except after last dose)
            if index < count - 1 {
                Thread.sleep(forTimeInterval: delay)
            }
        }
    }

    /// Sets up a standard test environment with medication profile(s) and doses
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - doseCount: Number of doses to create (default: 3)
    ///   - medicationProfiles: Number of medication profiles to create (default: 1)
    ///   - medicationName: Generic medication name for first profile (default: "semaglutide")
    ///   - brandName: Brand name for first profile (default: "Ozempic")
    ///   - dose: Dose amount for first profile (default: "0.25")
    /// - Returns: The configured app ready for dose history testing
    @discardableResult
    static func setupDoseHistoryTest(
        app: XCUIApplication,
        doseCount: Int = 3,
        medicationProfiles: Int = 1,
        medicationName: String = "semaglutide",
        brandName: String = "Ozempic",
        dose: String = "0.25") -> XCUIApplication
    {
        // Create medication profiles using the standard method
        // The navigateToMedicationProfiles will check if we're already there
        if medicationProfiles >= 1 {
            createMedicationProfile(app, genericName: medicationName, brandName: brandName, dose: dose)
        }

        if medicationProfiles >= 2 {
            // The second call will see we're already on Medication Profiles screen and not navigate again
            // Use the createMedicationProfileWithDefaults to avoid dose selection issues
            self.createMedicationProfileWithDefaults(app, genericName: "tirzepatide", brandName: "Mounjaro")
        }

        if medicationProfiles >= 3 {
            self.createMedicationProfileWithDefaults(app, genericName: "liraglutide", brandName: "Victoza")
        }

        if medicationProfiles >= 4 {
            self.createMedicationProfileWithDefaults(app, genericName: "dulaglutide", brandName: "Trulicity")
        }

        // Create multiple doses (will be associated with the first medication profile by default)
        self.createMultipleDoses(in: app, count: doseCount)

        return app
    }

    /// Creates a medication profile using default dose (doesn't select a specific dose)
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - genericName: Generic medication name
    ///   - brandName: Brand name
    private static func createMedicationProfileWithDefaults(
        _ app: XCUIApplication,
        genericName: String,
        brandName: String,
        timeout: TimeInterval = 3)
    {
        navigateToMedicationProfiles(app, timeout: timeout)

        // Tap the + button in the navigation bar to add a new profile
        let addButton = app.navigationBars["Medication Profiles"].buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: timeout),
                      "Add (+) button should exist in navigation bar")
        addButton.tap()

        // Select medication
        let medicationPicker = app.buttons["medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: timeout),
                      "Medication picker should exist")
        medicationPicker.tap()

        let medicationOption = app.buttons["medication-\(genericName)"]
        XCTAssertTrue(medicationOption.waitForExistence(timeout: timeout),
                      "Medication option \(genericName) should exist")
        medicationOption.tap()

        // Select brand
        let brandPicker = app.buttons["add-brand-picker"]
        XCTAssertTrue(brandPicker.waitForExistence(timeout: timeout),
                      "Brand picker should exist")
        brandPicker.tap()

        let brandOption = app.buttons["add-brand-\(brandName.lowercased())"]
        XCTAssertTrue(brandOption.waitForExistence(timeout: timeout),
                      "Brand option \(brandName) should exist")
        brandOption.tap()

        // Skip dose selection - just use the default that's already selected

        // Save profile
        let saveButton = app.buttons["save-medication-profile"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: timeout),
                      "Save button should exist")
        saveButton.tap()

        // Wait for the profile to appear in the list (don't verify specific dose in identifier)
        let profileCell = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS %@", "medication-profile-\(genericName)")
        ).firstMatch
        XCTAssertTrue(profileCell.waitForExistence(timeout: timeout),
                      "Created profile should appear in list")
    }

    /// Navigates to History tab and waits for history content to load
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - timeout: Timeout for history content to appear (default: 3 seconds)
    /// - Returns: The visible history content element (list or calendar)
    @discardableResult
    static func navigateToHistoryView(in app: XCUIApplication, timeout: TimeInterval = 3) -> XCUIElement {
        // Navigate to History tab
        let historyTab = app.tabBars.element.buttons["History"]
        historyTab.tap()

        // Wait for the segmented control to appear (this indicates HistoryView is loaded)
        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: timeout),
                      "History view segmented control should appear within \(timeout) seconds")

        // By default, HistoryView starts in list mode, so wait for list view
        let listView = app.descendants(matching: .any)["dose-history-list"]
        if listView.waitForExistence(timeout: 2) {
            return listView
        }

        // If list view doesn't appear quickly, check if we're in calendar mode and switch
        let calendarView = app.descendants(matching: .any)["dose-calendar-view"]
        if calendarView.exists {
            let listToggle = segmentedControl.buttons["history-list-toggle"]
            if listToggle.exists {
                listToggle.tap()
                XCTAssertTrue(listView.waitForExistence(timeout: 2),
                              "List view should appear after switching from calendar")
                return listView
            }
        }

        XCTFail("Could not navigate to history list view within \(timeout) seconds")
        return listView // This will be non-existent, but satisfies return requirement
    }

    /// Gets dose rows from the history list
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - minimumCount: Minimum expected number of dose rows (default: 1)
    /// - Returns: XCUIElementQuery for dose rows
    static func getDoseRows(from app: XCUIApplication, minimumCount: Int = 1) -> XCUIElementQuery {
        let doseRows = app.buttons.matching(identifier: "dose-history-row")
        XCTAssertGreaterThanOrEqual(doseRows.count, minimumCount,
                                    "Should have at least \(minimumCount) dose row(s)")
        return doseRows
    }
}
