//
//  ModelContext+CurrentUser.swift
//  JabTracker
//
//  Extension to fetch the current user from ModelContext.
//  Consolidates duplicated fetchUser() methods across ViewModels.
//

import OSLog
import SwiftData

/// Default logger for ModelContext extensions
private let defaultLogger = Logger(
    subsystem: "com.gannonhall.JabTracker",
    category: "ModelContext"
)

extension ModelContext {
    /// Fetch the current user from the context
    /// - Parameter logger: Logger for error logging (defaults to ModelContext category logger)
    /// - Returns: The first user found, or nil if none exists
    func fetchCurrentUser(logger: Logger = defaultLogger) -> User? {
        let descriptor = FetchDescriptor<User>()
        do {
            let users = try fetch(descriptor)
            return users.first
        } catch {
            // Always log errors - never silently fail
            logger.error("Failed to fetch user: \(error.localizedDescription)")
            return nil
        }
    }
}
