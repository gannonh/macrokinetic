//
//  ChartExportView.swift
//  JabTracker
//

import Charts
import SwiftUI

/// High-resolution chart export functionality for medical records and provider reports
/// Provides professional-quality chart rendering optimized for print and digital distribution
struct ChartExportView: View {

  // MARK: - Properties

  /// Chart dataset to export
  let dataset: ConcentrationChartDataset

  /// Export configuration settings
  let exportConfig: ChartExportConfiguration

  /// Export completion handler
  let onExportComplete: (Result<URL, ChartExportError>) -> Void

  /// Current export status
  @State private var exportStatus: ExportStatus = .idle
  @State private var exportProgress: Double = 0.0

  // MARK: - Initialization

  /// Creates a chart export view with the specified dataset and configuration
  /// - Parameters:
  ///   - dataset: Chart dataset to export
  ///   - exportConfig: Export configuration settings
  ///   - onExportComplete: Completion handler called when export finishes
  init(
    dataset: ConcentrationChartDataset,
    exportConfig: ChartExportConfiguration = .default,
    onExportComplete: @escaping (Result<URL, ChartExportError>) -> Void
  ) {
    self.dataset = dataset
    self.exportConfig = exportConfig
    self.onExportComplete = onExportComplete
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 24) {
      exportHeaderView()

      if exportStatus == .exporting {
        exportProgressView()
      } else {
        exportPreviewView()
        exportOptionsView()
        exportActionsView()
      }
    }
    .padding()
    .navigationTitle("Export Chart")
    .navigationBarTitleDisplayMode(.inline)
  }

  // MARK: - Export Header

  @ViewBuilder
  private func exportHeaderView() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Export Concentration Timeline")
        .font(.headline)
        .foregroundColor(.primary)

      Text("Generate high-resolution chart for medical records or provider reports")
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Export Preview

  @ViewBuilder
  private func exportPreviewView() -> some View {
    VStack(spacing: 12) {
      Text("Preview")
        .font(.subheadline)
        .fontWeight(.medium)
        .frame(maxWidth: .infinity, alignment: .leading)

      // Scaled-down preview of the export chart
      ConcentrationTimelineChart(dataset: dataset)
        .frame(height: 200)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemBackground))
            .shadow(radius: 2)
        )
        .accessibilityLabel("Export preview")
        .accessibilityHint("Shows how the exported chart will appear")
    }
  }

  // MARK: - Export Options

  @ViewBuilder
  private func exportOptionsView() -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Export Options")
        .font(.subheadline)
        .fontWeight(.medium)

      VStack(spacing: 12) {
        exportFormatRow()
        exportQualityRow()
        exportSizeRow()
        exportIncludeMetadataRow()
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func exportFormatRow() -> some View {
    HStack {
      Text("Format:")
        .foregroundColor(.secondary)
      Spacer()
      Text(exportConfig.format.displayName)
        .foregroundColor(.primary)
        .fontWeight(.medium)
    }
  }

  @ViewBuilder
  private func exportQualityRow() -> some View {
    HStack {
      Text("Quality:")
        .foregroundColor(.secondary)
      Spacer()
      Text(exportConfig.quality.displayName)
        .foregroundColor(.primary)
        .fontWeight(.medium)
    }
  }

  @ViewBuilder
  private func exportSizeRow() -> some View {
    HStack {
      Text("Size:")
        .foregroundColor(.secondary)
      Spacer()
      Text("\(Int(exportConfig.size.width))×\(Int(exportConfig.size.height))")
        .foregroundColor(.primary)
        .fontWeight(.medium)
    }
  }

  @ViewBuilder
  private func exportIncludeMetadataRow() -> some View {
    HStack {
      Text("Include Metadata:")
        .foregroundColor(.secondary)
      Spacer()
      Text(exportConfig.includeMetadata ? "Yes" : "No")
        .foregroundColor(.primary)
        .fontWeight(.medium)
    }
  }

  // MARK: - Export Progress

  @ViewBuilder
  private func exportProgressView() -> some View {
    VStack(spacing: 16) {
      Text("Exporting Chart...")
        .font(.headline)
        .foregroundColor(.primary)

      ProgressView(value: exportProgress, total: 1.0)
        .progressViewStyle(LinearProgressViewStyle())
        .scaleEffect(1.2)

      Text("\(Int(exportProgress * 100))% Complete")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.systemBackground))
        .shadow(radius: 4)
    )
  }

  // MARK: - Export Actions

  @ViewBuilder
  private func exportActionsView() -> some View {
    VStack(spacing: 12) {
      Button(action: startExport) {
        HStack {
          Image(systemName: "square.and.arrow.up")
            .font(.system(size: 16, weight: .medium))
          Text("Export Chart")
            .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
      }
      .disabled(exportStatus == .exporting)
      .accessibilityLabel("Export chart")
      .accessibilityHint("Generates high-resolution chart file for sharing")

      Button(
        action: { /* Configure export options */  },
        label: {
          HStack {
            Image(systemName: "gearshape")
              .font(.system(size: 16, weight: .medium))
            Text("Configure Options")
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color(.systemGray5))
          .foregroundColor(.primary)
          .cornerRadius(12)
        }
      )
      .disabled(exportStatus == .exporting)
      .accessibilityLabel("Configure export options")
      .accessibilityHint("Modify export format, quality, and size settings")
    }
  }

  // MARK: - Export Logic

  /// Initiates the chart export process
  private func startExport() {
    exportStatus = .exporting
    exportProgress = 0.0

    Task {
      do {
        let exportURL = try await performExport()
        await MainActor.run {
          exportStatus = .completed
          onExportComplete(.success(exportURL))
        }
      } catch {
        await MainActor.run {
          exportStatus = .failed
          if let exportError = error as? ChartExportError {
            onExportComplete(.failure(exportError))
          } else {
            onExportComplete(.failure(.unknownError(error)))
          }
        }
      }
    }
  }

  /// Performs the actual chart export operation
  /// - Returns: URL of the exported chart file
  private func performExport() async throws -> URL {
    // Simulate export progress
    for index in 1...10 {
      try await Task.sleep(nanoseconds: 100_000_000)  // 100ms
      await MainActor.run {
        exportProgress = Double(index) / 10.0
      }
    }

    // Generate high-resolution chart image
    let chartRenderer = ChartRenderer(
      dataset: dataset,
      configuration: exportConfig
    )

    return try await chartRenderer.renderToFile()
  }
}

// MARK: - Supporting Types

/// Export configuration for chart rendering
struct ChartExportConfiguration {
  let format: ExportFormat
  let quality: ExportQuality
  let size: CGSize
  let includeMetadata: Bool

  static let `default` = ChartExportConfiguration(
    format: .pdf,
    quality: .high,
    size: CGSize(width: 1200, height: 800),
    includeMetadata: true
  )
}

/// Available export formats
enum ExportFormat: String, CaseIterable {
  case pdf
  case png
  case jpeg

  var displayName: String {
    switch self {
    case .pdf: return "PDF"
    case .png: return "PNG"
    case .jpeg: return "JPEG"
    }
  }

  var fileExtension: String {
    rawValue
  }
}

/// Export quality settings
enum ExportQuality: String, CaseIterable {
  case standard
  case high
  case ultra

  var displayName: String {
    switch self {
    case .standard: return "Standard"
    case .high: return "High"
    case .ultra: return "Ultra"
    }
  }

  var scaleFactor: CGFloat {
    switch self {
    case .standard: return 1.0
    case .high: return 2.0
    case .ultra: return 3.0
    }
  }
}

/// Export status tracking
enum ExportStatus {
  case idle
  case exporting
  case completed
  case failed
}

/// Chart export errors
enum ChartExportError: Error, LocalizedError {
  case renderingFailed
  case fileSystemError
  case invalidConfiguration
  case unknownError(Error)

  var errorDescription: String? {
    switch self {
    case .renderingFailed:
      return "Failed to render chart image"
    case .fileSystemError:
      return "Unable to save exported file"
    case .invalidConfiguration:
      return "Invalid export configuration"
    case .unknownError(let error):
      return "Export failed: \(error.localizedDescription)"
    }
  }
}

/// Chart renderer for high-resolution export
struct ChartRenderer {
  let dataset: ConcentrationChartDataset
  let configuration: ChartExportConfiguration

  func renderToFile() async throws -> URL {
    // This would implement actual chart rendering to file
    // For now, return a placeholder URL
    let documentsPath =
      FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
      ).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
    let filename =
      "concentration_chart_\(Date().timeIntervalSince1970).\(configuration.format.fileExtension)"
    return documentsPath.appendingPathComponent(filename)
  }
}

// MARK: - Preview

#Preview {
  NavigationStack {
    ChartExportView(
      dataset: .preview,
      exportConfig: .default
    ) { result in
      switch result {
      case .success(let url):
        print("Export successful: \(url)")
      case .failure(let error):
        print("Export failed: \(error)")
      }
    }
  }
}

// MARK: - Preview Data Extension

extension ConcentrationChartDataset {
  static var preview: ConcentrationChartDataset {
    let samplePoints = [
      AdvancedConcentrationPoint(date: Date().addingTimeInterval(-24 * 3600), concentration: 0.0),
      AdvancedConcentrationPoint(date: Date().addingTimeInterval(-12 * 3600), concentration: 5.2),
      AdvancedConcentrationPoint(date: Date(), concentration: 2.1),
    ]

    let sampleMarkers = [
      AdvancedDoseMarker(
        date: Date().addingTimeInterval(-24 * 3600),
        amount: 1.0,
        markerStyle: .firstDose
      )
    ]

    let sampleCurve = ConcentrationCurve(
      points: samplePoints,
      medication: "semaglutide"
    )

    return ConcentrationChartDataset(
      concentrationCurves: [sampleCurve],
      doseMarkers: sampleMarkers,
      configuration: .default
    )
  }
}
