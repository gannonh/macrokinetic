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
}
