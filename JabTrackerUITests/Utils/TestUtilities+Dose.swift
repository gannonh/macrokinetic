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
    static func createMultipleDoses(
        in app: XCUIApplication, count: Int = 3, delay: TimeInterval = 1.0
    ) {
        let addTab = app.tabBars.element.buttons["Add"]
        let medicationPicker = app.buttons["quick-dose-medication-picker"]
        let saveButton = app.buttons["quick-dose-save-button"]
        let successIndicator = app.staticTexts["dose-logged-success"]

        for index in 0..<count {
            // Navigate to Add tab
            addTab.tap()

            // Wait for medication picker and save button
            XCTAssertTrue(
                medicationPicker.waitForExistence(timeout: 3),
                "Medication picker should exist for dose \(index + 1)")
            XCTAssertTrue(
                saveButton.exists && saveButton.isEnabled,
                "Save button should be enabled for dose \(index + 1)")

            // Save the dose
            saveButton.tap()

            // Wait for success indicator and dismissal
            XCTAssertTrue(
                successIndicator.waitForExistence(timeout: 3),
                "Success indicator should appear for dose \(index + 1)")
            XCTAssertTrue(
                successIndicator.waitForNonExistence(timeout: 3),
                "Success indicator should dismiss for dose \(index + 1)")

            // Add delay between doses for different timestamps (except after last dose)
            // if index < count - 1 {
            //     Thread.sleep(forTimeInterval: delay)
            // }
        }
    }

    /// Sets up a standard test environment with medication profile(s) and doses using data seeding
    /// - Parameters:
    ///   - app: The XCUIApplication instance (unused, kept for API compatibility)
    ///   - doseCount: Number of doses to create (default: 3)
    ///   - medicationProfiles: Number of medication profiles to create (default: 1)
    ///   - medicationName: Generic medication name for first profile (default: "semaglutide")
    ///   - brandName: Brand name for first profile (default: "Ozempic")
    ///   - dose: Dose amount for first profile (default: "0.25")
    /// - Returns: A newly launched app with seeded test data
    /// - Note: This now uses data seeding instead of UI creation (~40x faster)
    @discardableResult
    static func setupDoseHistoryTest(
        app: XCUIApplication,
        doseCount: Int = 3,
        medicationProfiles: Int = 1,
        medicationName: String = "semaglutide",
        brandName: String = "Ozempic",
        dose: String = "0.25"
    ) -> XCUIApplication {
        // Use custom preset for flexible test setup
        let customPreset = TestDataPreset.custom(
            doseCount: doseCount,
            medicationProfiles: medicationProfiles,
            medication: medicationName,
            brand: brandName,
            dose: dose,
            adherence: 1.0,  // 100% adherence for test consistency
            variability: false  // No timing variability for predictable tests
        )

        // Launch with seeded data (resets app data automatically)
        return TestUtilities.launchAppWithSeededData(preset: customPreset, resetData: true)
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
        timeout: TimeInterval = 3
    ) {
        navigateToMedicationProfiles(app, timeout: timeout)

        // Tap the + button in the navigation bar to add a new profile
        let addButton = app.navigationBars["Medication Profiles"].buttons["Add"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: timeout),
            "Add (+) button should exist in navigation bar")
        addButton.tap()

        // Select medication
        let medicationPicker = app.buttons["medication-picker"]
        XCTAssertTrue(
            medicationPicker.waitForExistence(timeout: timeout),
            "Medication picker should exist")
        medicationPicker.tap()

        let medicationOption = app.buttons["medication-\(genericName)"]
        XCTAssertTrue(
            medicationOption.waitForExistence(timeout: timeout),
            "Medication option \(genericName) should exist")
        medicationOption.tap()

        // Select brand
        let brandPicker = app.buttons["add-brand-picker"]
        XCTAssertTrue(
            brandPicker.waitForExistence(timeout: timeout),
            "Brand picker should exist")
        brandPicker.tap()

        let brandOption = app.buttons["add-brand-\(brandName.lowercased())"]
        XCTAssertTrue(
            brandOption.waitForExistence(timeout: timeout),
            "Brand option \(brandName) should exist")
        brandOption.tap()

        // Skip dose selection - just use the default that's already selected

        // Save profile
        let saveButton = app.buttons["save-medication-profile"]
        XCTAssertTrue(
            saveButton.waitForExistence(timeout: timeout),
            "Save button should exist")
        saveButton.tap()

        // Wait for the profile to appear in the list (don't verify specific dose in identifier)
        let profileCell = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS %@", "medication-profile-\(genericName)")
        ).firstMatch
        XCTAssertTrue(
            profileCell.waitForExistence(timeout: timeout),
            "Created profile should appear in list")
    }

    /// Navigates to History view (via Shots tab -> History segment) and waits for history content to load
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - timeout: Timeout for history content to appear (default: 3 seconds)
    /// - Returns: The visible history content element (list or calendar)
    @discardableResult
    static func navigateToHistoryView(in app: XCUIApplication, timeout: TimeInterval = 3)
        -> XCUIElement
    {
        // Navigate to Shots tab and select History segment
        navigateToHistory(app, timeout: timeout)

        // Wait for the history container or list to load
        let listContainer = app.descendants(matching: .any)["dose-history-container"]
        let listView = app.descendants(matching: .any)["dose-history-list"]

        // Try container first (ShotsView wrapper), then internal list
        if listContainer.waitForExistence(timeout: timeout) {
            // Now wait for the internal list with dose rows
            _ = listView.waitForExistence(timeout: 2)
            return listContainer
        }

        if listView.waitForExistence(timeout: timeout) {
            return listView
        }

        // Check for segmented control to switch to list mode if in calendar mode
        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        if segmentedControl.waitForExistence(timeout: 2) {
            let calendarContainer = app.descendants(matching: .any)["dose-calendar-view"]
            let calendarView = app.descendants(matching: .any)["dose-calendar-view"]
            if calendarContainer.exists || calendarView.exists {
                // Button is labeled "List" based on HistoryMode.list.rawValue
                let listToggle = segmentedControl.buttons["List"]
                if listToggle.exists {
                    listToggle.tap()
                    XCTAssertTrue(
                        listContainer.waitForExistence(timeout: 2) || listView.waitForExistence(timeout: 2),
                        "List view should appear after switching from calendar")
                    return listContainer.exists ? listContainer : listView
                }
            }
        }

        XCTFail("Could not navigate to history list view within \(timeout) seconds")
        return listView  // This will be non-existent, but satisfies return requirement
    }

    /// Gets dose rows from the history list
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - minimumCount: Minimum expected number of dose rows (default: 1)
    ///   - timeout: Time to wait for rows to appear (default: 10 seconds)
    /// - Returns: XCUIElementQuery for dose rows
    static func getDoseRows(
        from app: XCUIApplication,
        minimumCount: Int = 1,
        timeout: TimeInterval = 10
    ) -> XCUIElementQuery {
        // First, wait for any loading indicator to disappear
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            let loadingDisappeared = !loadingIndicator.waitForExistence(timeout: timeout / 2)
            if !loadingDisappeared {
                // Still loading - wait more
                Thread.sleep(forTimeInterval: 1)
            }
        }

        // Check for empty state - if present, data seeding may have failed
        let emptyState = app.otherElements["dose-history-empty-state"]
        if emptyState.exists {
            XCTFail("History view shows empty state - data seeding may have failed")
        }

        // In SwiftUI Lists with .buttonStyle(.plain), buttons may be exposed as cells
        // Try buttons first, then cells as fallback
        var doseRows = app.buttons.matching(identifier: "dose-history-row")
        var firstRow = doseRows.firstMatch

        if !firstRow.waitForExistence(timeout: timeout / 2) {
            // Try cells instead
            doseRows = app.cells.matching(identifier: "dose-history-row")
            firstRow = doseRows.firstMatch
        }

        let rowsAppeared = firstRow.waitForExistence(timeout: timeout / 2)
        XCTAssertTrue(rowsAppeared, "Dose rows should appear within \(timeout) seconds")

        // Verify minimum count after waiting
        XCTAssertGreaterThanOrEqual(
            doseRows.count, minimumCount,
            "Should have at least \(minimumCount) dose row(s)")
        return doseRows
    }

    // swiftlint:disable cyclomatic_complexity
    /// Creates doses with historical dates using the date picker for chart testing
    /// Creates doses spanning multiple weeks for proper concentration timeline testing
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - count: Number of doses to create (default: 5)
    static func createHistoricalChartData(in app: XCUIApplication, count: Int = 5) {
        let addTab = app.tabBars.element.buttons["Add"]
        let medicationPicker = app.buttons["quick-dose-medication-picker"]
        let datePicker = app.datePickers["quick-dose-datetime-picker"]
        let saveButton = app.buttons["quick-dose-save-button"]
        let successIndicator = app.staticTexts["dose-logged-success"]

        // Create doses at 0, 7, 14, 21, 28 days ago for good chart spread
        let dayIntervals = [0, 7, 14, 21, 28]

        for index in 0..<min(count, dayIntervals.count) {
            let daysAgo = dayIntervals[index]

            // Navigate to Add tab
            addTab.tap()

            // Wait for form elements to appear
            XCTAssertTrue(
                medicationPicker.waitForExistence(timeout: 3),
                "Medication picker should exist for dose \(index + 1)")

            // Set historical date using the date picker
            if daysAgo > 0 {
                XCTAssertTrue(
                    datePicker.waitForExistence(timeout: 3),
                    "Date picker should exist for dose \(index + 1)")

                // Calculate target date (daysAgo days in the past)
                let targetDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!

                // Tap the date picker to open it
                datePicker.tap()

                // Wait a moment for the calendar interface to appear
                // sleep(2)

                // Calendar interface is now open

                // Calculate target date components
                let calendar = Calendar.current
                let targetDateComponents = calendar.dateComponents([.day, .month, .year], from: targetDate)
                let currentDateComponents = calendar.dateComponents([.day, .month, .year], from: Date())

                guard let targetDay = targetDateComponents.day,
                    let targetMonth = targetDateComponents.month,
                    let targetYear = targetDateComponents.year,
                    let currentMonth = currentDateComponents.month,
                    let currentYear = currentDateComponents.year
                else {
                    XCTFail("Could not extract date components for dose \(index + 1)")
                    return
                }

                print("🔍 DEBUG: Target date: \(targetDate)")
                print("🔍 DEBUG: Target day: \(targetDay), month: \(targetMonth), year: \(targetYear)")
                print("🔍 DEBUG: Current month: \(currentMonth), year: \(currentYear)")

                // Navigate to the correct month if needed
                if targetYear != currentYear || targetMonth != currentMonth {
                    // Need to navigate to a different month
                    let monthDifference = (targetYear - currentYear) * 12 + (targetMonth - currentMonth)

                    if monthDifference < 0 {
                        // Go backwards in time - tap left arrow
                        for _ in 0..<abs(monthDifference) {
                            let previousButton = app.buttons.matching(identifier: "Previous Month").firstMatch
                            if !previousButton.exists {
                                // Try generic left arrow or navigation
                                let leftArrow = app.buttons.element(matching: .button, identifier: "ChevronLeft")
                                if leftArrow.exists {
                                    leftArrow.tap()
                                } else {
                                    XCTFail("Could not find previous month navigation for dose \(index + 1)")
                                    return
                                }
                            } else {
                                previousButton.tap()
                            }
                            // sleep(1)
                        }
                    }
                }

                // Select the specific day in the calendar
                // Calendar buttons have full labels like "Monday, September 16" not just "16"
                let monthName = DateFormatter().monthSymbols[targetMonth - 1]  // Month names array is 0-indexed
                let targetDateLabelPattern = "\\w+, \(monthName) \(targetDay)"

                print("🔍 DEBUG: Looking for day button with pattern: '\(targetDateLabelPattern)'")

                // Find button with label matching the pattern
                let dayButton = app.buttons.matching(
                    NSPredicate(format: "label MATCHES %@", targetDateLabelPattern)
                ).firstMatch

                print("🔍 DEBUG: Day button exists: \(dayButton.exists)")
                if dayButton.exists {
                    print("🔍 DEBUG: Found day button with label: '\(dayButton.label)'")
                } else {
                    print("🔍 DEBUG: Day button with pattern '\(targetDateLabelPattern)' not found")
                }

                XCTAssertTrue(
                    dayButton.waitForExistence(timeout: 3),
                    "Day \(targetDay) button should exist in calendar for dose \(index + 1)")
                dayButton.tap()

                print(
                    "📅 Setting dose \(index + 1) to \(daysAgo) days ago: \(targetDate) (day \(targetDay))")

                // Wait a moment for the date selection to register
                //// sleep(1)

                // Dismiss the calendar by tapping outside of it
                // Try multiple approaches to find what works

                // First attempt: Tap the Notes field below the calendar to dismiss it
                let notesField = app.textFields.matching(identifier: "quick-dose-notes").firstMatch
                if notesField.exists {
                    notesField.tap()
                    print("🔍 DEBUG: Tapped Notes field to dismiss calendar")
                } else {
                    // Second attempt: Tap the form/sheet background
                    // The calendar is a popover, so tapping the sheet behind it should dismiss
                    let sheets = app.sheets.firstMatch
                    if sheets.exists {
                        // Tap near the bottom of the sheet, below the calendar
                        let sheetCoordinate = sheets.coordinate(
                            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
                        sheetCoordinate.tap()
                        print("🔍 DEBUG: Tapped sheet background to dismiss calendar")
                    } else {
                        // Last resort: Tap at coordinates where "ADDITIONAL INFORMATION" section would be
                        // This is definitely outside the calendar area
                        let bottomCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.85))
                        bottomCoordinate.tap()
                        print("🔍 DEBUG: Tapped bottom area to dismiss calendar")
                    }
                }

                // Wait for calendar to fully dismiss
                // sleep(2)
            }

            // Save the dose
            XCTAssertTrue(
                saveButton.exists && saveButton.isEnabled,
                "Save button should be enabled for dose \(index + 1)")

            // Use coordinate-based tapping to bypass scroll issues
            if saveButton.isHittable {
                saveButton.tap()
            } else {
                // Force tap using coordinates
                let coordinate = saveButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                coordinate.tap()
                print("🔍 DEBUG: Used coordinate tap for save button")
            }

            // Wait for success indicator and dismissal
            XCTAssertTrue(
                successIndicator.waitForExistence(timeout: 3),
                "Success indicator should appear for dose \(index + 1)")
            XCTAssertTrue(
                successIndicator.waitForNonExistence(timeout: 3),
                "Success indicator should dismiss for dose \(index + 1)")
        }
    }
    // swiftlint:enable cyclomatic_complexity
}
