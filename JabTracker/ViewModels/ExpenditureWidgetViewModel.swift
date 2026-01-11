//
//  ExpenditureWidgetViewModel.swift
//  JabTracker
//
//  ViewModel for ExpenditureWidget - provides TDEE expenditure data.
//

import Foundation
import OSLog
import SwiftData

/// ViewModel providing TDEE expenditure data for ExpenditureWidget
@MainActor
@Observable
final class ExpenditureWidgetViewModel {

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "ExpenditureWidgetViewModel"
    )

    private let context: ModelContext

    // MARK: - Published State

    /// Whether data is currently loading
    private(set) var isLoading: Bool = false

    /// Current TDEE value (nil if not calculated)
    private(set) var tdee: Double?

    /// Whether TDEE data exists
    var hasData: Bool {
        tdee != nil
    }

    // MARK: - Initialization

    /// Initialize with model context
    /// - Parameter context: ModelContext for fetching user data
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Data Loading

    /// Load TDEE data from user's active NutritionGoal
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Get user and active nutrition goal
        guard let user = context.fetchCurrentUser(logger: Self.logger),
            let activeGoal = user.activeNutritionGoal
        else {
            tdee = nil
            Self.logger.debug("No user or active nutrition goal found")
            return
        }

        // Get TDEE: prefer lastCalculatedTDEE, fall back to initialEstimatedTDEE
        if let lastCalculated = activeGoal.lastCalculatedTDEE {
            tdee = lastCalculated
        } else if let initial = activeGoal.initialEstimatedTDEE {
            tdee = initial
        } else {
            tdee = nil
        }

        Self.logger.debug("Loaded TDEE: \(self.tdee ?? 0)")
    }
}

// MARK: - Preview Support

extension ExpenditureWidgetViewModel {
    /// Preview data for SwiftUI previews
    static var preview: ExpenditureWidgetViewModel {
        let context = PreviewHelpers.previewContext()
        return ExpenditureWidgetViewModel(context: context)
    }
}
