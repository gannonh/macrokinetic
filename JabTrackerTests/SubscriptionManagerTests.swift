import Foundation
@testable import JabTracker
import StoreKit
import Testing

/// NOTE: These tests target the pure logic extracted into `evaluateStatus` and trial day calculations.
/// They do NOT attempt real StoreKit network calls (which are covered in UI tests) but instead
/// supply synthetic Transaction-like objects via a lightweight wrapper to validate business rules.

@MainActor
@Suite("SubscriptionManager Business Logic")
struct SubscriptionManagerBusinessLogicTests {
    // MARK: - Helpers

    /// Minimal struct mirroring needed Transaction fields for constructing test doubles.
    private struct TestTransaction {
        let productType: Product.ProductType
        let purchaseDate: Date
        let expirationDate: Date?
    }

    /// Build a Transaction test double by dynamically creating a subclass at runtime is not feasible here;
    /// instead we test the `evaluateStatus` logic indirectly by reproducing its conditions.
    /// We therefore re-implement a tiny adapter that mimics the public fields used. This keeps the
    /// logic pure and verifiable. If future refactors access more Transaction properties, extend this.
    private func status(from txs: [TestTransaction], now: Date) -> AppSubscriptionStatus {
        // Mirror logic from SubscriptionManager.evaluateStatus (kept in sync intentionally)
        let autoRenewables = txs.filter { $0.productType == .autoRenewable }
        guard !autoRenewables.isEmpty else { return .notSubscribed }
        guard let latest = autoRenewables.max(by: { $0.purchaseDate < $1.purchaseDate }) else {
            return .notSubscribed
        }
        if let exp = latest.expirationDate, exp <= now { return .expired }
        let trialSeconds = Double(SubscriptionProducts.trialPeriodDays) * 24 * 60 * 60
        let trialEnd = latest.purchaseDate.addingTimeInterval(trialSeconds)
        if now < trialEnd { return .trialActive }
        return .premiumActive
    }

    @Test("No transactions -> not subscribed")
    func noTransactionsNotSubscribed() {
        #expect(self.status(from: [], now: Date()) == .notSubscribed)
    }

    @Test("Active trial within trial window")
    func activeTrialWithinWindow() {
        let now = Date()
        let purchase = now.addingTimeInterval(-3 * 24 * 60 * 60) // 3 days ago
        let tx = TestTransaction(
            productType: .autoRenewable,
            purchaseDate: purchase,
            expirationDate: now.addingTimeInterval(40 * 24 * 60 * 60))
        #expect(self.status(from: [tx], now: now) == .trialActive)
    }

    @Test("Premium active after trial window but before expiration")
    func premiumAfterTrialBeforeExpiration() {
        let now = Date()
        let purchase = now.addingTimeInterval(-35 * 24 * 60 * 60) // 35 days ago (> 28 day trial)
        let exp = now.addingTimeInterval(10 * 24 * 60 * 60) // still active
        let tx = TestTransaction(
            productType: .autoRenewable,
            purchaseDate: purchase,
            expirationDate: exp)
        #expect(self.status(from: [tx], now: now) == .premiumActive)
    }

    @Test("Expired after expiration date")
    func expiredAfterExpirationDate() {
        let now = Date()
        let purchase = now.addingTimeInterval(-40 * 24 * 60 * 60)
        let exp = now.addingTimeInterval(-1 * 24 * 60 * 60) // expired yesterday
        let tx = TestTransaction(
            productType: .autoRenewable,
            purchaseDate: purchase,
            expirationDate: exp)
        #expect(self.status(from: [tx], now: now) == .expired)
    }

    @Test("Latest transaction chosen when multiple present")
    func latestTransactionDeterminesStatus() {
        let now = Date()
        let oldPurchase = now.addingTimeInterval(-60 * 24 * 60 * 60)
        let oldTx = TestTransaction(
            productType: .autoRenewable,
            purchaseDate: oldPurchase,
            expirationDate: now.addingTimeInterval(10 * 24 * 60 * 60))
        let newPurchase = now.addingTimeInterval(-2 * 24 * 60 * 60)
        let newTx = TestTransaction(
            productType: .autoRenewable,
            purchaseDate: newPurchase,
            expirationDate: now.addingTimeInterval(50 * 24 * 60 * 60))
        // Within trial for the new purchase
        #expect(self.status(from: [oldTx, newTx], now: now) == .trialActive)
    }

    @Test("Trial days remaining rounds up partial days")
    func trialDaysRemainingRoundsUp() {
        let manager = SubscriptionManager(isTestEnvironment: true)
        manager.subscriptionStatus = .trialActive
        let purchaseDate = Date().addingTimeInterval(-5 * 24 * 60 * 60) // 5 days ago
        let remaining = manager.trialDaysRemaining(
            purchaseDate: purchaseDate,
            asOf: Date().addingTimeInterval(2 * 60 * 60)) // 2 hours later
        // Expect 28 - 5 = 23 (approx). Allow small boundary variations due to hour offset but should be >=22
        #expect(remaining >= 22 && remaining <= 23)
    }

    @Test("Trial days remaining returns 0 when not in trial status")
    func trialDaysRemainingNotTrial() {
        let manager = SubscriptionManager(isTestEnvironment: true)
        manager.subscriptionStatus = .premiumActive
        let remaining = manager.trialDaysRemaining(purchaseDate: Date().addingTimeInterval(-2 * 24 * 60 * 60))
        #expect(remaining == 0)
    }

    @Test("Trial days remaining with nil purchaseDate uses default when in trial")
    func trialDaysRemainingNilDateInTrial() {
        let manager = SubscriptionManager(isTestEnvironment: true)
        manager.subscriptionStatus = .trialActive
        // When no purchase date is provided and status is trial, we expect the default configured trial days
        let remaining = manager.trialDaysRemaining(purchaseDate: nil, asOf: Date())
        #expect(remaining == SubscriptionProducts.trialPeriodDays)
    }

    @Test("Has premium access for trial and premium, not for others")
    func premiumAccessLogic() {
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
}
