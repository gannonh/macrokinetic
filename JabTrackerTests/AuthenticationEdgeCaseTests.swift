import Foundation
@testable import JabTracker
import SwiftData
import Testing

@Suite("Authentication Edge Cases")
struct AuthenticationEdgeCaseTests {
    @Test("Sign in with Apple maintains state after failure")
    @MainActor
    func signInWithAppleStateAfterFailure() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test initial state
        #expect(authManager.authenticationState == .notDetermined)
        #expect(authManager.currentUser == nil)

        // Test that failed sign in attempt leaves authentication in consistent state
        Task {
            var didThrowError = false
            do {
                _ = try await authManager.signInWithApple()
            } catch {
                didThrowError = true
                // After failure, state should remain consistent
                #expect(authManager.authenticationState == .notDetermined,
                        "State should remain notDetermined after failed sign in")
                #expect(authManager.currentUser == nil,
                        "currentUser should remain nil after failed sign in")
            }
            #expect(didThrowError, "signInWithApple should fail in test environment")
        }
    }
}
