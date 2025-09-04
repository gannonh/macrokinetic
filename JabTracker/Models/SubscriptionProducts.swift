import Foundation

/// Defines subscription product identifiers and configuration
public enum SubscriptionProducts {
    // MARK: - Product Identifiers

    public static let monthly = "com.gannonhall.JabTracker.premium.monthly"
    public static let annual = "com.gannonhall.JabTracker.premium.annual"

    public static let allProductIdentifiers = [monthly, annual]

    // MARK: - Trial Configuration

    /// 4-week trial period in days
    public static let trialPeriodDays = 28
}
