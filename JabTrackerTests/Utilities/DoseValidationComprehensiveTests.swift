//
//  DoseValidationComprehensiveTests.swift
//  JabTrackerTests
//

import Foundation
import Testing

@testable import JabTracker

/// Test suite for comprehensive dose validation and integration testing
@Suite("Comprehensive Dose Validation Tests")
struct DoseValidationComprehensiveTests {
  // MARK: - Temporal Validation Tests

  @Suite("Temporal Validation")
  struct TemporalValidationTests {
    @Test("Valid dose timing for different medications")
    func validDoseTiming() async throws {
      let now = Date()

      // Daily medication (liraglutide) - 24 hours apart
      let yesterday = now.addingTimeInterval(-25 * 60 * 60)  // 25 hours ago
      #expect(DoseValidation.isValidDoseTiming(now, lastDoseDate: yesterday, for: .liraglutide))

      // Weekly medication (semaglutide) - 7 days apart
      let lastWeek = now.addingTimeInterval(-7 * 24 * 60 * 60)  // 7 days ago
      #expect(DoseValidation.isValidDoseTiming(now, lastDoseDate: lastWeek, for: .semaglutide))

      // First dose (no previous dose)
      #expect(DoseValidation.isValidDoseTiming(now, lastDoseDate: nil, for: .semaglutide))
      #expect(DoseValidation.isValidDoseTiming(now, lastDoseDate: nil, for: .liraglutide))
    }

    @Test("Invalid dose timing is rejected")
    func testInvalidDoseTiming() async throws {
      let now = Date()

      // Daily medication - too soon (less than 20 hours)
      let tooRecent = now.addingTimeInterval(-10 * 60 * 60)  // 10 hours ago
      #expect(!DoseValidation.isValidDoseTiming(now, lastDoseDate: tooRecent, for: .liraglutide))

      // Weekly medication - too soon (less than 6 days)
      let tooRecentWeekly = now.addingTimeInterval(-5 * 24 * 60 * 60)  // 5 days ago
      #expect(
        !DoseValidation.isValidDoseTiming(now, lastDoseDate: tooRecentWeekly, for: .semaglutide))
      #expect(
        !DoseValidation.isValidDoseTiming(now, lastDoseDate: tooRecentWeekly, for: .tirzepatide))
      #expect(
        !DoseValidation.isValidDoseTiming(now, lastDoseDate: tooRecentWeekly, for: .dulaglutide))
    }

    @Test("Dose date validation")
    func doseDateValidation() async throws {
      let now = Date()

      // Current time and recent past should be valid
      #expect(DoseValidation.isValidDoseDate(now))
      #expect(DoseValidation.isValidDoseDate(now.addingTimeInterval(-60)))  // 1 minute ago
      #expect(DoseValidation.isValidDoseDate(now.addingTimeInterval(-3600)))  // 1 hour ago

      // Small tolerance for clock skew (5 minutes) - these should be valid
      #expect(DoseValidation.isValidDoseDate(now.addingTimeInterval(60)))  // 1 minute future - within tolerance
      #expect(DoseValidation.isValidDoseDate(now.addingTimeInterval(300)))  // 5 minutes future - exactly at tolerance

      // Future dates beyond tolerance should be invalid
      #expect(!DoseValidation.isValidDoseDate(now.addingTimeInterval(301)))  // Just over tolerance
      #expect(!DoseValidation.isValidDoseDate(now.addingTimeInterval(3600)))  // 1 hour future
      #expect(!DoseValidation.isValidDoseDate(now.addingTimeInterval(24 * 60 * 60)))  // 1 day future
    }

    @Test("Historical date validation")
    func historicalDateValidation() async throws {
      let now = Date()

      // Recent dates should be valid
      #expect(DoseValidation.isReasonableHistoricalDate(now))
      #expect(DoseValidation.isReasonableHistoricalDate(now.addingTimeInterval(-30 * 24 * 60 * 60)))  // 30 days ago
      #expect(
        DoseValidation.isReasonableHistoricalDate(now.addingTimeInterval(-365 * 24 * 60 * 60)))  // 1 year ago

      // Very old dates should be invalid
      #expect(
        !DoseValidation.isReasonableHistoricalDate(now.addingTimeInterval(-366 * 24 * 60 * 60)))  // Over 1 year ago
      #expect(
        !DoseValidation.isReasonableHistoricalDate(now.addingTimeInterval(-2 * 365 * 24 * 60 * 60)))  // 2 years ago

      // Custom max past days
      #expect(
        DoseValidation.isReasonableHistoricalDate(
          now.addingTimeInterval(-90 * 24 * 60 * 60), maxPastDays: 90))  // 90 days ago with 90 day limit
      #expect(
        !DoseValidation.isReasonableHistoricalDate(
          now.addingTimeInterval(-91 * 24 * 60 * 60), maxPastDays: 90))  // Over 90 day limit
    }

    @Test("Timing boundary conditions")
    func timingBoundaryConditions() async throws {
      let now = Date()

      // Exact minimum intervals
      let exactDailyInterval = now.addingTimeInterval(-20 * 60 * 60)  // Exactly 20 hours
      #expect(
        DoseValidation.isValidDoseTiming(now, lastDoseDate: exactDailyInterval, for: .liraglutide))

      let exactWeeklyInterval = now.addingTimeInterval(-6 * 24 * 60 * 60)  // Exactly 6 days
      #expect(
        DoseValidation.isValidDoseTiming(now, lastDoseDate: exactWeeklyInterval, for: .semaglutide))

      // Just under minimum intervals
      let justUnderDaily = now.addingTimeInterval(-20 * 60 * 60 + 1)  // 1 second less than 20 hours
      #expect(
        !DoseValidation.isValidDoseTiming(now, lastDoseDate: justUnderDaily, for: .liraglutide))

      let justUnderWeekly = now.addingTimeInterval(-6 * 24 * 60 * 60 + 1)  // 1 second less than 6 days
      #expect(
        !DoseValidation.isValidDoseTiming(now, lastDoseDate: justUnderWeekly, for: .semaglutide))
    }
  }

  // MARK: - Comprehensive Dose Validation Tests

  @Suite("Complete Dose Entry Validation")
  struct CompleteDoseValidationTests {
    @Test("Valid complete dose entry")
    func validCompleteDoseEntry() async throws {
      let now = Date()
      let lastWeek = now.addingTimeInterval(-7 * 24 * 60 * 60)
      let previousSites = ["Abdomen", "Upper Arm", "Buttocks"]

      let result = DoseValidation.validateDose(
        amount: 1.0,
        date: now,
        site: "Thigh",
        medication: .semaglutide,
        brand: "Ozempic",
        lastDoseDate: lastWeek,
        previousSites: previousSites)

      #expect(result.isValid)
      #expect(result.errors.isEmpty)
      #expect(result.errorDescription == nil)
    }

    @Test("Invalid dose amount error")
    func invalidDoseAmountError() async throws {
      let now = Date()

      let result = DoseValidation.validateDose(
        amount: 3.0,  // Not available for Ozempic
        date: now,
        site: "Thigh",
        medication: .semaglutide,
        brand: "Ozempic",
        lastDoseDate: nil,
        previousSites: [])

      #expect(!result.isValid)
      #expect(result.errors.count == 1)

      if case let .invalidDoseAmount(amount, medication, brand) = result.errors.first {
        #expect(amount == 3.0)
        #expect(medication == .semaglutide)
        #expect(brand == "Ozempic")
      } else {
        Issue.record("Expected invalidDoseAmount error")
      }

      #expect(result.errorDescription?.contains("3.0 mg is not available") == true)
    }

    @Test("Multiple validation errors")
    func multipleValidationErrors() async throws {
      let futureDate = Date().addingTimeInterval(24 * 60 * 60)  // 1 day future
      let tooRecentDate = Date().addingTimeInterval(-1 * 60 * 60)  // 1 hour ago

      let result = DoseValidation.validateDose(
        amount: 50.0,  // Invalid amount
        date: futureDate,  // Future date
        site: "Face",  // Invalid site
        medication: .semaglutide,
        brand: "Ozempic",
        lastDoseDate: tooRecentDate,  // Too recent
        previousSites: ["Thigh"])

      #expect(!result.isValid)
      #expect(result.errors.count >= 3)  // At least 3 errors expected

      // Check for specific error types
      #expect(
        result.errors.contains {
          if case .invalidDoseAmount = $0 { return true }
          return false
        })
      #expect(
        result.errors.contains {
          if case .futureDate = $0 { return true }
          return false
        })
      #expect(
        result.errors.contains {
          if case .invalidInjectionSite = $0 { return true }
          return false
        })
      #expect(
        result.errors.contains {
          if case .invalidDoseTiming = $0 { return true }
          return false
        })
    }

    @Test("Dose validation without injection site")
    func doseValidationWithoutInjectionSite() async throws {
      let now = Date()

      let result = DoseValidation.validateDose(
        amount: 1.0,
        date: now,
        site: nil,  // No injection site provided
        medication: .semaglutide,
        brand: "Ozempic",
        lastDoseDate: nil,
        previousSites: [])

      #expect(result.isValid)  // Should be valid - injection site is optional
      #expect(result.errors.isEmpty)
    }

    @Test("Error descriptions are user-friendly")
    func errorDescriptionsAreUserFriendly() async throws {
      let futureDate = Date().addingTimeInterval(3600)

      let result = DoseValidation.validateDose(
        amount: 100.0,
        date: futureDate,
        site: "InvalidSite",
        medication: .tirzepatide,
        brand: "Mounjaro",
        lastDoseDate: nil,
        previousSites: [])

      #expect(!result.isValid)
      let description = result.errorDescription
      #expect(description != nil)

      // Should contain helpful information
      #expect(description?.contains("100.0 mg is not available") == true)
      #expect(description?.contains("cannot be in the future") == true)
      #expect(description?.contains("InvalidSite") == true)
      #expect(description?.contains("safe injection site") == true)
    }
  }

  // MARK: - Edge Cases and Input Handling

  @Suite("Edge Cases and Input Handling")
  struct EdgeCasesTests {
    @Test("Empty and nil input handling")
    func emptyAndNilInputHandling() async throws {
      let now = Date()

      // Empty injection site array
      #expect(DoseValidation.isValidSiteRotation("Thigh", previousSites: []))

      // Nil injection site in comprehensive validation
      let result = DoseValidation.validateDose(
        amount: 1.0,
        date: now,
        site: nil,
        medication: .semaglutide,
        brand: "Ozempic",
        lastDoseDate: nil,
        previousSites: [])
      #expect(result.isValid)

      // Empty strings in site validation
      #expect(!DoseValidation.isValidInjectionSite(""))
      #expect(!DoseValidation.isValidInjectionSite("   "))
    }

    @Test("ValidationResult error handling")
    func validationResultErrorHandling() async throws {
      // Test empty errors
      let validResult = ValidationResult(isValid: true, errors: [])
      #expect(validResult.isValid)
      #expect(validResult.errors.isEmpty)
      #expect(validResult.errorDescription == nil)

      // Test single error
      let singleErrorResult = ValidationResult(
        isValid: false,
        errors: [.invalidDoseAmount(amount: 5.0, medication: .semaglutide, brand: "Ozempic")])
      #expect(!singleErrorResult.isValid)
      #expect(singleErrorResult.errors.count == 1)
      #expect(singleErrorResult.errorDescription?.contains("5.0 mg is not available") == true)

      // Test multiple errors formatting
      let multiErrorResult = ValidationResult(
        isValid: false,
        errors: [
          .futureDate(date: Date()),
          .invalidInjectionSite(site: "Face"),
        ])
      #expect(!multiErrorResult.isValid)
      #expect(multiErrorResult.errors.count == 2)
      let description = multiErrorResult.errorDescription ?? ""
      #expect(description.contains("cannot be in the future"))
      #expect(description.contains("safe injection site"))
    }
  }
}
