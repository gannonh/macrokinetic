//
//  UnitsOfMeasureView.swift
//  JabTracker
//
//  Settings screen for configuring weight and measurement unit preferences.
//

import SwiftData
import SwiftUI

struct UnitsOfMeasureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    private var user: User? { users.first }

    var body: some View {
        List {
            // Weight section
            Section {
                Picker(
                    "Weight",
                    selection: Binding(
                        get: { user?.weightUnit ?? "kg" },
                        set: { newValue in
                            user?.weightUnit = newValue
                            try? modelContext.save()
                        }
                    )
                ) {
                    Text("Kilograms (kg)").tag("kg")
                    Text("Pounds (lbs)").tag("lbs")
                }
                .accessibilityIdentifier("weight-unit-picker")
            } header: {
                Text("Weight")
            } footer: {
                Text("Used for body weight entries and HealthKit sync.")
            }

            // Body Measurements section
            Section {
                Picker(
                    "Measurements",
                    selection: Binding(
                        get: { user?.measurementUnit ?? "cm" },
                        set: { newValue in
                            user?.measurementUnit = newValue
                            try? modelContext.save()
                        }
                    )
                ) {
                    Text("Centimeters (cm)").tag("cm")
                    Text("Inches (in)").tag("in")
                }
                .accessibilityIdentifier("measurement-unit-picker")
            } header: {
                Text("Body Measurements")
            } footer: {
                Text("Used for waist, hip, chest, and other circumference measurements.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Units of Measure")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("units-of-measure-view")
    }
}

#Preview {
    NavigationStack {
        UnitsOfMeasureView()
    }
    .modelContainer(for: User.self, inMemory: true)
}
