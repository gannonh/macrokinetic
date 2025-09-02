# Subscription E2E Testing Strategy

Status: Draft (Initial adoption)  
Owner: Subscription / StoreKit Integration  
Audience: Engineering, QA, CI Maintainers

## 1. Objectives

Ensure reliable, automated, and compliant validation of in‑app subscription (auto‑renewable) purchase flows without using production accounts, while covering:

- Product discovery & pricing display
- Intro offer / trial eligibility
- Purchase, renewal, expiration, grace / billing retry
- Restore, refund / revocation, price increase confirmation
- Entitlement persistence across launches & devices
- Receipt integrity (local & future server-side path)

## 2. Environment Layers (Do Not Skip Any)

| Layer                                | Purpose                            | Automation Level   | Apple Account Needed |
| ------------------------------------ | ---------------------------------- | ------------------ | -------------------- |
| StoreKit Configuration (.storekit)   | Fast deterministic simulator tests | Full (CI)          | No                   |
| `SKTestSession` Programmatic Control | Edge cases & time travel           | Full (CI)          | No                   |
| Sandbox Testers (App Store Connect)  | Real network / receipt pipeline    | Manual / Semi      | Yes (sandbox)        |
| TestFlight (Internal)                | Distribution realism               | Manual             | Sandbox Apple ID     |
| Production Canary (Passive)          | Runtime assurance                  | Observability only | Real users           |

Use .storekit + SKTestSession for every PR; sandbox testers for pre‑release sign‑off.

## 3. Key Principles

1. Never automate *real* production purchases.
2. Avoid brittle UI string assertions for localized prices; assert product IDs + controlled accessibility identifiers.
3. Separate entitlement evaluation logic from UI; expose a pure function: `EntitlementState evaluate(transactions:)`.
4. Model time‑based transitions via SKTestSession time travel (not `Task.sleep` loops).
5. Treat refund/revocation as first‑class test cases (regression surface for entitlement cache bugs).

## 4. StoreKit Configuration (.storekit)

Located alongside project resources (existing `JabTrackerStoreKit.storekit`). Add to scheme: Run > Options > StoreKit Configuration.

Recommended product identifiers:
- `premium.monthly`
- `premium.annual`

Trial / Intro Offer Example:
- Monthly: 14‑day free trial
- Annual: 1‑month intro (pay upfront with discount)

Renewal Acceleration (Apple default sandbox rules):
- 1 week ≈ 3–5 real minutes.
- 1 month ≈ 10–15 real minutes.
Limit: Usually 6 renewals before auto‑stop. Plan test assertions for <=5 renewals.

## 5. SKTestSession Usage Patterns

```swift
import StoreKitTest
import StoreKit

final class SubscriptionIntegrationTests: XCTestCase {
    var session: SKTestSession! = nil

    override func setUp() async throws {
        session = try SKTestSession(configurationFileNamed: "JabTrackerStoreKit")
        session.resetToInitialState()
        session.disableDialogs = true
        session.clearTransactions()
    }

    func testMonthlyPurchaseAndRenewal() async throws {
        let products = try await Product.products(for: ["premium.monthly"])
        let monthly = try XCTUnwrap(products.first)
        let result = try await monthly.purchase()
        guard case .success(let verification) = result else { return XCTFail("No success") }
        _ = try verification.payloadValue

        // Simulate time for 2 renewals (tune based on accelerated duration)
        try session.advanceTime(by: 12 * 60) // seconds

        // Assert active entitlement
        let entitlements = await Transaction.currentEntitlements
        var hasMonthly = false
        for await status in entitlements {
            if case .verified(let tx) = status, tx.productID == "premium.monthly" { hasMonthly = true }
        }
        XCTAssertTrue(hasMonthly)
    }
}
```

Other session controls:
- `session.failTransactionsEnabled = true` (billing retry).
- `session.revokeEntitlements(forProductIdentifiers:)` (refund simulation).
- `session.expireSubscription(productIdentifier:)` (force immediate expiration—if available in API version; else time advance).
*Always guard these behind `#if DEBUG || INTERNAL_TESTING` when bridging into app harness code.*

## 6. Restore Flow Testing

1. Purchase monthly.
2. Capture entitlement state.
3. `session.clearTransactions()` (simulates new device context) *or* create a fresh SKTestSession.
4. Trigger in‑app Restore (`Transaction.updates` + `AppStore.sync()`).
5. Assert entitlements reappear and local persistence updated.

## 7. Refund / Revocation

Use: `session.revokeEntitlements(forProductIdentifiers: ["premium.monthly"])`.
Expect: entitlement resolver transitions to Not Subscribed within one app lifecycle or via transaction updates stream.
UI should reflect loss of premium instantly or after next refresh (define SLA <2s).

## 8. Price Increase & Grace Period (Future Enhancements)

StoreKit Test supports simulating price increases; plan acceptance criteria:
- Display mandatory consent UI when required.
- Maintain entitlement until renewal window passes without consent.

## 9. Sandbox Tester Accounts

Creation Path: App Store Connect → Users and Access → Sandbox Testers.
Guidelines:
- One tester per scenario (trial, expired, refunded) to prevent cross‑contamination.
- Reset by deleting & recreating tester (clears purchase history).
- Document mapping in `docs/testing-strategy.md` (table: email → scenario).

Manual Test Checklist (Device):
- Sign out real Apple ID in Settings > Media & Purchases (if needed).
- Sign in with sandbox Apple ID only when prompted during first purchase.
- Verify receipt in `Settings > [App]` logs (or planned server endpoint).

## 10. Test Matrix

| Scenario                       | Layer           | Automated? | Notes                            |
| ------------------------------ | --------------- | ---------- | -------------------------------- |
| Initial purchase (monthly)     | StoreKit Config | Yes        | Core path                        |
| Initial purchase (annual)      | StoreKit Config | Yes        | Pricing tier coverage            |
| Trial → first renewal          | SKTestSession   | Yes        | Time advance                     |
| Multiple renewals (billing ok) | SKTestSession   | Yes        | Entitlement stability            |
| Grace period (billing failure) | SKTestSession   | Yes        | Enable `failTransactionsEnabled` |
| Restore on fresh install       | SKTestSession   | Yes        | Clear transactions & restore     |
| Refund / revocation            | SKTestSession   | Yes        | Revoke entitlements              |
| Price increase consent         | SKTestSession   | Planned    | Future                           |
| Real sandbox purchase (device) | Sandbox         | Manual     | Weekly regression                |
| TestFlight distribution smoke  | TestFlight      | Manual     | Pre‑release gate                 |

## 11. CI Integration

Pipeline Steps:
1. `xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -only-testing:JabTrackerTests/SubscriptionIntegrationTests` (once created).
2. Fail fast if entitlement state mismatch.
3. Upload derived `xcresult` for coverage (receipt parsing code should count).
4. (Optional) JUnit transform for dashboard summarizing: Purchased, Renewals, Restores, Revocations counts.

Flakiness Guards:
- Use `XCTExpectFailure` around known transient network branches (should be none in pure StoreKit config mode).
- Keep per‑test runtime < 30s by bounding renewal count.

## 12. Logging & Telemetry (Runtime)

Add lightweight structured logs (DEBUG only) around:
- Purchase attempt → success/failure cause
- Transaction listener events (transactionID, productID, state)
- Entitlement evaluation diffs (old → new state)

Optionally emit in production (redacted) for canary metrics.

## 13. Entitlement Evaluation Contract

Input: Sequence<Transaction> (verified) + current date.  
Output: `EntitlementState { case notSubscribed, trialEnds(Date), active(expiration: Date), inGrace(expiration: Date), revoked }`.

Pure function invariants:
- Latest non-revoked subscription per product governs.
- Trial recognized if `transaction.offerType == .introductory` and not previously consumed.
- Grace/billing retry flagged if renewal transaction pending but last period expired (simulate via failure flags).

## 14. Accessibility & Localization

Expose stable accessibility identifiers:
- `subscription-product-premium.monthly`
- `subscription-purchase-button`
- `subscription-restore-button`
- `subscription-status-label`
- `subscription-trial-countdown`

Never assert localized currency strings directly; assert identifier presence + semantic state (e.g., entitlement label contains "Active").

## 15. Risks & Mitigations

| Risk                                  | Impact             | Mitigation                         |
| ------------------------------------- | ------------------ | ---------------------------------- |
| Over‑reliance on sandbox manual tests | Missed regressions | Automate SKTestSession flows       |
| Flaky time-based renewals             | CI noise           | Time travel via session, no sleeps |
| Localized price changes               | Broken assertions  | Use productID & custom labels      |
| Refund logic drift                    | Entitlements stale | Dedicated revocation test case     |
| Schema change to entitlement          | Silent failures    | Snapshot test serialized state     |

## 16. Immediate Action Items

1. Implement `EntitlementState` enum + evaluator.
2. Add `SubscriptionIntegrationTests` (StoreKit 2 + SKTestSession).
3. Add accessibility identifiers listed above.
4. Update scheme to include `.storekit` config (commit `.xcscheme` change via XcodeGen if required).
5. Add CI job invoking integration subset.
6. Document sandbox tester emails (private internal doc, not checked into repo publicly if containing PII).

## 17. Future Enhancements

- Introduce lightweight server receipt validation (hybrid: local preflight + remote trust).
- Telemetry-based flaky test auto-rerun for subscription suite.
- Price increase + consent flow simulation tests.
- Automated weekly scheduled run using latest Xcode + device matrix.

## 18. References

- Apple Docs: StoreKit Testing, SKTestSession, Auto-Renewable Subscriptions.
- Internal: `JabTrackerStoreKit.storekit` configuration file.
- Existing UI tests: `SubscriptionUITests.swift` (migrate brittle price string assertions over time).

---
Succinct TL;DR: Use `.storekit` + `SKTestSession` for all automated edges, sandbox testers only for human verification; assert deterministic identifiers, not localized strings; pure entitlement evaluation function underpins every layer.
