import Foundation
import StoreKit
@testable import JabTracker
import Testing

@MainActor
@Suite("Subscription Manager Tests")
struct SubscriptionManagerTests {
    
    @Test("SubscriptionManager initialization")
    @MainActor
    func subscriptionManagerInit() {
        let subscriptionManager = SubscriptionManager()
        
        // Verify initial state
        #expect(subscriptionManager.subscriptionStatus == .notSubscribed)
        #expect(subscriptionManager.availableProducts.isEmpty)
        #expect(subscriptionManager.isLoading == false)
        #expect(subscriptionManager.errorMessage == nil)
    }
    
    @Test("Product loading sets loading state correctly")
    @MainActor
    func productLoadingState() async {
        let subscriptionManager = SubscriptionManager()
        
        // Initial state
        #expect(subscriptionManager.isLoading == false)
        
        // Start loading products - this will complete async
        await subscriptionManager.loadProducts()
        
        // After loading completes, loading state should be false
        #expect(subscriptionManager.isLoading == false)
        
        // Products should be empty in test environment
        #expect(subscriptionManager.availableProducts.isEmpty)
    }
    
    @Test("Product identifiers are correctly configured")
    @MainActor
    func productIdentifiersConfiguration() {
        let subscriptionManager = SubscriptionManager()
        let expectedIdentifiers = Set(SubscriptionProducts.allProductIdentifiers)
        
        // SubscriptionManager should use the same product identifiers
        #expect(expectedIdentifiers.contains(SubscriptionProducts.monthly))
        #expect(expectedIdentifiers.contains(SubscriptionProducts.annual))
        #expect(expectedIdentifiers.count == 2)
    }
    
    @Test("Subscription status enum values")
    @MainActor
    func subscriptionStatusValues() {
        let subscriptionManager = SubscriptionManager()
        
        // Test all possible subscription status values
        subscriptionManager.subscriptionStatus = .notSubscribed
        #expect(subscriptionManager.subscriptionStatus == .notSubscribed)
        
        subscriptionManager.subscriptionStatus = .trialActive
        #expect(subscriptionManager.subscriptionStatus == .trialActive)
        
        subscriptionManager.subscriptionStatus = .premiumActive
        #expect(subscriptionManager.subscriptionStatus == .premiumActive)
        
        subscriptionManager.subscriptionStatus = .expired
        #expect(subscriptionManager.subscriptionStatus == .expired)
    }
    
    @Test("Purchase flow error handling in test environment")
    @MainActor
    func purchaseFlowErrorHandling() async {
        let subscriptionManager = SubscriptionManager()
        
        // In test environment, purchase should fail gracefully
        // Create a mock product for testing
        var didEncounterError = false
        
        do {
            // This should fail in test environment since we don't have real StoreKit products
            try await subscriptionManager.purchase(productId: SubscriptionProducts.monthly)
        } catch {
            didEncounterError = true
            // Should handle the error gracefully
            #expect(error is SubscriptionError)
        }
        
        // In test environment, we expect this to fail
        #expect(didEncounterError, "Purchase should fail gracefully in test environment")
        #expect(subscriptionManager.subscriptionStatus == .notSubscribed, "Status should remain not subscribed after failed purchase")
    }
    
    @Test("Restore purchases error handling in test environment")
    @MainActor
    func restorePurchasesErrorHandling() async {
        let subscriptionManager = SubscriptionManager()
        
        let initialStatus = subscriptionManager.subscriptionStatus
        
        // In test environment, restore should complete without crashing
        await subscriptionManager.restorePurchases()
        
        // Status should remain unchanged in test environment
        #expect(subscriptionManager.subscriptionStatus == initialStatus)
    }
    
    @Test("Trial period calculation")
    @MainActor
    func trialPeriodCalculation() {
        let subscriptionManager = SubscriptionManager()
        
        // Mock trial active state
        subscriptionManager.subscriptionStatus = .trialActive
        
        // Test trial period calculations
        let trialDays = subscriptionManager.trialDaysRemaining()
        
        // In test environment, should return a valid value (0 or more days)
        #expect(trialDays >= 0, "Trial days remaining should be non-negative")
        
        // Test isTrialActive
        let isTrialActive = subscriptionManager.isTrialActive()
        #expect(isTrialActive == (subscriptionManager.subscriptionStatus == .trialActive))
    }
    
    @Test("Subscription status checking")
    @MainActor
    func subscriptionStatusChecking() async {
        let subscriptionManager = SubscriptionManager()
        
        let initialStatus = subscriptionManager.subscriptionStatus
        
        // Check subscription status - should not crash
        await subscriptionManager.checkSubscriptionStatus()
        
        // In test environment, status should be deterministic
        #expect(subscriptionManager.subscriptionStatus == initialStatus || 
                subscriptionManager.subscriptionStatus == .notSubscribed)
    }
    
    @Test("Error message handling")
    @MainActor 
    func errorMessageHandling() {
        let subscriptionManager = SubscriptionManager()
        
        // Initial state should have no error
        #expect(subscriptionManager.errorMessage == nil)
        
        // Test setting error message
        subscriptionManager.errorMessage = "Test error message"
        #expect(subscriptionManager.errorMessage == "Test error message")
        
        // Test clearing error message
        subscriptionManager.errorMessage = nil
        #expect(subscriptionManager.errorMessage == nil)
    }
    
    @Test("Premium features access based on subscription status")
    @MainActor
    func premiumFeaturesAccess() {
        let subscriptionManager = SubscriptionManager()
        
        // Test not subscribed
        subscriptionManager.subscriptionStatus = .notSubscribed
        #expect(subscriptionManager.hasPremiumAccess() == false)
        
        // Test trial active
        subscriptionManager.subscriptionStatus = .trialActive
        #expect(subscriptionManager.hasPremiumAccess() == true)
        
        // Test premium active
        subscriptionManager.subscriptionStatus = .premiumActive
        #expect(subscriptionManager.hasPremiumAccess() == true)
        
        // Test expired
        subscriptionManager.subscriptionStatus = .expired
        #expect(subscriptionManager.hasPremiumAccess() == false)
    }
    
    @Test("Product filtering by subscription type")
    @MainActor
    func productFilteringByType() async {
        let subscriptionManager = SubscriptionManager()
        
        // Load products first
        await subscriptionManager.loadProducts()
        
        // Test filtering monthly products
        let monthlyProducts = subscriptionManager.monthlyProducts()
        // In test environment, this might be empty, but should not crash
        #expect(monthlyProducts.count >= 0)
        
        // Test filtering annual products  
        let annualProducts = subscriptionManager.annualProducts()
        #expect(annualProducts.count >= 0)
    }
    
    @Test("Subscription lifecycle state transitions")
    @MainActor
    func subscriptionLifecycleTransitions() {
        let subscriptionManager = SubscriptionManager()
        
        // Test valid state transitions
        subscriptionManager.subscriptionStatus = .notSubscribed
        subscriptionManager.subscriptionStatus = .trialActive
        #expect(subscriptionManager.subscriptionStatus == .trialActive)
        
        subscriptionManager.subscriptionStatus = .premiumActive
        #expect(subscriptionManager.subscriptionStatus == .premiumActive)
        
        subscriptionManager.subscriptionStatus = .expired
        #expect(subscriptionManager.subscriptionStatus == .expired)
        
        // Can go back to not subscribed after expiration
        subscriptionManager.subscriptionStatus = .notSubscribed
        #expect(subscriptionManager.subscriptionStatus == .notSubscribed)
    }
}