import XCTest

/// Captures the five App Store screenshots (docs/app-store/screenshots/README.md) from real screens with fictional
/// seeded data, asserting each screen's behavior before its capture. Contributes tests only when the runner
/// receives `APP_STORE_CAPTURE_DIR` (pass `TEST_RUNNER_APP_STORE_CAPTURE_DIR=<dir>` to xcodebuild), so ordinary
/// UI runs neither execute nor skip it.
final class AppStoreScreenshotUITests: XCTestCase {
    private static let capturePath = ProcessInfo.processInfo.environment["APP_STORE_CAPTURE_DIR"]
    private var app: XCUIApplication!
    private var directory: URL!

    override static var defaultTestSuite: XCTestSuite {
        capturePath == nil ? XCTestSuite(name: "AppStoreScreenshotUITests (capture off)") : super.defaultTestSuite
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        let path = try XCTUnwrap(Self.capturePath, "Set TEST_RUNNER_APP_STORE_CAPTURE_DIR")
        directory = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: [
                "--bypass-onboarding", "--seed-1-month-active", "--disable-cloudkit",
                "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            ]
        )
        expect(app.tabBars.firstMatch.waitForExistence(timeout: 15), "The seeded fictional user opens the app")
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    func testCaptureAppStoreScreenshots() throws {
        expect(app.staticTexts["Weekly Nutrition"].waitForExistence(timeout: 15), "Dashboard shows weekly nutrition")
        expect(app.staticTexts["Today's Nutrition"].exists, "Dashboard shows today's nutrition")
        capture("dashboard")

        tap(app.tabBars.firstMatch.buttons["Food Log"], "Open Food Log")
        tap(app.otherElements["food-log-view"].buttons["add-food-button"], "Open food search")
        let search = app.otherElements["food-search-sheet"]
        expect(search.waitForExistence(timeout: 5), "Food search opens")
        let field = search.textFields["food-search-field"]
        tap(field, "Focus the search field")
        field.typeText("salmon\n")
        // Result order depends on the bundled database (CI fixture or production), so log the first result.
        let result = search.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'food-result-'")).firstMatch
        expect(result.waitForExistence(timeout: 15), "The bundled library returns salmon results")
        let food = result.staticTexts.firstMatch.label
        expect(food.localizedCaseInsensitiveContains("salmon"), "The first result is a salmon food: \(food)")
        capture("food-search")

        tap(result, "Select \(food)")
        let detail = app.otherElements["food-detail-sheet"]
        expect(detail.waitForExistence(timeout: 5), "Food detail opens")
        tap(detail.buttons["add-food-button"], "Log \(food)")
        expect(search.waitForNonExistence(timeout: 10), "Food search closes after logging")
        let row = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", food)).firstMatch
        expect(row.waitForExistence(timeout: 15), "The logged \(food) appears in the Food Log")
        capture("food-log")

        TestUtilities.openShortcutsSheet(app)
        tap(app.buttons["Metrics"].firstMatch, "Open Log Metrics")
        let sheet = app.descendants(matching: .any)["quick-metrics-sheet"].firstMatch
        expect(sheet.waitForExistence(timeout: 5), "Log Metrics opens")
        // Waist is the only measurement a new user has enabled; US locale records inches.
        let waist = app.textFields["waist-input"]
        tap(waist, "Focus the waist input")
        waist.typeText("32")
        expect(waist.value as? String == "32", "Waist is exactly 32")
        app.navigationBars.firstMatch.tap()
        // Keep the record in the app: turning Health sync off avoids the HealthKit permission sheet on Save.
        let healthKit = app.switches["healthkit-toggle"]
        if healthKit.exists, healthKit.value as? String == "1" {
            healthKit.switches.firstMatch.tap()
        }
        expect(!healthKit.exists || healthKit.value as? String == "0", "Health sync is off")
        capture("metrics")
        tap(app.buttons["save-metrics-button"], "Save the measurements")
        expect(sheet.waitForNonExistence(timeout: 10), "Log Metrics closes after saving")

        TestUtilities.navigateToGLP1Analytics(app)
        tap(app.segmentedControls["analytics-section-picker"].buttons["History"], "Open dose history")
        let dose = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Ozempic'")).firstMatch
        expect(dose.waitForExistence(timeout: 10), "Dose history lists the seeded Ozempic doses")
        capture("dose-history")
    }

    private func capture(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        XCTAssertNoThrow(try data.write(to: directory.appendingPathComponent("\(name).png")))
        let stamp = ISO8601DateFormatter().string(from: Date())
        XCTAssertNoThrow(try Data(stamp.utf8).write(to: directory.appendingPathComponent("\(name).time")))
    }

    private func tap(_ element: XCUIElement, _ message: String) {
        expect(element.waitForExistence(timeout: 10), message)
        element.tap()
    }

    private func expect(_ condition: @autoclosure () -> Bool, _ message: String, line: UInt = #line) {
        let passed = condition()
        if !passed {
            TestUtilities.debugScreenshot(app, name: "app-store-before-failure", context: message)
            print(app.debugDescription)
        }
        XCTAssertTrue(passed, message, line: line)
    }
}
