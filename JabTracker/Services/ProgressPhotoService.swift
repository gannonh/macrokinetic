//
//  ProgressPhotoService.swift
//  JabTracker
//
//  CRUD operations and queries for progress photo tracking.
//

import Foundation
import OSLog
import SwiftData

/// Errors for progress photo service operations
enum ProgressPhotoServiceError: LocalizedError {
    case invalidPhoto(String)
    case noEntriesFound
    case contextError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidPhoto(let message):
            return "Invalid photo: \(message)"
        case .noEntriesFound:
            return "No progress photos found"
        case .contextError(let error):
            return "Database error: \(error.localizedDescription)"
        }
    }
}

/// Service for managing progress photo log entries
/// Provides CRUD operations and date-based queries
@MainActor
final class ProgressPhotoService {
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "ProgressPhotoService")

    private let context: ModelContext

    /// Initialize with model context
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Create

    /// Log a new progress photo
    /// - Parameters:
    ///   - imageData: Photo data (JPEG compressed)
    ///   - photoType: Type of photo (front, side, back)
    ///   - timestamp: When the photo was taken
    ///   - notes: Optional notes
    /// - Returns: The created ProgressPhoto
    /// - Throws: ProgressPhotoServiceError if validation fails
    func logPhoto(
        imageData: Data,
        photoType: PhotoType,
        timestamp: Date = Date(),
        notes: String? = nil
    ) async throws -> ProgressPhoto {
        // Validate image data is not empty
        guard !imageData.isEmpty else {
            throw ProgressPhotoServiceError.invalidPhoto("Image data cannot be empty")
        }

        let entry = ProgressPhoto(
            timestamp: timestamp,
            imageData: imageData,
            photoType: photoType,
            notes: notes
        )

        context.insert(entry)

        do {
            try context.save()
            Self.logger.info("Logged progress photo (\(photoType.displayName)) at \(timestamp)")
            return entry
        } catch {
            throw ProgressPhotoServiceError.contextError(error)
        }
    }

    // MARK: - Read

    /// Get the most recent progress photo
    /// - Returns: The latest ProgressPhoto or nil if none exist
    func getLatestEntry() async throws -> ProgressPhoto? {
        var descriptor = FetchDescriptor<ProgressPhoto>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        do {
            let entries = try context.fetch(descriptor)
            return entries.first
        } catch {
            throw ProgressPhotoServiceError.contextError(error)
        }
    }

    /// Get progress photos within a date range
    /// - Parameters:
    ///   - startDate: Start of date range (inclusive)
    ///   - endDate: End of date range (inclusive)
    /// - Returns: Array of ProgressPhoto sorted by timestamp descending
    func getEntries(from startDate: Date, to endDate: Date) async throws -> [ProgressPhoto] {
        let descriptor = FetchDescriptor<ProgressPhoto>(
            predicate: #Predicate { entry in
                entry.timestamp >= startDate && entry.timestamp <= endDate
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            throw ProgressPhotoServiceError.contextError(error)
        }
    }

    /// Get all progress photos
    /// - Parameter limit: Maximum number of entries to return (nil for all)
    /// - Returns: Array of ProgressPhoto sorted by timestamp descending
    func getAllEntries(limit: Int? = nil) async throws -> [ProgressPhoto] {
        var descriptor = FetchDescriptor<ProgressPhoto>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        if let limit = limit {
            descriptor.fetchLimit = limit
        }

        do {
            return try context.fetch(descriptor)
        } catch {
            throw ProgressPhotoServiceError.contextError(error)
        }
    }

    /// Get progress photos filtered by photo type
    /// - Parameters:
    ///   - photoType: Type of photo to filter by
    ///   - limit: Maximum number of entries to return (nil for all)
    /// - Returns: Array of ProgressPhoto sorted by timestamp descending
    func getEntries(photoType: PhotoType, limit: Int? = nil) async throws -> [ProgressPhoto] {
        let photoTypeString = photoType.rawValue

        var descriptor = FetchDescriptor<ProgressPhoto>(
            predicate: #Predicate { entry in
                entry.photoType == photoTypeString
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        if let limit = limit {
            descriptor.fetchLimit = limit
        }

        do {
            return try context.fetch(descriptor)
        } catch {
            throw ProgressPhotoServiceError.contextError(error)
        }
    }

    // MARK: - Update

    /// Update an existing progress photo entry
    /// - Parameters:
    ///   - entry: Entry to update
    ///   - imageData: New image data (optional)
    ///   - photoType: New photo type (optional)
    ///   - notes: New notes (optional, use inner nil to clear)
    /// - Throws: ProgressPhotoServiceError if validation fails
    func updateEntry(
        _ entry: ProgressPhoto,
        imageData: Data? = nil,
        photoType: PhotoType? = nil,
        notes: String?? = nil
    ) async throws {
        if let imageData = imageData {
            guard !imageData.isEmpty else {
                throw ProgressPhotoServiceError.invalidPhoto("Image data cannot be empty")
            }
            entry.imageData = imageData
        }

        if let photoType = photoType {
            entry.photoTypeEnum = photoType
        }

        if let notes = notes {
            entry.notes = notes
        }

        do {
            try context.save()
            Self.logger.info("Updated progress photo entry")
        } catch {
            throw ProgressPhotoServiceError.contextError(error)
        }
    }

    // MARK: - Delete

    /// Delete a progress photo entry
    /// - Parameter entry: Entry to delete
    func deleteEntry(_ entry: ProgressPhoto) async throws {
        let photoType = entry.photoTypeEnum.displayName
        context.delete(entry)

        do {
            try context.save()
            Self.logger.info("Deleted progress photo (\(photoType))")
        } catch {
            throw ProgressPhotoServiceError.contextError(error)
        }
    }
}
