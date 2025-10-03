import Foundation
import Testing

@testable import JabTracker

/// Comprehensive tests for ChartDatasetCache disk persistence functionality
struct ChartDatasetCacheTests {

    // MARK: - Helper Methods

    private func createTestDataset() -> ConcentrationChartDataset {
        let point = AdvancedConcentrationPoint(
            date: Date(),
            concentration: 1.5,
            isInterpolated: false,
            interpolationType: .pharmacokinetic,
            confidenceInterval: nil
        )

        let curve = ConcentrationCurve(
            points: [point],
            medication: "Semaglutide",
            curveStyle: .smooth,
            isVisible: true
        )

        let marker = AdvancedDoseMarker(
            date: Date(),
            amount: 1.0,
            isSkipped: false,
            markerStyle: .standard,
            alertLevel: .normal,
            metadata: DoseMarkerMetadata(
                site: "Abdomen",
                notes: nil,
                hasPhoto: false
            )
        )

        return ConcentrationChartDataset(
            concentrationCurves: [curve],
            doseMarkers: [marker],
            configuration: .default,
            metadata: ChartMetadata()
        )
    }

    // MARK: - Save Tests

    @Test("save successfully persists dataset to disk")
    func savePersistsDataset() throws {
        let cache = ChartDatasetCache()
        let dataset = createTestDataset()

        // Clear any existing cache first
        cache.clear()

        // Test save
        try cache.save(dataset)

        // Verify file exists
        #expect(cache.hasCachedData == true, "Cache file should exist after save")
    }

    @Test("save creates cache directory if needed")
    func saveCreatesDirectory() throws {
        let cache = ChartDatasetCache()
        let dataset = createTestDataset()

        // Even if directory doesn't exist, save should create it
        try cache.save(dataset)

        #expect(cache.hasCachedData == true, "Cache file should be created")
    }

    // MARK: - Load Tests

    @Test("load returns notFound when no cache exists")
    func loadReturnsNotFoundWithoutCache() throws {
        let cache = ChartDatasetCache()

        // Clear cache to ensure no file exists
        cache.clear()

        let result = cache.load()

        guard case .notFound = result else {
            #expect(Bool(false), "Should return .notFound when no cache file exists")
            return
        }
        #expect(cache.hasCachedData == false, "hasCachedData should be false")
    }

    @Test("load successfully retrieves saved dataset")
    func loadRetrievesSavedDataset() throws {
        let cache = ChartDatasetCache()
        let originalDataset = createTestDataset()

        // Clear and save
        cache.clear()
        try cache.save(originalDataset)

        // Load back
        let result = cache.load()

        guard case .success(let loadedDataset) = result else {
            #expect(Bool(false), "Should return .success with dataset")
            return
        }

        #expect(
            loadedDataset.concentrationCurves.count == 1,
            "Should have same number of curves")
        #expect(
            loadedDataset.doseMarkers.count == 1, "Should have same number of markers")
    }

    @Test("load preserves dataset structure")
    func loadPreservesStructure() throws {
        let cache = ChartDatasetCache()
        let originalDataset = createTestDataset()

        cache.clear()
        try cache.save(originalDataset)

        let result = cache.load()

        guard case .success(let loadedDataset) = result else {
            #expect(Bool(false), "Should return .success with dataset")
            return
        }

        // Verify curve data
        #expect(
            loadedDataset.concentrationCurves.first?.points.first?.concentration == 1.5,
            "Should preserve concentration values")

        // Verify marker data
        #expect(
            loadedDataset.doseMarkers.first?.amount == 1.0,
            "Should preserve dose marker amount")
        #expect(
            loadedDataset.doseMarkers.first?.metadata.site == "Abdomen",
            "Should preserve injection site")

        // Verify configuration
        #expect(
            loadedDataset.configuration.timeRange == .automatic,
            "Should preserve time range configuration")
    }

    @Test("load handles corrupted cache gracefully")
    func loadHandlesCorruptedCache() throws {
        let cache = ChartDatasetCache()

        // Save valid dataset first
        let dataset = createTestDataset()
        try cache.save(dataset)

        // Now corrupt the file by writing invalid JSON
        let cacheURL = getCacheURL()
        let corruptedData = Data("corrupted data".utf8)
        try corruptedData.write(to: cacheURL, options: .atomic)

        // Load should return .corrupted for corrupted data
        let result = cache.load()

        guard case .corrupted = result else {
            #expect(Bool(false), "Should return .corrupted for corrupted cache")
            return
        }
    }

    // MARK: - Clear Tests

    @Test("clear removes cache file")
    func clearRemovesCacheFile() throws {
        let cache = ChartDatasetCache()
        let dataset = createTestDataset()

        // Save then clear
        try cache.save(dataset)
        #expect(cache.hasCachedData == true, "Cache should exist before clear")

        cache.clear()

        #expect(cache.hasCachedData == false, "Cache should not exist after clear")
    }

    @Test("clear handles non-existent cache gracefully")
    func clearHandlesNonExistentCache() throws {
        let cache = ChartDatasetCache()

        // Clear when no cache exists should not error
        cache.clear()
        cache.clear()  // Call twice to ensure idempotency

        #expect(cache.hasCachedData == false, "Should remain false")
    }

    // MARK: - hasCachedData Tests

    @Test("hasCachedData reflects cache state correctly")
    func hasCachedDataReflectsState() throws {
        let cache = ChartDatasetCache()

        // Initially no cache
        cache.clear()
        #expect(cache.hasCachedData == false, "Should be false initially")

        // After save
        let dataset = createTestDataset()
        try cache.save(dataset)
        #expect(cache.hasCachedData == true, "Should be true after save")

        // After clear
        cache.clear()
        #expect(cache.hasCachedData == false, "Should be false after clear")
    }

    // MARK: - Integration Tests

    @Test("full save-load-clear cycle works correctly")
    func fullCycleWorksCorrectly() throws {
        let cache = ChartDatasetCache()
        let dataset = createTestDataset()

        // 1. Start clean
        cache.clear()
        #expect(cache.hasCachedData == false)

        // 2. Save
        try cache.save(dataset)
        #expect(cache.hasCachedData == true)

        // 3. Load
        let result = cache.load()
        guard case .success(let loaded) = result else {
            #expect(Bool(false), "Should load successfully")
            return
        }
        #expect(loaded.concentrationCurves.count == 1)

        // 4. Clear
        cache.clear()
        #expect(cache.hasCachedData == false)

        // 5. Load after clear returns notFound
        let resultAfterClear = cache.load()
        guard case .notFound = resultAfterClear else {
            #expect(Bool(false), "Should return .notFound after clear")
            return
        }
    }

    @Test("multiple save-load cycles maintain data integrity")
    func multipleCyclesMaintainIntegrity() throws {
        let cache = ChartDatasetCache()

        for iteration in 1...3 {
            let dataset = createTestDataset()

            cache.clear()
            try cache.save(dataset)

            let result = cache.load()
            guard case .success(let loaded) = result else {
                #expect(
                    Bool(false), "Failed to load dataset on iteration \(iteration)")
                return
            }

            #expect(
                loaded.concentrationCurves.count == 1,
                "Iteration \(iteration) should have 1 curve")
            #expect(
                loaded.doseMarkers.count == 1,
                "Iteration \(iteration) should have 1 marker")
        }
    }

    // MARK: - Helper to get cache URL

    private func getCacheURL() -> URL {
        guard
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else {
            fatalError("Unable to access Application Support directory")
        }

        let cacheDirectory = appSupport.appendingPathComponent("ChartCache", isDirectory: true)
        return cacheDirectory.appendingPathComponent("concentrationDataset.json")
    }
}
