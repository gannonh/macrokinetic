//
//  ConcentrationChartGestureHandler.swift
//  JabTracker
//

import SwiftUI

/// Gesture handler for concentration timeline chart interactions
/// Manages zoom and pan gestures with clamping and animation
@Observable
class ConcentrationChartGestureHandler {

    // MARK: - Properties

    /// Current zoom level (0.5 to 3.0)
    var zoomLevel: Double = 1.0

    /// Current pan offset in points
    var panOffset: CGSize = .zero

    /// Whether user is currently dragging
    var isDragging: Bool = false

    // MARK: - Public Methods

    /// Resets zoom and pan to default state with animation
    func resetZoomAndPan() {
        withAnimation(.easeInOut(duration: 0.5)) {
            zoomLevel = 1.0
            panOffset = .zero
        }
    }

    /// Sets zoom level programmatically with clamping and animation
    /// - Parameter level: Zoom level (will be clamped to 0.5-3.0 range)
    func setZoomLevel(_ level: Double) {
        let clampedLevel = max(0.5, min(3.0, level))
        withAnimation(.easeInOut(duration: 0.3)) {
            zoomLevel = clampedLevel
        }
    }

    /// Sets pan offset programmatically with clamping and animation
    /// - Parameter offset: Pan offset (will be clamped to prevent excessive panning)
    func setPanOffset(_ offset: CGSize) {
        let maxOffset: CGFloat = 100
        let clampedOffset = CGSize(
            width: max(-maxOffset, min(maxOffset, offset.width)),
            height: max(-maxOffset, min(maxOffset, offset.height))
        )
        withAnimation(.easeInOut(duration: 0.3)) {
            panOffset = clampedOffset
        }
    }

    // MARK: - Gesture Definitions

    /// Zoom gesture for chart interaction
    var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                self.zoomLevel = max(0.5, min(3.0, value))
            }
            .onEnded { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    if self.zoomLevel < 0.8 {
                        self.zoomLevel = 1.0
                        self.panOffset = .zero
                    }
                }
            }
    }

    /// Pan gesture for chart interaction
    var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                self.isDragging = true
                self.panOffset = CGSize(
                    width: value.translation.width / self.zoomLevel,
                    height: value.translation.height / self.zoomLevel
                )
            }
            .onEnded { _ in
                self.isDragging = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    // Snap back if dragged too far
                    let maxOffset: CGFloat = 100
                    self.panOffset = CGSize(
                        width: max(-maxOffset, min(maxOffset, self.panOffset.width)),
                        height: max(-maxOffset, min(maxOffset, self.panOffset.height))
                    )
                }
            }
    }
}
