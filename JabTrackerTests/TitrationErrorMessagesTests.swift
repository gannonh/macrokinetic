//
//  TitrationErrorMessagesTests.swift
//  JabTrackerTests
//
//  Tests for TitrationErrorMessages utility
//

import Foundation
import Testing

@testable import JabTracker

struct TitrationErrorMessagesTests {

    // MARK: - Completion Failed Tests

    @Test("completionFailed returns message with error description")
    func testCompletionFailedWithError() {
        let testError = NSError(
            domain: "TestDomain",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "Test error description"]
        )

        let message = TitrationErrorMessages.completionFailed(testError)

        #expect(message.contains("Failed to complete dose increase"))
        #expect(message.contains("Test error description"))
    }

    @Test("completionFailed handles generic error")
    func testCompletionFailedWithGenericError() {
        struct GenericError: Error {}
        let testError = GenericError()

        let message = TitrationErrorMessages.completionFailed(testError)

        #expect(message.contains("Failed to complete dose increase"))
        // Generic errors have default localizedDescription
        #expect(!message.isEmpty)
    }

    @Test("completionFailed handles custom error types")
    func testCompletionFailedWithCustomError() {
        enum CustomError: LocalizedError {
            case invalidDose

            var errorDescription: String? {
                "Custom dose error"
            }
        }

        let message = TitrationErrorMessages.completionFailed(CustomError.invalidDose)

        #expect(message.contains("Failed to complete dose increase"))
        #expect(message.contains("Custom dose error"))
    }

    // MARK: - Reschedule Failed Tests

    @Test("rescheduleFailed returns message with error description")
    func testRescheduleFailedWithError() {
        let testError = NSError(
            domain: "TestDomain",
            code: 100,
            userInfo: [NSLocalizedDescriptionKey: "Reschedule error description"]
        )

        let message = TitrationErrorMessages.rescheduleFailed(testError)

        #expect(message.contains("Failed to reschedule dose increase"))
        #expect(message.contains("Reschedule error description"))
    }

    @Test("rescheduleFailed handles generic error")
    func testRescheduleFailedWithGenericError() {
        struct GenericError: Error {}
        let testError = GenericError()

        let message = TitrationErrorMessages.rescheduleFailed(testError)

        #expect(message.contains("Failed to reschedule dose increase"))
        #expect(!message.isEmpty)
    }

    @Test("rescheduleFailed handles custom error types")
    func testRescheduleFailedWithCustomError() {
        enum CustomError: LocalizedError {
            case networkFailure

            var errorDescription: String? {
                "Network connection lost"
            }
        }

        let message = TitrationErrorMessages.rescheduleFailed(CustomError.networkFailure)

        #expect(message.contains("Failed to reschedule dose increase"))
        #expect(message.contains("Network connection lost"))
    }

    // MARK: - No Medication Profile Tests

    @Test("noMedicationProfile returns correct message")
    func testNoMedicationProfile() {
        let message = TitrationErrorMessages.noMedicationProfile

        #expect(message == "No medication profile found. Please create a medication profile first.")
    }

    @Test("noMedicationProfile is not empty")
    func testNoMedicationProfileNotEmpty() {
        let message = TitrationErrorMessages.noMedicationProfile

        #expect(!message.isEmpty)
    }

    @Test("noMedicationProfile contains user guidance")
    func testNoMedicationProfileContainsGuidance() {
        let message = TitrationErrorMessages.noMedicationProfile

        #expect(message.contains("medication profile"))
        #expect(message.contains("create"))
    }

    // MARK: - Message Format Consistency Tests

    @Test("completionFailed and rescheduleFailed have consistent format")
    func testErrorMessageFormatConsistency() {
        let testError = NSError(
            domain: "TestDomain",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Test error"]
        )

        let completionMessage = TitrationErrorMessages.completionFailed(testError)
        let rescheduleMessage = TitrationErrorMessages.rescheduleFailed(testError)

        // Both should start with "Failed to" for consistency
        #expect(completionMessage.hasPrefix("Failed to"))
        #expect(rescheduleMessage.hasPrefix("Failed to"))

        // Both should contain error description
        #expect(completionMessage.contains("Test error"))
        #expect(rescheduleMessage.contains("Test error"))
    }

    @Test("all error messages are user-friendly")
    func testUserFriendlyMessages() {
        let testError = NSError(
            domain: "TestDomain",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Test error"]
        )

        let messages = [
            TitrationErrorMessages.completionFailed(testError),
            TitrationErrorMessages.rescheduleFailed(testError),
            TitrationErrorMessages.noMedicationProfile,
        ]

        // All messages should be user-friendly (no technical jargon)
        for message in messages {
            #expect(!message.isEmpty)
            #expect(!message.contains("nil"))
            #expect(!message.contains("null"))
            #expect(!message.contains("undefined"))
        }
    }

    // MARK: - Edge Cases

    @Test("error messages handle very long error descriptions")
    func testLongErrorDescriptions() {
        let longDescription = String(repeating: "error ", count: 100)
        let testError = NSError(
            domain: "TestDomain",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: longDescription]
        )

        let completionMessage = TitrationErrorMessages.completionFailed(testError)
        let rescheduleMessage = TitrationErrorMessages.rescheduleFailed(testError)

        #expect(completionMessage.contains(longDescription))
        #expect(rescheduleMessage.contains(longDescription))
    }

    @Test("error messages handle special characters in error description")
    func testSpecialCharactersInErrorDescription() {
        let specialDescription = "Error with special chars: @#$%^&*()[]{}|\\/<>?~`"
        let testError = NSError(
            domain: "TestDomain",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: specialDescription]
        )

        let message = TitrationErrorMessages.completionFailed(testError)

        #expect(message.contains(specialDescription))
    }
}
