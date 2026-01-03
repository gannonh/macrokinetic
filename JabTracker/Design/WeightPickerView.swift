//
//  WeightPickerView.swift
//  JabTracker
//
//  Reusable wheel picker for weight input with unit support.
//  Used in AccountView, QuickWeightSheet, and GoalWizard.
//

import SwiftUI

/// Reusable wheel picker for weight entry
/// Displays whole number and decimal pickers with unit label
struct WeightPickerView: View {
    /// Weight whole number (e.g., 150 in 150.5)
    @Binding var weightWhole: Int
    /// Weight decimal (0-9, e.g., 5 in 150.5)
    @Binding var weightDecimal: Int
    /// Unit to display ("kg" or "lbs")
    let unit: String

    /// Range for whole number picker (default 30-400)
    var wholeRange: ClosedRange<Int> = 30...400

    var body: some View {
        HStack(spacing: 0) {
            Picker("Whole", selection: $weightWhole) {
                ForEach(wholeRange, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(width: 100, height: 150)
            .clipped()

            Text(".")
                .font(.title)

            Picker("Decimal", selection: $weightDecimal) {
                ForEach(0...9, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(width: 60, height: 150)
            .clipped()

            Text(unit)
                .font(.title3)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
        }
        .accessibilityIdentifier("weight-picker")
    }

    // MARK: - Computed Weight Values

    /// Combined weight value from whole and decimal
    var weightValue: Double {
        Double(weightWhole) + Double(weightDecimal) / 10.0
    }

    /// Weight converted to kg (if unit is lbs, converts; otherwise returns as-is)
    var weightInKg: Double {
        if unit == "lbs" {
            return weightValue / WeightEntry.kgToLbsConversion
        }
        return weightValue
    }

    // MARK: - Initialization Helpers

    /// Initialize picker values from a weight in display units
    static func pickerValues(from weight: Double) -> (whole: Int, decimal: Int) {
        let whole = Int(weight)
        let decimal = Int(((weight - Double(whole)) * 10).rounded())
        return (whole, decimal)
    }

    /// Initialize picker values from kg, converting to display unit if needed
    static func pickerValues(fromKg weightKg: Double, unit: String) -> (whole: Int, decimal: Int) {
        let displayWeight = unit == "lbs" ? weightKg * WeightEntry.kgToLbsConversion : weightKg
        return pickerValues(from: displayWeight)
    }
}

// MARK: - Double Extension

extension Double {
    /// Round to specified decimal places
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var whole = 150
        @State var decimal = 5

        var body: some View {
            VStack {
                WeightPickerView(
                    weightWhole: $whole,
                    weightDecimal: $decimal,
                    unit: "lbs"
                )

                Text("Value: \(whole).\(decimal) lbs")
            }
        }
    }
    return PreviewWrapper()
}
