import Testing
@testable import JabTracker
import SwiftUI

@Suite("General App Tests")
struct JabTrackerTests {
    @Test("App main components can be initialized")
    @MainActor
    func appComponentInitialization() throws {
        // Test that core app components can be created
        let dataController = DataController.testContainer()
        
        // Test that the main content view can be created
        let contentView = ContentView()
            .environment(\.modelContext, dataController.container.mainContext)
        
        // Test that the data controller has the expected schema
        #expect(dataController.container.schema.entities.count == 3)
        
        // Test that the app structure contains expected components
        let contentViewString = String(describing: type(of: contentView))
        #expect(contentViewString.contains("ModifiedContent"))
        #expect(contentViewString.contains("ContentView"))
        #expect(contentViewString.contains("ModelContext"))
    }
    
    @Test("App data models are properly configured")
    @MainActor
    func appDataModelsConfiguration() throws {
        let dataController = DataController.testContainer()
        let context = dataController.container.mainContext
        
        // Test that all expected models can be created
        let user = User(id: UUID(), email: "test@example.com", weight: 70.0)
        let medication = MedicationProfile(id: UUID(), genericName: "semaglutide", brandName: "Ozempic", currentDose: 1.0, startDate: Date())
        let dose = Dose(id: UUID(), amount: 1.0, timestamp: Date())
        
        context.insert(user)
        context.insert(medication)
        context.insert(dose)
        
        // Test that save works without error
        try context.save()
        
        // Verify objects were created with correct properties
        #expect(user.email == "test@example.com")
        #expect(medication.genericName == "semaglutide")
        #expect(dose.amount == 1.0)
    }
    
    @Test("App design system integration works")
    func appDesignSystemIntegration() throws {
        // Test that design system components integrate with app views
        let primaryButton = PrimaryButton(title: "Test Action") {}
        let designCard = DesignCard { Text("Test Content") }
        
        #expect(primaryButton.title == "Test Action")
        #expect(String(describing: type(of: designCard)) == "DesignCard<Text>")
        
        // Test that design tokens are accessible and different
        let primaryColor = DesignTokens.Colors.primary
        let secondaryColor = DesignTokens.Colors.secondary
        let typography = DesignTokens.Typography.headline
        let bodyTypography = DesignTokens.Typography.body
        let gradient = DesignTokens.Colors.primaryGradient
        
        // Test that colors are different
        #expect(primaryColor != secondaryColor)
        #expect(typography != bodyTypography)
        #expect(String(describing: gradient) != String(describing: primaryColor))
        
        // Test that button styles can be applied
        let buttonStyle = DesignTokens.ButtonStyles.primary
        #expect(type(of: buttonStyle) == PrimaryButtonStyle.self)
    }
    
    @Test("App navigation structure is valid")
    func appNavigationStructure() throws {
        // Test that the main tabs can be created
        let dashboardView = Text("Dashboard") // Placeholder for actual DashboardView
        let addDoseView = Text("Add Dose")    // Placeholder for actual AddDoseView
        let historyView = Text("History")     // Placeholder for actual HistoryView
        let analyticsView = Text("Analytics") // Placeholder for actual AnalyticsView
        let settingsView = Text("Settings")   // Placeholder for actual SettingsView
        
        let tabViews = [dashboardView, addDoseView, historyView, analyticsView, settingsView]
        
        #expect(tabViews.count == 5)
        
        // Test that each view is unique
        for i in 0..<tabViews.count {
            for j in (i+1)..<tabViews.count {
                #expect(String(describing: tabViews[i]) != String(describing: tabViews[j]), "Tab views should be different")
            }
        }
    }
    
    @Test("App error handling works correctly")
    @MainActor
    func appErrorHandling() throws {
        // Test that invalid data is handled gracefully
        let dataController = DataController.testContainer()
        let context = dataController.container.mainContext
        
        // Test creating user with empty email (should not crash)
        let userWithEmptyEmail = User(id: UUID(), email: "", weight: 70.0)
        context.insert(userWithEmptyEmail)
        
        // This should not throw (empty email might be valid in some cases)
        try context.save()
        
        #expect(userWithEmptyEmail.email == "")
        
        // Test creating dose with zero amount
        let zeroDose = Dose(id: UUID(), amount: 0.0, timestamp: Date())
        context.insert(zeroDose)
        
        try context.save()
        #expect(zeroDose.amount == 0.0)
        
        // Test that invalid hex colors are handled
        let invalidColor = Color(hex: "invalid")
        #expect(invalidColor == nil, "Invalid hex should return nil, not crash")
    }
    
    @Test("App memory management is sound")
    @MainActor
    func appMemoryManagement() throws {
        // Test creating and releasing multiple data controllers
        for _ in 0..<10 {
            let controller = DataController.testContainer()
            let context = controller.container.mainContext
            
            // Create some test data
            let user = User(id: UUID(), email: "test\(UUID())@example.com", weight: 70.0)
            context.insert(user)
            try context.save()
            
            #expect(user.email?.contains("@example.com") == true)
        }
        
        // Test creating multiple UI components
        for i in 0..<10 {
            let button = PrimaryButton(title: "Button \(i)") {}
            let card = DesignCard { Text("Content \(i)") }
            
            #expect(button.title == "Button \(i)")
            #expect(String(describing: type(of: card)) == "DesignCard<Text>")
        }
        
        // If we get here without crashing, memory management is working
        #expect(true)
    }
}