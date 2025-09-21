//
//  TestError.swift
//  JabTrackerTests
//
//  Shared test error types for consistent error handling across all test files
//

import Foundation

/// Common errors that can occur during test execution
enum TestError: Error, CustomStringConvertible {
    case invalidTestData(String)
    case invalidMedicationProfile(String)
    case noSampleData(String)
    case unexpectedNil(String)
    case testSetupFailed(String)

    var description: String {
        switch self {
        case let .invalidTestData(message):
            return "Invalid test data: \(message)"
        case let .invalidMedicationProfile(message):
            return "Invalid medication profile: \(message)"
        case let .noSampleData(message):
            return "No sample data: \(message)"
        case let .unexpectedNil(message):
            return "Unexpected nil value: \(message)"
        case let .testSetupFailed(message):
            return "Test setup failed: \(message)"
        }
    }
}
