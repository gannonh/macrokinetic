//
//  ProgramWizardStepViews.swift
//  JabTracker
//
//  Step views and reusable components for the ProgramWizard.
//

import SwiftUI

// MARK: - Weekday Utility

/// Shared weekday representation for consistent day handling across wizard steps
enum Weekday: Int, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    /// Weekdays ordered Monday-first (common display preference)
    static var mondayFirst: [Weekday] {
        [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }
}

// MARK: - View Modifiers

/// Card background modifier for consistent card styling
struct CardBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
            )
    }
}

extension View {
    func cardBackground() -> some View {
        modifier(CardBackgroundModifier())
    }
}

// MARK: - Step Views

/// Program style selection step
struct ProgramStyleStepView: View {
    @Binding var selection: ProgramStyle?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.programStyle.title,
                subtitle: ProgramWizardStep.programStyle.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ProgramStyle.allCases, id: \.self) { style in
                        SelectionCard(
                            title: style.displayName,
                            description: style.description,
                            icon: style.icon,
                            isSelected: selection == style
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = style
                            }
                        }
                        .accessibilityIdentifier("program-wizard-programStyle-\(style.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

/// Profile completion step for missing TDEE data
struct ProfileCompletionStepView: View {
    @Bindable var viewModel: ProgramWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.profileCompletion.title,
                subtitle: ProgramWizardStep.profileCompletion.subtitle
            )

            ScrollView {
                VStack(spacing: 20) {
                    // Info card
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)

                        Text("We need these details to calculate your personalized calorie and macro targets.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )

                    // Height field
                    if viewModel.missingHeight {
                        profileField(title: "Height", icon: "ruler") {
                            HStack(spacing: 0) {
                                Picker("Feet", selection: $viewModel.editHeightFeet) {
                                    ForEach(3...7, id: \.self) { feet in
                                        Text("\(feet) ft").tag(feet)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 100, height: 120)

                                Picker("Inches", selection: $viewModel.editHeightInches) {
                                    ForEach(0...11, id: \.self) { inches in
                                        Text("\(inches) in").tag(inches)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 100, height: 120)
                            }
                        }
                        .accessibilityIdentifier("profile-completion-height")
                    }

                    // Sex field
                    if viewModel.missingSex {
                        profileField(title: "Sex", icon: "person.fill") {
                            Picker("Sex", selection: $viewModel.editSex) {
                                Text("Select...").tag("")
                                Text("Male").tag("male")
                                Text("Female").tag("female")
                            }
                            .pickerStyle(.segmented)
                        }
                        .accessibilityIdentifier("profile-completion-sex")
                    }

                    // Birthday field
                    if viewModel.missingBirthday {
                        profileField(title: "Birthday", icon: "calendar") {
                            DatePicker(
                                "Birthday",
                                selection: $viewModel.editBirthday,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        }
                        .accessibilityIdentifier("profile-completion-birthday")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func profileField<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }

            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

/// Diet preference selection step
struct DietPreferenceStepView: View {
    @Binding var selection: DietPreference?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.dietPreference.title,
                subtitle: ProgramWizardStep.dietPreference.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(DietPreference.allCases, id: \.self) { diet in
                        SelectionCard(
                            title: diet.displayName,
                            description: diet.description,
                            icon: diet.icon,
                            detail: macroDetail(for: diet),
                            isSelected: selection == diet
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = diet
                            }
                        }
                        .accessibilityIdentifier("program-wizard-dietPreference-\(diet.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func macroDetail(for diet: DietPreference) -> String {
        let macros = diet.macroPercentages
        return "P: \(Int(macros.protein))% C: \(Int(macros.carbs))% F: \(Int(macros.fat))%"
    }
}

/// Calorie floor selection step
struct CalorieFloorStepView: View {
    @Binding var selection: CalorieFloorType?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.calorieFloor.title,
                subtitle: ProgramWizardStep.calorieFloor.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(CalorieFloorType.allCases, id: \.self) { floorType in
                        SelectionCard(
                            title: floorType.displayName,
                            description: floorType.description,
                            icon: floorType.icon,
                            detail: "\(Int(floorType.minimumCalories)) cal/day minimum",
                            isSelected: selection == floorType,
                            showWarning: floorType.requiresWarning
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = floorType
                            }
                        }
                        .accessibilityIdentifier("program-wizard-calorieFloor-\(floorType.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

/// Training level selection step
struct TrainingLevelStepView: View {
    @Binding var selection: TrainingLevel?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.training.title,
                subtitle: ProgramWizardStep.training.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(TrainingLevel.allCases, id: \.self) { level in
                        SelectionCard(
                            title: level.displayName,
                            description: level.description,
                            icon: level.icon,
                            isSelected: selection == level
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = level
                            }
                        }
                        .accessibilityIdentifier("program-wizard-training-\(level.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

/// Weekly distribution selection step
struct WeeklyDistributionStepView: View {
    @Binding var selection: WeeklyDistributionMode?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.weeklyDistribution.title,
                subtitle: ProgramWizardStep.weeklyDistribution.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(WeeklyDistributionMode.allCases, id: \.self) { mode in
                        SelectionCard(
                            title: mode.displayName,
                            description: mode.description,
                            icon: mode.icon,
                            isSelected: selection == mode
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = mode
                            }
                        }
                        .accessibilityIdentifier("program-wizard-weeklyDistribution-\(mode.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

/// Protein level selection step
struct ProteinLevelStepView: View {
    @Binding var selection: ProteinLevel?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.proteinLevel.title,
                subtitle: ProgramWizardStep.proteinLevel.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ProteinLevel.allCases, id: \.self) { level in
                        SelectionCard(
                            title: level.displayName,
                            description: level.description,
                            icon: level.icon,
                            detail: "\(level.gramsPerKg)g per kg body weight",
                            isSelected: selection == level
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = level
                            }
                        }
                        .accessibilityIdentifier("program-wizard-proteinLevel-\(level.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

/// Confirmation step showing all program selections
struct ProgramConfirmationStepView: View {
    let viewModel: ProgramWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.confirmation.title,
                subtitle: ProgramWizardStep.confirmation.subtitle
            )

            ScrollView {
                VStack(spacing: 16) {
                    if !viewModel.isEditMode {
                        SummaryRow(label: "Program Style", value: viewModel.programStyle?.displayName ?? "—")
                    }
                    SummaryRow(label: "Diet Preference", value: viewModel.dietPreference?.displayName ?? "—")
                    SummaryRow(label: "Calorie Floor", value: viewModel.calorieFloorType?.displayName ?? "—")
                    SummaryRow(label: "Training Level", value: viewModel.trainingLevel?.displayName ?? "—")
                    SummaryRow(
                        label: "Weekly Distribution",
                        value: viewModel.weeklyDistributionMode?.displayName ?? "—"
                    )
                    SummaryRow(label: "Protein Level", value: viewModel.proteinLevel?.displayName ?? "—")

                    // Macro breakdown
                    if let diet = viewModel.dietPreference {
                        macroBreakdownCard(diet: diet)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func macroBreakdownCard(diet: DietPreference) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.blue)
                Text("Macro Breakdown")
                    .font(.headline)
                Spacer()
            }

            let macros = diet.macroPercentages
            HStack(spacing: 16) {
                macroItem(name: "Protein", percent: Int(macros.protein), color: .blue)
                macroItem(name: "Carbs", percent: Int(macros.carbs), color: .green)
                macroItem(name: "Fat", percent: Int(macros.fat), color: .orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }

    private func macroItem(name: String, percent: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(percent)%")
                .font(.headline)
                .foregroundColor(color)
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Reusable Step Header

struct StepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
}

// MARK: - Selection Card

/// Selection card for wizard options
struct SelectionCard: View {
    let title: String
    let description: String
    var icon: String?
    var detail: String?
    let isSelected: Bool
    var showWarning: Bool = false
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                if let icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .secondary)
                        .frame(width: 32)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if showWarning {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let detail {
                        Text(detail)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(description)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

/// Summary row for confirmation step
struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Macro Customization Step View (Collaborative)

/// Step view for Collaborative mode macro customization
/// Mock: mocks/goal-program/Collaborative/02.PNG
struct MacroCustomizationStepView: View {
    @Bindable var viewModel: ProgramWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.macroCustomization.title,
                subtitle: ProgramWizardStep.macroCustomization.subtitle
            )

            ScrollView {
                VStack(spacing: 20) {
                    // Protein slider (g per lb)
                    proteinSlider

                    // Carb/Fat ratio slider
                    carbFatRatioSlider
                }
                .padding(.horizontal, 24)
            }
        }
        .accessibilityIdentifier("macro-customization-step")
    }

    // Protein slider with g/lb display
    private var proteinSlider: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Protein")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f g/lb", viewModel.proteinGramsPerLb))
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }

            Slider(value: $viewModel.proteinGramsPerLb, in: 0.5...1.5, step: 0.1)
                .tint(.blue)

            Text("Higher protein helps preserve muscle during weight loss")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .cardBackground()
    }

    // Carb/Fat ratio slider
    private var carbFatRatioSlider: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Carb : Fat Ratio")
                    .font(.headline)
                Spacer()
                let carbPct = viewModel.carbFatRatio * 100
                let fatPct = (1 - viewModel.carbFatRatio) * 100
                Text(String(format: "%.0f%% : %.0f%%", carbPct, fatPct))
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }

            HStack {
                Text("Fat")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: $viewModel.carbFatRatio, in: 0...1, step: 0.05)
                    .tint(.blue)
                Text("Carbs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Adjust the balance of remaining calories between carbs and fat")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .cardBackground()
    }
}

// MARK: - Target Mode Step View (Manual)

/// Step view for Manual mode target selection
/// Mock: mocks/goal-program/Manual/01.PNG, 02.PNG, 03.PNG
struct TargetModeStepView: View {
    @Binding var useSameTargetsAllWeek: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.targetMode.title,
                subtitle: ProgramWizardStep.targetMode.subtitle
            )

            ScrollView {
                VStack(spacing: 24) {
                    Text("Do you want to follow the same targets all week?")
                        .font(.title3.bold())
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                    VStack(spacing: 12) {
                        // Same targets all week option
                        SelectionCard(
                            title: "Same targets all week",
                            description: "You will set the same macro and Calorie targets for all days in the week.",
                            icon: "arrow.turn.down.right",
                            isSelected: useSameTargetsAllWeek
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                useSameTargetsAllWeek = true
                            }
                        }
                        .accessibilityIdentifier("target-mode-same")

                        // Different targets per day option
                        SelectionCard(
                            title: "Different targets per day",
                            description:
                                "You will set different macro and Calorie targets for different days of the week.",
                            icon: "calendar",
                            isSelected: !useSameTargetsAllWeek
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                useSameTargetsAllWeek = false
                            }
                        }
                        .accessibilityIdentifier("target-mode-different")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .accessibilityIdentifier("target-mode-step")
    }
}

// MARK: - Single Week Macros Step View (Manual - Same All Week)

/// Step view for single macro entry in Manual mode (same all week)
/// Mock: mocks/goal-program/Manual/02.1.PNG
struct SingleWeekMacrosStepView: View {
    @Bindable var viewModel: ProgramWizardViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.singleWeekMacros.title,
                subtitle: ProgramWizardStep.singleWeekMacros.subtitle
            )

            ScrollView {
                VStack(spacing: 16) {
                    // Energy field (kcal)
                    macroInputField(label: "Energy", unit: "kcal", value: $viewModel.singleWeekCalories)
                        .accessibilityIdentifier("single-week-calories")

                    // Protein field (g)
                    macroInputField(label: "Protein", unit: "g", value: $viewModel.singleWeekProtein)
                        .accessibilityIdentifier("single-week-protein")

                    // Fat field (g)
                    macroInputField(label: "Fat", unit: "g", value: $viewModel.singleWeekFat)
                        .accessibilityIdentifier("single-week-fat")

                    // Carbs field (g)
                    macroInputField(label: "Carbs", unit: "g", value: $viewModel.singleWeekCarbs)
                        .accessibilityIdentifier("single-week-carbs")
                }
                .padding(.horizontal, 24)
            }
        }
        .focused($isInputFocused)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputFocused = false
                }
            }
        }
        .accessibilityIdentifier("single-week-macros-step")
    }

    private func macroInputField(label: String, unit: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                TextField("", value: value, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Text(unit)
                    .foregroundColor(.secondary)
            }
        }
        .cardBackground()
    }
}

// MARK: - Per Day Macros Step View (Manual - Different Per Day)

/// Step view for per-day macro entry in Manual mode
/// Mock: mocks/goal-program/Manual/03.1.PNG
struct PerDayMacrosStepView: View {
    @Bindable var viewModel: ProgramWizardViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.perDayMacros.title,
                subtitle: ProgramWizardStep.perDayMacros.subtitle
            )

            ScrollView {
                VStack(spacing: 24) {
                    ForEach(Weekday.mondayFirst, id: \.rawValue) { weekday in
                        dayMacroSection(weekday: weekday)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        }
        .focused($isInputFocused)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputFocused = false
                }
            }
        }
        .accessibilityIdentifier("per-day-macros-step")
    }

    private func dayMacroSection(weekday: Weekday) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day header
            Text(weekday.fullName)
                .font(.headline)

            // Energy field
            macroInputRow(
                label: "Energy",
                unit: "kcal",
                weekday: weekday.rawValue,
                keyPath: \.calories
            )

            // P/F/C in a row
            HStack(spacing: 8) {
                macroInputRow(label: "P", unit: "g", weekday: weekday.rawValue, keyPath: \.proteinGrams)
                macroInputRow(label: "F", unit: "g", weekday: weekday.rawValue, keyPath: \.fatGrams)
                macroInputRow(label: "C", unit: "g", weekday: weekday.rawValue, keyPath: \.carbsGrams)
            }
        }
        .cardBackground()
        .accessibilityIdentifier("per-day-macros-\(weekday.fullName.lowercased())")
    }

    private func macroInputRow(
        label: String,
        unit: String,
        weekday: Int,
        keyPath: WritableKeyPath<DailyMacros, Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                TextField(
                    "",
                    value: Binding(
                        get: { viewModel.perDayMacros[weekday]?[keyPath: keyPath] ?? 0 },
                        set: { newValue in
                            var macros = viewModel.perDayMacros[weekday] ?? .zero
                            macros[keyPath: keyPath] = newValue
                            viewModel.perDayMacros[weekday] = macros
                        }
                    ),
                    format: .number
                )
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 50)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Shifted Day Selection Step View (Coached/Shifted)

/// Step view for selecting high calorie days in Coached/Shifted mode
/// Mock: mocks/goal-program/Coached-Shift/IMG_2102.PNG
struct ShiftedDaySelectionStepView: View {
    @Binding var highCalorieDays: Set<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.shiftedDaySelection.title,
                subtitle: ProgramWizardStep.shiftedDaySelection.subtitle
            )

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Weekday.mondayFirst, id: \.rawValue) { weekday in
                        dayRow(weekday: weekday)
                        if weekday != .sunday {
                            Divider()
                                .padding(.leading, 24)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .accessibilityIdentifier("shifted-day-selection-step")
    }

    private func dayRow(weekday: Weekday) -> some View {
        let weekdayValue = weekday.rawValue
        return Button {
            if highCalorieDays.contains(weekdayValue) {
                highCalorieDays.remove(weekdayValue)
            } else {
                highCalorieDays.insert(weekdayValue)
            }
        } label: {
            HStack {
                Text(weekday.fullName)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: highCalorieDays.contains(weekdayValue) ? "checkmark.square.fill" : "square")
                    .foregroundColor(highCalorieDays.contains(weekdayValue) ? .blue : .secondary)
                    .font(.title2)
            }
            .padding(.vertical, 16)
        }
        .accessibilityLabel(weekday.fullName)
        .accessibilityAddTraits(highCalorieDays.contains(weekdayValue) ? .isSelected : [])
        .accessibilityIdentifier("shifted-day-\(weekday.fullName.lowercased())")
    }
}
