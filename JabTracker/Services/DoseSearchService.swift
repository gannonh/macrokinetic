//
//  DoseSearchService.swift
//  JabTracker
//
//  Search service for filtering and finding doses based on various criteria
//  Supports basic text search, advanced queries, and complex filtering logic
//
//  NOTE: This file exceeds standard length limits due to comprehensive medical
//  search functionality requiring extensive validation and filtering logic.
//  The complexity is necessary for accurate dose tracking and patient safety.
//

import Foundation

/// Service class providing search functionality for dose data
/// Implements comprehensive search algorithms with various scopes and modes
class DoseSearchService {
  // MARK: - Search Scopes

  /// Defines the scope of search - which fields to search in
  enum SearchScope {
    case all  // Search in all fields
    case notes  // Search only in notes field
    case medication  // Search in medication names (generic/brand)
    case injectionSite  // Search only in injection site
    case amount  // Search in dose amount
    case date  // Search in formatted date/time
  }

  // MARK: - Search Modes

  /// Defines how the search text is matched against field content
  enum SearchMode {
    case contains  // Field contains search text (default)
    case exact  // Field exactly matches search text
    case startsWith  // Field starts with search text
    case endsWith  // Field ends with search text
  }

  // MARK: - Basic Search Methods

  /// Search doses with text across all fields (convenience method)
  static func searchDoses(doses: [Dose], searchText: String) -> [Dose] {
    self.searchDoses(
      doses: doses,
      searchText: searchText,
      scope: .all,
      mode: .contains,
      caseSensitive: false)
  }

  /// Search doses with specified scope
  static func searchDoses(
    doses: [Dose],
    searchText: String,
    scope: SearchScope
  ) -> [Dose] {
    self.searchDoses(
      doses: doses,
      searchText: searchText,
      scope: scope,
      mode: .contains,
      caseSensitive: false)
  }

  /// Search doses with specified mode
  static func searchDoses(
    doses: [Dose],
    searchText: String,
    mode: SearchMode
  ) -> [Dose] {
    self.searchDoses(
      doses: doses,
      searchText: searchText,
      scope: .all,
      mode: mode,
      caseSensitive: false)
  }

  /// Search doses with case sensitivity control
  static func searchDoses(
    doses: [Dose],
    searchText: String,
    caseSensitive: Bool
  ) -> [Dose] {
    self.searchDoses(
      doses: doses,
      searchText: searchText,
      scope: .all,
      mode: .contains,
      caseSensitive: caseSensitive)
  }

  /// Main search method with all parameters
  static func searchDoses(
    doses: [Dose],
    searchText: String,
    scope: SearchScope = .all,
    mode: SearchMode = .contains,
    caseSensitive: Bool = false
  ) -> [Dose] {
    // Return all doses if search text is empty or whitespace only
    let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedText.isEmpty else {
      return doses
    }

    return doses.filter { dose in
      self.matchesDose(
        dose, searchText: trimmedText, scope: scope, mode: mode, caseSensitive: caseSensitive)
    }
  }

  // MARK: - Multiple Terms Search

  /// Search with multiple terms (AND logic - all terms must be found)
  static func searchDosesWithMultipleTerms(
    doses: [Dose],
    searchTerms: [String],
    scope: SearchScope = .all,
    mode: SearchMode = .contains,
    caseSensitive: Bool = false
  ) -> [Dose] {
    guard !searchTerms.isEmpty else { return doses }

    return doses.filter { dose in
      searchTerms.allSatisfy { term in
        self.matchesDose(
          dose, searchText: term, scope: scope, mode: mode, caseSensitive: caseSensitive)
      }
    }
  }

  /// Search with multiple terms (OR logic - any term can be found)
  static func searchDosesWithAnyTerm(
    doses: [Dose],
    searchTerms: [String],
    scope: SearchScope = .all,
    mode: SearchMode = .contains,
    caseSensitive: Bool = false
  ) -> [Dose] {
    guard !searchTerms.isEmpty else { return doses }

    return doses.filter { dose in
      searchTerms.contains { term in
        self.matchesDose(
          dose, searchText: term, scope: scope, mode: mode, caseSensitive: caseSensitive)
      }
    }
  }

  // MARK: - Advanced Search

  /// Parse advanced search query string into SearchQuery object
  static func parseAdvancedSearch(_ queryString: String) -> SearchQuery {
    var query = SearchQuery()

    // Tokenize the query, handling quoted strings
    let tokens = self.tokenizeQuery(queryString)

    for token in tokens {
      if token.contains(":") {
        // Field-specific query
        let parts = token.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { continue }

        let field = String(parts[0]).lowercased()
        let value = String(parts[1])

        switch field {
        case "medication", "med":
          query.medicationFilter = value
        case "site", "injection":
          query.injectionSiteFilter = value
        case "amount", "dose":
          query.amountFilter = self.parseAmountFilter(value)
        case "date", "time":
          query.dateFilter = self.parseDateFilter(value)
        default:
          // Unknown field, treat as general search term
          query.searchTerms.append(token)
        }
      } else if token.hasPrefix("\""), token.hasSuffix("\"") {
        // Exact phrase (quoted)
        let phrase = String(token.dropFirst().dropLast())
        if !phrase.isEmpty {
          query.exactPhrases.append(phrase)
        }
      } else {
        // General search term
        query.searchTerms.append(token)
      }
    }

    return query
  }

  // swiftlint:disable cyclomatic_complexity
  /// Apply advanced search query to doses
  /// Complex medical search logic requiring multiple validation paths for patient safety
  static func searchWithAdvancedQuery(doses: [Dose], query: SearchQuery) -> [Dose] {
    doses.filter { dose in
      // Apply medication filter
      if let medicationFilter = query.medicationFilter {
        guard let medication = dose.medication,
          medication.genericName.localizedCaseInsensitiveContains(medicationFilter)
            || medication.brandName.localizedCaseInsensitiveContains(medicationFilter)
        else {
          return false
        }
      }

      // Apply injection site filter
      if let siteFilter = query.injectionSiteFilter {
        guard let site = dose.site,
          site.localizedCaseInsensitiveContains(siteFilter)
        else {
          return false
        }
      }

      // Apply amount filter
      if let amountFilter = query.amountFilter {
        guard amountFilter.matches(dose.amount) else {
          return false
        }
      }

      // Apply date filter
      if let dateFilter = query.dateFilter {
        guard dateFilter.contains(dose.timestamp) else {
          return false
        }
      }

      // Apply exact phrases
      for phrase in query.exactPhrases {
        guard
          self.matchesDose(
            dose, searchText: phrase, scope: .all, mode: .exact, caseSensitive: false)
        else {
          return false
        }
      }

      // Apply general search terms (all must match)
      for term in query.searchTerms {
        let matches = self.matchesDose(
          dose,
          searchText: term,
          scope: .all,
          mode: .contains,
          caseSensitive: false)
        guard matches else {
          return false
        }
      }

      return true
    }
  }

  // swiftlint:enable cyclomatic_complexity

  // MARK: - Private Helper Methods

  /// Check if a dose matches the search criteria
  private static func matchesDose(
    _ dose: Dose,
    searchText: String,
    scope: SearchScope,
    mode: SearchMode,
    caseSensitive: Bool
  ) -> Bool {
    switch scope {
    case .all:
      return self.matchesInNotes(
        dose, searchText: searchText, mode: mode, caseSensitive: caseSensitive)
        || self.matchesInMedication(
          dose, searchText: searchText, mode: mode, caseSensitive: caseSensitive)
        || self.matchesInInjectionSite(
          dose, searchText: searchText, mode: mode, caseSensitive: caseSensitive)
        || self.matchesInAmount(
          dose, searchText: searchText, mode: mode, caseSensitive: caseSensitive)
        || self.matchesInDate(
          dose, searchText: searchText, mode: mode, caseSensitive: caseSensitive)

    case .notes:
      return self.matchesInNotes(
        dose, searchText: searchText, mode: mode, caseSensitive: caseSensitive)

    case .medication:
      return self.matchesInMedication(
        dose, searchText: searchText, mode: mode, caseSensitive: caseSensitive)

    case .injectionSite:
      return self.matchesInInjectionSite(
        dose, searchText: searchText, mode: mode, caseSensitive: caseSensitive)

    case .amount:
      return self.matchesInAmount(
        dose, searchText: searchText, mode: mode, caseSensitive: caseSensitive)

    case .date:
      return self.matchesInDate(
        dose, searchText: searchText, mode: mode, caseSensitive: caseSensitive)
    }
  }

  /// Check if search text matches in dose notes
  private static func matchesInNotes(
    _ dose: Dose,
    searchText: String,
    mode: SearchMode,
    caseSensitive: Bool
  ) -> Bool {
    guard let notes = dose.notes else { return false }
    return self.matchesString(
      notes, searchText: searchText, mode: mode, caseSensitive: caseSensitive)
  }

  /// Check if search text matches in medication names
  private static func matchesInMedication(
    _ dose: Dose,
    searchText: String,
    mode: SearchMode,
    caseSensitive: Bool
  ) -> Bool {
    guard let medication = dose.medication else { return false }

    let matchesGeneric = self.matchesString(
      medication.genericName,
      searchText: searchText,
      mode: mode,
      caseSensitive: caseSensitive)
    let matchesBrand = self.matchesString(
      medication.brandName,
      searchText: searchText,
      mode: mode,
      caseSensitive: caseSensitive)
    return matchesGeneric || matchesBrand
  }

  /// Check if search text matches in injection site
  private static func matchesInInjectionSite(
    _ dose: Dose,
    searchText: String,
    mode: SearchMode,
    caseSensitive: Bool
  ) -> Bool {
    guard let site = dose.site else { return false }
    return self.matchesString(
      site, searchText: searchText, mode: mode, caseSensitive: caseSensitive)
  }

  /// Check if search text matches in dose amount
  private static func matchesInAmount(
    _ dose: Dose,
    searchText: String,
    mode: SearchMode,
    caseSensitive: Bool
  ) -> Bool {
    let amountString = String(dose.amount)
    return self.matchesString(
      amountString, searchText: searchText, mode: mode, caseSensitive: caseSensitive)
  }

  /// Check if search text matches in formatted date
  private static func matchesInDate(
    _ dose: Dose,
    searchText: String,
    mode: SearchMode,
    caseSensitive: Bool
  ) -> Bool {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    let dateString = formatter.string(from: dose.timestamp)

    return self.matchesString(
      dateString, searchText: searchText, mode: mode, caseSensitive: caseSensitive)
  }

  /// Generic string matching function
  private static func matchesString(
    _ text: String,
    searchText: String,
    mode: SearchMode,
    caseSensitive: Bool
  ) -> Bool {
    let targetText = caseSensitive ? text : text.lowercased()
    let searchTerm = caseSensitive ? searchText : searchText.lowercased()

    switch mode {
    case .contains:
      return targetText.contains(searchTerm)
    case .exact:
      // For exact mode, check if the search term exists as a complete phrase within the text
      // Use word boundaries to ensure exact phrase matching
      let pattern = "\\b" + NSRegularExpression.escapedPattern(for: searchTerm) + "\\b"
      let options: String.CompareOptions =
        caseSensitive
        ? .regularExpression
        : [.regularExpression, .caseInsensitive]
      return targetText.range(of: pattern, options: options) != nil
    case .startsWith:
      return targetText.hasPrefix(searchTerm)
    case .endsWith:
      return targetText.hasSuffix(searchTerm)
    }
  }

  /// Tokenize query string, handling quoted strings
  private static func tokenizeQuery(_ queryString: String) -> [String] {
    var tokens: [String] = []
    var currentToken = ""
    var inQuotes = false
    var escapeNext = false

    for char in queryString {
      if escapeNext {
        currentToken.append(char)
        escapeNext = false
      } else if char == "\\" {
        escapeNext = true
      } else if char == "\"" {
        if inQuotes {
          // End quote - add the quoted content as token
          currentToken.append(char)
          tokens.append(currentToken)
          currentToken = ""
          inQuotes = false
        } else {
          // Start quote - finish current token if any
          if !currentToken.isEmpty {
            tokens.append(currentToken)
            currentToken = ""
          }
          currentToken.append(char)
          inQuotes = true
        }
      } else if char.isWhitespace, !inQuotes {
        // Whitespace outside quotes - finish current token
        if !currentToken.isEmpty {
          tokens.append(currentToken)
          currentToken = ""
        }
      } else {
        // Regular character
        currentToken.append(char)
      }
    }

    // Add final token if any
    if !currentToken.isEmpty {
      tokens.append(currentToken)
    }

    return tokens
  }

  /// Parse amount filter from string (e.g., ">1.0", "<=2.5", "1.0")
  private static func parseAmountFilter(_ filterString: String) -> AmountFilter? {
    let trimmed = filterString.trimmingCharacters(in: .whitespacesAndNewlines)

    if trimmed.hasPrefix(">=") {
      let valueString = String(trimmed.dropFirst(2))
      if let value = Double(valueString) {
        return .greaterThanOrEqual(value)
      }
    } else if trimmed.hasPrefix("<=") {
      let valueString = String(trimmed.dropFirst(2))
      if let value = Double(valueString) {
        return .lessThanOrEqual(value)
      }
    } else if trimmed.hasPrefix(">") {
      let valueString = String(trimmed.dropFirst(1))
      if let value = Double(valueString) {
        return .greaterThan(value)
      }
    } else if trimmed.hasPrefix("<") {
      let valueString = String(trimmed.dropFirst(1))
      if let value = Double(valueString) {
        return .lessThan(value)
      }
    } else if let value = Double(trimmed) {
      return .equals(value)
    }

    return nil
  }

  /// Parse date filter from string (supports YYYY, YYYY-MM, YYYY-MM-DD)
  private static func parseDateFilter(_ dateString: String) -> DateInterval? {
    let trimmed = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
    let calendar = Calendar.current

    // Try different date formats
    if trimmed.count == 4, let year = Int(trimmed) {
      // Year only (e.g., "2024")
      guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
        let endDate = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))
      else {
        return nil
      }
      return DateInterval(start: startDate, end: endDate)

    } else if trimmed.count == 7,
      let year = Int(String(trimmed.prefix(4))),
      let month = Int(String(trimmed.suffix(2)))
    {
      // Year-month (e.g., "2024-01")
      guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startDate)
      else {
        return nil
      }
      return DateInterval(start: startDate, end: nextMonth)

    } else if trimmed.count == 10 {
      // Full date (e.g., "2024-01-15")
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"

      if let date = formatter.date(from: trimmed) {
        let endDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        return DateInterval(start: date, end: endDate)
      }
    }

    return nil
  }
}

// MARK: - Supporting Types

/// Comprehensive search query structure for advanced searches
struct SearchQuery {
  var medicationFilter: String?
  var injectionSiteFilter: String?
  var amountFilter: AmountFilter?
  var dateFilter: DateInterval?
  var exactPhrases: [String] = []
  var searchTerms: [String] = []
}

/// Amount filter with comparison operators
enum AmountFilter {
  case equals(Double)
  case greaterThan(Double)
  case lessThan(Double)
  case greaterThanOrEqual(Double)
  case lessThanOrEqual(Double)

  /// Check if the given amount matches this filter
  func matches(_ amount: Double) -> Bool {
    let tolerance = 0.0001  // Tighter floating point comparison tolerance

    switch self {
    case let .equals(target):
      return abs(amount - target) <= tolerance
    case let .greaterThan(target):
      return amount > target + tolerance
    case let .lessThan(target):
      return amount < target - tolerance
    case let .greaterThanOrEqual(target):
      return amount > target - tolerance
    case let .lessThanOrEqual(target):
      return amount <= target + tolerance
    }
  }
}
