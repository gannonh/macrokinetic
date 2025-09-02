import Foundation
@testable import JabTracker
import StoreKitTest
import Testing

@MainActor
@Suite("SubscriptionManager Restore Integration (StoreKitTest)")
struct SubscriptionManagerRestoreIntegrationTests {
    @Test("restorePurchases() completes and reports a message in non-test environment")
    func restorePurchasesWithStoreKitTest() async {
        // Attempt to start a StoreKit test session using the app's .storekit configuration
        // If configuration can't be loaded in this environment, we still exercise the path
        // and assert graceful behavior (no crash, valid status, message set when possible).
        var session: SKTestSession?
        do {
            session = try SKTestSession(configurationFileNamed: "JabTrackerStoreKit")
            session?.disableDialogs = true
            session?.resetToDefaultState()
            session?.clearTransactions()
        } catch {
            // Proceed without a session; the method should still behave without crashing
        }

        let manager = SubscriptionManager(isTestEnvironment: false)
        // Ensure a known starting point
        manager.subscriptionStatus = .notSubscribed

        await manager.restorePurchases()

        // Validate: no hard failure; status is valid; and we prefer a user-facing message over an error
        let valid: Set<AppSubscriptionStatus> = [.notSubscribed, .trialActive, .premiumActive, .expired]
        #expect(valid.contains(manager.subscriptionStatus))
        #expect(manager.errorMessage == nil, "restorePurchases should not set an error for the happy/empty path")
        // We accept either message depending on entitlement state and simulator session
        if let msg = manager.restoreMessage {
            #expect(["No purchases to restore", "Purchases restored"].contains(msg))
        } else {
            Issue.record("Expected a restoreMessage to be set by restorePurchases()")
        }

        // Tidy up
        session?.clearTransactions()
    }
}
