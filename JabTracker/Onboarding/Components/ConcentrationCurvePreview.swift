//
//  ConcentrationCurvePreview.swift
//  JabTracker
//
//  Concentration curve preview chart for onboarding schedule setup
//

import Charts
import SwiftUI

/// Preview chart showing projected concentration curve for selected schedule pattern
///
/// Uses PharmacokineticsEngine to calculate realistic concentration curves
/// based on the selected dosing pattern. Helps users understand how their
/// medication levels will change over time with different schedules.
struct ConcentrationCurvePreview: View {
    let pattern: SchedulePatternType
    let medication: Medication?
    let pkEngine: PharmacokineticsEngine
    let doseAmount: Double

    @State private var concentrationData: [PreviewConcentrationPoint] = []
    @State private var isCalculating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How Your Medication Works")
                .font(.headline)
                .foregroundColor(.primary)

            if isCalculating {
                // Loading state
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
            } else if concentrationData.isEmpty {
                // Empty state
                Text("No preview available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
            } else {
                // Chart
                Chart {
                    ForEach(concentrationData) { point in
                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("Concentration", point.concentration)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 0...maxConcentration * 1.1)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        AxisGridLine()
                        AxisTick()
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.day())
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .frame(height: 150)
                .accessibilityLabel(concentrationTrendDescription)

                // Peak/Trough labels
                HStack(spacing: 32) {
                    ConcentrationLabel(
                        title: "Peak",
                        value: peakConcentration,
                        color: .green
                    )

                    Spacer()

                    ConcentrationLabel(
                        title: "Trough",
                        value: troughConcentration,
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
        .accessibilityIdentifier("concentration-curve-preview")
        .task {
            await updateConcentrationData()
        }
        .onChange(of: pattern) { _, _ in
            Task { await updateConcentrationData() }
        }
        .onChange(of: medication?.rawValue) { _, _ in
            Task { await updateConcentrationData() }
        }
    }

    // MARK: - Computed Properties

    /// Maximum concentration for chart scaling
    private var maxConcentration: Double {
        concentrationData.map(\.concentration).max() ?? 100.0
    }

    /// Peak concentration value
    private var peakConcentration: Double {
        concentrationData.map(\.concentration).max() ?? 0.0
    }

    /// Trough concentration value (minimum non-zero)
    private var troughConcentration: Double {
        concentrationData.map(\.concentration).filter { $0 > 0 }.min() ?? 0.0
    }

    /// Accessibility description of concentration trend
    private var concentrationTrendDescription: String {
        let peak = peakConcentration
        let trough = troughConcentration
        let peakStr = String(format: "%.2f", peak)
        let troughStr = String(format: "%.2f", trough)
        return "Concentration curve showing peak level \(peakStr) and trough level \(troughStr)"
    }

    // MARK: - Data Calculation

    /// Update concentration data based on selected pattern
    @MainActor
    private func updateConcentrationData() async {
        guard let medication = medication else {
            concentrationData = []
            return
        }

        isCalculating = true
        defer { isCalculating = false }

        // Generate sample doses for preview
        let doses = generateSampleDoses(
            pattern: pattern,
            medication: medication,
            doseAmount: doseAmount
        )

        // Calculate concentration curve over 28 days
        concentrationData = calculateConcentrationCurve(
            doses: doses,
            medication: medication,
            days: 28
        )
    }

    /// Generate sample doses for preview based on pattern
    private func generateSampleDoses(
        pattern: SchedulePatternType,
        medication: Medication,
        doseAmount: Double
    ) -> [Dose] {
        var doses: [Dose] = []
        let startDate = Date().addingTimeInterval(-28 * 24 * 3600)  // 4 weeks ago

        let intervalDays: Int
        switch pattern {
        case .weekly:
            intervalDays = 7
        case .splitDose:
            intervalDays = 3  // Approximately twice weekly
        case .custom:
            intervalDays = 7  // Default to weekly
        }

        var currentDate = startDate
        let endDate = Date()

        while currentDate <= endDate {
            let dose = Dose(
                amount: doseAmount,
                timestamp: currentDate,
                site: "Thigh"
            )
            doses.append(dose)
            currentDate = currentDate.addingTimeInterval(Double(intervalDays) * 24 * 3600)
        }

        return doses
    }

    /// Calculate concentration curve from doses
    private func calculateConcentrationCurve(
        doses: [Dose],
        medication: Medication,
        days: Int
    ) -> [PreviewConcentrationPoint] {
        var points: [PreviewConcentrationPoint] = []
        guard let startDate = doses.first?.timestamp else { return points }
        let endDate = Date()

        // Generate points every 12 hours for smooth curve
        var currentTime = startDate
        let intervalHours: Double = 12

        while currentTime <= endDate {
            let concentration = pkEngine.calculateConcentration(
                from: doses,
                medication: medication,
                at: currentTime
            )

            points.append(
                PreviewConcentrationPoint(
                    id: UUID(),
                    date: currentTime,
                    concentration: concentration
                ))

            currentTime = currentTime.addingTimeInterval(intervalHours * 3600)
        }

        return points
    }
}

/// Data point for concentration curve preview
struct PreviewConcentrationPoint: Identifiable {
    let id: UUID
    let date: Date
    let concentration: Double
}

// MARK: - Preview

#Preview {
    @Previewable @State var pattern: SchedulePatternType = .weekly

    VStack(spacing: 24) {
        // Pattern selector for preview
        Picker("Pattern", selection: $pattern) {
            Text("Weekly").tag(SchedulePatternType.weekly)
            Text("Split Dose").tag(SchedulePatternType.splitDose)
        }
        .pickerStyle(.segmented)

        // Preview component
        ConcentrationCurvePreview(
            pattern: pattern,
            medication: .semaglutide,
            pkEngine: PharmacokineticsEngine(),
            doseAmount: 0.5
        )
    }
    .padding()
}
