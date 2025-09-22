import Foundation
import Testing

@testable import JabTracker

@Suite("Authentication Enum Tests")
struct AuthenticationEnumTests {
  @Test("Authentication error types and descriptions")
  func authenticationErrorTypes() throws {
    // Test all AuthenticationError cases have proper descriptions
    let notImplemented = AuthenticationError.notImplemented
    #expect(
      notImplemented.errorDescription?.contains("not fully implemented") == true,
      "notImplemented should have descriptive error message")

    let authDenied = AuthenticationError.authorizationDenied
    #expect(
      authDenied.errorDescription?.contains("denied authorization") == true,
      "authorizationDenied should have descriptive error message")

    let credentialsNotFound = AuthenticationError.credentialsNotFound
    #expect(
      credentialsNotFound.errorDescription?.contains("credentials found") == true,
      "credentialsNotFound should have descriptive error message")

    let keychainError = AuthenticationError.keychainError
    #expect(
      keychainError.errorDescription?.contains("Keychain") == true,
      "keychainError should have descriptive error message")
  }

  @Test("Authentication state enum all cases")
  func authenticationStateEnumCases() throws {
    // Test all AuthenticationState cases exist and have proper raw values
    let states: [AuthenticationState] = [
      .notDetermined, .authenticated, .notAuthenticated, .restricted, .expired,
    ]

    #expect(states.count == 5, "Should have exactly 5 authentication states")
    #expect(AuthenticationState.notDetermined.rawValue == "notDetermined")
    #expect(AuthenticationState.authenticated.rawValue == "authenticated")
    #expect(AuthenticationState.notAuthenticated.rawValue == "notAuthenticated")
    #expect(AuthenticationState.restricted.rawValue == "restricted")
    #expect(AuthenticationState.expired.rawValue == "expired")

    // Test CaseIterable conformance
    #expect(AuthenticationState.allCases.count == 5, "allCases should contain all 5 states")
  }
}
