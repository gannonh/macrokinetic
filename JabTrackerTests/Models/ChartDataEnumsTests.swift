//
//  ChartDataEnumsTests.swift
//  JabTrackerTests
//

import Foundation
import SwiftUI
import Testing

@testable import JabTracker

/// Comprehensive tests for ChartData enum types and their properties
/// Covers dose marker styles, alert levels, adherence status, and timing accuracy
@Suite("ChartData Enums Tests")
struct ChartDataEnumsTests {

    // MARK: - DoseAlertLevel Tests

    @Test("DoseAlertLevel provides correct colors for all cases")
    func testDoseAlertLevelColors() {
        #expect(DoseAlertLevel.normal.color == .primary)
        #expect(DoseAlertLevel.info.color == .blue)
        #expect(DoseAlertLevel.warning.color == .orange)
        #expect(DoseAlertLevel.critical.color == .red)
    }

    @Test("DoseAlertLevel provides correct opacity values")
    func testDoseAlertLevelOpacity() {
        #expect(DoseAlertLevel.normal.opacity == 1.0)
        #expect(DoseAlertLevel.info.opacity == 0.8)
        #expect(DoseAlertLevel.warning.opacity == 0.9)
        #expect(DoseAlertLevel.critical.opacity == 1.0)
    }

    // MARK: - AdherenceStatus Tests

    @Test("AdherenceStatus provides correct display names")
    func testAdherenceStatusDisplayNames() {
        #expect(AdherenceStatus.early.displayName == "Early")
        #expect(AdherenceStatus.onTime.displayName == "On Time")
        #expect(AdherenceStatus.late.displayName == "Late")
        #expect(AdherenceStatus.missed.displayName == "Missed")
    }

    @Test("AdherenceStatus provides correct colors")
    func testAdherenceStatusColors() {
        #expect(AdherenceStatus.early.color == .blue)
        #expect(AdherenceStatus.onTime.color == .green)
        #expect(AdherenceStatus.late.color == .orange)
        #expect(AdherenceStatus.missed.color == .red)
    }

    // MARK: - TimingAccuracy Tests

    @Test("TimingAccuracy provides correct display names")
    func testTimingAccuracyDisplayNames() {
        #expect(TimingAccuracy.exact.displayName == "Exact")
        #expect(TimingAccuracy.approximate.displayName == "Approximate")
        #expect(TimingAccuracy.estimated.displayName == "Estimated")
        #expect(TimingAccuracy.unknown.displayName == "Unknown")
    }

    // MARK: - Enum Completeness Tests

    @Test("All DoseAlertLevel cases are covered")
    func testDoseAlertLevelCompleteness() {
        let allCases = DoseAlertLevel.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.normal))
        #expect(allCases.contains(.info))
        #expect(allCases.contains(.warning))
        #expect(allCases.contains(.critical))
    }

    @Test("All AdherenceStatus cases are covered")
    func testAdherenceStatusCompleteness() {
        let allCases = AdherenceStatus.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.early))
        #expect(allCases.contains(.onTime))
        #expect(allCases.contains(.late))
        #expect(allCases.contains(.missed))
    }

    @Test("All TimingAccuracy cases are covered")
    func testTimingAccuracyCompleteness() {
        let allCases = TimingAccuracy.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.exact))
        #expect(allCases.contains(.approximate))
        #expect(allCases.contains(.estimated))
        #expect(allCases.contains(.unknown))
    }

    // MARK: - DoseMarkerStyle Tests (Already covered but adding for completeness)

    @Test("DoseMarkerStyle provides correct colors")
    func testDoseMarkerStyleColors() {
        #expect(DoseMarkerStyle.standard.color == .blue)
        #expect(DoseMarkerStyle.emphasized.color == .green)
        #expect(DoseMarkerStyle.skipped.color == .gray)
        #expect(DoseMarkerStyle.withSite.color == .purple)
        #expect(DoseMarkerStyle.firstDose.color == .orange)
        #expect(DoseMarkerStyle.milestone.color == .red)
    }

    @Test("DoseMarkerStyle provides correct sizes")
    func testDoseMarkerStyleSizes() {
        #expect(DoseMarkerStyle.standard.size == 8)
        #expect(DoseMarkerStyle.emphasized.size == 12)
        #expect(DoseMarkerStyle.skipped.size == 6)
        #expect(DoseMarkerStyle.withSite.size == 10)
        #expect(DoseMarkerStyle.firstDose.size == 14)
        #expect(DoseMarkerStyle.milestone.size == 16)
    }

    @Test("DoseMarkerStyle provides correct symbols")
    func testDoseMarkerStyleSymbols() {
        #expect(DoseMarkerStyle.standard.symbol == "circle.fill")
        #expect(DoseMarkerStyle.emphasized.symbol == "star.fill")
        #expect(DoseMarkerStyle.skipped.symbol == "xmark.circle")
        #expect(DoseMarkerStyle.withSite.symbol == "mappin.circle.fill")
        #expect(DoseMarkerStyle.firstDose.symbol == "1.circle.fill")
        #expect(DoseMarkerStyle.milestone.symbol == "flag.fill")
    }
}
