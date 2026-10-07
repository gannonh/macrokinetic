import XCTest

final class OnboardingLaunchUITests: XCTestCase {
    private enum PermissionChoice {
        case skip
        case denyAtSystemPrompt
    }

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    func testCompletionRetainsNutritionGoalProfileAndLogAfterRelaunch() {
        launchFirstRunWithTestAuthentication()
        completeNutritionSetupWithSkippedPermissions()
        verifyNutritionGoal()
        verifyProfile()
        logManualCalories()

        relaunchWithoutResetSeedOrOnboardingOverrides()
        verifyNutritionGoal()
        verifyProfile()
        verifyManualCalories()
        capture("onboarding-completion-relaunched")
    }

    func testExplicitSkipRetainsNoGoalAndManualLogAfterRelaunch() {
        launchFirstRunWithTestAuthentication()
        advanceToGoalTypeWithoutHealthKit()
        confirmSkip()
        verifyNoGoal()
        logManualCalories()

        relaunchWithoutResetSeedOrOnboardingOverrides()
        verifyNoGoal()
        verifyManualCalories()
        capture("onboarding-skip-relaunched")
    }

    func testCancelSkipKeepsGoalSetupAndHiddenRoutesAbsent() {
        launchFirstRunWithTestAuthentication()
        advanceToGoalTypeWithoutHealthKit()
        tap("onboarding-skip-button")
        let confirmation = app.alerts["Skip Goal Setup?"]
        check(confirmation.waitForExistence(timeout: 3), "Explicit skip should require its confirmation")
        capture("onboarding-skip-confirmation")
        confirmation.buttons["Cancel"].tap()
        step("onboarding-goalType-step")
        check(!app.tabBars.firstMatch.exists, "Cancel should retain setup instead of entering the app")
        capture("onboarding-skip-canceled")
    }

    func testSkippedPermissionsLeaveSettingsRecoveryRoutesReachable() {
        launchFirstRunWithTestAuthentication()
        completeNutritionSetupWithSkippedPermissions()
        tab("More")
        verifyHiddenMoreRoutes()
        tap("security-privacy-row")
        check(element("security-privacy-view").waitForExistence(timeout: 5), "Security settings should open")
        let health = element("health-toggle")
        check(health.waitForExistence(timeout: 3), "Health integration should remain available in settings")
        capture("onboarding-permissions-settings")
        tap(app.navigationBars.buttons.firstMatch, name: "security-settings-back")
        tap("notifications-row")
        check(element("notification-settings-view").waitForExistence(timeout: 5), "Notification settings should open")
        check(app.switches["weigh-in-daily-toggle"].exists, "Manual weigh-in reminders should remain configurable")
        capture("onboarding-notifications-settings")
        tab("Food Log")
        logManualCalories()
    }

    func testDeniedSystemPromptsForHealthKitAndNotificationsLeaveNutritionUsable() {
        launchFirstRunWithTestAuthentication()
        completeNutritionSetupWithSkippedPermissions(healthKit: .denyAtSystemPrompt, notifications: .denyAtSystemPrompt)
        verifyNutritionGoal()
        logManualCalories()

        tab("More")
        tap("notifications-row")
        check(element("notification-settings-view").waitForExistence(timeout: 5), "Notification settings should open after denial")
        capture("onboarding-notifications-denied-settings")
        // After a real denial the status row reads "Not Configured" in this test-authenticated launch, so the
        // system Settings button is not asserted here; re-grant through iOS Settings stays an open gap.
        check(app.switches["weigh-in-daily-toggle"].exists, "Manual weigh-in reminders should remain configurable")

        relaunchWithoutResetSeedOrOnboardingOverrides()
        verifyNutritionGoal()
        verifyManualCalories()
    }

    private func launchFirstRunWithTestAuthentication() {
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data", "--force-onboarding", "--disable-cloudkit"]
        app.launchEnvironment = ["UI_TESTING": "true", "TEST_DATA_SEED": "false"]
        app.launch()
        step("onboarding-welcome-step")
        capture("onboarding-test-auth-welcome")
    }

    private func relaunchWithoutResetSeedOrOnboardingOverrides() {
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["--disable-cloudkit"]
        app.launchEnvironment = ["UI_TESTING": "false", "TEST_DATA_SEED": "false"]
        app.launch()
        waitForNutritionApp()
        check(!element("onboarding-view").exists, "Saved completion or skip should prevent repeated onboarding")
        check(!app.buttons["sign-in-with-apple-button"].exists, "This saved fictional account should restore")
    }

    private func advanceToGoalTypeWithoutHealthKit(healthKit: PermissionChoice = .skip) {
        tap("onboarding-continue-button")
        step("onboarding-usp-showcase-step")
        tap("onboarding-continue-button")
        step("onboarding-healthkit-step")
        if healthKit == .denyAtSystemPrompt {
            denyAtSystemPrompt(toggle: "healthkit-toggle", name: "healthkit")
        }
        verifyPermissionIsOffOrUnavailable("healthkit-toggle", unavailable: "Apple Health Not Available")
        capture("onboarding-healthkit-skipped")
        tap("onboarding-continue-button")
        step("onboarding-goalType-step")
    }

    private func completeNutritionSetupWithSkippedPermissions(
        healthKit: PermissionChoice = .skip, notifications: PermissionChoice = .skip
    ) {
        advanceToGoalTypeWithoutHealthKit(healthKit: healthKit)
        tap("goal-wizard-goalType-maintenance")
        tap("onboarding-continue-button")
        step("onboarding-targetWeight-step")
        tap("onboarding-continue-button")
        step("onboarding-profileCompletion-step")
        let male = app.buttons.matching(
            NSPredicate(
                format: "identifier IN %@ AND label == %@",
                ["onboarding-sex-male", "onboarding-profile-sex"], "Male"
            )
        ).firstMatch
        tap(male, name: "onboarding-profile-male")
        tap("onboarding-continue-button")
        step("onboarding-programStyle-step")
        check(!app.buttons["program-wizard-programStyle-manual"].exists, "Unfinished Manual onboarding should stay hidden")
        tap("program-wizard-programStyle-coached")
        tap("onboarding-continue-button")

        for (stepID, selectionID) in [
            ("dietPreference", "program-wizard-dietPreference-balanced"),
            ("calorieFloor", "program-wizard-calorieFloor-standard"),
            ("activityLevel", "program-wizard-training-none"),
            ("weeklyDistribution", "program-wizard-weeklyDistribution-even"),
            ("proteinLevel", "program-wizard-proteinLevel-moderate"),
        ] {
            step("onboarding-\(stepID)-step")
            tap(selectionID)
            tap("onboarding-continue-button")
        }

        step("onboarding-setupConfirmation-step", timeout: 10)
        capture("onboarding-nutrition-setup-confirmation")
        tap("onboarding-continue-button")
        step("onboarding-faceid-step")
        verifyPermissionIsOffOrUnavailable("faceid-toggle", unavailable: "Biometrics Not Available")
        capture("onboarding-biometrics-skipped")
        tap("onboarding-continue-button")
        step("onboarding-notifications-step")
        if notifications == .denyAtSystemPrompt {
            denyAtSystemPrompt(toggle: "notifications-toggle", name: "notifications")
        }
        verifyPermissionIsOffOrUnavailable("notifications-toggle", unavailable: nil)
        capture("onboarding-notifications-skipped")
        tap("onboarding-continue-button")
        step("onboarding-completion-step")
        check(labeled("Goal: Maintain Weight").exists, "Completion should describe the selected nutrition goal")
        check(labeled("Program Style: Coached").exists, "Completion should describe the selected program")
        capture("onboarding-nutrition-completion")
        tap("onboarding-complete-button")
        waitForNutritionApp()
    }

    private func confirmSkip() {
        tap("onboarding-skip-button")
        let confirmation = app.alerts["Skip Goal Setup?"]
        check(confirmation.waitForExistence(timeout: 3), "Skip should show the explicit choice")
        check(
            confirmation.staticTexts["You can set up your nutrition goal later from the Strategy tab."].exists,
            "Skip should explain how to set up a goal later"
        )
        capture("onboarding-explicit-skip")
        confirmation.buttons["Skip for Now"].tap()
        waitForNutritionApp()
    }

    /// Turns a permission toggle on and answers the real system prompt with Don't Allow.
    /// Skips nothing: a missing prompt fails with both hierarchies printed.
    private func denyAtSystemPrompt(toggle identifier: String, name: String) {
        let toggle = app.switches[identifier]
        guard toggle.waitForExistence(timeout: 5) else {
            if app.staticTexts["Apple Health Not Available"].exists {
                capture("onboarding-\(name)-unavailable-no-prompt")
            }
            check(false, "\(identifier) should exist to request the system prompt")
            return
        }
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let denial = NSPredicate(format: "label BEGINSWITH[c] 'Don' AND label CONTAINS[c] 'Allow'")
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deadline = Date().addingTimeInterval(45)
        while Date() < deadline {
            for host in [springboard, app!] {
                let button = host.buttons.matching(denial).firstMatch
                if button.exists {
                    capture("onboarding-\(name)-system-prompt")
                    // The Health Access sheet lists its Don't Allow button below the topic toggles.
                    for _ in 0..<8 where !button.isHittable {
                        host.swipeUp()
                    }
                    capture("onboarding-\(name)-system-prompt-denial")
                    button.tap()
                    // Health confirms a denial with "You can turn on health data categories later".
                    let acknowledge = host.alerts.buttons["OK"]
                    if acknowledge.waitForExistence(timeout: 3) {
                        capture("onboarding-\(name)-denial-acknowledged")
                        acknowledge.tap()
                    }
                    check(
                        toggle.waitForExistence(timeout: 5),
                        "\(identifier) should return after the system prompt is denied"
                    )
                    return
                }
            }
            usleep(500_000)
        }
        print("SPRINGBOARD:", springboard.debugDescription)
        check(false, "No system permission prompt appeared for \(identifier)")
    }

    private func verifyPermissionIsOffOrUnavailable(_ identifier: String, unavailable: String?) {
        let toggle = app.switches[identifier]
        if toggle.exists {
            check(toggle.value as? String == "0", "\(identifier) should remain off when permission is skipped")
        } else if let unavailable {
            check(app.staticTexts[unavailable].exists, "Missing permission toggle should show its unavailable state")
        } else {
            check(false, "\(identifier) should exist")
        }
    }

    private func verifyNutritionGoal() {
        tab("Strategy")
        check(app.staticTexts["Maintenance Goal"].waitForExistence(timeout: 5), "The maintenance goal should be retained")
        check(app.staticTexts["Coached Program"].exists, "The selected program should be retained")
        check(!app.buttons["create-goal-button"].exists, "Completion should retain the existing goal")
        check(
            app.staticTexts.matching(NSPredicate(format: "label == %@", "Maintenance Goal")).count == 1,
            "Only one active goal should be displayed"
        )
        capture("onboarding-retained-nutrition-goal")
    }

    private func verifyNoGoal() {
        tab("Strategy")
        check(app.buttons["create-goal-button"].waitForExistence(timeout: 5), "Skip should leave goal creation available")
        check(app.staticTexts["No Active Goal"].exists, "Skip should leave an explicit empty goal state")
        check(!element("current-program-card").exists, "Skip should not create a program")
    }

    private func verifyProfile() {
        tab("More")
        verifyHiddenMoreRoutes()
        tap("profile-link")
        check(element("account-view").waitForExistence(timeout: 5), "The saved profile should open")
        check(app.staticTexts["UI Test User"].exists, "The original fictional profile name should remain")
        check(element("sex-row").staticTexts["Male"].exists, "Manual biological sex should remain saved")
        check(element("height-row").staticTexts["5' 7\""].exists, "Onboarding profile height should remain saved")
        capture("onboarding-retained-profile")
        tap(app.navigationBars.buttons.firstMatch, name: "profile-back")
    }

    private func verifyHiddenMoreRoutes() {
        for identifier in [
            "subscription-row", "dashboard-settings-placeholder", "food-log-placeholder", "shortcuts-placeholder",
            "faq-placeholder", "help-support-placeholder",
        ] {
            check(!element(identifier).exists, "Unfinished route \(identifier) should stay hidden")
        }
    }

    private func logManualCalories() {
        tab("Food Log")
        tap("add-button")
        let quickAdd = app.buttons["Quick Add"]
        check(quickAdd.waitForExistence(timeout: 5), "Manual Quick Add should remain available")
        check(!app.buttons["AI"].exists, "Unfinished AI food capture should stay hidden")
        check(!app.buttons["Progress Photos"].exists, "Unfinished photo capture should stay hidden")
        tap(quickAdd, name: "Quick Add")
        let energy = app.textFields["quick-add-energy-input"]
        check(energy.waitForExistence(timeout: 5), "Manual nutrition entry should work without permissions")
        energy.tap()
        energy.typeText("100")
        tap("quick-add-add-button")
        check(element("food-search-sheet").waitForNonExistence(timeout: 5), "The entry should save and dismiss")
        verifyManualCalories()
        capture("onboarding-manual-nutrition-logged")
    }

    private func verifyManualCalories() {
        tab("Food Log")
        let rows = app.buttons.matching(identifier: "food-entry-row")
        check(rows.firstMatch.waitForExistence(timeout: 5), "The manual food entry should remain")
        check(rows.count == 1, "The single manual food entry should not be duplicated")
        check(rows.firstMatch.label.contains("Quick Add"), "The retained entry should be the manual Quick Add")
        let total = app.staticTexts.matching(identifier: "macro-consumed-cal").firstMatch
        check(total.waitForExistence(timeout: 3), "Consumed calories should be shown")
        check(total.label.hasPrefix("100/"), "The retained manual entry should contribute exactly 100 calories")
    }

    private func waitForNutritionApp() {
        check(app.tabBars.firstMatch.waitForExistence(timeout: 5), "Nutrition should be usable without a medication or purchase")
        check(app.tabBars.buttons["Food Log"].exists, "Food logging should be available")
        check(app.tabBars.buttons["Strategy"].exists, "Nutrition goals should be available")
    }

    private func step(_ identifier: String, timeout: TimeInterval = 5) {
        check(element(identifier).waitForExistence(timeout: timeout), "Expected \(identifier)")
        for hidden in ["medication-selection-view", "subscription-view"] {
            check(!element(hidden).exists, "Onboarding should not require \(hidden)")
        }
    }

    private func tab(_ title: String) {
        tap(app.tabBars.buttons[title], name: "tab-\(title)")
    }

    private func tap(_ identifier: String) {
        tap(app.buttons[identifier], name: identifier)
    }

    private func tap(_ button: XCUIElement, name: String) {
        _ = button.waitForExistence(timeout: 5)
        for _ in 0..<4 where !button.isHittable {
            app.swipeUp()
        }
        check(button.exists, "Expected button \(name)")
        check(button.isEnabled, "Button \(name) should be enabled")
        if button.isHittable {
            button.tap()
        } else {
            // Intermittent: on the Choose Your Goal step "onboarding-skip-button" reports isHittable == false
            // in roughly 1 of 3 runs while idle, enabled and unobstructed (no keyboard, sheet or animation in
            // the captured screenshot and tree, even after a 3 s hittable wait). It passes on rerun with no
            // code change. Tap the on-screen center instead of failing on the accessibility flag.
            check(app.windows.firstMatch.frame.contains(button.frame), "Button \(name) should be on screen")
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func labeled(_ label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    private func check(_ condition: Bool, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        if !condition {
            capture("before-onboarding-failure")
        }
        XCTAssertTrue(condition, message, file: file, line: line)
    }

    private func capture(_ name: String) {
        TestUtilities.debugScreenshot(app, name: name)
        print(app.debugDescription)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
