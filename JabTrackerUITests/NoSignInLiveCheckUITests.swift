import XCTest

/// KAT-3586 live checks. These launch the app the way a user's phone does (no `--ui-testing`) against an
/// on-disk store that `docs/launch-evidence/KAT-3586/live-checks.sh` prepares first, so they skip otherwise.
final class NoSignInLiveCheckUITests: XCTestCase {
    private var environment: [String: String] { ProcessInfo.processInfo.environment }

    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipUnless(environment["KAT3586_LIVE"] == "1", "Run via docs/launch-evidence/KAT-3586/live-checks.sh")
    }

    private func launch(biometricLock: Bool? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--disable-cloudkit"]
        if let biometricLock {
            app.launchArguments += ["-biometricAuthEnabled", biometricLock ? "YES" : "NO"]
        }
        app.launch()
        return app
    }

    private func attach(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func assertNoSignIn(_ app: XCUIApplication) {
        XCTAssertFalse(app.buttons["sign-in-with-apple-button"].exists, "No Sign in with Apple button")
        XCTAssertFalse(app.buttons["Sign in with Apple"].exists, "No Sign in with Apple button by label")
        XCTAssertFalse(app.staticTexts["Sign in with Apple"].exists, "No Sign in with Apple text")
    }

    /// The lock screen's `lock-screen-view` identifier propagates to every child, so match its text instead.
    private func lockScreen(_ app: XCUIApplication) -> XCUIElement {
        app.staticTexts["Unlock to access your health data"]
    }

    private func has(_ app: XCUIApplication, label: String) -> Bool {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch.exists
    }

    private func openAccount(_ app: XCUIApplication) {
        let more = app.tabBars.buttons["More"]
        XCTAssertTrue(more.waitForExistence(timeout: 5))
        more.tap()
        let link = app.buttons["profile-link"]
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        link.tap()
        XCTAssertTrue(app.descendants(matching: .any)["account-view"].waitForExistence(timeout: 5))
    }

    /// Scenarios 1, 3, 4, 5, 6, 9: upgrade (signed in / signed out / erased Apple ID) opens straight into the app.
    func testUpgradeOpensStraightIntoApp() throws {
        let app = launch(biometricLock: false)
        XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 20), "Tab bar: app opened with no sign-in")
        XCTAssertFalse(app.otherElements["onboarding-view"].exists, "Onboarding must not reappear")
        assertNoSignIn(app)
        attach("app-opened-without-sign-in", app)

        openAccount(app)
        XCTAssertFalse(app.buttons["log-out-button"].exists, "No Log Out button")
        XCTAssertFalse(app.staticTexts["Log Out"].exists, "No Log Out text")
        XCTAssertTrue(
            has(app, label: "Your data is stored on this iPhone. Deleting the app removes it."),
            "On-device storage note")
        if let name = environment["KAT3586_EXPECT_NAME"] {
            XCTAssertTrue(has(app, label: name), "Account shows \(name)")
        }
        attach("account-no-logout", app)
    }

    /// Scenario 2: fresh install goes to onboarding.
    func testFreshInstallReachesOnboarding() throws {
        let app = launch(biometricLock: false)
        XCTAssertTrue(app.otherElements["onboarding-view"].waitForExistence(timeout: 20), "Onboarding shown")
        assertNoSignIn(app)
        attach("fresh-install-onboarding", app)
    }

    /// Scenario 7a: lock on, relaunch is locked.
    func testLockOnRelaunchIsLocked() throws {
        let app = launch(biometricLock: true)
        XCTAssertTrue(lockScreen(app).waitForExistence(timeout: 20), "Lock screen on relaunch")
        attach("lock-on-relaunch", app)
    }

    /// Scenario 7b: the system biometric sheet is cancelled / does not match, and the app stays locked.
    func testLockStaysLockedWhenBiometricsFail() throws {
        let app = launch(biometricLock: true)
        XCTAssertTrue(lockScreen(app).waitForExistence(timeout: 20))
        app.buttons["Unlock with Face ID"].tap()
        sleep(4)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.buttons["Cancel"].firstMatch.exists { springboard.buttons["Cancel"].firstMatch.tap() }
        XCTAssertTrue(lockScreen(app).waitForExistence(timeout: 5), "Still locked")
        attach("lock-still-locked-after-cancel", app)
    }

    /// Scenario 7c: a matching face unlocks, and returning from the background locks again.
    func testLockUnlocksOnMatchAndRelocksFromBackground() throws {
        let app = launch(biometricLock: true)
        XCTAssertTrue(lockScreen(app).waitForExistence(timeout: 20))
        app.buttons["Unlock with Face ID"].tap()
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 15))
        XCTAssertFalse(lockScreen(app).exists, "Unlocked after match")
        attach("lock-unlocked-after-match", app)
        XCUIDevice.shared.press(.home)
        sleep(2)
        app.activate()
        XCTAssertTrue(lockScreen(app).waitForExistence(timeout: 10), "Locked after background")
        attach("lock-relocked-after-background", app)
    }

    /// Scenario 8: lock off, relaunch opens directly.
    func testLockOffRelaunchOpensDirectly() throws {
        let app = launch(biometricLock: false)
        XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 20))
        XCTAssertFalse(lockScreen(app).exists, "No lock screen when the lock is off")
        attach("lock-off-opens-directly", app)
    }
}
