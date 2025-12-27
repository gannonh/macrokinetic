//
//  EntrySource.swift
//  JabTracker
//
//  Shared source enum for weight and metrics entries.
//

import Foundation

/// Source of a tracking entry (weight, metrics, etc.)
enum EntrySource: String, Codable {
    case manual
    case healthkit
}
