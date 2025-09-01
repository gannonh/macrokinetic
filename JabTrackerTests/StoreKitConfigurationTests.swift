import Testing
import StoreKit
@testable import JabTracker

@Suite("StoreKit Configuration")
struct StoreKitConfigurationTests {
    
    @Test("Product identifiers are defined correctly")
    func productIdentifiers() {
        // Test that our product identifiers match StoreKit configuration
        let expectedProductIds = Set([
            "premium_monthly",
            "premium_annual"
        ])
        
        let actualProductIds = Set(SubscriptionProducts.allProductIdentifiers)
        #expect(actualProductIds == expectedProductIds)
    }
    
    @Test("Monthly subscription has correct properties")
    func monthlySubscriptionProperties() {
        let monthlyId = SubscriptionProducts.monthly
        #expect(monthlyId == "premium_monthly")
    }
    
    @Test("Annual subscription has correct properties") 
    func annualSubscriptionProperties() {
        let annualId = SubscriptionProducts.annual
        #expect(annualId == "premium_annual")
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
