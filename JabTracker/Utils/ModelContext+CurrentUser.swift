//
//  ModelContext+CurrentUser.swift
//  JabTracker
//
//  Extension to fetch the current user from ModelContext.
//  Consolidates duplicated fetchUser() methods across ViewModels.
//

import OSLog
import SwiftData

extension ModelContext {
    /// Fetch the current user from the context
    /// - Parameter logger: Optional logger for error logging
    /// - Returns: The first user found, or nil if none exists
    func fetchCurrentUser(logger: Logger? = nil) -> User? {
        let descriptor = FetchDescriptor<User>()
        do {
            let users = try fetch(descriptor)
            return users.first
        } catch {
            logger?.error("Failed to fetch user: \(error)")
            return nil
        }
    }
}
