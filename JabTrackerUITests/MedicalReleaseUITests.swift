import XCTest

final class MedicalReleaseUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
    }

    override func tearDownWithError() throws {
        if testRun?.hasSucceeded == false {
            TestUtilities.captureFailureScreenshot(app, testName: name)
        }
        app = nil
    }

    func testCompoundedProfileRecordsExactAmountWithoutCalculatorOrClinicalOutputs() {
        createCompoundedProfile()
        openCreatedProfile()
        recordEvidence("medical-release-profile-detail")
        for identifier in ["detail-reconstitution-calculator", "dose-escalation-button"] {
            XCTAssertFalse(app.buttons[identifier].exists)
        }
        for label in ["Concentration", "Dose in Units", "Half-life"] {
            XCTAssertFalse(app.staticTexts[label].exists)
        }

        app.buttons["edit-medication-profile"].tap()
        let amount = app.textFields["edit-prescribed-dose-input"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        recordEvidence("medical-release-edit-prescribed-amount")
        XCTAssertEqual(Double(amount.value as? String ?? ""), 1.375)
        XCTAssertFalse(app.buttons["edit-calculate-reconstitution"].exists)
        XCTAssertFalse(app.textFields["edit-vial-strength-input"].exists)
        replaceAmount(in: amount, with: "2.125", saveButton: app.buttons["edit-save-button"])
        app.buttons["edit-save-button"].tap()
        XCTAssertTrue(app.buttons["edit-medication-profile"].waitForExistence(timeout: 5))
        app.buttons["edit-medication-profile"].tap()
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        recordEvidence("medical-release-edited-exact-amount")
        XCTAssertEqual(Double(amount.value as? String ?? ""), 2.125)
        app.buttons["edit-cancel-button"].tap()

        app.terminate()
        app = TestUtilities.launchAppWithTestMode(resetData: false)
        navigateToMedications()
        openCreatedProfile()
        app.buttons["edit-medication-profile"].tap()
        let reloadedAmount = app.textFields["edit-prescribed-dose-input"]
        XCTAssertTrue(reloadedAmount.waitForExistence(timeout: 5))
        recordEvidence("medical-release-reloaded-prescribed-amount")
        XCTAssertEqual(Double(reloadedAmount.value as? String ?? ""), 2.125)
    }

    func testManualDailyScheduleAndQuickDoseHistoryKeepExactRecordedAmounts() {
        createCompoundedProfile()
        openCreatedProfile()
        let createSchedule = app.buttons["create-schedule-button"]
        XCTAssertTrue(createSchedule.waitForExistence(timeout: 5))
        createSchedule.tap()
        recordEvidence("medical-release-manual-schedule")
        XCTAssertFalse(app.buttons["Split Dose"].exists)
        XCTAssertFalse(app.staticTexts["Split Dose"].exists)
        let daily = app.buttons["Daily"]
        XCTAssertTrue(daily.waitForExistence(timeout: 5))
        daily.tap()
        app.buttons["save-schedule-edit"].tap()
        XCTAssertTrue(app.buttons["edit-schedule-button"].waitForExistence(timeout: 5))

        app.tabBars.buttons.element(boundBy: 0).tap()
        TestUtilities.openShortcutsSheet(app)
        app.buttons["shortcut-button-shots"].tap()
        let amount = app.textFields["quick-dose-prescribed-amount-input"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        recordEvidence("medical-release-quick-dose")
        XCTAssertFalse(app.steppers["quick-dose-amount-stepper"].exists)
        XCTAssertFalse(app.staticTexts["Therapeutic range"].exists)
        replaceAmount(in: amount, with: "0.375", saveButton: app.buttons["quick-dose-save-button"])
        let save = app.buttons["quick-dose-save-button"]
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertTrue(amount.waitForNonExistence(timeout: 5))

        openHistory()
        let row = app.buttons["dose-history-row"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()
        app.buttons["Edit"].tap()
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        recordEvidence("medical-release-history-edit")
        XCTAssertEqual(Double(amount.value as? String ?? ""), 0.375)
        replaceAmount(in: amount, with: "0.625", saveButton: app.buttons["quick-dose-save-button"])
        app.buttons["quick-dose-save-button"].tap()
        XCTAssertTrue(amount.waitForNonExistence(timeout: 5))
        row.swipeLeft()
        app.buttons["Edit"].tap()
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        recordEvidence("medical-release-history-edited-exact-amount")
        XCTAssertEqual(Double(amount.value as? String ?? ""), 0.625)
        app.buttons["quick-dose-cancel-button"].tap()
        app.terminate()
        app = TestUtilities.launchAppWithTestMode(resetData: false)
        openHistory()
        let reloadedRow = app.buttons["dose-history-row"].firstMatch
        XCTAssertTrue(reloadedRow.waitForExistence(timeout: 5))
        reloadedRow.swipeLeft()
        app.buttons["Edit"].tap()
        let reloadedAmount = app.textFields["quick-dose-prescribed-amount-input"]
        XCTAssertTrue(reloadedAmount.waitForExistence(timeout: 5))
        recordEvidence("medical-release-history-reloaded-exact-amount")
        XCTAssertEqual(Double(reloadedAmount.value as? String ?? ""), 0.625)
    }

    private func createCompoundedProfile() {
        navigateToMedications()
        app.buttons["add-medication-button"].tap()
        let amount = app.textFields["add-prescribed-dose-input"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        let compoundSwitch = app.switches["add-compounded-medication-toggle"].switches.firstMatch
        recordEvidence("medical-release-compound-switch-before-toggle")
        XCTAssertTrue(compoundSwitch.exists)
        compoundSwitch.tap()
        recordEvidence("medical-release-add-compounded-profile")
        XCTAssertEqual(compoundSwitch.value as? String, "1")
        XCTAssertFalse(app.buttons["add-calculate-reconstitution"].exists)
        XCTAssertFalse(app.textFields["add-vial-strength-input"].exists)
        XCTAssertFalse(app.buttons["add-dose-picker"].exists)
        replaceAmount(in: amount, with: "1.375", saveButton: app.buttons["save-medication-profile"])
        app.buttons["save-medication-profile"].tap()
        XCTAssertTrue(amount.waitForNonExistence(timeout: 5))
    }

    private func navigateToMedications() {
        TestUtilities.navigateToTab(app, tabName: "More")
        let programs = app.buttons["glp1-programs-row"]
        XCTAssertTrue(programs.waitForExistence(timeout: 5))
        programs.tap()
        let history = app.buttons["History"]
        XCTAssertTrue(history.waitForExistence(timeout: 5))
        recordEvidence("medical-release-history-default")
        XCTAssertTrue(history.isSelected)
        XCTAssertTrue(app.buttons["Adherence"].exists)
        XCTAssertFalse(app.buttons["Concentration"].exists)
        app.buttons["Medications"].tap()
        XCTAssertTrue(app.buttons["add-medication-button"].waitForExistence(timeout: 5))
    }

    private func openCreatedProfile() {
        let row = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH 'medication-profile-semaglutide-generic-'"
        )).firstMatch
        recordEvidence("before-profile-row-failure")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.buttons["edit-medication-profile"].waitForExistence(timeout: 5))
    }

    private func replaceAmount(in field: XCUIElement, with value: String, saveButton: XCUIElement) {
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        let previous = field.value as? String ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: previous.count))
        recordEvidence("medical-release-cleared-amount")
        XCTAssertEqual(field.value as? String, "")
        XCTAssertFalse(saveButton.isEnabled)
        field.typeText(value)
        recordEvidence("medical-release-entered-exact-amount")
        XCTAssertEqual(field.value as? String, value)
        XCTAssertTrue(saveButton.isEnabled)
    }

    private func openHistory() {
        TestUtilities.navigateToTab(app, tabName: "More")
        if app.buttons["edit-medication-profile"].exists {
            let back = app.navigationBars.buttons["BackButton"]
            recordEvidence("medical-release-return-from-profile")
            XCTAssertTrue(back.exists)
            back.tap()
        }
        if app.buttons["glp1-programs-row"].exists {
            app.buttons["glp1-programs-row"].tap()
        }
        let analytics = app.buttons["Analytics"]
        recordEvidence("medical-release-return-to-analytics")
        XCTAssertTrue(analytics.waitForExistence(timeout: 5))
        if !analytics.isSelected { analytics.tap() }
        let history = app.buttons["History"]
        recordEvidence("medical-release-return-to-history")
        XCTAssertTrue(history.waitForExistence(timeout: 5))
        history.tap()
    }

    private func recordEvidence(_ name: String) {
        TestUtilities.debugScreenshot(app, name: name)
        print(app.debugDescription)
    }
}
