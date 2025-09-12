//
//  DoseSearchService.swift
//  JabTracker
//

import Foundation

/// Service for searching and filtering dose data with full-text search capabilities
/// Provides advanced search functionality across all dose fields and related medication data
struct DoseSearchService {
    
    // MARK: - Search Types
    
    enum SearchScope {
        case all
        case notes
        case medication
        case injectionSite
        case amount
        case date
    }
    
    enum SearchMode {
        case contains    // Default - partial matching
        case exact       // Exact matching
        case startsWith  // Prefix matching
        case endsWith    // Suffix matching
    }
    
    // MARK: - Primary Search Methods
    
    /// Perform comprehensive search across all dose fields
    static func searchDoses(
        doses: [Dose],
        searchText: String,
        scope: SearchScope = .all,
        mode: SearchMode = .contains,
        caseSensitive: Bool = false
    ) -> [Dose] {
        guard !searchText.isEmpty else { return doses }
        
        let processedSearchText = caseSensitive ? searchText : searchText.lowercased()
        
        return doses.filter { dose in
            switch scope {
            case .all:
                return searchAllFields(dose: dose, searchText: processedSearchText, mode: mode, caseSensitive: caseSensitive)
            case .notes:
                return searchNotes(dose: dose, searchText: processedSearchText, mode: mode, caseSensitive: caseSensitive)
            case .medication:
                return searchMedication(dose: dose, searchText: processedSearchText, mode: mode, caseSensitive: caseSensitive)
            case .injectionSite:
                return searchInjectionSite(dose: dose, searchText: processedSearchText, mode: mode, caseSensitive: caseSensitive)
            case .amount:
                return searchAmount(dose: dose, searchText: processedSearchText, mode: mode)
            case .date:
                return searchDate(dose: dose, searchText: processedSearchText, mode: mode, caseSensitive: caseSensitive)
            }
        }
    }
    
    /// Search with multiple terms (AND logic)
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
                !searchDoses(
                    doses: [dose],
                    searchText: term,
                    scope: scope,
                    mode: mode,
                    caseSensitive: caseSensitive
                ).isEmpty
            }
        }
    }
    
    /// Search with multiple terms (OR logic)
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
                !searchDoses(
                    doses: [dose],
                    searchText: term,
                    scope: scope,
                    mode: mode,
                    caseSensitive: caseSensitive
                ).isEmpty
            }
        }
    }
    
    // MARK: - Field-Specific Search Methods
    
    private static func searchAllFields(
        dose: Dose,
        searchText: String,
        mode: SearchMode,
        caseSensitive: Bool
    ) -> Bool {
        return searchNotes(dose: dose, searchText: searchText, mode: mode, caseSensitive: caseSensitive) ||
               searchMedication(dose: dose, searchText: searchText, mode: mode, caseSensitive: caseSensitive) ||
               searchInjectionSite(dose: dose, searchText: searchText, mode: mode, caseSensitive: caseSensitive) ||
               searchAmount(dose: dose, searchText: searchText, mode: mode) ||
               searchDate(dose: dose, searchText: searchText, mode: mode, caseSensitive: caseSensitive)
    }
    
    private static func searchNotes(
        dose: Dose,
        searchText: String,
        mode: SearchMode,
        caseSensitive: Bool
    ) -> Bool {
        guard let notes = dose.notes else { return false }
        let targetText = caseSensitive ? notes : notes.lowercased()
        return matchesText(targetText, searchText: searchText, mode: mode)
    }
    
    private static func searchMedication(
        dose: Dose,
        searchText: String,
        mode: SearchMode,
        caseSensitive: Bool
    ) -> Bool {
        guard let medication = dose.medication else { return false }
        
        let genericName = caseSensitive ? medication.genericName : medication.genericName.lowercased()
        let brandName = caseSensitive ? medication.brandName : medication.brandName.lowercased()
        
        return matchesText(genericName, searchText: searchText, mode: mode) ||
               matchesText(brandName, searchText: searchText, mode: mode)
    }
    
    private static func searchInjectionSite(
        dose: Dose,
        searchText: String,
        mode: SearchMode,
        caseSensitive: Bool
    ) -> Bool {
        guard let site = dose.site else { return false }
        let targetText = caseSensitive ? site : site.lowercased()
        return matchesText(targetText, searchText: searchText, mode: mode)
    }
    
    private static func searchAmount(
        dose: Dose,
        searchText: String,
        mode: SearchMode
    ) -> Bool {
        let amountString = String(dose.amount)
        let formattedAmount = String(format: "%.1f", dose.amount)
        let formattedAmountTwoDecimal = String(format: "%.2f", dose.amount)
        
        // Check various amount representations
        return matchesText(amountString, searchText: searchText, mode: mode) ||
               matchesText(formattedAmount, searchText: searchText, mode: mode) ||
               matchesText(formattedAmountTwoDecimal, searchText: searchText, mode: mode)
    }
    
    private static func searchDate(
        dose: Dose,
        searchText: String,
        mode: SearchMode,
        caseSensitive: Bool
    ) -> Bool {
        let dateFormatters = [
            createDateFormatter(dateStyle: .full, timeStyle: .short),
            createDateFormatter(dateStyle: .long, timeStyle: .short),
            createDateFormatter(dateStyle: .medium, timeStyle: .short),
            createDateFormatter(dateStyle: .short, timeStyle: .short),
            createDateFormatter(dateStyle: .medium, timeStyle: .none),
            createDateFormatter(dateStyle: .none, timeStyle: .short)
        ]
        
        for formatter in dateFormatters {
            let dateString = formatter.string(from: dose.timestamp)
            let targetText = caseSensitive ? dateString : dateString.lowercased()
            if matchesText(targetText, searchText: searchText, mode: mode) {
                return true
            }
        }
        
        // Also search individual date components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dose.timestamp)
        
        if let year = components.year, matchesText(String(year), searchText: searchText, mode: mode) {
            return true
        }
        if let month = components.month, matchesText(String(month), searchText: searchText, mode: mode) {
            return true
        }
        if let day = components.day, matchesText(String(day), searchText: searchText, mode: mode) {
            return true
        }
        
        return false
    }
    
    // MARK: - Text Matching Utilities
    
    private static func matchesText(
        _ text: String,
        searchText: String,
        mode: SearchMode
    ) -> Bool {
        switch mode {
        case .contains:
            return text.contains(searchText)
        case .exact:
            return text == searchText
        case .startsWith:
            return text.hasPrefix(searchText)
        case .endsWith:
            return text.hasSuffix(searchText)
        }
    }
    
    private static func createDateFormatter(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter
    }
    
    // MARK: - Advanced Search Features
    
    /// Parse search query for advanced search syntax
    /// Supports:
    /// - "exact phrase" (quoted text)
    /// - medication:semaglutide (field-specific search)
    /// - site:thigh (injection site search)
    /// - amount:>1.0 (amount comparison)
    /// - date:2024-01 (date search)
    static func parseAdvancedSearch(_ query: String) -> SearchQuery {
        var searchQuery = SearchQuery()
        
        // Split query into tokens while preserving quoted strings
        let tokens = tokenizeQuery(query)
        
        for token in tokens {
            if token.hasPrefix("medication:") {
                let value = String(token.dropFirst("medication:".count))
                searchQuery.medicationFilter = value.isEmpty ? nil : value
            } else if token.hasPrefix("site:") {
                let value = String(token.dropFirst("site:".count))
                searchQuery.injectionSiteFilter = value.isEmpty ? nil : value
            } else if token.hasPrefix("amount:") {
                let value = String(token.dropFirst("amount:".count))
                searchQuery.amountFilter = parseAmountFilter(value)
            } else if token.hasPrefix("date:") {
                let value = String(token.dropFirst("date:".count))
                searchQuery.dateFilter = parseDateFilter(value)
            } else if token.hasPrefix("\"") && token.hasSuffix("\"") {
                // Exact phrase search
                let phrase = String(token.dropFirst().dropLast())
                searchQuery.exactPhrases.append(phrase)
            } else {
                // Regular search term
                searchQuery.searchTerms.append(token)
            }
        }
        
        return searchQuery
    }
    
    /// Apply advanced search query to dose array
    static func searchWithAdvancedQuery(doses: [Dose], query: SearchQuery) -> [Dose] {
        var results = doses
        
        // Apply search terms
        if !query.searchTerms.isEmpty {
            results = searchDosesWithMultipleTerms(
                doses: results,
                searchTerms: query.searchTerms,
                scope: .all,
                mode: .contains,
                caseSensitive: false
            )
        }
        
        // Apply exact phrases
        for phrase in query.exactPhrases {
            results = searchDoses(
                doses: results,
                searchText: phrase,
                scope: .all,
                mode: .exact,
                caseSensitive: false
            )
        }
        
        // Apply medication filter
        if let medicationFilter = query.medicationFilter {
            results = results.filter { dose in
                dose.medication?.genericName.lowercased().contains(medicationFilter.lowercased()) == true ||
                dose.medication?.brandName.lowercased().contains(medicationFilter.lowercased()) == true
            }
        }
        
        // Apply injection site filter
        if let siteFilter = query.injectionSiteFilter {
            results = results.filter { dose in
                dose.site?.lowercased().contains(siteFilter.lowercased()) == true
            }
        }
        
        // Apply amount filter
        if let amountFilter = query.amountFilter {
            results = results.filter { dose in
                amountFilter.matches(dose.amount)
            }
        }
        
        // Apply date filter
        if let dateFilter = query.dateFilter {
            results = results.filter { dose in
                dateFilter.contains(dose.timestamp)
            }
        }
        
        return results
    }
    
    // MARK: - Query Parsing Utilities
    
    private static func tokenizeQuery(_ query: String) -> [String] {
        var tokens: [String] = []
        var currentToken = ""
        var inQuotes = false
        
        for char in query {
            if char == "\"" {
                if inQuotes {
                    // End of quoted string
                    currentToken += String(char)
                    tokens.append(currentToken)
                    currentToken = ""
                    inQuotes = false
                } else {
                    // Start of quoted string
                    if !currentToken.isEmpty {
                        tokens.append(currentToken)
                        currentToken = ""
                    }
                    currentToken += String(char)
                    inQuotes = true
                }
            } else if char.isWhitespace && !inQuotes {
                if !currentToken.isEmpty {
                    tokens.append(currentToken)
                    currentToken = ""
                }
            } else {
                currentToken += String(char)
            }
        }
        
        if !currentToken.isEmpty {
            tokens.append(currentToken)
        }
        
        return tokens
    }
    
    private static func parseAmountFilter(_ value: String) -> AmountFilter? {
        if value.hasPrefix(">=") {
            guard let amount = Double(String(value.dropFirst(2))) else { return nil }
            return .greaterThanOrEqual(amount)
        } else if value.hasPrefix("<=") {
            guard let amount = Double(String(value.dropFirst(2))) else { return nil }
            return .lessThanOrEqual(amount)
        } else if value.hasPrefix(">") {
            guard let amount = Double(String(value.dropFirst(1))) else { return nil }
            return .greaterThan(amount)
        } else if value.hasPrefix("<") {
            guard let amount = Double(String(value.dropFirst(1))) else { return nil }
            return .lessThan(amount)
        } else if value.hasPrefix("=") {
            guard let amount = Double(String(value.dropFirst(1))) else { return nil }
            return .equals(amount)
        } else {
            guard let amount = Double(value) else { return nil }
            return .equals(amount)
        }
    }
    
    private static func parseDateFilter(_ value: String) -> DateInterval? {
        let dateFormatter = DateFormatter()
        
        // Try various date formats
        let formats = [
            "yyyy-MM-dd",
            "yyyy-MM",
            "yyyy",
            "MM/dd/yyyy",
            "MM-dd-yyyy"
        ]
        
        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: value) {
                let calendar = Calendar.current
                
                switch format {
                case "yyyy":
                    // Full year
                    let startOfYear = calendar.dateInterval(of: .year, for: date)
                    return startOfYear
                case "yyyy-MM":
                    // Full month
                    let startOfMonth = calendar.dateInterval(of: .month, for: date)
                    return startOfMonth
                default:
                    // Single day
                    let startOfDay = calendar.startOfDay(for: date)
                    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                    return DateInterval(start: startOfDay, end: endOfDay)
                }
            }
        }
        
        return nil
    }
}

// MARK: - Supporting Types

/// Advanced search query structure
struct SearchQuery {
    var searchTerms: [String] = []
    var exactPhrases: [String] = []
    var medicationFilter: String?
    var injectionSiteFilter: String?
    var amountFilter: AmountFilter?
    var dateFilter: DateInterval?
}

/// Amount comparison filter
enum AmountFilter {
    case equals(Double)
    case greaterThan(Double)
    case lessThan(Double)
    case greaterThanOrEqual(Double)
    case lessThanOrEqual(Double)
    
    func matches(_ amount: Double) -> Bool {
        let tolerance = 0.001
        
        switch self {
        case .equals(let target):
            return abs(amount - target) <= tolerance
        case .greaterThan(let target):
            return amount > target
        case .lessThan(let target):
            return amount < target
        case .greaterThanOrEqual(let target):
            return amount >= target || abs(amount - target) <= tolerance
        case .lessThanOrEqual(let target):
            return amount <= target || abs(amount - target) <= tolerance
        }
    }
}