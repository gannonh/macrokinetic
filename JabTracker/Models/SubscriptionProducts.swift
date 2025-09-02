import Foundation

/// Defines subscription product identifiers and configuration
enum SubscriptionProducts {
    // MARK: - Product Identifiers

    static let monthly = "com.gannonhall.jabtracker.premium.monthly"
    static let annual = "com.gannonhall.jabtracker.premium.annual"

    static let allProductIdentifiers = [monthly, annual]

    // MARK: - Trial Configuration

    /// 4-week trial period in days
    static let trialPeriodDays = 28
}
