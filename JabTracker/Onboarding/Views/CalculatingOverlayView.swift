//
//  CalculatingOverlayView.swift
//  JabTracker
//
//  Full-screen overlay shown while calculating personalized targets.
//

import SwiftUI

/// Full-screen overlay shown while calculating personalized targets
struct CalculatingOverlayView: View {
    @State private var isAnimating = false
    @State private var currentMessageIndex = 0

    private let messages = [
        "Analyzing your profile...",
        "Calculating TDEE...",
        "Building your macro targets...",
        "Personalizing your plan...",
    ]

    var body: some View {
        ZStack {
            // Semi-transparent background
            DesignTokens.Colors.groupedBackground
                .opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Animated icon
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(DesignTokens.Colors.accent.opacity(0.2), lineWidth: 4)
                        .frame(width: 80, height: 80)

                    // Animated arc
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(DesignTokens.Colors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)

                    // Center icon
                    Image(systemName: "function")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.accent)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                }

                VStack(spacing: 12) {
                    Text("Calculating Your Plan")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(messages[currentMessageIndex])
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .animation(.easeInOut, value: currentMessageIndex)
                }
            }
        }
        .onAppear {
            isAnimating = true
            startMessageRotation()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Calculating your personalized plan")
        .accessibilityIdentifier("calculating-overlay")
    }

    private func startMessageRotation() {
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            withAnimation {
                currentMessageIndex = (currentMessageIndex + 1) % messages.count
            }
        }
    }
}
