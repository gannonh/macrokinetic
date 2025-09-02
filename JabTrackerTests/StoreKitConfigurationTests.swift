@testable import JabTracker
import StoreKit
import Testing

@Suite("StoreKit Configuration")
struct StoreKitConfigurationTests {
    @Test("Product identifiers are defined correctly")
    func productIdentifiers() {
        // Test that our product identifiers match StoreKit configuration
        let expectedProductIds = Set([
            "com.gannonhall.jabtracker.premium.monthly",
            "com.gannonhall.jabtracker.premium.annual",
        ])

        let actualProductIds = Set(SubscriptionProducts.allProductIdentifiers)
        #expect(actualProductIds == expectedProductIds)
    }

    @Test("Monthly subscription has correct properties")
    func monthlySubscriptionProperties() {
        let monthlyId = SubscriptionProducts.monthly
        #expect(monthlyId == "com.gannonhall.jabtracker.premium.monthly")
    }

    @Test("Annual subscription has correct properties")
    func annualSubscriptionProperties() {
        let annualId = SubscriptionProducts.annual
        #expect(annualId == "com.gannonhall.jabtracker.premium.annual")
    }

    @Test("Trial period configuration")
    func trialPeriodConfiguration() {
        // 4-week trial = 28 days
        let expectedTrialDays = 28
        let actualTrialDays = SubscriptionProducts.trialPeriodDays
        #expect(actualTrialDays == expectedTrialDays)
    }

    @Test("StoreKit configuration file exists")
    func storeKitConfigurationFileExists() {
        let bundle = Bundle.main
        let configPath = bundle.path(forResource: "JabTrackerStoreKit", ofType: "storekit")
        #expect(configPath != nil, "StoreKit configuration file should exist in main bundle")
    }
}
