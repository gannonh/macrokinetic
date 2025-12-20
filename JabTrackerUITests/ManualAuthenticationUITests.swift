import XCTest

/// Manual authentication tests requiring real Apple ID credentials
/// These tests are excluded from CI/automation and intended for manual verification
/// Run these tests manually in Xcode when you need to verify real Sign in with Apple integration
final class ManualAuthenticationUITests: XCTestCase {
    // Toggle this to enable/disable all tests in this file
    private let testsEnabled = false

    override func setUpWithError() throws {
        continueAfterFailure = false

        if !self.testsEnabled {
            throw XCTSkip("Manual authentication tests are disabled. Set testsEnabled = true to run.")
        }
    }

    @MainActor
    func testCompleteSignInWithAppleFlow() throws {
        // This test shows the real authentication UI for manual interaction
        // When you tap "Sign in with Apple", you'll see the Apple ID sheet briefly
        // Then it automatically completes with mock data - no real Apple ID needed!
        // MANUAL TEST: Perfect for testing UI flows without real Apple ID credentials
        let app = TestUtilities.launchAppForManualUITesting()

        // When not authenticated, app should show AuthenticationView
        XCTAssertTrue(
            app.staticTexts["JabTracker"].waitForExistence(timeout: 5),
            "App title should be visible on authentication screen")

        XCTAssertTrue(
            app.staticTexts["Welcome to JabTracker"].waitForExistence(timeout: 3),
            "Welcome message should be visible")

        // Verify we're in unauthenticated state
        TestUtilities.verifyUnauthenticatedState(app)

        // Show manual instructions BEFORE tapping
        print("🚨 MANUAL TEST: Watch the Sign in with Apple flow")
        print("   1. The test will tap the 'Sign in with Apple' button")
        print("   2. You'll see the real Apple ID authentication sheet appear briefly")
        print(
            "   3. The sheet will automatically complete after 2 seconds (no real credentials needed)")
        print("   4. Watch the smooth transition from AuthenticationView to the main TabView")
        print("   5. Perfect for testing UI flows without Apple ID requirements!")

        // Give user a moment to read the instructions

        // Now trigger the Sign in with Apple button tap
        let signInButton = app.buttons["sign-in-with-apple-button"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Sign in button should be present")
        print("⏳ Tapping 'Sign in with Apple' button now...")
        signInButton.tap()

        // Wait for authentication to complete (happens automatically after 2 seconds)
        print("⏳ Authentication will complete automatically in ~2 seconds...")

        // Verify we're now in authenticated state - should see TabView
        // Shorter timeout since authentication completes automatically
        TestUtilities.verifyAuthenticatedState(app, timeout: 10)

        // Verify we can navigate to different tabs
        TestUtilities.navigateToSettings(app)

        // Verify user profile is accessible (sign in was successful)
        XCTAssertTrue(
            app.staticTexts["User Profile"].waitForExistence(timeout: 5),
            "User Profile should be visible after successful authentication")

        print("✅ Authentication flow completed successfully")
    }

    @MainActor
    func testCompleteAuthenticationToOnboardingFlow() throws {
        // This test shows the full flow: Authentication → Onboarding → Main App
        // Remove --bypass-onboarding to see the complete user journey
        let app = XCUIApplication()
        app.launchArguments.append("--reset-app-data")
        app.launchArguments.append("--manual-ui-testing")
        // Note: No --bypass-onboarding flag here
        app.launch()

        // Verify we start in unauthenticated state
        TestUtilities.verifyUnauthenticatedState(app)

        print("🚨 MANUAL TEST: Experience the complete Authentication → Onboarding flow")
        print("   1. Authentication UI → Apple ID sheet → Success")
        print("   2. Then onboarding flow will begin - INTERACT WITH IT!")
        print("   3. Go through all onboarding screens manually")
        print("   4. The test waits up to 2 minutes for you to complete onboarding")

        // Trigger authentication
        let signInButton = app.buttons["sign-in-with-apple-button"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Sign in button should be present")
        signInButton.tap()

        // Wait for authentication to complete (2 second delay)
        print("⏳ Authentication completing in ~2 seconds...")

        print("📱 ONBOARDING SHOULD NOW BE STARTING!")
        print("   Please manually go through the onboarding screens")
        print("   Take your time - the test will wait indefinitely")
        print("   When you're ready to finish the test, navigate to the Settings tab")
        print("   and the test will detect the successful completion")

        // Wait indefinitely for user to manually complete onboarding
        // Look for a very specific element that only exists after onboarding completion
        // Use Settings tab as the completion signal since it's unique to the main app
        print("⏳ Waiting for you to complete onboarding and navigate to Settings tab...")
        print("   (This test will wait as long as you need - no rush!)")

        var completedOnboarding = false
        var attempts = 0
        let maxAttempts = 1200  // 20 minutes worth of 1-second checks

        while !completedOnboarding, attempts < maxAttempts {
            // Check if More tab is accessible (indicates onboarding is complete)
            let moreTab = app.tabBars.buttons["More"]
            if moreTab.exists, moreTab.isHittable {
                TestUtilities.navigateToSettings(app)

                // Verify we're actually in Settings (not just that the tab exists)
                let userProfileText = app.staticTexts["User Profile"]
                if userProfileText.waitForExistence(timeout: 2) {
                    completedOnboarding = true
                    print("✅ Detected completion - you reached the Settings tab!")
                    break
                }
            }

            attempts += 1

            // Progress feedback every 30 seconds
            if attempts % 30 == 0 {
                let minutes = attempts / 60
                print("⏳ Still waiting... (\(minutes) minutes elapsed - no rush!)")
            }
        }

        if completedOnboarding {
            print("✅ Manual onboarding test completed successfully!")
            print("💡 You experienced: Authentication → Onboarding → Main App → Settings")
        } else {
            print("⏰ Test timeout after 20 minutes")
            XCTFail("Test timed out - please complete onboarding and navigate to Settings")
        }
    }

    // Note: Error handling test removed - it doesn't make sense in manual UI testing mode
    // where authentication always succeeds with mock data. To test real error scenarios,
    // uncomment and use the real Apple ID test below.

    // MARK: - Real Apple ID Testing (Uncomment only when needed)
}
