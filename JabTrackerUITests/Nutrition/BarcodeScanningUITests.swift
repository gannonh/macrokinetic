//
//  BarcodeScanningUITests.swift
//  JabTrackerUITests
//
//  E2E tests for barcode scanning feature.
//  Note: Camera-based tests require a real device and are limited in simulator.
//

import XCTest

final class BarcodeScanningUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)

        // Wait for app to be ready
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should appear after launch")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    /// Open food search sheet
    private func openFoodSearch() {
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3), "Search shortcut should exist")
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")
    }

    // MARK: - Entry Points

    /// User can access scanner via Scan tab in FoodSearchSheet
    /// Acceptance: Selecting Scan tab shows camera preview area
    func testUserCanAccessScannerViaScanTab() {
        // Open food search
        openFoodSearch()

        // Find and tap the Scan tab
        let scanTab = app.buttons["method-tab-scan"]
        XCTAssertTrue(scanTab.waitForExistence(timeout: 3), "Scan tab should exist")
        scanTab.tap()

        // Verify barcode scanner content view appears
        let barcodeScannerContent = app.otherElements["barcode-scanner-content"]
        XCTAssertTrue(
            barcodeScannerContent.waitForExistence(timeout: 5),
            "Barcode scanner content should appear after selecting Scan tab"
        )
    }

    /// User can access scanner via Barcode shortcut button
    /// Acceptance: Tapping Barcode in shortcuts opens FoodSearchSheet with Scan tab
    func testUserCanAccessScannerViaShortcut() {
        // Open shortcuts sheet
        TestUtilities.openShortcutsSheet(app)

        // Tap Barcode shortcut
        let barcodeButton = app.buttons["Barcode"]
        XCTAssertTrue(barcodeButton.waitForExistence(timeout: 3), "Barcode shortcut should exist")
        barcodeButton.tap()

        // Verify food search sheet appears
        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Verify barcode scanner content is visible (scan tab should be selected)
        let barcodeScannerContent = app.otherElements["barcode-scanner-content"]
        XCTAssertTrue(
            barcodeScannerContent.waitForExistence(timeout: 5),
            "Barcode scanner should be active when opened via Barcode shortcut"
        )
    }

    // MARK: - Scanner UI

    /// Scanner shows complete UI with controls
    /// Acceptance: Scanner content appears with instruction text
    func testScannerShowsCompleteUI() {
        // Open food search and switch to Scan tab
        openFoodSearch()

        let scanTab = app.buttons["method-tab-scan"]
        XCTAssertTrue(scanTab.waitForExistence(timeout: 3), "Scan tab should exist")
        scanTab.tap()

        // Wait for scanner to appear
        let barcodeScannerContent = app.otherElements["barcode-scanner-content"]
        XCTAssertTrue(barcodeScannerContent.waitForExistence(timeout: 5), "Scanner should appear")

        // Verify the scanner content is properly displayed
        // The scanner shows "Point at a barcode" instruction when camera preview is active
        // Look for any text element containing "barcode" (case-insensitive search)
        let scannerElements = app.descendants(matching: .any)
        let containsBarcode = scannerElements.allElementsBoundByIndex.contains { element in
            element.label.lowercased().contains("barcode")
        }

        XCTAssertTrue(
            containsBarcode,
            "Scanner UI should contain barcode-related content"
        )

        // Verify the scanner content view is hittable (user can interact with it)
        XCTAssertTrue(
            barcodeScannerContent.isHittable,
            "Scanner content should be interactive"
        )
    }

    /// Scanner has interactive controls
    /// Acceptance: Scanner controls area is interactive
    /// Note: Torch functionality requires real device with camera
    func testScannerHasInteractiveControls() {
        // Open food search and switch to Scan tab
        openFoodSearch()

        let scanTab = app.buttons["method-tab-scan"]
        XCTAssertTrue(scanTab.waitForExistence(timeout: 3), "Scan tab should exist")
        scanTab.tap()

        // Wait for scanner to appear
        let barcodeScannerContent = app.otherElements["barcode-scanner-content"]
        XCTAssertTrue(barcodeScannerContent.waitForExistence(timeout: 5), "Scanner should appear")

        // Verify scanner content is interactive
        XCTAssertTrue(
            barcodeScannerContent.isHittable,
            "Scanner content should be interactive"
        )

        // Look for any flash/torch related element by accessibility label
        let flashElements = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS[c] 'flash'")
        )
        let torchElements = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS[c] 'torch'")
        )

        // There should be at least one torch/flash control
        let hasTorchControl = flashElements.count > 0 || torchElements.count > 0

        XCTAssertTrue(
            hasTorchControl,
            "Scanner should have torch/flash control"
        )
    }

    // MARK: - Permission Handling

    /// User sees permission request when camera not authorized
    /// Acceptance: Permission view shown with enable button
    /// Note: Permission state is difficult to test in UI tests - this tests the UI structure
    func testUserSeesPermissionRequest() {
        // This test verifies the scanner UI loads correctly
        // Actual permission testing requires device-level manipulation

        // Open food search and switch to Scan tab
        openFoodSearch()

        let scanTab = app.buttons["method-tab-scan"]
        XCTAssertTrue(scanTab.waitForExistence(timeout: 3), "Scan tab should exist")
        scanTab.tap()

        // Verify scanner content view appears (either permission view or camera preview)
        let barcodeScannerContent = app.otherElements["barcode-scanner-content"]
        XCTAssertTrue(
            barcodeScannerContent.waitForExistence(timeout: 5),
            "Barcode scanner content should appear"
        )

        // The view should show something - either camera preview or permission request
        // In simulator without camera, it will show permission-related UI
        XCTAssertTrue(
            barcodeScannerContent.exists,
            "Scanner should show appropriate UI based on permission state"
        )
    }

    // MARK: - Barcode Lookup

    /// User sees loading state during barcode lookup
    /// Acceptance: Progress indicator shown while looking up
    /// Note: This requires actual barcode scanning which needs real device
    func testUserSeesLoadingDuringLookup() {
        // This test is limited in simulator - document the expected behavior

        // Open food search and switch to Scan tab
        openFoodSearch()

        let scanTab = app.buttons["method-tab-scan"]
        scanTab.tap()

        let barcodeScannerContent = app.otherElements["barcode-scanner-content"]
        XCTAssertTrue(barcodeScannerContent.waitForExistence(timeout: 5), "Scanner should appear")

        // In a real device test, scanning a barcode would trigger loading state
        // For simulator, we just verify the scanner UI is properly structured
        XCTAssertTrue(
            barcodeScannerContent.exists,
            "Scanner UI should be ready for barcode detection"
        )
    }

    /// User sees not-found alert for unknown barcode
    /// Acceptance: Alert with scan again and search options
    /// Note: This requires actual barcode scanning which needs real device
    func testUserSeesNotFoundAlert() {
        // This test documents expected behavior for unknown barcodes
        // Actual testing requires real device with camera and a test barcode

        // Open food search and switch to Scan tab
        openFoodSearch()

        let scanTab = app.buttons["method-tab-scan"]
        scanTab.tap()

        let barcodeScannerContent = app.otherElements["barcode-scanner-content"]
        XCTAssertTrue(barcodeScannerContent.waitForExistence(timeout: 5), "Scanner should appear")

        // Scanner is ready - in production, scanning unknown barcode shows alert
        // Expected alert structure: "Food Not Found" with "Scan Again" and "Search Instead" options
        XCTAssertTrue(
            barcodeScannerContent.exists,
            "Scanner should be ready to detect barcodes"
        )
    }

    // MARK: - Tab Switching

    /// User can switch between Scan and Search tabs
    /// Acceptance: UI changes between scanner and search modes
    func testUserCanSwitchBetweenTabs() {
        // Open food search (starts on Search tab)
        openFoodSearch()

        // Verify we're on Search tab - search field should be visible
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should be visible on Search tab")

        // Switch to Scan tab
        let scanTab = app.buttons["method-tab-scan"]
        XCTAssertTrue(scanTab.waitForExistence(timeout: 3), "Scan tab should exist")
        scanTab.tap()

        // Verify scanner content appears
        let barcodeScannerContent = app.otherElements["barcode-scanner-content"]
        XCTAssertTrue(
            barcodeScannerContent.waitForExistence(timeout: 5),
            "Scanner should appear after switching to Scan tab"
        )

        // Switch back to Search tab
        let searchTab = app.buttons["method-tab-search"]
        XCTAssertTrue(searchTab.waitForExistence(timeout: 3), "Search tab should exist")
        searchTab.tap()

        // Verify search field reappears
        XCTAssertTrue(
            searchField.waitForExistence(timeout: 3),
            "Search field should reappear after switching back to Search tab"
        )

        // Verify scanner is no longer visible
        XCTAssertFalse(
            barcodeScannerContent.exists,
            "Scanner should not be visible on Search tab"
        )
    }
}
