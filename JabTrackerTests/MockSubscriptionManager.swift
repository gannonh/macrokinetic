import Foundation
import StoreKit
@testable import JabTracker

/// Mock SubscriptionManager for unit testing without StoreKit dependencies
class MockSubscriptionManager: ObservableObject {
    @Published var subscriptionStatus: JabTracker.SubscriptionStatus = .notSubscribed
    @Published var availableProducts: [Product] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Mock state controls for testing
    var shouldFailPurchase = false
    var shouldFailProductLoad = false
    
    init() {
        // No StoreKit operations in mock
    }
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        if shouldFailProductLoad {
            errorMessage = "Mock: Failed to load products"
            availableProducts = []
        } else {
            // Mock empty products for test environment
            availableProducts = []
        }
        
        isLoading = false
    }
    
    func purchase(productId: String) async throws {
        if shouldFailPurchase {
            throw JabTracker.SubscriptionError.purchaseFailed("Mock purchase failure")
        }
        // Mock successful purchase - status remains unchanged for testing
    }
    
    func purchase(_ product: Product) async throws {
        if shouldFailPurchase {
            throw JabTracker.SubscriptionError.purchaseFailed("Mock purchase failure")
        }
        // Mock successful purchase - status remains unchanged for testing
    }
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        // Mock restore - no changes to subscription status
        
        isLoading = false
    }
    
    func checkSubscriptionStatus() async {
        // Mock - no changes to status
    }
    
    func hasPremiumAccess() -> Bool {
        switch subscriptionStatus {
        case JabTracker.SubscriptionStatus.trialActive, JabTracker.SubscriptionStatus.premiumActive:
            return true
        case JabTracker.SubscriptionStatus.notSubscribed, JabTracker.SubscriptionStatus.expired:
            return false
        }
    }
    
    func isTrialActive() -> Bool {
        subscriptionStatus == JabTracker.SubscriptionStatus.trialActive
    }
    
    func trialDaysRemaining() -> Int {
        subscriptionStatus == JabTracker.SubscriptionStatus.trialActive ? 14 : 0
    }
    
    func monthlyProducts() -> [Product] {
        availableProducts.filter { $0.id == SubscriptionProducts.monthly }
    }
    
    func annualProducts() -> [Product] {
        availableProducts.filter { $0.id == SubscriptionProducts.annual }
    }
}
