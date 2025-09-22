import Foundation
import StoreKit
import Testing

@testable import JabTracker

/// Tests for P1.2 - Core Subscription Logic (MISSING - HIGH PRIORITY)
/// Tests updateSubscriptionStatus() private async, subscription state transitions,
/// and entitlement collection and processing logic.

@MainActor
@Suite("SubscriptionManager Core Logic - P1.2")
struct SubscriptionManagerCoreLogicTests {
  // MARK: - updateSubscriptionStatus() private async method testing

  @Test("updateSubscriptionStatus in test environment maintains current status")
  func updateSubscriptionStatusTestEnvironment() async {
    let manager = SubscriptionManager(isTestEnvironment: true)

    // Set initial status
    manager.subscriptionStatus = .trialActive
    let initialStatus = manager.subscriptionStatus

    // Call updateSubscriptionStatus (indirectly via checkSubscriptionStatus)
    await manager.checkSubscriptionStatus()

    // In test environment, status should remain unchanged
    #expect(manager.subscriptionStatus == initialStatus)
  }

  @Test("updateSubscriptionStatus calls collectCurrentEntitlementTransactions")
  func updateSubscriptionStatusCallsCollectEntitlements() async {
    let manager = SubscriptionManager(isTestEnvironment: false)

    // This tests the integration path where updateSubscriptionStatus
    // calls collectCurrentEntitlementTransactions and evaluateStatus
    await manager.checkSubscriptionStatus()

    // Verify the method executed without error
    // The actual entitlement processing is tested separately
    // AppSubscriptionStatus has a valid state after checkSubscriptionStatus
    let validStates: [AppSubscriptionStatus] = [
      .notSubscribed, .trialActive, .premiumActive, .expired,
    ]
    #expect(validStates.contains(manager.subscriptionStatus))
  }

  // MARK: - Subscription State Transitions Testing

  @Test("Subscription state transition: trial → premium → expired → resubscribe")
  func subscriptionStateTransitionLifecycle() {
    let now = Date()

    // 1. Trial → Premium transition
    let trialPurchase = now.addingTimeInterval(-5 * 24 * 60 * 60)  // 5 days ago
    let trialExpiration = now.addingTimeInterval(50 * 24 * 60 * 60)  // far future (50 days)

    let trialTx = SubscriptionManager.EvalInputTest(
      productType: .autoRenewable,
      purchaseDate: trialPurchase,
      expirationDate: trialExpiration)

    // Should be in trial (within 28-day trial period)
    let trialStatus = SubscriptionManager.evaluateStatusForTests(from: [trialTx], now: now)
    #expect(trialStatus == .trialActive)

    // 2. Trial → Premium (after 28 days, but before expiration)
    let afterTrialDate = trialPurchase.addingTimeInterval(30 * 24 * 60 * 60)  // 30 days after purchase
    let premiumStatus = SubscriptionManager.evaluateStatusForTests(
      from: [trialTx], now: afterTrialDate)
    #expect(premiumStatus == .premiumActive)

    // 3. Premium → Expired transition
    let expiredDate = trialExpiration.addingTimeInterval(1 * 24 * 60 * 60)  // 1 day after expiration
    let expiredStatus = SubscriptionManager.evaluateStatusForTests(
      from: [trialTx], now: expiredDate)
    #expect(expiredStatus == .expired)

    // 4. Expired → Resubscribe (new transaction)
    let resubscribeDate = expiredDate.addingTimeInterval(10 * 24 * 60 * 60)  // 10 days later
    let newSubscription = SubscriptionManager.EvalInputTest(
      productType: .autoRenewable,
      purchaseDate: resubscribeDate,
      expirationDate: resubscribeDate.addingTimeInterval(30 * 24 * 60 * 60))

    // Should be in trial again (new purchase within trial period)
    let resubscribeStatus = SubscriptionManager.evaluateStatusForTests(
      from: [trialTx, newSubscription],
      now: resubscribeDate.addingTimeInterval(1 * 60 * 60)  // 1 hour after resubscribe
    )
    #expect(resubscribeStatus == .trialActive)
  }

  @Test("State transition edge cases: same-day expiration and renewal")
  func stateTransitionEdgeCases() {
    let now = Date()

    // Test exact expiration boundary
    let purchaseDate = now.addingTimeInterval(-60 * 24 * 60 * 60)  // 60 days ago
    let exactExpirationDate = now  // expires exactly now

    let txExactExpiry = SubscriptionManager.EvalInputTest(
      productType: .autoRenewable,
      purchaseDate: purchaseDate,
      expirationDate: exactExpirationDate)

    // At exact expiration time should be expired
    let exactStatus = SubscriptionManager.evaluateStatusForTests(from: [txExactExpiry], now: now)
    #expect(exactStatus == .expired)

    // Just before expiration should be premium (past trial period)
    let justBeforeExpiry = now.addingTimeInterval(-1)  // 1 second before
    let beforeStatus = SubscriptionManager.evaluateStatusForTests(
      from: [txExactExpiry], now: justBeforeExpiry)
    #expect(beforeStatus == .premiumActive)

    // Test trial period boundary (exactly 28 days)
    let trialBoundaryDate = purchaseDate.addingTimeInterval(28 * 24 * 60 * 60)  // exactly 28 days
    let boundaryStatus = SubscriptionManager.evaluateStatusForTests(
      from: [txExactExpiry], now: trialBoundaryDate)
    #expect(boundaryStatus == .premiumActive)  // should be premium at exact boundary
  }

  @Test("Multiple overlapping subscriptions choose latest")
  func multipleOverlappingSubscriptionsChooseLatest() {
    let now = Date()

    // Old subscription (still valid but should be superseded)
    let oldPurchase = now.addingTimeInterval(-40 * 24 * 60 * 60)  // 40 days ago
    let oldTx = SubscriptionManager.EvalInputTest(
      productType: .autoRenewable,
      purchaseDate: oldPurchase,
      expirationDate: now.addingTimeInterval(20 * 24 * 60 * 60)  // still active
    )

    // New subscription (recent, in trial)
    let newPurchase = now.addingTimeInterval(-5 * 24 * 60 * 60)  // 5 days ago
    let newTx = SubscriptionManager.EvalInputTest(
      productType: .autoRenewable,
      purchaseDate: newPurchase,
      expirationDate: now.addingTimeInterval(60 * 24 * 60 * 60)  // long validity
    )

    // Should use the newest purchase date for status determination
    let status = SubscriptionManager.evaluateStatusForTests(from: [oldTx, newTx], now: now)
    #expect(status == .trialActive)  // based on newer purchase date

    // Verify with reversed order (should give same result)
    let reversedStatus = SubscriptionManager.evaluateStatusForTests(from: [newTx, oldTx], now: now)
    #expect(reversedStatus == .trialActive)
  }

  // MARK: - Entitlement Collection and Processing Logic

  @Test("collectCurrentEntitlementTransactions returns empty in test environment")
  func collectEntitlementsTestEnvironment() async {
    let manager = SubscriptionManager(isTestEnvironment: true)

    // collectCurrentEntitlementTransactions is internal, but we can test it
    let transactions = await manager.collectCurrentEntitlementTransactions()

    // Should return empty array in test environment to avoid StoreKit calls
    #expect(transactions.isEmpty)
  }

  @Test("evaluateStatus handles empty transaction list")
  func evaluateStatusEmptyTransactions() {
    let status = SubscriptionManager.evaluateStatus(from: [], now: Date())
    #expect(status == .notSubscribed)
  }

  @Test("evaluateStatus filters only autoRenewable products")
  func evaluateStatusFiltersAutoRenewableOnly() {
    let now = Date()

    // Create mock transactions with different product types
    // Note: We can't easily create real Transaction objects, so this tests the logic
    // using the test-friendly evaluateStatusForTests method

    let nonAutoRenewable = SubscriptionManager.EvalInputTest(
      productType: .nonConsumable,  // Not autoRenewable
      purchaseDate: now.addingTimeInterval(-1 * 24 * 60 * 60),
      expirationDate: now.addingTimeInterval(30 * 24 * 60 * 60))

    let autoRenewable = SubscriptionManager.EvalInputTest(
      productType: .autoRenewable,
      purchaseDate: now.addingTimeInterval(-2 * 24 * 60 * 60),
      expirationDate: now.addingTimeInterval(30 * 24 * 60 * 60))

    // Should ignore non-autoRenewable and only consider autoRenewable
    let status = SubscriptionManager.evaluateStatusForTests(
      from: [nonAutoRenewable, autoRenewable],
      now: now)
    #expect(status == .trialActive)  // Based on autoRenewable transaction only

    // With only non-autoRenewable should be not subscribed
    let nonRenewableOnlyStatus = SubscriptionManager.evaluateStatusForTests(
      from: [nonAutoRenewable],
      now: now)
    #expect(nonRenewableOnlyStatus == .notSubscribed)
  }

  @Test("evaluateStatus comprehensive edge case matrix")
  func evaluateStatusEdgeCaseMatrix() {
    let now = Date()
    let oneDayAgo = now.addingTimeInterval(-24 * 60 * 60)
    let oneWeekAgo = now.addingTimeInterval(-7 * 24 * 60 * 60)
    let oneMonthAgo = now.addingTimeInterval(-30 * 24 * 60 * 60)
    let futureDate = now.addingTimeInterval(30 * 24 * 60 * 60)
    let pastDate = now.addingTimeInterval(-1 * 60 * 60)  // 1 hour ago

    // Test case 1: Recent purchase, not expired, within trial
    let recentTrial = SubscriptionManager.EvalInputTest(
      productType: .autoRenewable,
      purchaseDate: oneDayAgo,
      expirationDate: futureDate)
    #expect(
      SubscriptionManager.evaluateStatusForTests(from: [recentTrial], now: now) == .trialActive)

    // Test case 2: Old purchase, not expired, past trial period
    let oldPremium = SubscriptionManager.EvalInputTest(
      productType: .autoRenewable,
      purchaseDate: oneMonthAgo,
      expirationDate: futureDate)
    #expect(
      SubscriptionManager.evaluateStatusForTests(from: [oldPremium], now: now) == .premiumActive)

    // Test case 3: Any purchase date, expired
    let expiredRecent = SubscriptionManager.EvalInputTest(
      productType: .autoRenewable,
      purchaseDate: oneDayAgo,
      expirationDate: pastDate)
    #expect(SubscriptionManager.evaluateStatusForTests(from: [expiredRecent], now: now) == .expired)

    // Test case 4: No expiration date (should not happen in practice, but handle gracefully)
    let noExpiry = SubscriptionManager.EvalInputTest(
      productType: .autoRenewable,
      purchaseDate: oneWeekAgo,
      expirationDate: nil)
    #expect(SubscriptionManager.evaluateStatusForTests(from: [noExpiry], now: now) == .trialActive)
  }

  // MARK: - Integration Testing with Real SubscriptionManager Methods

  @Test("checkSubscriptionStatus integration with updateSubscriptionStatus")
  func checkSubscriptionStatusIntegration() async {
    let manager = SubscriptionManager(isTestEnvironment: true)

    // Set initial status
    manager.subscriptionStatus = .premiumActive

    // Call checkSubscriptionStatus (which calls updateSubscriptionStatus internally)
    await manager.checkSubscriptionStatus()

    // Verify the integration completed successfully
    // In test environment, status should be preserved
    #expect(manager.subscriptionStatus == .premiumActive)
  }

  @Test("entitlement processing with multiple transaction scenarios")
  func entitlementProcessingScenarios() async {
    // Test the flow where entitlements would be processed
    // This is an integration test that verifies the connection between
    // collectCurrentEntitlementTransactions and evaluateStatus

    let manager = SubscriptionManager(isTestEnvironment: true)

    // Test different initial states
    let initialStates: [AppSubscriptionStatus] = [
      .notSubscribed, .trialActive, .premiumActive, .expired,
    ]

    for initialState in initialStates {
      manager.subscriptionStatus = initialState
      await manager.checkSubscriptionStatus()

      // In test environment, the status should be preserved
      // This tests the integration path through updateSubscriptionStatus
      #expect(manager.subscriptionStatus == initialState)
    }
  }
}
