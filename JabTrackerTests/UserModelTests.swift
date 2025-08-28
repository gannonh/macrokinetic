import Foundation
@testable import JabTracker
import SwiftData
import Testing

@MainActor
@Suite("User SwiftData Model Tests")
struct UserModelTests {
    @Test("User model has all required fields")
    func userModelRequiredFields() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Test creating user with all required fields as per Issue #11
        let user = User(
            email: "test@example.com",
            name: "Test User",
            dateOfBirth: Date(timeIntervalSince1970: 0), // Jan 1, 1970
            weight: 70.0,
            weightUnit: "kg",
            timezone: "UTC")

        context.insert(user)
        try context.save()

        // Verify all fields are properly set
        #expect(user.id != UUID()) // ID should be auto-generated and unique
        #expect(user.email == "test@example.com")
        #expect(user.name == "Test User")
        #expect(user.dateOfBirth != nil)
        #expect(user.weight == 70.0)
        #expect(user.weightUnit == "kg")
        #expect(user.timezone == "UTC")
        // createdAt and updatedAt are Date objects (non-optional), so they always exist
        #expect(user.createdAt.timeIntervalSince1970 > 0)
        #expect(user.updatedAt.timeIntervalSince1970 > 0)
    }

    @Test("User weight unit validation")
    func userWeightUnitValidation() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Test with kg
        let userKg = User(
            email: "kg-user@example.com",
            weight: 70.0,
            weightUnit: "kg")
        context.insert(userKg)

        // Test with lbs
        let userLbs = User(
            email: "lbs-user@example.com",
            weight: 154.0,
            weightUnit: "lbs")
        context.insert(userLbs)

        try context.save()

        #expect(userKg.weightUnit == "kg")
        #expect(userLbs.weightUnit == "lbs")
    }

    @Test("User with Apple ID association")
    func userAppleIDAssociation() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Test user creation with Apple ID (this will be the identifier)
        let user = User(
            email: "apple.user@icloud.com",
            name: "Apple User")

        // Apple ID would be stored as the primary identifier
        // In real implementation, this would come from Sign in with Apple response

        context.insert(user)
        try context.save()

        #expect(user.email == "apple.user@icloud.com")
        #expect(user.name == "Apple User")
    }

    @Test("Authentication manager maintains clean initial state")
    func authenticationManagerCleanInitialState() throws {
        // This test verifies the AuthenticationManager initializes with expected state
        // after consolidation work - consistent behavior across instances
        let dataController = DataController.testContainer()

        // Create multiple instances to verify consistent initialization
        let authManager1 = AuthenticationManager(dataController: dataController)
        let authManager2 = AuthenticationManager(dataController: dataController)

        // Both instances should have identical initial state (consolidated behavior)
        #expect(authManager1.authenticationState == authManager2.authenticationState,
                "Multiple AuthenticationManager instances should have identical initial state")
        #expect(authManager1.currentUser == nil,
                "Initial currentUser should be nil")
        #expect(authManager2.currentUser == nil,
                "Initial currentUser should be nil")
        #expect(authManager1.authenticationState == .notDetermined,
                "Initial authentication state should be notDetermined")
    }

    // MARK: - Test Data Factories

    static func createTestUser(
        email: String = "test@example.com",
        name: String = "Test User") -> User
    {
        User(
            email: email,
            name: name,
            weight: 70.0,
            weightUnit: "kg",
            timezone: TimeZone.current.identifier)
    }
}
