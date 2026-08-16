//
//  FoodSearchReleaseBenchmarkUITests.swift
//  JabTrackerUITests
//
//  Release-only latency benchmark for the bundled food database. Run through
//  scripts/benchmark-food-search.sh on the required physical device.
//

import XCTest

final class FoodSearchReleaseBenchmarkUITests: XCTestCase {
    private let queries = ["pizza", "chicken", "bread"]
    private let runCount = 10
    private let resultTimeout: TimeInterval = 15

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)
    }

    func testReleaseSearchLatencyBenchmark() throws {
        for query in queries {
            let coldRuns = measureColdRuns(for: query)
            let warmRuns = measureWarmRuns(for: query)

            XCTAssertEqual(coldRuns.count, runCount)
            XCTAssertEqual(warmRuns.count, runCount)

            let coldP95 = p95Milliseconds(coldRuns)
            let warmP95 = p95Milliseconds(warmRuns)
            XCTAssertLessThanOrEqual(
                coldP95,
                1000,
                "Cold p95 for \(query) must be at most 1 second"
            )
            XCTAssertLessThanOrEqual(
                warmP95,
                1000,
                "Warm p95 for \(query) must be at most 1 second"
            )
            print(
                "FOOD_SEARCH_RELEASE_BENCHMARK "
                    + "query=\(query) "
                    + "cold_runs=\(coldRuns.count) "
                    + "warm_runs=\(warmRuns.count) "
                    + "cold_p95_ms=\(formattedMilliseconds(coldP95)) "
                    + "warm_p95_ms=\(formattedMilliseconds(warmP95)) "
                    + "device_requirement=iPhone_17_Pro_iOS_26.2"
            )
        }
    }

    private func measureColdRuns(for query: String) -> [TimeInterval] {
        app.terminate()

        var durations: [TimeInterval] = []
        for run in 0..<runCount {
            app = TestUtilities.launchAppWithTestMode(resetData: run == 0)
            durations.append(measureSearch(query))
            app.terminate()
        }
        return durations
    }

    private func measureWarmRuns(for query: String) -> [TimeInterval] {
        // The warmup opens the database connection and is intentionally excluded
        // from the ten reported warm runs.
        app = TestUtilities.launchAppWithTestMode(resetData: false)
        _ = measureSearch(query)
        dismissSearch()

        var durations: [TimeInterval] = []
        for _ in 0..<runCount {
            durations.append(measureSearch(query))
            dismissSearch()
        }
        app.terminate()
        return durations
    }

    private func measureSearch(_ query: String) -> TimeInterval {
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 5), "Search shortcut should exist")
        searchButton.tap()

        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Food search field should exist")
        searchField.tap()

        let executionMarker = app.descendants(matching: .any)["food-search-execution-start"].firstMatch
        let previousStart = executionMarker.value as? String ?? ""
        searchField.typeText(query)
        let start = searchExecutionStart(marker: executionMarker, previousValue: previousStart)

        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(
            firstResult.waitForExistence(timeout: resultTimeout),
            "Search should return results for '\(query)'"
        )
        return Date().timeIntervalSince(start)
    }

    private func searchExecutionStart(marker: XCUIElement, previousValue: String) -> Date {
        let deadline = Date().addingTimeInterval(resultTimeout)

        while Date() < deadline {
            if let value = marker.value as? String,
                !value.isEmpty,
                value != previousValue,
                let timestamp = TimeInterval(value)
            {
                return Date(timeIntervalSince1970: timestamp)
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }

        XCTFail("Search execution timestamp should be published for the new query")
        return Date()
    }

    private func dismissSearch() {
        let cancelButton = app.buttons["food-search-cancel-button"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "Food search close button should exist")
        cancelButton.tap()
        TestUtilities.dismissShortcutsSheet(app)
    }

    private func p95Milliseconds(_ durations: [TimeInterval]) -> Double {
        let sortedDurations = durations.sorted()
        let index = max(
            0,
            min(sortedDurations.count - 1, Int(ceil(Double(sortedDurations.count) * 0.95)) - 1)
        )
        return sortedDurations[index] * 1000
    }

    private func formattedMilliseconds(_ milliseconds: Double) -> String {
        String(format: "%.1f", milliseconds)
    }
}
