import Foundation
import StoreKit
import Testing

@testable import JabTracker

/// NOTE: These tests focus on core business logic using real SubscriptionManager methods.
/// StoreKit integration tests are handled separately in SubscriptionManagerStoreKitIntegrationTests.

@MainActor
@Suite("SubscriptionManager Business Logic")
struct SubscriptionManagerBusinessLogicTests {
  @Test("No transactions -> not subscribed")
  func noTransactionsNotSubscribed() {
    let status = SubscriptionManager.evaluateStatusForTests(from: [], now: Date())
    #expect(status == .notSubscribed)
  }

  @Test("Active trial within trial window")
  func activeTrialWithinWindow() {
    let now = Date()
    let purchase = now.addingTimeInterval(-3 * 24 * 60 * 60)  // 3 days ago
    let tx = SubscriptionManager.EvalInputTest(
      productType: .autoRenewable,
      purchaseDate: purchase,
      expirationDate: now.addingTimeInterval(40 * 24 * 60 * 60))
    let status = SubscriptionManager.evaluateStatusForTests(from: [tx], now: now)
    #expect(status == .trialActive)
  }

  @Test("Premium active after trial window but before expiration")
  func premiumAfterTrialBeforeExpiration() {
    let now = Date()
    let purchase = now.addingTimeInterval(-35 * 24 * 60 * 60)  // 35 days ago (> 28 day trial)
    let exp = now.addingTimeInterval(10 * 24 * 60 * 60)  // still active
    let tx = SubscriptionManager.EvalInputTest(
      productType: .autoRenewable,
      purchaseDate: purchase,
      expirationDate: exp)
    let status = SubscriptionManager.evaluateStatusForTests(from: [tx], now: now)
    #expect(status == .premiumActive)
  }

  @Test("Expired after expiration date")
  func expiredAfterExpirationDate() {
    let now = Date()
    let purchase = now.addingTimeInterval(-40 * 24 * 60 * 60)
    let exp = now.addingTimeInterval(-1 * 24 * 60 * 60)  // expired yesterday
    let tx = SubscriptionManager.EvalInputTest(
      productType: .autoRenewable,
      purchaseDate: purchase,
      expirationDate: exp)
    let status = SubscriptionManager.evaluateStatusForTests(from: [tx], now: now)
    #expect(status == .expired)
  }

  @Test("Latest transaction chosen when multiple present")
  func latestTransactionDeterminesStatus() {
    let now = Date()
    let oldPurchase = now.addingTimeInterval(-60 * 24 * 60 * 60)
    let oldTx = SubscriptionManager.EvalInputTest(
      productType: .autoRenewable,
      purchaseDate: oldPurchase,
      expirationDate: now.addingTimeInterval(10 * 24 * 60 * 60))
    let newPurchase = now.addingTimeInterval(-2 * 24 * 60 * 60)
    let newTx = SubscriptionManager.EvalInputTest(
      productType: .autoRenewable,
      purchaseDate: newPurchase,
      expirationDate: now.addingTimeInterval(50 * 24 * 60 * 60))
    // Within trial for the new purchase
    let status = SubscriptionManager.evaluateStatusForTests(from: [oldTx, newTx], now: now)
    #expect(status == .trialActive)
  }

  @Test("Trial days remaining rounds up partial days")
  func trialDaysRemainingRoundsUp() {
    let manager = SubscriptionManager(isTestEnvironment: true)
    manager.subscriptionStatus = .trialActive
    let purchaseDate = Date().addingTimeInterval(-5 * 24 * 60 * 60)  // 5 days ago
    let remaining = manager.trialDaysRemaining(
      purchaseDate: purchaseDate,
      asOf: Date().addingTimeInterval(2 * 60 * 60))  // 2 hours later
    // Expect 28 - 5 = 23 (approx). Allow small boundary variations due to hour offset but should be >=22
    #expect(remaining >= 22 && remaining <= 23)
  }

  @Test("Trial days remaining returns 0 when not in trial status")
  func trialDaysRemainingNotTrial() {
    let manager = SubscriptionManager(isTestEnvironment: true)
    manager.subscriptionStatus = .premiumActive
    let remaining = manager.trialDaysRemaining(
      purchaseDate: Date().addingTimeInterval(-2 * 24 * 60 * 60))
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
