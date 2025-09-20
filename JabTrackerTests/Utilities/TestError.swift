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
        case .invalidTestData(let message):
            return "Invalid test data: \(message)"
        case .invalidMedicationProfile(let message):
            return "Invalid medication profile: \(message)"
        case .noSampleData(let message):
            return "No sample data: \(message)"
        case .unexpectedNil(let message):
            return "Unexpected nil value: \(message)"
        case .testSetupFailed(let message):
            return "Test setup failed: \(message)"
        }
    }
}
