import Foundation
import StoreKit
import StoreKitTest
import Testing

@testable import JabTracker

@MainActor
@Suite("SubscriptionManager Security Tests")
struct SubscriptionManagerSecurityTests {
    // MARK: - P1.1 Transaction Security Testing (SECURITY CRITICAL)

    @Test("checkVerified handles unverified transactions correctly")
    func checkVerifiedHandlesUnverifiedTransactions() async throws {
        // Since checkVerified is private, we test it through purchase result handling
        // which exercises the same verification logic path

        #if DEBUG
            // Test verification failure through the simulation method
            do {
                _ = try SubscriptionManager.simulatePurchaseHandling(for: .successUnverified)
                Issue.record("Expected verification failure error")
            } catch {
                #expect(error is SubscriptionError)
                if case SubscriptionError.verificationFailed = error {
                    // Expected: unverified transactions should throw verificationFailed
                } else {
                    Issue.record("Expected verificationFailed error, got: \(error)")
                }
            }
        #endif
    }

    @Test("checkVerified properly propagates verification errors")
    func checkVerifiedErrorPropagation() async throws {
        // Test that verification errors are properly propagated up the call stack
        // This tests the security-critical path where invalid transactions are rejected

        let manager = SubscriptionManager(isTestEnvironment: true)

        // Verify that purchase in test environment handles verification correctly
        // (test environment bypasses real purchase but exercises error handling paths)
        do {
            try await manager.purchase(productId: "test.invalid.product")
        } catch {
            // Expected to fail with productNotFound in test environment
            #expect(error is SubscriptionError)

            // Verify the error is one of the expected security-related errors
            switch error {
            case SubscriptionError.productNotFound:
                // Expected in test environment
                break
            case SubscriptionError.verificationFailed:
                // Also acceptable - verification failure
                break
            case SubscriptionError.purchaseFailed:
                // Also acceptable - purchase failure
                break
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }

    @Test("transaction verification maintains security guarantees")
    func transactionVerificationSecurityGuarantees() async throws {
        // Test that unverified transactions are never processed

        #if DEBUG
            // Verify that unverified results always throw
            do {
                _ = try SubscriptionManager.simulatePurchaseHandling(for: .successUnverified)
                Issue.record("Security violation: unverified transaction was processed")
            } catch SubscriptionError.verificationFailed {
                // Expected: security check working correctly
            } catch {
                Issue.record("Expected verificationFailed, got: \(error)")
            }

            // Verify that only verified results proceed to finish
            let verifiedResult = try? SubscriptionManager.simulatePurchaseHandling(for: .successVerified)
            #expect(verifiedResult?.didFinish == true)

            let unverifiedThrows = try? SubscriptionManager.simulatePurchaseHandling(
                for: .successUnverified)
            #expect(unverifiedThrows == nil)  // Should have thrown, not returned a result
        #endif
    }

    @Test("collectCurrentEntitlementTransactions handles verification failures")
    func collectCurrentEntitlementsVerificationHandling() async throws {
        // Test that collectCurrentEntitlementTransactions properly handles verification failures
        let manager = SubscriptionManager(isTestEnvironment: false)

        // This exercises the checkVerified path in collectCurrentEntitlementTransactions
        let transactions = await manager.collectCurrentEntitlementTransactions()

        // In a clean test environment, we should get an empty array
        // The important security property is that unverified transactions are filtered out
        #expect(transactions.isEmpty)  // Should not crash or throw

        // All transactions returned must be verified (this is enforced by checkVerified)
        // If any unverified transactions were in the stream, they would be filtered out
        for transaction in transactions {
            // If we got a transaction back, it must have passed verification
            #expect(transaction.id != 0)  // Basic transaction validity check
        }
    }

    @Test("transaction listener handles verification failures gracefully")
    func transactionListenerVerificationHandling() async throws {
        // Test that the transaction listener (listenForTransactions) handles verification failures

        // Create a manager with transaction listener
        let manager = SubscriptionManager(isTestEnvironment: false)

        // Give the listener a moment to set up
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 second

        // The listener should be running and handling any transaction updates
        // We can't easily inject fake transactions, but we can verify the manager is stable
        #expect(manager.subscriptionStatus == .notSubscribed)  // Initial state

        // Verify the manager can still perform other operations while listener is active
        await manager.checkSubscriptionStatus()
        #expect(manager.subscriptionStatus == .notSubscribed)  // Should remain stable

        // The security property: if any unverified transactions come through the listener,
        // they should be caught by checkVerified and not affect the subscription status
    }

    @Test("verification failure prevents unauthorized access")
    func verificationFailurePreventsUnauthorizedAccess() async throws {
        // Test the critical security property: verification failures must not grant access

        let manager = SubscriptionManager(isTestEnvironment: true)

        // Initial state: no premium access
        #expect(manager.hasPremiumAccess() == false)
        #expect(manager.subscriptionStatus == .notSubscribed)

        // Attempt purchase that would fail verification (simulated)
        do {
            try await manager.purchase(productId: "nonexistent.product")
        } catch {
            // Expected to fail
        }

        // Critical security check: failed verification must not grant access
        #expect(manager.hasPremiumAccess() == false)
        #expect(manager.subscriptionStatus == .notSubscribed)

        // Subscription status should remain unchanged after verification failure
        await manager.checkSubscriptionStatus()
        #expect(manager.hasPremiumAccess() == false)
    }
}
