//
//  AccountView.swift
//  JabTracker
//
//  Account management with Profile data and Account settings.
//

import SwiftData
import SwiftUI

// MARK: - Experience Level

enum ExperienceLevel: String, CaseIterable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Account View

struct AccountView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var biometricManager: BiometricAuthManager

    @Query private var users: [User]

    // Edit state for each field
    @State private var editingField: String?
    @State private var editName: String = ""
    @State private var editBirthday: Date = Date()
    @State private var editSex: String = ""
    @State private var editHeightCm: Double = 170.0
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 7
    @State private var editWeight: Double = 70.0  // Used for initial load
    @State private var editCardioExperience: String = "intermediate"
    @State private var editLiftingExperience: String = "intermediate"

    @State private var showingLogOutConfirmation = false
    @State private var showingRestartOnboarding = false
    @State private var showingDisableHealthSync = false
    @State private var errorMessage: String?
    @State private var showingError = false

    // HealthKit-sourced values for display
    @State private var displayedWeightKg: Double?
    @State private var displayedHeightCm: Double?
    @State private var displayedSex: String?
    @State private var displayedBirthday: Date?

    // Track if values came from HealthKit (read-only)
    @State private var sexFromHealthKit = false
    @State private var birthdayFromHealthKit = false
    @State private var showingHealthKitReadOnlyAlert = false
    @State private var healthKitReadOnlyField: String?

    // Refresh trigger to reload HealthKit data when view appears
    @State private var refreshTrigger = UUID()

    private var metricsService: MetricsService? {
        AppServices.shared.metricsService
    }

    var body: some View {
        List {
            // MARK: - Profile Header
            Section("Profile") {
                profileHeaderCard
            }

            // MARK: - Profile Details
            Section("Details") {
                profileRow(label: "Name", value: users.first?.name ?? "Not set", field: "name")
                if birthdayFromHealthKit {
                    healthKitReadOnlyRow(
                        label: "Birthday", value: formatBirthday(users.first?.dateOfBirth), field: "birthday")
                } else {
                    profileRow(label: "Birthday", value: formatBirthday(users.first?.dateOfBirth), field: "birthday")
                }
                if sexFromHealthKit {
                    healthKitReadOnlyRow(label: "Sex", value: formatSex(users.first?.gender), field: "sex")
                } else {
                    profileRow(label: "Sex", value: formatSex(users.first?.gender), field: "sex")
                }
                profileRow(label: "Height", value: formatHeight(users.first?.heightCm), field: "height")
                profileRow(label: "Weight", value: formatWeight(users.first), field: "weight")
                profileRow(
                    label: "Cardio Experience",
                    value: ExperienceLevel(rawValue: users.first?.cardioExperience ?? "intermediate")?.displayName
                        ?? "Intermediate",
                    field: "cardio"
                )
                profileRow(
                    label: "Lifting Experience",
                    value: ExperienceLevel(rawValue: users.first?.liftingExperience ?? "intermediate")?.displayName
                        ?? "Intermediate",
                    field: "lifting"
                )
            }

            // MARK: - Security Section
            if biometricManager.isAvailable {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: biometricManager.biometricType == .faceID ? "faceid" : "touchid")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .frame(width: 28)
                        Text(biometricManager.biometricTypeDisplayName)
                            .font(.body)
                        Spacer()
                        Toggle("", isOn: $biometricManager.isBiometricEnabled)
                            .labelsHidden()
                    }
                    .accessibilityIdentifier("biometric-toggle-row")
                } header: {
                    Text("Security")
                } footer: {
                    Text(
                        "Use \(biometricManager.biometricTypeDisplayName) to protect your data "
                            + "and require authentication when opening the app."
                    )
                }
            }

            // MARK: - Health Section
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                        .frame(width: 28)
                    Text("Health")
                        .font(.body)
                    Spacer()
                    Toggle("", isOn: healthToggleBinding)
                        .labelsHidden()
                }
                .accessibilityIdentifier("health-toggle-row")
            } header: {
                Text("Integrations")
            } footer: {
                Text("Sync weight, height, and biometrics from the Health app to keep your profile up to date.")
            }

            // MARK: - Account Actions
            Section {
                Button(role: .destructive) {
                    showingLogOutConfirmation = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.title3)
                            .frame(width: 28)
                        Text("Log Out")
                    }
                }
                .accessibilityIdentifier("log-out-button")

                Button {
                    showingRestartOnboarding = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .frame(width: 28)
                        Text("Restart Onboarding")
                            .foregroundColor(.primary)
                    }
                }
                .accessibilityIdentifier("restart-onboarding-button")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: refreshTrigger) { await loadUserData() }
        .onAppear { refreshTrigger = UUID() }
        .sheet(item: $editingField) { field in
            editSheet(for: field)
        }
        .confirmationDialog("Log Out", isPresented: $showingLogOutConfirmation) {
            Button("Log Out", role: .destructive) {
                Task { await signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your data will remain on this device.")
        }
        .confirmationDialog("Restart Onboarding", isPresented: $showingRestartOnboarding) {
            Button("Restart", role: .destructive) {
                restartOnboarding()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset your onboarding progress.")
        }
        .confirmationDialog("Disable Health Sync", isPresented: $showingDisableHealthSync) {
            Button("Disable", role: .destructive) {
                Task { await disableHealthSync() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This will stop syncing your health data with Apple Health. "
                    + "To completely revoke permissions, open Health → Sharing → Apps → MacroKinetic."
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .alert("Synced from Health", isPresented: $showingHealthKitReadOnlyAlert) {
            Button("OK") {}
        } message: {
            Text(
                "\(healthKitReadOnlyField ?? "This field") is synced from the Health app. To change it, go to Settings → Health → Health Details."
            )
        }
        .accessibilityIdentifier("account-view")
    }

    // MARK: - Profile Header Card

    private var profileHeaderCard: some View {
        HStack(spacing: 16) {
            // Avatar with initials
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 64, height: 64)

                Image(systemName: "person.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(users.first?.name ?? "Guest")
                    .font(.headline)
                Text(users.first?.email ?? "Not signed in")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .accessibilityIdentifier("profile-header")
    }

    // MARK: - Health Toggle Binding

    private var healthToggleBinding: Binding<Bool> {
        Binding(
            get: { users.first?.healthSyncEnabled ?? false },
            set: { newValue in
                if newValue {
                    // Enabling - request permission and enable
                    Task {
                        await enableHealthSync()
                    }
                } else {
                    // Disabling - show confirmation dialog
                    showingDisableHealthSync = true
                }
            }
        )
    }

    @MainActor
    private func enableHealthSync() async {
        guard let user = users.first, let service = metricsService else { return }

        do {
            let success = try await service.setHealthSyncEnabled(true, for: user)
            if !success {
                errorMessage = "Could not enable Health sync. Please allow access in Settings."
                showingError = true
            }
        } catch {
            errorMessage = "Could not enable Health sync: \(error.localizedDescription)"
            showingError = true
        }
    }

    @MainActor
    private func disableHealthSync() async {
        guard let user = users.first, let service = metricsService else { return }

        do {
            _ = try await service.setHealthSyncEnabled(false, for: user)
        } catch {
            errorMessage = "Could not disable Health sync: \(error.localizedDescription)"
            showingError = true
        }
    }

    @MainActor
    private func saveWeightEntry(weightKg: Double, for user: User) async {
        print("🔵 AccountView.saveWeightEntry:")
        print("   weightKg: \(weightKg)")
        print("   user.healthSyncEnabled: \(user.healthSyncEnabled)")
        print("   metricsService available: \(metricsService != nil)")

        guard let service = metricsService else {
            print("   ⚠️ No metricsService - using fallback")
            // Fallback: convert kg back to user's preferred unit for storage
            if user.weightUnit == "lbs" {
                user.weight = weightKg * WeightEntry.kgToLbsConversion
            } else {
                user.weight = weightKg
            }
            user.updatedAt = Date()
            try? modelContext.save()
            return
        }

        do {
            _ = try await service.logWeight(weightKg: weightKg, for: user)
            print("   ✅ Weight saved successfully via MetricsService")
        } catch {
            print("   ❌ Error saving weight: \(error)")
            errorMessage = "Could not save weight: \(error.localizedDescription)"
            showingError = true
        }
    }

    // MARK: - Profile Row

    private func profileRow(label: String, value: String, field: String) -> some View {
        Button {
            editingField = field
        } label: {
            HStack {
                Text(label)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                Text(value)
                    .font(.body)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("\(field)-row")
    }

    private func healthKitReadOnlyRow(label: String, value: String, field: String) -> some View {
        Button {
            healthKitReadOnlyField = label
            showingHealthKitReadOnlyAlert = true
        } label: {
            HStack {
                Text(label)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text(value)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("\(field)-row")
    }

    // MARK: - Edit Sheets

    @ViewBuilder
    private func editSheet(for field: String) -> some View {
        NavigationStack {
            Form {
                switch field {
                case "name":
                    TextField("Name", text: $editName)
                        .accessibilityIdentifier("edit-name-field")
                case "birthday":
                    DatePicker("Birthday", selection: $editBirthday, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .accessibilityIdentifier("edit-birthday-picker")
                case "sex":
                    Picker("Sex", selection: $editSex) {
                        Text("Not set").tag("")
                        Text("Male").tag("male")
                        Text("Female").tag("female")
                    }
                    .pickerStyle(.inline)
                    .accessibilityIdentifier("edit-sex-picker")
                case "height":
                    heightEditor
                case "weight":
                    weightEditor
                case "cardio":
                    experiencePicker(selection: $editCardioExperience, label: "Cardio Experience")
                case "lifting":
                    experiencePicker(selection: $editLiftingExperience, label: "Lifting Experience")
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Edit \(fieldDisplayName(field))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { editingField = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveField(field)
                            editingField = nil
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var heightEditor: some View {
        HStack(spacing: 0) {
            Picker("Feet", selection: $heightFeet) {
                ForEach(3...7, id: \.self) { feet in
                    Text("\(feet) ft").tag(feet)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 120)

            Picker("Inches", selection: $heightInches) {
                ForEach(0...11, id: \.self) { inches in
                    Text("\(inches) in").tag(inches)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 120)
        }
        .accessibilityIdentifier("height-picker")
    }

    @State private var weightWhole: Int = 70
    @State private var weightDecimal: Int = 0

    private var weightEditor: some View {
        let unit = users.first?.weightUnit ?? "lbs"

        return HStack(spacing: 0) {
            Picker("Whole", selection: $weightWhole) {
                ForEach(30...400, id: \.self) { Text("\($0)").tag($0) }
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
        .onAppear {
            // Initialize picker from editWeight
            weightWhole = Int(editWeight)
            weightDecimal = Int(((editWeight - Double(Int(editWeight))) * 10).rounded())
        }
        .accessibilityIdentifier("edit-weight-picker")
    }

    private func experiencePicker(selection: Binding<String>, label: String) -> some View {
        Picker(label, selection: selection) {
            ForEach(ExperienceLevel.allCases, id: \.rawValue) { level in
                Text(level.displayName).tag(level.rawValue)
            }
        }
        .pickerStyle(.inline)
        .accessibilityIdentifier("edit-\(label.lowercased().replacingOccurrences(of: " ", with: "-"))-picker")
    }

}

// MARK: - Data Management

extension AccountView {
    func fieldDisplayName(_ field: String) -> String {
        switch field {
        case "name": return "Name"
        case "birthday": return "Birthday"
        case "sex": return "Sex"
        case "height": return "Height"
        case "weight": return "Weight"
        case "cardio": return "Cardio Experience"
        case "lifting": return "Lifting Experience"
        default: return field.capitalized
        }
    }

    func loadUserData() async {
        guard let user = users.first else { return }
        editName = user.name ?? ""
        editCardioExperience = user.cardioExperience
        editLiftingExperience = user.liftingExperience

        // Load biometric data from HealthKit if sync is enabled
        if user.healthSyncEnabled, let service = metricsService {
            // Get current weight (from HealthKit if enabled, otherwise local)
            let weightKg = await service.getCurrentWeight(for: user)
            displayedWeightKg = weightKg
            editWeight = user.weightUnit == "lbs" ? weightKg * WeightEntry.kgToLbsConversion : weightKg

            // Get current height (from HealthKit if enabled, otherwise local)
            if let heightCm = await service.getCurrentHeight(for: user) {
                displayedHeightCm = heightCm
                editHeightCm = heightCm
            } else {
                editHeightCm = user.heightCm ?? 170.0
            }

            // Get biological sex from HealthKit (only if not already set locally)
            if user.gender.isEmpty, let sex = await service.fetchBiologicalSex() {
                displayedSex = sex
                editSex = sex
                sexFromHealthKit = true
            } else {
                editSex = user.gender
                sexFromHealthKit = false
            }

            // Get date of birth from HealthKit (only if not already set locally)
            if user.dateOfBirth == nil, let dob = await service.fetchDateOfBirth() {
                displayedBirthday = dob
                editBirthday = dob
                birthdayFromHealthKit = true
            } else {
                editBirthday =
                    user.dateOfBirth ?? Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
                birthdayFromHealthKit = false
            }
        } else {
            // Clear HealthKit displayed values - use local data only
            displayedWeightKg = nil
            displayedHeightCm = nil
            displayedSex = nil
            displayedBirthday = nil

            editHeightCm = user.heightCm ?? 170.0
            editWeight = user.weight
            editSex = user.gender
            editBirthday = user.dateOfBirth ?? Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
            sexFromHealthKit = false
            birthdayFromHealthKit = false
        }

        // Convert cm to feet/inches for picker
        let totalInches = editHeightCm / 2.54
        heightFeet = Int(totalInches / 12)
        heightInches = Int(totalInches.truncatingRemainder(dividingBy: 12))
    }

    func saveField(_ field: String) async {
        guard let user = users.first else { return }

        switch field {
        case "name":
            user.name = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        case "birthday":
            user.dateOfBirth = editBirthday
        case "sex":
            user.gender = editSex
        case "height":
            // Convert feet/inches to cm and save with HealthKit sync
            let totalInches = Double(heightFeet * 12 + heightInches)
            let heightCm = totalInches * 2.54
            if let service = metricsService {
                do {
                    try await service.saveHeight(heightCm, for: user)
                    return  // saveHeight already updates user and saves context
                } catch {
                    errorMessage = "Could not save height: \(error.localizedDescription)"
                    showingError = true
                    return
                }
            } else {
                user.heightCm = heightCm
            }
        case "weight":
            // Compute weight from picker state
            let pickerWeight = Double(weightWhole) + Double(weightDecimal) / 10.0

            // Convert to kg if user's unit is lbs
            let weightKg: Double
            if user.weightUnit == "lbs" {
                weightKg = pickerWeight / WeightEntry.kgToLbsConversion
            } else {
                weightKg = pickerWeight
            }

            // Save weight (via HealthKit if enabled, otherwise locally)
            await saveWeightEntry(weightKg: weightKg, for: user)
            return  // saveWeightEntry already updates user and saves context
        case "cardio":
            user.cardioExperience = editCardioExperience
        case "lifting":
            user.liftingExperience = editLiftingExperience
        default:
            break
        }

        user.updatedAt = Date()
        try? modelContext.save()
    }

    func signOut() async {
        do {
            try await authManager.signOut()
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
            showingError = true
        }
    }

    func restartOnboarding() {
        guard let user = users.first else { return }
        user.hasCompletedOnboarding = false
        user.onboardingCompletedAt = nil
        try? modelContext.save()
    }
}

// MARK: - Formatters

extension AccountView {
    func formatBirthday(_ date: Date?) -> String {
        // Use HealthKit value if available, otherwise fall back to local
        let birthday = displayedBirthday ?? date
        guard let birthday else { return "Not set" }
        return birthday.formatted(date: .abbreviated, time: .omitted)
    }

    func formatSex(_ gender: String?) -> String {
        // Use HealthKit value if available, otherwise fall back to local
        let sex = displayedSex ?? gender
        switch sex {
        case "male": return "Male"
        case "female": return "Female"
        default: return "Not set"
        }
    }

    func formatHeight(_ cm: Double?) -> String {
        // Use HealthKit value if available, otherwise fall back to local
        let heightCm = displayedHeightCm ?? cm
        guard let heightCm else { return "Not set" }
        let totalInches = heightCm / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return "\(feet)' \(inches)\""
    }

    func formatWeight(_ user: User?) -> String {
        guard let user else { return "Not set" }
        // Use HealthKit value if available, otherwise fall back to local
        if let weightKg = displayedWeightKg {
            let displayValue = user.weightUnit == "lbs" ? weightKg * WeightEntry.kgToLbsConversion : weightKg
            return formatWeightValue(displayValue, unit: user.weightUnit)
        }
        return formatWeightValue(user.weight, unit: user.weightUnit)
    }

    func formatWeightValue(_ value: Double, unit: String) -> String {
        if unit == "kg" {
            return String(format: "%.1f kg", value)
        } else {
            // Convert kg to lbs for display if stored in kg
            return String(format: "%.1f lbs", value)
        }
    }
}

// MARK: - String Extension for Sheet Item

extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AccountView()
            .modelContainer(DataController.preview.container)
            .environmentObject(AuthenticationManager())
            .environmentObject(BiometricAuthManager())
    }
}
