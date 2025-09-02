import Foundation
@testable import JabTracker
import StoreKit

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
        self.isLoading = true
        self.errorMessage = nil

        if self.shouldFailProductLoad {
            self.errorMessage = "Mock: Failed to load products"
            self.availableProducts = []
        } else {
            // Mock empty products for test environment
            self.availableProducts = []
        }

        self.isLoading = false
    }

    func purchase(productId _: String) async throws {
        if self.shouldFailPurchase {
            throw JabTracker.SubscriptionError.purchaseFailed("Mock purchase failure")
        }
        // Mock successful purchase - status remains unchanged for testing
    }

    func purchase(_: Product) async throws {
        if self.shouldFailPurchase {
            throw JabTracker.SubscriptionError.purchaseFailed("Mock purchase failure")
        }
        // Mock successful purchase - status remains unchanged for testing
    }

    func restorePurchases() async {
        self.isLoading = true
        self.errorMessage = nil

        // Mock restore - no changes to subscription status

        self.isLoading = false
    }

    func checkSubscriptionStatus() async {
        // Mock - no changes to status
    }

    func hasPremiumAccess() -> Bool {
        switch self.subscriptionStatus {
        case JabTracker.SubscriptionStatus.trialActive, JabTracker.SubscriptionStatus.premiumActive:
            return true
        case JabTracker.SubscriptionStatus.notSubscribed, JabTracker.SubscriptionStatus.expired:
            return false
        }
    }

    func isTrialActive() -> Bool {
        self.subscriptionStatus == JabTracker.SubscriptionStatus.trialActive
    }

    func trialDaysRemaining() -> Int {
        self.subscriptionStatus == JabTracker.SubscriptionStatus.trialActive ? 14 : 0
    }

    func monthlyProducts() -> [Product] {
        self.availableProducts.filter { $0.id == SubscriptionProducts.monthly }
    }

    func annualProducts() -> [Product] {
        self.availableProducts.filter { $0.id == SubscriptionProducts.annual }
    }
}
