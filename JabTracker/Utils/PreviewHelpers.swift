//
//  PreviewHelpers.swift
//  JabTracker
//
//  Shared utilities for SwiftUI preview support.
//  Consolidates duplicated preview setup code across ViewModels.
//

import SwiftData

/// Shared utilities for SwiftUI preview support
@MainActor
enum PreviewHelpers {
    /// Schema used for preview containers (includes common nutrition-related models)
    static let nutritionSchema = Schema([User.self, FoodEntry.self])

    /// Create an in-memory ModelContext for previews
    /// - Returns: A ModelContext backed by an in-memory container with CloudKit disabled
    static func previewContext() -> ModelContext {
        let config = ModelConfiguration(
            schema: nutritionSchema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: nutritionSchema, configurations: [config])
        return container.mainContext
    }

    /// Create a MealLogService for previews
    /// - Returns: A MealLogService backed by an in-memory context
    static func previewMealLogService() -> MealLogService {
        MealLogService(context: previewContext())
    }
}
