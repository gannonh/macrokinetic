import XCTest

/// KAT-3601 live checks. They launch the app the way a user's phone does (no `--ui-testing`, real
/// notification permission) against a store `docs/launch-evidence/KAT-3601/live-checks.sh` seeds first,
/// which also reads the simulator's pending notification requests between steps. They skip otherwise.
final class DoseReminderLiveCheckUITests: XCTestCase {
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["KAT3601_LIVE"] == "1",
            "Run via docs/launch-evidence/KAT-3601/live-checks.sh")
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--dump-pending-notifications"]
        app.launch()
        XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 20), "App opened")
        return app
    }

    private func attach(_ name: String, _ screen: XCUIScreenshot) {
        let attachment = XCTAttachment(screenshot: screen)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func openProfile(_ app: XCUIApplication) {
        TestUtilities.navigateToTab(app, tabName: "More")
        let programs = app.buttons["glp1-programs-row"]
        XCTAssertTrue(programs.waitForExistence(timeout: 5))
        programs.tap()
        let medications = app.segmentedControls.buttons["Medications"]
        XCTAssertTrue(medications.waitForExistence(timeout: 5))
        medications.tap()
        let profile = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "medication-profile-liraglutide-victoza")
        ).firstMatch
        XCTAssertTrue(profile.waitForExistence(timeout: 5))
        profile.tap()
    }

    private func openNotificationSettings(_ app: XCUIApplication) {
        TestUtilities.navigateToTab(app, tabName: "More")
        let row = app.buttons["notifications-row"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
    }

    private func createSchedule(_ app: XCUIApplication) {
        let create = app.buttons["create-schedule-button"]
        XCTAssertTrue(create.waitForExistence(timeout: 5), "No schedule yet")
        create.tap()
        let daily = app.buttons.matching(identifier: "pattern-picker").matching(
            NSPredicate(format: "label == %@", "Daily")
        ).firstMatch
        XCTAssertTrue(daily.waitForExistence(timeout: 5))
        daily.tap()
        let save = app.buttons["save-schedule-edit"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()
        if !app.buttons["edit-schedule-button"].waitForExistence(timeout: 8) {
            attach("schedule-not-saved", app.screenshot())
            print(app.debugDescription)
            XCTFail("Schedule saved")
        }
    }

    private func doseReminderToggle(_ app: XCUIApplication) -> XCUIElement {
        let toggle = app.switches["dose-reminder-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        return toggle
    }

    private func isOn(_ toggle: XCUIElement) -> Bool { (toggle.value as? String) == "1" }

    /// XCTest kills the app at the end of a test; going Home first lets UserDefaults reach disk.
    private func settle() {
        XCUIDevice.shared.press(.home)
        sleep(3)
    }

    private func waitUntilOn(_ toggle: XCUIElement, timeout: TimeInterval) -> Bool {
        let on = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == '1'"), object: toggle)
        return XCTWaiter().wait(for: [on], timeout: timeout) == .completed
    }

    /// Switches render their tappable control at the trailing edge.
    private func flip(_ toggle: XCUIElement) {
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
    }

    private func answerPermissionAlert(_ button: String) {
        let alertButton = springboard.alerts.buttons[button]
        XCTAssertTrue(alertButton.waitForExistence(timeout: 10), "System permission alert shows \(button)")
        alertButton.tap()
    }

    /// Check 1 (main and branch), check 3 setup: daily schedule, then turn dose reminders on and allow.
    func testCreateDailyScheduleAndAllowReminders() throws {
        let app = launch()
        openProfile(app)
        createSchedule(app)

        openNotificationSettings(app)
        let toggle = doseReminderToggle(app)
        XCTAssertFalse(isOn(toggle))
        flip(toggle)
        answerPermissionAlert("Allow")
        XCTAssertTrue(isOn(doseReminderToggle(app)), "Dose reminders on")
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Enabled"].waitForExistence(timeout: 10), "Permission granted")
        sleep(3)  // let the queue refresh finish before the script reads it
        attach("reminders-on", app.screenshot())
        settle()
    }

    /// Check 1 (main): relaunch, then turn dose reminders off and on again.
    func testTurnRemindersOffAndOn() throws {
        let app = launch()
        openNotificationSettings(app)
        let toggle = doseReminderToggle(app)
        XCTAssertTrue(isOn(toggle))
        flip(toggle)
        XCTAssertFalse(isOn(doseReminderToggle(app)))
        flip(doseReminderToggle(app))
        XCTAssertTrue(isOn(doseReminderToggle(app)), "Dose reminders on")
        sleep(3)
        attach("reminders-toggled", app.screenshot())
        settle()
    }

    /// Check 2: pausing the schedule from its profile replaces the pending reminders.
    func testPauseScheduleForAWeek() throws {
        let app = launch()
        openProfile(app)
        app.buttons["pause-schedule-button"].tap()
        let confirm = app.buttons["pause-confirm-button"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertTrue(app.buttons["resume-schedule-button"].waitForExistence(timeout: 5), "Schedule paused")
        sleep(3)
        attach("paused", app.screenshot())
    }

    /// Check 2: resuming restores the full queue.
    func testResumeSchedule() throws {
        let app = launch()
        openProfile(app)
        app.buttons["resume-schedule-button"].tap()
        XCTAssertTrue(app.buttons["pause-schedule-button"].waitForExistence(timeout: 5), "Schedule resumed")
        sleep(3)
        attach("resumed", app.screenshot())
    }

    /// Check 2: send the running app to the background and bring it back.
    func testBackgroundAndForeground() throws {
        let app = launch()
        XCUIDevice.shared.press(.home)
        sleep(3)
        app.activate()
        XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 10), "App foregrounded")
        sleep(3)
    }

    /// Check 3: the script delivers a dose reminder while this waits on the Home Screen; tap its banner.
    func testTapDeliveredReminderOpensItsDose() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--dump-pending-notifications"]
        XCUIDevice.shared.press(.home)
        let token = try XCTUnwrap(ProcessInfo.processInfo.environment["KAT3601_PUSH_TOKEN"], "Push body token")
        let reminder = springboard.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", token)).firstMatch
        XCTAssertTrue(reminder.waitForExistence(timeout: 60), "Delivered reminder banner")
        attach("reminder-banner", springboard.screenshot())
        reminder.tap()

        let sheet = app.descendants(matching: .any)["quick-dose-sheet"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 20), "Tapping the reminder opens the dose sheet")
        sleep(2)
        XCTAssertFalse(
            app.descendants(matching: .any)["quick-dose-view-model-error"].exists,
            "The reminder's scheduled dose was found")
        XCTAssertEqual(app.textFields["quick-dose-prescribed-amount-input"].value as? String, "0.6")
        attach("dose-sheet", app.screenshot())
    }

    /// Check 4: deny permission, recover from Settings, then turn dose reminders on.
    func testDeniedPermissionRecoversFromSettings() throws {
        let app = launch()
        openProfile(app)
        createSchedule(app)

        openNotificationSettings(app)
        flip(doseReminderToggle(app))
        answerPermissionAlert("Don’t Allow")
        let ok = app.alerts.buttons["OK"]
        if ok.waitForExistence(timeout: 5) { ok.tap() }
        XCTAssertFalse(isOn(doseReminderToggle(app)), "Dose reminders stay off while denied")
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Disabled"].waitForExistence(timeout: 10), "Status shows Disabled")
        attach("denied", app.screenshot())

        app.buttons["notification-settings-button"].tap()
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 10), "iOS Settings opened")
        var allow = settings.switches["Allow Notifications"]
        if !allow.waitForExistence(timeout: 5) {
            print("KAT3601 Settings opened at root; tapping the app's Settings button again")
            app.activate()
            app.buttons["notification-settings-button"].tap()
            XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 10))
        }
        if !allow.waitForExistence(timeout: 5) {
            print("KAT3601 Settings still at root; navigating Apps > MacroKinetic > Notifications")
            // The Settings root can still be loading, and Apps sits several screens down
            let apps = settings.staticTexts["Apps"].firstMatch
            for _ in 0..<8 where !apps.isHittable {
                settings.swipeUp()
            }
            apps.tap()
            let appRow = settings.staticTexts["MacroKinetic"].firstMatch
            XCTAssertTrue(appRow.waitForExistence(timeout: 10))
            appRow.tap()
            settings.staticTexts["Notifications"].firstMatch.tap()
            allow = settings.switches["Allow Notifications"]
        }
        XCTAssertTrue(allow.waitForExistence(timeout: 10), "App's notification settings opened")
        attach("ios-settings-before", settings.screenshot())
        flip(allow)
        if !waitUntilOn(allow, timeout: 3) { allow.tap() }
        XCTAssertTrue(waitUntilOn(allow, timeout: 5), "Notifications allowed in iOS Settings")
        attach("ios-settings-after", settings.screenshot())

        app.activate()
        XCTAssertTrue(app.staticTexts["Enabled"].waitForExistence(timeout: 10), "Status shows Enabled on return")
        app.swipeDown()
        flip(doseReminderToggle(app))
        XCTAssertTrue(isOn(doseReminderToggle(app)), "Dose reminders on after recovery")
        sleep(3)
        attach("recovered", app.screenshot())
        settle()
    }
}
