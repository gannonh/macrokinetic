import SwiftUI

struct MedicationProfileHeader: View {
    let profile: MedicationProfile

    var body: some View {
        DesignCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Medication Details")
                    .font(DesignTokens.Typography.headline)

                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(title: "Medication", value: profile.medicationType.capitalized)
                    DetailRow(title: "Brand", value: profile.brandName)
                    DetailRow(
                        title: "Current Dose",
                        value: "\(String(format: "%.2f", profile.currentDose)) mg")
                    DetailRow(
                        title: "Start Date",
                        value: profile.startDate.formatted(date: .abbreviated, time: .omitted))
                    DetailRow(
                        title: "Preferred Sites",
                        value: profile.preferredInjectionSites.joined(separator: ", "))

                    // Show reconstitution data for compounded medications
                    if profile.isCompounded {
                        if let concentration = profile.concentration {
                            DetailRow(
                                title: "Concentration",
                                value: "\(String(format: "%.2f", concentration)) mg/ml")
                        }
                        if let unitsPerDose = profile.unitsPerDose {
                            DetailRow(
                                title: "Dose in Units",
                                value: "\(String(format: "%.1f", unitsPerDose)) units")
                        }
                    }

                    if let medication = Medication(rawValue: profile.medicationType) {
                        DetailRow(
                            title: "Half-life",
                            value: "\(String(format: "%.1f", medication.halfLifeDays)) days")
                        DetailRow(
                            title: "Frequency",
                            value: medication.frequency == .daily ? "Daily" : "Weekly")
                    }
                }
            }
        }
    }
}
