import Foundation
import Testing

@testable import JabTracker

@Suite("Authentication Enum Tests")
struct AuthenticationEnumTests {
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
