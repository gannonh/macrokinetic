import Foundation
@testable import JabTracker
import Testing

@MainActor
@Suite("SubscriptionManager Additional Coverage")
struct SubscriptionManagerMoreTests {
    @Test("isTrialActive reflects current status")
    func isTrialActiveReflectsStatus() async {
        let manager = SubscriptionManager(isTestEnvironment: true)
        manager.subscriptionStatus = .notSubscribed
        #expect(manager.isTrialActive() == false)
        manager.subscriptionStatus = .trialActive
        #expect(manager.isTrialActive() == true)
        manager.subscriptionStatus = .premiumActive
        #expect(manager.isTrialActive() == false)
        manager.subscriptionStatus = .expired
        #expect(manager.isTrialActive() == false)
    }

    @Test("monthlyProducts returns empty when no products available")
    func monthlyProductsEmpty() async {
        let manager = SubscriptionManager(isTestEnvironment: true)
        // availableProducts is empty by default
        #expect(manager.monthlyProducts().isEmpty)
    }

    @Test("annualProducts returns empty when no products available")
    func annualProductsEmpty() async {
        let manager = SubscriptionManager(isTestEnvironment: true)
        // availableProducts is empty by default
        #expect(manager.annualProducts().isEmpty)
    }

    @Test("checkSubscriptionStatus does not change state in test env")
    func checkSubscriptionStatusNoopInTestEnv() async {
        let manager = SubscriptionManager(isTestEnvironment: true)
        manager.subscriptionStatus = .premiumActive
        await manager.checkSubscriptionStatus()
        #expect(manager.subscriptionStatus == .premiumActive)
    }

    @Test("restorePurchases in test env returns immediate message")
    func restorePurchasesInTestEnv() async {
        let manager = SubscriptionManager(isTestEnvironment: true)
        manager.subscriptionStatus = .notSubscribed
        await manager.restorePurchases()
        #expect(manager.restoreMessage == "No purchases to restore")
        #expect(manager.errorMessage == nil)
    }

    @Test("purchase(productId:) with unknown id throws productNotFound")
    func purchaseProductIdNotFoundThrows() async {
        let manager = SubscriptionManager(isTestEnvironment: true)
        do {
            try await manager.purchase(productId: "non.existent.product")
            Issue.record("Expected to throw, but did not")
        } catch {
            #expect(error is SubscriptionError)
            if case SubscriptionError.productNotFound = error {
                // expected
            } else {
                Issue.record("Expected productNotFound, got: \(error)")
            }
        }
    }

    @Test("SubscriptionError descriptions are user-friendly")
    func subscriptionErrorDescriptions() {
        #expect(SubscriptionError.productNotFound.errorDescription == "Subscription product not found")
        #expect(SubscriptionError.purchaseFailed("X").errorDescription == "Purchase failed: X")
        #expect(SubscriptionError.restoreFailed("Y").errorDescription == "Restore failed: Y")
        #expect(SubscriptionError.verificationFailed.errorDescription == "Purchase verification failed")
        #expect(SubscriptionError.networkError.errorDescription == "Network error occurred")
    }

    @Test("trialDaysRemaining returns 0 when past trial end date")
    func trialDaysRemainingExpired() {
        let manager = SubscriptionManager(isTestEnvironment: true)
        manager.subscriptionStatus = .trialActive
        let purchase = Date().addingTimeInterval(-40 * 24 * 60 * 60)
        let remaining = manager.trialDaysRemaining(purchaseDate: purchase, asOf: Date())
        #expect(remaining == 0)
    }

    @Test("evaluateStatus empty array -> notSubscribed")
    func evaluateStatusEmpty() {
        let status = SubscriptionManager.evaluateStatus(from: [], now: Date())
        #expect(status == .notSubscribed)
    }

    @Test("_evaluateStatusForTests covers trial, premium, expired branches")
    func evaluateStatusBranches() {
        let now = Date()
        let trialPurchase = now.addingTimeInterval(-3 * 24 * 60 * 60)
        let premiumPurchase = now.addingTimeInterval(-40 * 24 * 60 * 60)
        let premiumExpiration = now.addingTimeInterval(10 * 24 * 60 * 60)
        let expiredPurchase = now.addingTimeInterval(-60 * 24 * 60 * 60)
        let expiredExpiration = now.addingTimeInterval(-1 * 24 * 60 * 60)

        // Trial
        let trial = SubscriptionManager.EvalInputTest(
            productType: .autoRenewable,
            purchaseDate: trialPurchase,
            expirationDate: premiumExpiration)
        #expect(SubscriptionManager.evaluateStatusForTests(from: [trial], now: now) == .trialActive)

        // Premium (outside trial, not expired)
        let premium = SubscriptionManager.EvalInputTest(
            productType: .autoRenewable,
            purchaseDate: premiumPurchase,
            expirationDate: premiumExpiration)
        #expect(SubscriptionManager.evaluateStatusForTests(from: [premium], now: now) == .premiumActive)

        // Expired
        let expired = SubscriptionManager.EvalInputTest(
            productType: .autoRenewable,
            purchaseDate: expiredPurchase,
            expirationDate: expiredExpiration)
        #expect(SubscriptionManager.evaluateStatusForTests(from: [expired], now: now) == .expired)
    }

    @Test("hasPremiumAccess reflects all states")
    func hasPremiumAccessAllStates() {
        let manager = SubscriptionManager(isTestEnvironment: true)
        manager.subscriptionStatus = .notSubscribed
        #expect(manager.hasPremiumAccess() == false)
        manager.subscriptionStatus = .trialActive
        #expect(manager.hasPremiumAccess() == true)
        manager.subscriptionStatus = .premiumActive
        #expect(manager.hasPremiumAccess() == true)
        manager.subscriptionStatus = .expired
        #expect(manager.hasPremiumAccess() == false)
    }

    @Test("_evaluateStatusForTests ignores non-autoRenewable")
    func evaluateStatusIgnoresNonAutoRenewable() {
        let now = Date()
        let item = SubscriptionManager.EvalInputTest(
            productType: .nonConsumable,
            purchaseDate: now,
            expirationDate: nil)
        let status = SubscriptionManager.evaluateStatusForTests(from: [item], now: now)
        #expect(status == .notSubscribed)
    }

    @Test("checkSubscriptionStatus updates in non-test environment without crashing")
    func checkSubscriptionStatusNonTestEnv() async {
        // This exercises the non-test path inside updateSubscriptionStatus().
        let manager = SubscriptionManager(isTestEnvironment: false)
        await manager.checkSubscriptionStatus()
        // We don't assert a specific value since it depends on simulator StoreKit state.
        // It's sufficient that the call returns and leaves a valid status enum.
        let valid: Set<AppSubscriptionStatus> = [.notSubscribed, .trialActive, .premiumActive, .expired]
        #expect(valid.contains(manager.subscriptionStatus))
    }

    // MARK: - Purchase result branch coverage (DEBUG-only helper)

    @Test("purchase result: userCancelled -> no error, no finish")
    func purchaseResultUserCancelled() {
        #if DEBUG
            let res = try? SubscriptionManager.simulatePurchaseHandling(for: .userCancelled)
            #expect(res?.errorMessage == nil)
            #expect(res?.didFinish == false)
        #endif
    }

    @Test("purchase result: pending -> sets pending message")
    func purchaseResultPending() {
        #if DEBUG
            let res = try? SubscriptionManager.simulatePurchaseHandling(for: .pending)
            #expect(res?.errorMessage == "Purchase is pending approval")
            #expect(res?.didFinish == false)
        #endif
    }

    @Test("purchase result: success verified -> finish true")
    func purchaseResultSuccessVerified() {
        #if DEBUG
            let res = try? SubscriptionManager.simulatePurchaseHandling(for: .successVerified)
            #expect(res?.errorMessage == nil)
            #expect(res?.didFinish == true)
        #endif
    }

    @Test("purchase result: success unverified -> throws verificationFailed")
    func purchaseResultSuccessUnverified() {
        #if DEBUG
            do {
                _ = try SubscriptionManager.simulatePurchaseHandling(for: .successUnverified)
                Issue.record("Expected verificationFailed")
            } catch {
                if case SubscriptionError.verificationFailed = error { /* expected */ } else {
                    Issue.record("Unexpected error: \(error)")
                }
            }
        #endif
    }

    @Test("purchase result: unknown -> throws purchaseFailed")
    func purchaseResultUnknown() {
        #if DEBUG
            do {
                _ = try SubscriptionManager.simulatePurchaseHandling(for: .unknown)
                Issue.record("Expected purchaseFailed")
            } catch {
                if case let SubscriptionError.purchaseFailed(msg) = error {
                    #expect(msg == "Unknown result")
                } else {
                    Issue.record("Unexpected error: \(error)")
                }
            }
        #endif
    }
}
