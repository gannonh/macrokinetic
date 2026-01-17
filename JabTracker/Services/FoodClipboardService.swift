//
//  FoodClipboardService.swift
//  JabTracker
//
//  Session-only clipboard service for food entry copy/paste operations.
//  Content is cleared on app termination.
//

import Foundation
import OSLog

/// Service for managing the session food clipboard.
///
/// Provides copy operations for food entries that store lightweight
/// ClipboardEntry values. Content is session-only (not persisted) and
/// cleared on app termination. New copy replaces existing content.
@MainActor
@Observable
final class FoodClipboardService {
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "FoodClipboardService")

    // MARK: - Properties

    /// Current clipboard content (nil = empty clipboard)
    private(set) var content: FoodClipboardContent?

    /// Whether the clipboard has content
    var hasContent: Bool {
        content != nil
    }

    /// Number of entries in the clipboard for UI display
    var entryCount: Int {
        content?.entryCount ?? 0
    }

    // MARK: - Initialization

    init() {
        // No setup needed - content starts as nil
    }

    // MARK: - Copy Operations

    /// Copy an entire day's food entries to the clipboard
    /// - Parameters:
    ///   - date: The source date being copied
    ///   - entries: The food entries to copy
    func copyDay(date: Date, entries: [FoodEntry]) {
        let clipboardEntries = entries.map { ClipboardEntry(from: $0) }
        content = .day(date: date, entries: clipboardEntries)
        Self.logger.info("Copied \(clipboardEntries.count) entries from day to clipboard")
    }

    /// Copy a meal's food entries to the clipboard
    /// - Parameters:
    ///   - date: The source date
    ///   - meal: The meal section being copied
    ///   - entries: The food entries to copy
    func copyMeal(date: Date, meal: MealSection, entries: [FoodEntry]) {
        let clipboardEntries = entries.map { ClipboardEntry(from: $0) }
        content = .meal(date: date, meal: meal, entries: clipboardEntries)
        Self.logger.info("Copied \(clipboardEntries.count) entries from \(meal.displayName) to clipboard")
    }

    // MARK: - Clear

    /// Clear the clipboard
    func clear() {
        content = nil
        Self.logger.debug("Clipboard cleared")
    }
}
