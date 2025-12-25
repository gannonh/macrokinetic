//
//  ProgressPhoto.swift
//  JabTracker
//
//  Progress photo log entry for tracking visual changes over time.
//

import Foundation
import SwiftData

/// Photo type for progress tracking
enum PhotoType: String, Codable, CaseIterable {
    case front
    case side
    case back

    /// Display name for UI
    var displayName: String {
        switch self {
        case .front:
            return "Front"
        case .side:
            return "Side"
        case .back:
            return "Back"
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .front:
            return "person.fill"
        case .side:
            return "person.fill.turn.right"
        case .back:
            return "person.fill.turn.down"
        }
    }
}

/// Progress photo log entry - stores photos with metadata
/// Note: No User relationship - entries are queried by date in a single-user app context
@Model
final class ProgressPhoto {
    // MARK: - Identity

    var id: UUID = UUID()

    // MARK: - Photo Data

    /// Timestamp of the photo entry
    var timestamp: Date = Date()

    /// Image data stored as binary (JPEG compressed)
    /// Uses external storage for efficient memory handling of large photos
    @Attribute(.externalStorage)
    var imageData: Data?

    /// Photo type stored as string for CloudKit compatibility
    var photoType: String = PhotoType.front.rawValue

    // MARK: - Metadata

    /// Optional notes
    var notes: String?

    // MARK: - Computed Properties

    /// Photo type as enum
    var photoTypeEnum: PhotoType {
        get {
            PhotoType(rawValue: photoType) ?? .front
        }
        set {
            photoType = newValue.rawValue
        }
    }

    /// Check if the entry has valid photo data
    var hasValidPhoto: Bool {
        guard let data = imageData else { return false }
        return !data.isEmpty
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        imageData: Data? = nil,
        photoType: PhotoType = .front,
        notes: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.imageData = imageData
        self.photoType = photoType.rawValue
        self.notes = notes
    }
}
