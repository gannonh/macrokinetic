import Foundation
import Testing

@testable import JabTracker

@MainActor
@Suite("SubscriptionManager Restore Integration")
struct SubscriptionRestoreIntegrationTests {
    @Test("restorePurchases() completes and reports a message")
    func restorePurchasesCompletesWithMessage() async {
        #if DEBUG
            // Force unit-test mode to guarantee no App Store UI is invoked.
            SubscriptionManager.testModeOverride = .unit
            defer { SubscriptionManager.testModeOverride = nil }
        #endif

        let manager = SubscriptionManager(isTestEnvironment: false)
        // Ensure a known starting point
        manager.subscriptionStatus = .notSubscribed

        await manager.restorePurchases()

        // Validate: no hard failure; status is valid; and we prefer a user-facing message over an error
        let valid: Set<AppSubscriptionStatus> = [
            .notSubscribed, .trialActive, .premiumActive, .expired,
        ]
        #expect(valid.contains(manager.subscriptionStatus))
        #expect(
            manager.errorMessage == nil,
            "restorePurchases should not set an error for the happy/empty path")
        // We accept either message depending on entitlement state and simulator session
        if let msg = manager.restoreMessage {
            #expect(["No purchases to restore", "Purchases restored"].contains(msg))
        } else {
            Issue.record("Expected a restoreMessage to be set by restorePurchases()")
        }
    }
}
