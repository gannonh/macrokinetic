import Foundation
import StoreKit
import Combine

/// Subscription status enumeration
public enum SubscriptionStatus: Equatable {
    case notSubscribed
    case trialActive
    case premiumActive
    case expired
}

/// Subscription-specific errors
public enum SubscriptionError: Error, LocalizedError {
    case productNotFound
    case purchaseFailed(String)
    case restoreFailed(String)
    case verificationFailed
    case networkError
    
    public var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription product not found"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .restoreFailed(let message):
            return "Restore failed: \(message)"
        case .verificationFailed:
            return "Purchase verification failed"
        case .networkError:
            return "Network error occurred"
        }
    }
}

/// Manages subscription operations using StoreKit 2
@MainActor
public class SubscriptionManager: ObservableObject {
    // MARK: - Published Properties
    @Published public var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published public var availableProducts: [Product] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?
    
    // MARK: - Initialization
    public init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Load available subscription products from StoreKit
    public func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let products = try await Product.products(for: SubscriptionProducts.allProductIdentifiers)
            self.availableProducts = products.sorted { $0.price < $1.price }
        } catch {
            self.errorMessage = "Failed to load products: \(error.localizedDescription)"
            self.availableProducts = []
        }
        
        isLoading = false
    }
    
    /// Purchase a subscription product
    public func purchase(productId: String) async throws {
        guard let product = availableProducts.first(where: { $0.id == productId }) else {
            throw SubscriptionError.productNotFound
        }
        
        try await purchase(product)
    }
    
    /// Purchase a subscription product
    public func purchase(_ product: Product) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try await checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()
                
            case .userCancelled:
                // User cancelled, not an error
                break
                
            case .pending:
                // Transaction pending (e.g., parental approval)
                errorMessage = "Purchase is pending approval"
                
            @unknown default:
                throw SubscriptionError.purchaseFailed("Unknown result")
            }
        } catch {
            let errorMessage = error.localizedDescription
            self.errorMessage = errorMessage
            throw SubscriptionError.purchaseFailed(errorMessage)
        }
    }
    
    /// Restore previous purchases
    public func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }
    
    /// Check current subscription status
    public func checkSubscriptionStatus() async {
        await updateSubscriptionStatus()
    }
    
    /// Check if user has premium access (trial or active subscription)
    public func hasPremiumAccess() -> Bool {
        switch subscriptionStatus {
        case .trialActive, .premiumActive:
            return true
        case .notSubscribed, .expired:
            return false
        }
    }
    
    /// Check if trial is currently active
    public func isTrialActive() -> Bool {
        return subscriptionStatus == .trialActive
    }
    
    /// Get remaining trial days
    public func trialDaysRemaining() -> Int {
        // This would be implemented with actual transaction date checking
        // For now, return a placeholder value
        return subscriptionStatus == .trialActive ? 14 : 0
    }
    
    /// Get monthly subscription products
    public func monthlyProducts() -> [Product] {
        return availableProducts.filter { $0.id == SubscriptionProducts.monthly }
    }
    
    /// Get annual subscription products
    public func annualProducts() -> [Product] {
        return availableProducts.filter { $0.id == SubscriptionProducts.annual }
    }
    
    // MARK: - Private Methods
    
    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    // Handle verification failure
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    /// Update subscription status based on current entitlements
    private func updateSubscriptionStatus() async {
        var newStatus: SubscriptionStatus = .notSubscribed
        
        // Check for current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try await checkVerified(result)
                
                // Check if subscription is still valid
                if transaction.productType == .autoRenewable {
                    // Simple subscription status check based on transaction
                    if transaction.expirationDate == nil || 
                       transaction.expirationDate! > Date() {
                        // Check if in trial period based on purchase date
                        // If purchased recently (within 4 weeks), consider it trial
                        let trialPeriod: TimeInterval = Double(SubscriptionProducts.trialPeriodDays) * 24 * 60 * 60
                        let trialEndDate = transaction.purchaseDate.addingTimeInterval(trialPeriod)
                        
                        if Date() < trialEndDate {
                            newStatus = .trialActive
                        } else {
                            newStatus = .premiumActive
                        }
                    } else {
                        newStatus = .expired
                    }
                }
            } catch {
                // Handle verification error
                continue
            }
        }
        
        self.subscriptionStatus = newStatus
    }
    
    /// Check transaction verification
    private func checkVerified<T>(_ result: VerificationResult<T>) async throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}