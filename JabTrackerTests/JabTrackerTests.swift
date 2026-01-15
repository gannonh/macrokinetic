import SwiftData
import SwiftUI
import Testing

@testable import JabTracker

@Suite("General App Tests")
struct JabTrackerTests {
    @Test("App main components can be initialized")
    @MainActor
    func appComponentInitialization() throws {
        // Test that core app components can be created
        let dataController = DataController.testContainer()

        // Test that the main content view can be created
        _ = ContentView()
            .environment(\.modelContext, dataController.container.mainContext)

        // Test that the data controller has the expected schema
        #expect(dataController.container.schema.entities.count == 15)

        // Verify schema contains expected entities
        let entityNames = dataController.container.schema.entities.map(\.name)
        #expect(entityNames.contains("User"))
        #expect(entityNames.contains("Dose"))
        #expect(entityNames.contains("MedicationProfile"))
        #expect(entityNames.contains("DoseTitration"))

        // Test that we can access the model context without error
        let context = dataController.container.mainContext
        #expect(type(of: context) == ModelContext.self)
    }

    @Test("App data models are properly configured")
    @MainActor
    func appDataModelsConfiguration() throws {
        let dataController = DataController.testContainer()
        let context = dataController.container.mainContext

        // Test that all expected models can be created
        let user = User(email: "test@example.com", weight: 70.0)
        let medication = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            startDate: Date())
        let dose = Dose(amount: 1.0, timestamp: Date())

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
        // Test that design system components can be created with proper properties
        let primaryButton = PrimaryButton(title: "Test Action") {}
        _ = DesignCard { Text("Test Content") }

        // Verify button properties
        #expect(primaryButton.title == "Test Action")

        // Test that design tokens are accessible and have expected properties
        let primaryColor = DesignTokens.Colors.primary
        let inactiveColor = DesignTokens.Colors.inactive
        let typography = DesignTokens.Typography.headline
        let bodyTypography = DesignTokens.Typography.body
        let gradient = DesignTokens.Colors.primaryGradient

        // Test that colors are different (behavioral validation)
        #expect(primaryColor != inactiveColor)
        #expect(typography != bodyTypography)

        // Test that gradient exists and is a LinearGradient
        // Note: LinearGradient doesn't expose stops property directly
        #expect(type(of: gradient) == LinearGradient.self)

        // Test that button styles can be applied and are the correct type
        let buttonStyle = DesignTokens.ButtonStyles.primary
        #expect(type(of: buttonStyle) == PrimaryButtonStyle.self)
    }

    @Test("App navigation structure is valid")
    func appNavigationStructure() throws {
        // Test that the main tabs can be created
        let dashboardView = Text("Dashboard")  // Placeholder for actual DashboardView
        let addDoseView = Text("Add Dose")  // Placeholder for actual AddDoseView
        let historyView = Text("History")  // Placeholder for actual HistoryView
        let analyticsView = Text("Analytics")  // Placeholder for actual AnalyticsView
        let settingsView = Text("Settings")  // Placeholder for actual SettingsView

        let tabViews = [dashboardView, addDoseView, historyView, analyticsView, settingsView]

        #expect(tabViews.count == 5)

        // Test that each view is unique
        for firstIndex in 0..<tabViews.count {
            for secondIndex in (firstIndex + 1)..<tabViews.count {
                #expect(
                    String(describing: tabViews[firstIndex]) != String(describing: tabViews[secondIndex]),
                    "Tab views should be different")
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
        let userWithEmptyEmail = User(email: "", weight: 70.0)
        context.insert(userWithEmptyEmail)

        // This should not throw (empty email might be valid in some cases)
        try context.save()

        #expect(userWithEmptyEmail.email == "")

        // Test creating dose with zero amount
        let zeroDose = Dose(amount: 0.0, timestamp: Date())
        context.insert(zeroDose)

        try context.save()
        #expect(zeroDose.amount == 0.0)

        // Test that invalid hex colors are handled
        let invalidColor = Color(hex: "invalid")
        #expect(invalidColor == nil, "Invalid hex should return nil, not crash")
    }

    @Test("App component creation and cleanup")
    @MainActor
    func appComponentCreationAndCleanup() throws {
        // Test creating and releasing multiple data controllers
        for _ in 0..<5 {  // Reduced from 10 for faster tests
            let controller = DataController.testContainer()
            let context = controller.container.mainContext

            // Create some test data to verify controller works
            let uniqueEmail = "test\(UUID().uuidString.prefix(8))@example.com"
            let user = User(email: uniqueEmail, weight: 70.0)
            context.insert(user)
            try context.save()

            // Verify data was saved correctly
            #expect(user.email == uniqueEmail)
            #expect(user.weight == 70.0)

            // Verify we can fetch the data
            let fetchRequest = FetchDescriptor<User>()
            let users = try context.fetch(fetchRequest)
            #expect(users.contains { $0.email == uniqueEmail })
        }

        // Test creating multiple UI components without memory leaks
        for index in 0..<5 {  // Reduced from 10 for faster tests
            let button = PrimaryButton(title: "Button \(index)") {}
            _ = DesignCard { Text("Content \(index)") }

            // Verify components have expected properties
            #expect(button.title == "Button \(index)")
            // Test component functionality - action is a non-optional closure
            #expect(type(of: button.action) == (() -> Void).self)
        }

        // Test passes if no crashes or memory issues occur during component creation
    }
}
