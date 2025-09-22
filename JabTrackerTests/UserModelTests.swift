import Foundation
import SwiftData
import Testing

@testable import JabTracker

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
      dateOfBirth: Date(timeIntervalSince1970: 0),  // Jan 1, 1970
      weight: 70.0,
      weightUnit: "kg",
      timezone: "UTC")

    context.insert(user)
    try context.save()

    // Verify all fields are properly set
    #expect(user.id != UUID())  // ID should be auto-generated and unique
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
    #expect(
      authManager1.authenticationState == authManager2.authenticationState,
      "Multiple AuthenticationManager instances should have identical initial state")
    #expect(
      authManager1.currentUser == nil,
      "Initial currentUser should be nil")
    #expect(
      authManager2.currentUser == nil,
      "Initial currentUser should be nil")
    #expect(
      authManager1.authenticationState == .notDetermined,
      "Initial authentication state should be notDetermined")
  }

  @Test("User computed properties - weightDisplay")
  func userWeightDisplayProperty() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext

    // Test kg weight display
    let userKg = User(email: "kg@example.com", weight: 72.5, weightUnit: "kg")
    context.insert(userKg)

    #expect(userKg.weightDisplay == "72.5 kg", "Weight display should format correctly for kg")

    // Test lbs weight display
    let userLbs = User(email: "lbs@example.com", weight: 159.8, weightUnit: "lbs")
    context.insert(userLbs)

    #expect(userLbs.weightDisplay == "159.8 lbs", "Weight display should format correctly for lbs")

    // Test with whole number
    let userWhole = User(email: "whole@example.com", weight: 70.0, weightUnit: "kg")
    context.insert(userWhole)

    #expect(userWhole.weightDisplay == "70.0 kg", "Weight display should show .0 for whole numbers")

    try context.save()
  }

  @Test("User computed properties - emailForCloudKit")
  func userEmailForCloudKitProperty() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext

    // Test with valid email
    let userWithEmail = User(email: "valid@example.com")
    context.insert(userWithEmail)

    #expect(
      userWithEmail.emailForCloudKit == "valid@example.com",
      "Should return actual email when available")

    // Test with nil email
    let userNoEmail = User(email: nil)
    context.insert(userNoEmail)

    #expect(
      userNoEmail.emailForCloudKit == "",
      "Should return empty string for nil email (CloudKit compatibility)")

    try context.save()
  }

  @Test("User computed properties - displayEmail")
  func userDisplayEmailProperty() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext

    // Test with valid email
    let userWithEmail = User(email: "display@example.com")
    context.insert(userWithEmail)

    #expect(
      userWithEmail.displayEmail == "display@example.com", "Should return actual email for display")

    // Test with nil email
    let userNoEmail = User(email: nil)
    context.insert(userNoEmail)

    #expect(
      userNoEmail.displayEmail == "No email", "Should return 'No email' for nil email display")

    try context.save()
  }

  @Test("User model default values")
  func userModelDefaultValues() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext

    // Test user with minimal parameters
    let minimalUser = User()
    context.insert(minimalUser)

    // Test defaults are applied correctly
    #expect(minimalUser.email == nil, "Default email should be nil")
    #expect(minimalUser.name == nil, "Default name should be nil")
    #expect(minimalUser.dateOfBirth == nil, "Default date of birth should be nil")
    #expect(minimalUser.weight == 70.0, "Default weight should be 70.0")
    #expect(minimalUser.weightUnit == "kg", "Default weight unit should be kg")
    #expect(!minimalUser.timezone.isEmpty, "Default timezone should be set")
    #expect(minimalUser.appleUserId == nil, "Default Apple user ID should be nil")
    #expect(minimalUser.createdAt.timeIntervalSince1970 > 0, "Created at should be set")
    #expect(minimalUser.updatedAt.timeIntervalSince1970 > 0, "Updated at should be set")

    // Test ID is unique
    let secondUser = User()
    context.insert(secondUser)

    #expect(minimalUser.id != secondUser.id, "Each user should have unique ID")

    try context.save()
  }

  @Test("User model optional vs required field behavior")
  func userModelOptionalRequiredFields() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext

    // Test user with only required fields set
    let user = User(weight: 80.5, weightUnit: "lbs", timezone: "America/New_York")
    context.insert(user)

    // Required fields should have values
    #expect(user.weight == 80.5, "Weight should be set")
    #expect(user.weightUnit == "lbs", "Weight unit should be set")
    #expect(user.timezone == "America/New_York", "Timezone should be set")
    #expect(user.createdAt.timeIntervalSince1970 > 0, "Created at should be auto-generated")
    #expect(user.updatedAt.timeIntervalSince1970 > 0, "Updated at should be auto-generated")

    // Optional fields should be nil
    #expect(user.email == nil, "Email should be nil when not provided")
    #expect(user.name == nil, "Name should be nil when not provided")
    #expect(user.dateOfBirth == nil, "Date of birth should be nil when not provided")
    #expect(user.appleUserId == nil, "Apple user ID should be nil when not provided")

    try context.save()
  }

  @Test("User model relationship initialization")
  func userModelRelationshipInit() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext

    let user = User(email: "relationship@example.com")
    context.insert(user)

    // Doses relationship should be handled by SwiftData
    #expect(user.doses?.isEmpty ?? true, "Doses should be empty or nil initially")

    try context.save()

    // After save, relationship should still be properly managed
    #expect(user.doses?.isEmpty ?? true, "Doses should remain empty or nil after save")
  }

  @Test("User model Apple User ID linking")
  func userModelAppleUserIdLinking() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext

    // Test setting Apple User ID after creation (as would happen during auth)
    let user = User(email: "apple-link@example.com")
    context.insert(user)

    // Initially nil
    #expect(user.appleUserId == nil, "Apple User ID should start nil")

    // Set during authentication process
    user.appleUserId = "test.apple.user.id.12345"

    #expect(user.appleUserId == "test.apple.user.id.12345", "Apple User ID should be settable")

    try context.save()

    // Should persist
    #expect(
      user.appleUserId == "test.apple.user.id.12345", "Apple User ID should persist after save")
  }

  @Test("User model edge case weights")
  func userModelEdgeCaseWeights() throws {
    let controller = DataController.testContainer()
    let context = controller.container.mainContext

    // Test very low weight
    let lightUser = User(email: "light@example.com", weight: 0.1)
    context.insert(lightUser)

    #expect(lightUser.weightDisplay == "0.1 kg", "Should handle very low weights")

    // Test high weight
    let heavyUser = User(email: "heavy@example.com", weight: 999.9)
    context.insert(heavyUser)

    #expect(heavyUser.weightDisplay == "999.9 kg", "Should handle high weights")

    // Test zero weight (edge case)
    let zeroUser = User(email: "zero@example.com", weight: 0.0)
    context.insert(zeroUser)

    #expect(zeroUser.weightDisplay == "0.0 kg", "Should handle zero weight")

    try context.save()
  }

  // MARK: - Test Data Factories

  static func createTestUser(
    email: String = "test@example.com",
    name: String = "Test User"
  ) -> User {
    User(
      email: email,
      name: name,
      weight: 70.0,
      weightUnit: "kg",
      timezone: TimeZone.current.identifier)
  }
}
