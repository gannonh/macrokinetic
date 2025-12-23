//
//  CameraService.swift
//  JabTracker
//
//  Camera service for barcode scanning with permission handling.
//

@preconcurrency import AVFoundation
import OSLog

/// CameraService manages camera access and AVCaptureSession for barcode scanning.
///
/// This service handles:
/// - Camera permission requests and status tracking
/// - AVCaptureSession configuration and lifecycle
/// - Torch/flash control
///
/// Architecture:
/// - Uses @Observable pattern for real-time updates (iOS 17+)
/// - Session runs on background queue, UI updates on main actor
/// - Not added to AppServices - owned by BarcodeScannerContentView
///
/// Thread Safety: All public methods are @MainActor to ensure safe access to @Observable properties
@Observable
@MainActor
final class CameraService {
    // MARK: - Properties

    /// Current camera authorization status
    var authorizationStatus: AVAuthorizationStatus = .notDetermined

    /// The AVCaptureSession for video capture
    private(set) var session: AVCaptureSession?

    /// Indicates if the capture session is currently running
    var isSessionRunning: Bool = false

    /// Indicates if the torch/flash is currently on
    var isTorchOn: Bool = false

    /// Logger for camera service operations
    private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "CameraService")

    /// Background queue for session operations
    private let sessionQueue = DispatchQueue(label: "com.gannonhall.JabTracker.CameraService.sessionQueue")

    // MARK: - Initialization

    init() {
        logger.info("CameraService initialized")
    }

    // MARK: - Authorization

    /// Request camera authorization from the user.
    ///
    /// Updates the authorizationStatus property based on the user's response.
    ///
    /// - Returns: True if authorized, false if denied or restricted
    func requestAuthorization() async -> Bool {
        logger.info("Requesting camera authorization")

        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            authorizationStatus = .authorized
            logger.info("Camera already authorized")
            return true

        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorizationStatus = granted ? .authorized : .denied
            logger.info("Camera authorization request: \(granted ? "granted" : "denied")")
            return granted

        case .denied, .restricted:
            authorizationStatus = status
            logger.warning("Camera authorization denied or restricted")
            return false

        @unknown default:
            authorizationStatus = .denied
            logger.error("Unknown camera authorization status")
            return false
        }
    }

    /// Check the current camera authorization status.
    ///
    /// - Returns: Current AVAuthorizationStatus for video capture
    func checkAuthorizationStatus() -> AVAuthorizationStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        authorizationStatus = status
        logger.debug("Camera authorization status: \(String(describing: status))")
        return status
    }

    // MARK: - Session Management

    /// Configure and start the AVCaptureSession with video input.
    ///
    /// Creates a new session if one doesn't exist, configures video input,
    /// and starts the session on a background queue.
    ///
    /// - Throws: CameraServiceError if session configuration fails
    func startSession() throws {
        logger.info("Starting camera session")

        guard authorizationStatus == .authorized else {
            logger.error("Cannot start session: camera not authorized")
            throw CameraServiceError.notAuthorized
        }

        // Create session if needed
        if session == nil {
            session = AVCaptureSession()
        }

        guard let captureSession = session else {
            logger.error("Failed to create capture session")
            throw CameraServiceError.sessionConfigurationFailed
        }

        // Configure session on background queue
        sessionQueue.async { [weak self] in
            guard let self else { return }

            captureSession.beginConfiguration()

            // Set session preset for barcode scanning
            if captureSession.canSetSessionPreset(.high) {
                captureSession.sessionPreset = .high
            }

            // Add video input
            do {
                guard let videoDevice = AVCaptureDevice.default(for: .video) else {
                    Task { @MainActor in
                        self.logger.error("No video device available")
                    }
                    captureSession.commitConfiguration()
                    return
                }

                let videoInput = try AVCaptureDeviceInput(device: videoDevice)

                if captureSession.canAddInput(videoInput) {
                    captureSession.addInput(videoInput)
                } else {
                    Task { @MainActor in
                        self.logger.error("Cannot add video input to session")
                    }
                    captureSession.commitConfiguration()
                    return
                }
            } catch {
                Task { @MainActor in
                    self.logger.error("Failed to create video input: \(error.localizedDescription)")
                }
                captureSession.commitConfiguration()
                return
            }

            captureSession.commitConfiguration()

            // Start running
            captureSession.startRunning()

            Task { @MainActor in
                self.isSessionRunning = captureSession.isRunning
                self.logger.info("Camera session started: \(captureSession.isRunning)")
            }
        }
    }

    /// Stop and clean up the capture session.
    ///
    /// Stops the session on a background queue and updates state.
    func stopSession() {
        logger.info("Stopping camera session")

        // Turn off torch before stopping
        if isTorchOn {
            toggleTorch(on: false)
        }

        // Capture session reference before async block
        let captureSession = session

        sessionQueue.async { [weak self] in
            guard let self else { return }

            captureSession?.stopRunning()

            Task { @MainActor in
                self.isSessionRunning = false
                self.logger.info("Camera session stopped")
            }
        }
    }

    // MARK: - Torch Control

    /// Toggle the torch/flash on or off.
    ///
    /// - Parameter on: True to turn torch on, false to turn off
    func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
            device.hasTorch,
            device.isTorchAvailable
        else {
            logger.warning("Torch not available on this device")
            return
        }

        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
            isTorchOn = on
            logger.debug("Torch toggled: \(on ? "on" : "off")")
        } catch {
            logger.error("Failed to toggle torch: \(error.localizedDescription)")
        }
    }
}

// MARK: - CameraServiceError

/// Errors specific to CameraService operations.
enum CameraServiceError: LocalizedError {
    case notAuthorized
    case sessionConfigurationFailed
    case noVideoDevice

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return NSLocalizedString(
                "Camera access is not authorized. Please enable camera access in Settings.",
                comment: "Camera not authorized error"
            )
        case .sessionConfigurationFailed:
            return NSLocalizedString(
                "Failed to configure camera session. Please try again.",
                comment: "Session configuration failed error"
            )
        case .noVideoDevice:
            return NSLocalizedString(
                "No camera available on this device.",
                comment: "No video device error"
            )
        }
    }
}
