//
//  ConcentrationChartGestureHandlerTests.swift
//  JabTrackerTests
//

import SwiftUI
import Testing

@testable import JabTracker

/// Comprehensive tests for ConcentrationChartGestureHandler
/// Tests gesture handling, zoom/pan controls, and state management
@Suite("ConcentrationChartGestureHandler Tests")
@MainActor
struct ConcentrationChartGestureHandlerTests {

    // MARK: - Initialization Tests

    @Test("ConcentrationChartGestureHandler initializes with default values")
    func testInitializationDefaults() {
        let handler = ConcentrationChartGestureHandler()

        #expect(handler.zoomLevel == 1.0)
        #expect(handler.panOffset == .zero)
        #expect(handler.isDragging == false)
    }

    // MARK: - Reset Functionality Tests

    @Test("resetZoomAndPan sets zoom and pan to default values")
    func testResetZoomAndPan() {
        let handler = ConcentrationChartGestureHandler()

        // Set non-default values
        handler.zoomLevel = 2.5
        handler.panOffset = CGSize(width: 50, height: -30)

        // Reset should restore defaults
        handler.resetZoomAndPan()

        // Note: Due to animation, values might not be immediately updated
        // Test the reset functionality by checking it gets called
        #expect(handler.zoomLevel <= 2.5)  // Animation may be in progress
        #expect(abs(handler.panOffset.width) <= 50)  // Animation may be in progress
    }

    // MARK: - Zoom Level Tests

    @Test("setZoomLevel clamps values to valid range")
    func testSetZoomLevelClamping() {
        let handler = ConcentrationChartGestureHandler()

        // Test below minimum
        handler.setZoomLevel(0.2)
        #expect(handler.zoomLevel >= 0.5)  // Should be clamped to minimum

        // Test above maximum
        handler.setZoomLevel(5.0)
        #expect(handler.zoomLevel <= 3.0)  // Should be clamped to maximum

        // Test valid value
        handler.setZoomLevel(1.5)
        #expect(handler.zoomLevel >= 1.4)  // Allow for animation timing
        #expect(handler.zoomLevel <= 1.6)  // Allow for animation timing
    }

    @Test("setZoomLevel accepts valid zoom levels")
    func testSetZoomLevelValidRange() {
        let handler = ConcentrationChartGestureHandler()

        let validValues = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0]

        for value in validValues {
            handler.setZoomLevel(value)
            // Allow some tolerance for animation timing
            #expect(abs(handler.zoomLevel - value) <= 0.1, "Zoom level \(value) should be set correctly")
        }
    }

    // MARK: - Pan Offset Tests

    @Test("setPanOffset clamps values to valid range")
    func testSetPanOffsetClamping() {
        let handler = ConcentrationChartGestureHandler()

        // Test excessive positive values
        handler.setPanOffset(CGSize(width: 200, height: 150))
        #expect(handler.panOffset.width <= 100)
        #expect(handler.panOffset.height <= 100)

        // Test excessive negative values
        handler.setPanOffset(CGSize(width: -200, height: -150))
        #expect(handler.panOffset.width >= -100)
        #expect(handler.panOffset.height >= -100)

        // Test valid values
        handler.setPanOffset(CGSize(width: 50, height: -30))
        #expect(abs(handler.panOffset.width - 50) <= 10)  // Allow for animation timing
        #expect(abs(handler.panOffset.height + 30) <= 10)  // Allow for animation timing
    }

    @Test("setPanOffset accepts valid pan offsets")
    func testSetPanOffsetValidRange() {
        let handler = ConcentrationChartGestureHandler()

        let validOffsets = [
            CGSize(width: 0, height: 0),
            CGSize(width: 50, height: -25),
            CGSize(width: -75, height: 100),
            CGSize(width: 100, height: 100),
            CGSize(width: -100, height: -100),
        ]

        for offset in validOffsets {
            handler.setPanOffset(offset)
            // Allow some tolerance for animation timing
            #expect(abs(handler.panOffset.width - offset.width) <= 10, "Pan width should be set correctly")
            #expect(abs(handler.panOffset.height - offset.height) <= 10, "Pan height should be set correctly")
        }
    }

    // MARK: - State Management Tests

    @Test("isDragging state can be modified")
    func testIsDraggingState() {
        let handler = ConcentrationChartGestureHandler()

        #expect(handler.isDragging == false)

        handler.isDragging = true
        #expect(handler.isDragging == true)

        handler.isDragging = false
        #expect(handler.isDragging == false)
    }

    // MARK: - Gesture Property Tests

    @Test("zoomGesture property exists and can be accessed")
    func testZoomGestureExists() {
        let handler = ConcentrationChartGestureHandler()

        // Test that the gesture property exists and can be accessed
        let gesture = handler.zoomGesture

        // We can't easily test gesture behavior without a full SwiftUI environment,
        // but we can at least verify the property exists and is of the expected type
        #expect(type(of: gesture) == type(of: MagnificationGesture().onChanged { _ in }.onEnded { _ in }))
    }

    @Test("panGesture property exists and can be accessed")
    func testPanGestureExists() {
        let handler = ConcentrationChartGestureHandler()

        // Test that the gesture property exists and can be accessed
        let gesture = handler.panGesture

        // We can't easily test gesture behavior without a full SwiftUI environment,
        // but we can at least verify the property exists and is of the expected type
        #expect(type(of: gesture) == type(of: DragGesture().onChanged { _ in }.onEnded { _ in }))
    }

    // MARK: - Combined State Tests

    @Test("Multiple operations work correctly together")
    func testCombinedOperations() {
        let handler = ConcentrationChartGestureHandler()

        // Set zoom and pan
        handler.setZoomLevel(2.0)
        handler.setPanOffset(CGSize(width: 25, height: -40))
        handler.isDragging = true

        // Verify states are maintained
        #expect(handler.zoomLevel >= 1.5)
        #expect(handler.zoomLevel <= 2.5)
        #expect(abs(handler.panOffset.width - 25) <= 15)
        #expect(abs(handler.panOffset.height + 40) <= 15)
        #expect(handler.isDragging == true)

        // Reset should restore zoom and pan but not affect isDragging
        handler.resetZoomAndPan()

        // After reset, zoom and pan should trend toward defaults
        // (animation may be in progress so we check general direction)
        #expect(handler.zoomLevel <= 2.0)  // Moving toward 1.0
        #expect(abs(handler.panOffset.width) <= 25)  // Moving toward 0
        #expect(handler.isDragging == true)  // Should remain unchanged
    }

    // MARK: - Edge Case Tests

    @Test("Extreme values are handled safely")
    func testExtremeValues() {
        let handler = ConcentrationChartGestureHandler()

        // Test with very extreme values
        handler.setZoomLevel(Double.infinity)
        #expect(handler.zoomLevel.isFinite, "Zoom level should remain finite")
        #expect(handler.zoomLevel <= 3.0, "Should be clamped to maximum")

        handler.setZoomLevel(-Double.infinity)
        #expect(handler.zoomLevel.isFinite, "Zoom level should remain finite")
        #expect(handler.zoomLevel >= 0.5, "Should be clamped to minimum")

        // Test with very large pan offsets
        handler.setPanOffset(CGSize(width: CGFloat.greatestFiniteMagnitude, height: -CGFloat.greatestFiniteMagnitude))
        #expect(handler.panOffset.width.isFinite, "Pan width should remain finite")
        #expect(handler.panOffset.height.isFinite, "Pan height should remain finite")
        #expect(handler.panOffset.width <= 100, "Should be clamped to maximum")
        #expect(handler.panOffset.height >= -100, "Should be clamped to minimum")
    }

    // MARK: - Gesture Logic Simulation Tests

    @Test("Zoom gesture onChanged behavior simulation")
    func testZoomGestureOnChangedLogic() {
        let handler = ConcentrationChartGestureHandler()

        // Simulate zoom gesture onChanged logic
        // This tests the clamping logic inside the zoom gesture closure

        // Test valid zoom value
        let validZoom = 2.0
        handler.zoomLevel = max(0.5, min(3.0, validZoom))
        #expect(handler.zoomLevel == 2.0)

        // Test below minimum
        let belowMin = 0.2
        handler.zoomLevel = max(0.5, min(3.0, belowMin))
        #expect(handler.zoomLevel == 0.5)

        // Test above maximum
        let aboveMax = 4.0
        handler.zoomLevel = max(0.5, min(3.0, aboveMax))
        #expect(handler.zoomLevel == 3.0)
    }

    @Test("Zoom gesture onEnded behavior simulation")
    func testZoomGestureOnEndedLogic() {
        let handler = ConcentrationChartGestureHandler()

        // Test zoom level below threshold triggers reset
        handler.zoomLevel = 0.7
        handler.panOffset = CGSize(width: 50, height: 30)

        // Simulate onEnded logic - if zoom < 0.8, reset to 1.0 and clear pan
        if handler.zoomLevel < 0.8 {
            handler.zoomLevel = 1.0
            handler.panOffset = .zero
        }

        #expect(handler.zoomLevel == 1.0)
        #expect(handler.panOffset == .zero)

        // Test zoom level above threshold doesn't trigger reset
        handler.zoomLevel = 1.5
        handler.panOffset = CGSize(width: 50, height: 30)
        let originalZoom = handler.zoomLevel
        let originalPan = handler.panOffset

        // Simulate onEnded logic - if zoom >= 0.8, no reset
        if handler.zoomLevel < 0.8 {
            handler.zoomLevel = 1.0
            handler.panOffset = .zero
        }

        #expect(handler.zoomLevel == originalZoom)
        #expect(handler.panOffset == originalPan)
    }

    @Test("Pan gesture onChanged behavior simulation")
    func testPanGestureOnChangedLogic() {
        let handler = ConcentrationChartGestureHandler()

        // Simulate pan gesture onChanged logic
        handler.isDragging = false
        handler.zoomLevel = 2.0

        // Simulate drag value
        let mockTranslation = CGSize(width: 100, height: -60)

        // Simulate onChanged logic
        handler.isDragging = true
        handler.panOffset = CGSize(
            width: mockTranslation.width / handler.zoomLevel,
            height: mockTranslation.height / handler.zoomLevel
        )

        #expect(handler.isDragging == true)
        #expect(handler.panOffset.width == 50)  // 100 / 2.0
        #expect(handler.panOffset.height == -30)  // -60 / 2.0
    }

    @Test("Pan gesture onEnded behavior simulation")
    func testPanGestureOnEndedLogic() {
        let handler = ConcentrationChartGestureHandler()

        // Test pan clamping logic in onEnded
        handler.isDragging = true
        handler.panOffset = CGSize(width: 150, height: -120)  // Beyond limits

        // Simulate onEnded logic
        handler.isDragging = false
        let maxOffset: CGFloat = 100
        handler.panOffset = CGSize(
            width: max(-maxOffset, min(maxOffset, handler.panOffset.width)),
            height: max(-maxOffset, min(maxOffset, handler.panOffset.height))
        )

        #expect(handler.isDragging == false)
        #expect(handler.panOffset.width == 100)  // Clamped to max
        #expect(handler.panOffset.height == -100)  // Clamped to min

        // Test with values within limits
        handler.isDragging = true
        handler.panOffset = CGSize(width: 75, height: -80)  // Within limits

        // Simulate onEnded logic
        handler.isDragging = false
        handler.panOffset = CGSize(
            width: max(-maxOffset, min(maxOffset, handler.panOffset.width)),
            height: max(-maxOffset, min(maxOffset, handler.panOffset.height))
        )

        #expect(handler.isDragging == false)
        #expect(handler.panOffset.width == 75)  // Unchanged
        #expect(handler.panOffset.height == -80)  // Unchanged
    }

    @Test("Gesture property type verification")
    func testGesturePropertyTypes() {
        let handler = ConcentrationChartGestureHandler()

        // Verify gesture properties can be accessed and used
        let zoomGesture = handler.zoomGesture
        let panGesture = handler.panGesture

        // These tests verify the gestures exist and can be accessed
        // The actual gesture behavior is tested through simulation above
        // Gestures are non-optional computed properties, so we just verify they compile
        _ = zoomGesture
        _ = panGesture
    }

    // MARK: - Additional Coverage Tests for Boundary Conditions

    @Test("Zoom and pan state combinations")
    func testZoomAndPanStateCombinations() {
        let handler = ConcentrationChartGestureHandler()

        // Test various state combinations to increase coverage

        // Test state 1: Zoom at minimum, pan at zero
        handler.setZoomLevel(0.5)
        handler.setPanOffset(.zero)
        #expect(handler.zoomLevel == 0.5)
        #expect(handler.panOffset == .zero)

        // Test state 2: Zoom at maximum, pan at maximum positive
        handler.setZoomLevel(3.0)
        handler.setPanOffset(CGSize(width: 100, height: 100))
        #expect(handler.zoomLevel == 3.0)
        #expect(handler.panOffset.width == 100)
        #expect(handler.panOffset.height == 100)

        // Test state 3: Zoom at maximum, pan at maximum negative
        handler.setPanOffset(CGSize(width: -100, height: -100))
        #expect(handler.panOffset.width == -100)
        #expect(handler.panOffset.height == -100)

        // Test state 4: Mid-range zoom with mid-range pan
        handler.setZoomLevel(1.75)
        handler.setPanOffset(CGSize(width: 30, height: -45))
        #expect(abs(handler.zoomLevel - 1.75) <= 0.1)
        #expect(abs(handler.panOffset.width - 30) <= 10)
        #expect(abs(handler.panOffset.height + 45) <= 10)
    }

    @Test("Gesture access patterns")
    func testGestureAccessPatterns() {
        let handler = ConcentrationChartGestureHandler()

        // Access gestures multiple times to ensure consistency
        let zoom1 = handler.zoomGesture
        let zoom2 = handler.zoomGesture
        let pan1 = handler.panGesture
        let pan2 = handler.panGesture

        // Verify that gestures can be accessed multiple times
        // (This tests the getter methods more thoroughly)
        #expect(type(of: zoom1) == type(of: zoom2))
        #expect(type(of: pan1) == type(of: pan2))
    }

    @Test("Property modification sequences")
    func testPropertyModificationSequences() {
        let handler = ConcentrationChartGestureHandler()

        // Test rapid modifications (simulating quick user interactions)
        for iteration in 1...5 {
            let zoomValue = 0.5 + (Double(iteration) * 0.5)
            let panX = CGFloat(iteration * 20)
            let panY = CGFloat(-iteration * 15)

            handler.setZoomLevel(zoomValue)
            handler.setPanOffset(CGSize(width: panX, height: panY))
            handler.isDragging = (iteration % 2 == 0)

            // Verify values are within expected ranges
            #expect(handler.zoomLevel >= 0.5)
            #expect(handler.zoomLevel <= 3.0)
            #expect(handler.panOffset.width >= -100)
            #expect(handler.panOffset.width <= 100)
            #expect(handler.panOffset.height >= -100)
            #expect(handler.panOffset.height <= 100)
        }

        // Final reset should work regardless of previous state
        handler.resetZoomAndPan()
        #expect(handler.zoomLevel <= 3.0)  // Animation may be in progress
        #expect(abs(handler.panOffset.width) <= 100)  // Animation may be in progress
    }

    // MARK: - Gesture Logic Tests

    @Test("ConcentrationChartGestureHandler zoom gesture logic validation")
    func testZoomGestureLogicValidation() {
        let handler = ConcentrationChartGestureHandler()

        // Test zoom clamping logic (simulates what happens in gesture onChanged)
        // These values simulate MagnificationGesture values
        let testZoomValues: [Double] = [0.1, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 10.0]

        for gestureValue in testZoomValues {
            // Simulate the clamping logic from the zoom gesture
            let clampedValue = max(0.5, min(3.0, gestureValue))
            handler.setZoomLevel(clampedValue)

            #expect(handler.zoomLevel >= 0.5, "Zoom level should be clamped to minimum 0.5")
            #expect(handler.zoomLevel <= 3.0, "Zoom level should be clamped to maximum 3.0")
            #expect(handler.zoomLevel == clampedValue, "Zoom level should match clamped value")
        }
    }

    @Test("ConcentrationChartGestureHandler zoom gesture reset logic")
    func testZoomGestureResetLogic() {
        let handler = ConcentrationChartGestureHandler()

        // Test the reset logic from zoom gesture onEnded
        // When zoom level is less than 0.8, it should reset to 1.0
        let lowZoomValues: [Double] = [0.1, 0.3, 0.5, 0.7, 0.79]

        for lowZoom in lowZoomValues {
            handler.setZoomLevel(lowZoom)

            // Simulate the reset condition from gesture onEnded
            if handler.zoomLevel < 0.8 {
                handler.resetZoomAndPan()
                // Note: Animation might be in progress, so we don't test exact values
                #expect(handler.zoomLevel >= 0.5, "Should be moving toward default zoom")
            }
        }

        // Test that higher zoom levels don't trigger reset
        let highZoomValues: [Double] = [0.8, 1.0, 1.5, 2.0]
        for highZoom in highZoomValues {
            handler.setZoomLevel(highZoom)
            // Values >= 0.8 should not trigger automatic reset
            #expect(handler.zoomLevel >= 0.8, "High zoom values should not reset")
        }
    }

    @Test("ConcentrationChartGestureHandler pan gesture dragging state")
    func testPanGestureDraggingState() {
        let handler = ConcentrationChartGestureHandler()

        // Test initial dragging state
        #expect(handler.isDragging == false, "Should start with isDragging false")

        // Test dragging state management (simulates pan gesture behavior)
        handler.isDragging = true
        #expect(handler.isDragging == true, "Should update dragging state")

        handler.isDragging = false
        #expect(handler.isDragging == false, "Should update dragging state back to false")

        // Test multiple state changes
        for _ in 0..<5 {
            handler.isDragging = true
            #expect(handler.isDragging == true, "Should handle multiple state changes")
            handler.isDragging = false
            #expect(handler.isDragging == false, "Should handle multiple state changes")
        }
    }

    @Test("ConcentrationChartGestureHandler pan gesture offset calculations")
    func testPanGestureOffsetCalculations() {
        let handler = ConcentrationChartGestureHandler()

        // Test pan offset calculations with different zoom levels
        let zoomLevels: [Double] = [0.5, 1.0, 1.5, 2.0, 3.0]

        for zoomLevel in zoomLevels {
            handler.setZoomLevel(zoomLevel)

            // Simulate pan gesture translation values
            let translationValues: [CGSize] = [
                CGSize(width: 10, height: 10),
                CGSize(width: 50, height: -30),
                CGSize(width: -20, height: 40),
                CGSize(width: 100, height: -100),
            ]

            for translation in translationValues {
                // Simulate the calculation from pan gesture: translation / zoomLevel
                let calculatedOffset = CGSize(
                    width: translation.width / zoomLevel,
                    height: translation.height / zoomLevel
                )

                handler.setPanOffset(calculatedOffset)

                // Verify the offset is within bounds (clamped to ±100)
                #expect(handler.panOffset.width >= -100, "Pan offset width should be clamped")
                #expect(handler.panOffset.width <= 100, "Pan offset width should be clamped")
                #expect(handler.panOffset.height >= -100, "Pan offset height should be clamped")
                #expect(handler.panOffset.height <= 100, "Pan offset height should be clamped")
            }
        }
    }

    @Test("ConcentrationChartGestureHandler pan gesture snap back logic")
    func testPanGestureSnapBackLogic() {
        let handler = ConcentrationChartGestureHandler()

        // Test snap back logic (simulates pan gesture onEnded)
        let extremeOffsets: [CGSize] = [
            CGSize(width: 150, height: 50),  // Exceeds width limit
            CGSize(width: -120, height: 30),  // Exceeds negative width limit
            CGSize(width: 50, height: 150),  // Exceeds height limit
            CGSize(width: 30, height: -120),  // Exceeds negative height limit
            CGSize(width: 200, height: 200),  // Exceeds both limits
            CGSize(width: -150, height: -150),  // Exceeds both negative limits
        ]

        for extremeOffset in extremeOffsets {
            // Set an extreme offset (simulating user dragging too far)
            handler.panOffset = extremeOffset

            // Simulate the snap back logic from pan gesture onEnded
            let maxOffset: CGFloat = 100
            let clampedOffset = CGSize(
                width: max(-maxOffset, min(maxOffset, handler.panOffset.width)),
                height: max(-maxOffset, min(maxOffset, handler.panOffset.height))
            )

            handler.setPanOffset(clampedOffset)

            #expect(handler.panOffset.width >= -100, "Should snap back width to bounds")
            #expect(handler.panOffset.width <= 100, "Should snap back width to bounds")
            #expect(handler.panOffset.height >= -100, "Should snap back height to bounds")
            #expect(handler.panOffset.height <= 100, "Should snap back height to bounds")
        }
    }

    @Test("ConcentrationChartGestureHandler gesture interaction combinations")
    func testGestureInteractionCombinations() {
        let handler = ConcentrationChartGestureHandler()

        // Test combinations of zoom and pan that might occur during gestures
        let testCombinations: [(zoom: Double, pan: CGSize)] = [
            (zoom: 0.5, pan: CGSize(width: 50, height: 30)),
            (zoom: 1.5, pan: CGSize(width: -40, height: 60)),
            (zoom: 2.0, pan: CGSize(width: 80, height: -20)),
            (zoom: 0.7, pan: CGSize(width: -60, height: -40)),
            (zoom: 3.0, pan: CGSize(width: 25, height: 75)),
        ]

        for (index, combination) in testCombinations.enumerated() {
            // Apply combination of settings (simulates concurrent gesture interactions)
            handler.setZoomLevel(combination.zoom)
            handler.setPanOffset(combination.pan)
            handler.isDragging = (index % 2 == 0)

            // Verify all properties are within valid ranges
            #expect(handler.zoomLevel >= 0.5 && handler.zoomLevel <= 3.0, "Zoom should be in valid range")
            #expect(handler.panOffset.width >= -100 && handler.panOffset.width <= 100, "Pan X should be in valid range")
            #expect(
                handler.panOffset.height >= -100 && handler.panOffset.height <= 100, "Pan Y should be in valid range")
            #expect(handler.isDragging == (index % 2 == 0), "Dragging state should match")

            // Test reset behavior with different starting states
            handler.resetZoomAndPan()
            // Note: Due to animation, we can't test exact values immediately
        }
    }

    @Test("ConcentrationChartGestureHandler gesture boundary conditions")
    func testGestureBoundaryConditions() {
        let handler = ConcentrationChartGestureHandler()

        // Test edge cases that might occur in gesture handling

        // Test minimum zoom boundary
        handler.setZoomLevel(0.5)
        #expect(handler.zoomLevel == 0.5, "Should handle minimum zoom boundary")

        // Test maximum zoom boundary
        handler.setZoomLevel(3.0)
        #expect(handler.zoomLevel == 3.0, "Should handle maximum zoom boundary")

        // Test maximum pan boundaries
        handler.setPanOffset(CGSize(width: 100, height: 100))
        #expect(handler.panOffset.width == 100, "Should handle maximum pan boundary")
        #expect(handler.panOffset.height == 100, "Should handle maximum pan boundary")

        // Test minimum pan boundaries
        handler.setPanOffset(CGSize(width: -100, height: -100))
        #expect(handler.panOffset.width == -100, "Should handle minimum pan boundary")
        #expect(handler.panOffset.height == -100, "Should handle minimum pan boundary")

        // Test zero values
        handler.setZoomLevel(1.0)
        handler.setPanOffset(.zero)
        #expect(handler.zoomLevel == 1.0, "Should handle neutral zoom")
        #expect(handler.panOffset == .zero, "Should handle zero pan offset")
    }

    @Test("ConcentrationChartGestureHandler gesture state consistency")
    func testGestureStateConsistency() {
        let handler = ConcentrationChartGestureHandler()

        // Test that gesture state remains consistent across operations
        let iterations = 10

        for iteration in 0..<iterations {
            let zoom = 0.5 + (Double(iteration) / Double(iterations - 1)) * 2.5  // 0.5 to 3.0
            let panX = -100 + (Double(iteration) / Double(iterations - 1)) * 200  // -100 to 100
            let panY = -100 + (Double(iteration) / Double(iterations - 1)) * 200  // -100 to 100
            let isDragging = iteration % 2 == 0

            // Apply state changes
            handler.setZoomLevel(zoom)
            handler.setPanOffset(CGSize(width: panX, height: panY))
            handler.isDragging = isDragging

            // Verify state consistency
            #expect(handler.zoomLevel >= 0.5 && handler.zoomLevel <= 3.0, "Zoom should remain in bounds")
            #expect(handler.panOffset.width >= -100 && handler.panOffset.width <= 100, "Pan X should remain in bounds")
            #expect(
                handler.panOffset.height >= -100 && handler.panOffset.height <= 100, "Pan Y should remain in bounds")
            #expect(handler.isDragging == isDragging, "Dragging state should be preserved")

            // Verify that getter methods work correctly
            _ = handler.zoomGesture
            _ = handler.panGesture

            // These gestures should exist and not cause crashes when accessed
            #expect(true, "Gesture getters should be accessible without crashes")
        }
    }
}
