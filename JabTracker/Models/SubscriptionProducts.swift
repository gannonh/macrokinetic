import Foundation

/// Defines subscription product identifiers and configuration
enum SubscriptionProducts {
    // MARK: - Product Identifiers

    static let monthly = "premium_monthly"
    static let annual = "premium_annual"

    static let allProductIdentifiers = [monthly, annual]

    // MARK: - Trial Configuration

    /// 4-week trial period in days
    static let trialPeriodDays = 28
}
