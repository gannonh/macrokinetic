//
//  BarcodeScannerContentView.swift
//  JabTracker
//
//  Barcode scanner content view with camera preview and controls.
//

import AVFoundation
import OSLog
import SwiftUI

/// Logger for BarcodeScannerContentView
private let logger = Logger(
    subsystem: "com.gannonhall.JabTracker",
    category: "BarcodeScannerContentView"
)

/// Scan type options for the scanner
enum ScanType: String, CaseIterable, Identifiable {
    case barcode
    case label

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .barcode: return "Barcode"
        case .label: return "Label"
        }
    }

    /// Whether this scan type is currently functional
    var isEnabled: Bool {
        switch self {
        case .barcode: return true
        case .label: return false  // Coming in future phase
        }
    }
}

/// Content view for barcode scanning with camera preview and controls.
///
/// Features:
/// - Sub-toggle row with Barcode/Label pills
/// - Torch toggle button
/// - Full camera preview with scanning reticle
/// - Permission denied state handling
///
/// Usage:
/// ```swift
/// BarcodeScannerContentView { barcode in
///     print("Scanned: \(barcode)")
/// }
/// ```
struct BarcodeScannerContentView: View {
    // MARK: - Properties

    /// Callback when a barcode is detected
    let onBarcodeDetected: (String) -> Void

    // MARK: - State

    @State private var cameraService = CameraService()
    @State private var selectedScanType: ScanType = .barcode

    // MARK: - Static Identifiers

    static let accessibilityIdentifierValue = "barcode-scanner-content"
    static let cameraPreviewIdentifier = "camera-preview"
    static let scanTypeBarcodeIdentifier = "scan-type-barcode"
    static let scanTypeLabelIdentifier = "scan-type-label"
    static let torchToggleIdentifier = "torch-toggle-button"
    static let galleryButtonIdentifier = "gallery-button"

    // MARK: - Theme Constants

    private enum ScannerTheme {
        static let backgroundOpacity: Double = 0.1
        static let borderOpacity: Double = 0.3
        static let disabledTextOpacity: Double = 0.5
        static let reticleStrokeOpacity: Double = 0.8
        static let reticleFillOpacity: Double = 0.05
        static let instructionTextOpacity: Double = 0.9
        static let instructionBackgroundOpacity: Double = 0.5
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Sub-toggle row
            subToggleRow

            // Main content: camera preview, error state, or permission denied
            if cameraService.authorizationStatus == .denied
                || cameraService.authorizationStatus == .restricted
            {
                permissionDeniedView
            } else if let error = cameraService.sessionError {
                cameraErrorView(error: error)
            } else {
                cameraPreviewSection
            }
        }
        .accessibilityIdentifier(Self.accessibilityIdentifierValue)
        .onAppear {
            // Reset debounce state to allow re-scanning same barcode
            cameraService.resetDebounce()
            // Wire up barcode detection callback (direct assignment)
            cameraService.onBarcodeDetected = onBarcodeDetected
            Task {
                await setupCamera()
            }
        }
        .onDisappear {
            // Clear callback to prevent potential retain cycles
            cameraService.onBarcodeDetected = nil
            cameraService.stopSession()
        }
    }

    // MARK: - Sub-Toggle Row

    private var subToggleRow: some View {
        HStack(spacing: 8) {
            // Scan type pills
            ForEach(ScanType.allCases) { scanType in
                scanTypePill(scanType)
            }

            Spacer()

            // Gallery button (disabled)
            Button {
                // Coming in future phase
            } label: {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
            .disabled(true)
            .accessibilityIdentifier(Self.galleryButtonIdentifier)
            .accessibilityLabel("Select from gallery")

            // Torch button
            Button {
                cameraService.toggleTorch(on: !cameraService.isTorchOn)
            } label: {
                Image(systemName: cameraService.isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 18))
                    .foregroundColor(cameraService.isTorchOn ? .yellow : .secondary)
            }
            .accessibilityIdentifier(Self.torchToggleIdentifier)
            .accessibilityLabel(cameraService.isTorchOn ? "Turn off flash" : "Turn on flash")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
    }

    private func scanTypePill(_ scanType: ScanType) -> some View {
        Button {
            if scanType.isEnabled {
                selectedScanType = scanType
            }
        } label: {
            Text(scanType.displayName)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    selectedScanType == scanType
                        ? Color.primary.opacity(ScannerTheme.backgroundOpacity)
                        : Color.clear
                )
                .foregroundColor(
                    scanType.isEnabled
                        ? .primary
                        : .secondary.opacity(ScannerTheme.disabledTextOpacity)
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            selectedScanType == scanType
                                ? Color.primary.opacity(ScannerTheme.borderOpacity)
                                : Color(.systemGray4),
                            lineWidth: 1
                        )
                )
        }
        .disabled(!scanType.isEnabled)
        .accessibilityIdentifier(
            scanType == .barcode
                ? Self.scanTypeBarcodeIdentifier
                : Self.scanTypeLabelIdentifier
        )
    }

    // MARK: - Camera Preview Section

    private var cameraPreviewSection: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview
                CameraPreviewView(session: cameraService.session)
                    .ignoresSafeArea()
                    .accessibilityIdentifier(Self.cameraPreviewIdentifier)

                // Scanning reticle overlay
                scanningReticle(in: geometry)
            }
        }
        .background(Color.black)
    }

    private func scanningReticle(in geometry: GeometryProxy) -> some View {
        let reticleWidth = min(geometry.size.width * 0.8, 300)
        let reticleHeight: CGFloat = 120

        return VStack(spacing: 16) {
            Spacer()

            // Reticle frame
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(ScannerTheme.reticleStrokeOpacity), lineWidth: 3)
                .frame(width: reticleWidth, height: reticleHeight)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(ScannerTheme.reticleFillOpacity))
                )

            // Instruction text
            Text("Point at a barcode")
                .font(.subheadline)
                .foregroundColor(.white.opacity(ScannerTheme.instructionTextOpacity))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(ScannerTheme.instructionBackgroundOpacity))
                )

            Spacer()
                .frame(height: geometry.size.height * 0.2)
        }
    }

    // MARK: - Permission Denied View

    private var permissionDeniedView: some View {
        ContentUnavailableView {
            Label("Camera Access Required", systemImage: "camera.fill")
        } description: {
            Text("JabTracker needs camera access to scan barcodes. Please enable camera access in Settings.")
        } actions: {
            Button("Open Settings") {
                openAppSettings()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Camera Error View

    private func cameraErrorView(error: CameraServiceError) -> some View {
        ContentUnavailableView {
            Label("Camera Error", systemImage: "exclamationmark.camera.fill")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Try Again") {
                startCameraSession()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Helpers

    private func setupCamera() async {
        let status = cameraService.checkAuthorizationStatus()

        // Early return for denied/restricted - UI shows permission denied view
        guard status != .denied && status != .restricted else { return }

        // Request authorization if not determined
        if status == .notDetermined {
            guard await cameraService.requestAuthorization() else { return }
        }

        startCameraSession()
    }

    private func startCameraSession() {
        do {
            try cameraService.startSession()
            logger.info("Camera session started for barcode scanning")
        } catch {
            logger.error("Failed to start camera session: \(error.localizedDescription)")
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsURL)
    }
}

// MARK: - Preview

#Preview("Scanner View") {
    BarcodeScannerContentView { barcode in
        print("Scanned: \(barcode)")
    }
}

#Preview("Permission Denied") {
    // This preview won't show denied state without mocking
    BarcodeScannerContentView { _ in }
}
