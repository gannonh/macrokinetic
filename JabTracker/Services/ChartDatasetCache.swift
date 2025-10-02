//
//  ChartDatasetCache.swift
//  JabTracker
//
//  Disk-based chart dataset caching for instant load times
//  Implements incremental updates to avoid full regeneration on new doses
//

import Foundation
import OSLog

/// Service for persisting chart datasets to disk for instant app launch
/// Requirements:
/// - Save computed chart dataset to disk after generation
/// - Load from disk on app startup (instant vs 80s regeneration)
/// - Append new concentration points incrementally (not full rebuild)
@Observable
final class ChartDatasetCache {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "JabTracker",
        category: "ChartDatasetCache"
    )

    // MARK: - Properties

    /// Cache file location
    private let cacheURL: URL

    /// Current cache version for migration support
    private let cacheVersion = "1.0"

    // MARK: - Initialization

    init() {
        // Use Application Support directory for persistent cache
        guard
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else {
            fatalError("Unable to access Application Support directory")
        }

        let cacheDirectory = appSupport.appendingPathComponent("ChartCache", isDirectory: true)

        // Create cache directory if needed
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )

        cacheURL = cacheDirectory.appendingPathComponent("concentrationDataset.json")
        Self.logger.info("📁 Chart dataset cache initialized at: \(self.cacheURL.path)")
    }

    // MARK: - Public API

    /// Save chart dataset to disk
    /// - Parameter dataset: Complete chart dataset to persist
    func save(_ dataset: ConcentrationChartDataset) throws {
        let startTime = Date()
        Self.logger.info("💾 Saving chart dataset to disk...")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted  // For debugging

        let data = try encoder.encode(dataset)
        try data.write(to: cacheURL, options: .atomic)

        let saveTime = Date().timeIntervalSince(startTime) * 1000
        let sizeKB = Double(data.count) / 1024.0

        Self.logger.info(
            """
            ✅ Chart dataset saved successfully:
               - Save time: \(String(format: "%.1f", saveTime))ms
               - File size: \(String(format: "%.1f", sizeKB))KB
               - Location: \(self.cacheURL.path)
            """
        )
    }

    /// Load chart dataset from disk
    /// - Returns: Cached dataset if available, nil otherwise
    func load() -> ConcentrationChartDataset? {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            Self.logger.info("📭 No cached dataset found - first launch or cache cleared")
            return nil
        }

        let startTime = Date()
        Self.logger.info("📂 Loading chart dataset from disk...")

        do {
            let data = try Data(contentsOf: cacheURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let dataset = try decoder.decode(ConcentrationChartDataset.self, from: data)

            let loadTime = Date().timeIntervalSince(startTime) * 1000
            let sizeKB = Double(data.count) / 1024.0

            Self.logger.info(
                """
                ✅ Chart dataset loaded successfully:
                   - Load time: \(String(format: "%.1f", loadTime))ms
                   - File size: \(String(format: "%.1f", sizeKB))KB
                   - Curves: \(dataset.concentrationCurves.count)
                   - Markers: \(dataset.doseMarkers.count)
                """
            )

            return dataset

        } catch {
            Self.logger.error("❌ Failed to load cached dataset: \(error.localizedDescription)")
            return nil
        }
    }

    /// Clear cached dataset (for testing or when data becomes invalid)
    func clear() {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            Self.logger.info("📭 No cache to clear")
            return
        }

        do {
            try FileManager.default.removeItem(at: cacheURL)
            Self.logger.info("🗑️  Cache cleared successfully")
        } catch {
            Self.logger.error("❌ Failed to clear cache: \(error.localizedDescription)")
        }
    }

    /// Check if cache exists
    var hasCachedData: Bool {
        FileManager.default.fileExists(atPath: cacheURL.path)
    }
}
