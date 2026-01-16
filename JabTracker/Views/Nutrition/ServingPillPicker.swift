//
//  ServingPillPicker.swift
//  JabTracker
//
//  Horizontal scrollable pill picker for selecting serving units.
//  Inspired by MacroFactor's serving size selector UX.
//

import SwiftUI

/// A serving option that can be selected in the pill picker
struct ServingPillOption: Identifiable, Equatable {
    let id: String
    let label: String  // Display text (e.g., "large egg", "g", "oz")
    let grams: Double  // Weight in grams for this serving
    let isUnitOnly: Bool  // True for universal units like g/oz (no quantity prefix)

    // Pre-compiled regex for parsing serving labels (e.g., "1.0 large (50g)" → "large")
    // Compiled once as static property for performance
    // swiftlint:disable:next force_try
    private static let labelRegex = try! NSRegularExpression(
        pattern: #"^[\d.]+\s+(.+?)\s*\([^)]+\)$"#
    )

    init(label: String, grams: Double, isUnitOnly: Bool = false) {
        self.id = "\(label)-\(grams)"
        self.label = label
        self.grams = grams
        self.isUnitOnly = isUnitOnly
    }

    /// Create from a ServingOption
    init(from option: ServingOption) {
        let formattedLabel = ServingPillOption.formatLabel(from: option.label)

        // Sanitize suspicious labels at runtime for existing database data
        let sanitizedLabel =
            ServingPillOption.isServingLabelSuspicious(formattedLabel, grams: option.grams)
            ? "serving"
            : formattedLabel

        self.id = "\(sanitizedLabel)-\(option.grams)"
        self.label = sanitizedLabel
        self.grams = option.grams
        self.isUnitOnly = false
    }

    // MARK: - Serving Label Validation

    /// Check if a serving label's gram value is unrealistic for its unit type.
    /// Used to sanitize suspicious labels from existing database data.
    /// - Parameters:
    ///   - label: The serving label (e.g., "cup", "tbsp")
    ///   - grams: The gram weight for this serving
    /// - Returns: True if the gram value is suspicious for the detected unit type
    private static func isServingLabelSuspicious(_ label: String, grams: Double) -> Bool {
        let lowerLabel = label.lowercased()

        // Check for common unit keywords and validate gram ranges
        if lowerLabel.contains("cup") {
            return grams < 80 || grams > 300
        }
        if lowerLabel.contains("tbsp") || lowerLabel.contains("tablespoon") {
            return grams < 5 || grams > 25
        }
        if lowerLabel.contains("tsp") || lowerLabel.contains("teaspoon") {
            return grams < 2 || grams > 10
        }
        // "oz" alone might be ambiguous - be lenient
        return false
    }

    /// Format the label to be more human-readable
    /// Converts "1.0 large (50g)" → "large"
    /// Converts "1.0 whole without shell (50g)" → "whole without shell"
    /// Keeps "100g" → "100g"
    private static func formatLabel(from raw: String) -> String {
        // If it's just grams, keep as-is
        if raw.hasSuffix("g") && Double(raw.dropLast()) != nil {
            return raw
        }

        // Try to extract the descriptive part: "1.0 whole without shell (50g)" → "whole without shell"
        // Uses pre-compiled regex for better performance
        if let match = labelRegex.firstMatch(
            in: raw,
            range: NSRange(raw.startIndex..., in: raw)
        ),
            let descRange = Range(match.range(at: 1), in: raw)
        {
            return String(raw[descRange]).trimmingCharacters(in: .whitespaces)
        }

        return raw
    }

    /// Universal gram unit
    static let grams = ServingPillOption(label: "g", grams: 1, isUnitOnly: true)

    /// Universal ounce unit
    static let ounces = ServingPillOption(label: "oz", grams: 28.3495, isUnitOnly: true)
}

/// Horizontal scrollable pill picker for serving unit selection
struct ServingPillPicker: View {
    // MARK: - Properties

    let servingOptions: [ServingOption]  // From food.servingOptions
    @Binding var selectedOption: ServingPillOption?

    // MARK: - Constants

    static let accessibilityIdentifierValue = "serving-pill-picker"

    // MARK: - Computed Properties

    /// All options to display, including universal g/oz
    private var allOptions: [ServingPillOption] {
        var options: [ServingPillOption] = []

        // Add serving options from database (filter out plain "100g" as we have "g" universal)
        for option in servingOptions {
            // Skip if it's just "100g" - we have universal gram option
            if option.label == "100g" { continue }

            let pillOption = ServingPillOption(from: option)
            // Avoid duplicates
            if !options.contains(where: { $0.label == pillOption.label }) {
                options.append(pillOption)
            }
        }

        // Always add g and oz as universal fallbacks
        options.append(.grams)
        options.append(.ounces)

        return options
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(allOptions) { option in
                    pillButton(for: option)
                }
            }
            .padding(.horizontal, 4)
        }
        .accessibilityIdentifier(Self.accessibilityIdentifierValue)
        .onAppear {
            selectDefaultOption()
        }
    }

    // MARK: - Pill Button

    private func pillButton(for option: ServingPillOption) -> some View {
        let isSelected = selectedOption?.id == option.id

        return Button {
            selectedOption = option
        } label: {
            Text(pillLabel(for: option))
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isSelected
                        ? Color.primary.opacity(0.15)
                        : Color(.tertiarySystemFill)
                )
                .foregroundColor(.primary)
                .clipShape(Capsule())
        }
        .accessibilityIdentifier("serving-pill-\(option.label)")
    }

    /// Format the pill label
    /// - For item-based: just the label (e.g., "large egg")
    /// - For unit-only: just the unit (e.g., "g", "oz")
    private func pillLabel(for option: ServingPillOption) -> String {
        option.label
    }

    // MARK: - Helpers

    /// Select the appropriate default option on appear
    private func selectDefaultOption() {
        guard selectedOption == nil else { return }

        // Prefer first item-based option if available
        if let itemOption = allOptions.first(where: { !$0.isUnitOnly }) {
            selectedOption = itemOption
        } else {
            // Fall back to grams
            selectedOption = .grams
        }
    }
}

// MARK: - Preview

#Preview("ServingPillPicker - With Options") {
    struct PreviewWrapper: View {
        @State private var selected: ServingPillOption?

        var body: some View {
            VStack(spacing: 20) {
                Text("Selected: \(selected?.label ?? "none")")
                    .font(.headline)

                if let selected {
                    Text("Grams: \(Int(selected.grams))")
                        .foregroundColor(.secondary)
                }

                ServingPillPicker(
                    servingOptions: [
                        ServingOption(label: "1.0 large (50g)", grams: 50),
                        ServingOption(label: "1.0 medium (44g)", grams: 44),
                        ServingOption(label: "100g", grams: 100),
                    ],
                    selectedOption: $selected
                )
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("ServingPillPicker - No Options") {
    struct PreviewWrapper: View {
        @State private var selected: ServingPillOption?

        var body: some View {
            VStack(spacing: 20) {
                Text("Selected: \(selected?.label ?? "none")")
                    .font(.headline)

                ServingPillPicker(
                    servingOptions: [],
                    selectedOption: $selected
                )
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
