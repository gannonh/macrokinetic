//
//  CameraPreviewView.swift
//  JabTracker
//
//  UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer.
//

import AVFoundation
import SwiftUI
import UIKit

/// UIViewRepresentable that wraps AVCaptureVideoPreviewLayer for camera preview.
///
/// Usage:
/// ```swift
/// CameraPreviewView(session: cameraService.session)
/// ```
struct CameraPreviewView: UIViewRepresentable {
    // MARK: - Properties

    /// The AVCaptureSession to display
    let session: AVCaptureSession?

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

// MARK: - PreviewView

/// Custom UIView that uses AVCaptureVideoPreviewLayer as its backing layer.
final class PreviewView: UIView {
    // MARK: - Layer Class

    // swiftlint:disable:next static_over_final_class
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    // MARK: - Properties

    /// The video preview layer (type-safe accessor)
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        // swiftlint:disable:next force_cast
        layer as! AVCaptureVideoPreviewLayer
    }
}

// MARK: - Preview

#Preview {
    CameraPreviewView(session: nil)
        .frame(height: 300)
        .background(Color.black)
}
