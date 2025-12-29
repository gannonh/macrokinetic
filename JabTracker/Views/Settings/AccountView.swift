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
    @State private var editWeight: Double = 70.0
    @State private var editCardioExperience: String = "intermediate"
    @State private var editLiftingExperience: String = "intermediate"

    @State private var showingLogOutConfirmation = false
    @State private var showingRestartOnboarding = false
    @State private var showingDisableHealthSync = false
    @State private var errorMessage: String?
    @State private var showingError = false

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
                profileRow(label: "Birthday", value: formatBirthday(users.first?.dateOfBirth), field: "birthday")
                profileRow(label: "Sex", value: formatSex(users.first?.gender), field: "sex")
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
        .onAppear { loadUserData() }
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
                "This will stop syncing your health data, including weight and other metrics, "
                    + "with Apple Health. To completely revoke permissions, go to Settings → Health → "
                    + "Data Access & Devices → MacroKinetic."
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An error occurred")
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

    private var weightEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weight: \(formatWeightValue(editWeight, unit: users.first?.weightUnit ?? "lbs"))")
                .font(.headline)

            Stepper(
                "Weight",
                value: $editWeight,
                in: 30...300,
                step: 0.5
            )
            .accessibilityIdentifier("edit-weight-stepper")
        }
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

    func loadUserData() {
        guard let user = users.first else { return }
        editName = user.name ?? ""
        editBirthday = user.dateOfBirth ?? Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        editSex = user.gender
        editHeightCm = user.heightCm ?? 170.0
        // Convert cm to feet/inches for picker
        let totalInches = editHeightCm / 2.54
        heightFeet = Int(totalInches / 12)
        heightInches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        editWeight = user.weight
        editCardioExperience = user.cardioExperience
        editLiftingExperience = user.liftingExperience
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
            if let service = metricsService {
                do {
                    // Log weight entry (also updates User.weight and syncs to HealthKit if enabled)
                    _ = try await service.logWeight(weightKg: editWeight, for: user)
                    return
                } catch {
                    errorMessage = "Could not save weight: \(error.localizedDescription)"
                    showingError = true
                    return
                }
            } else {
                user.weight = editWeight
            }
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
        guard let date else { return "Not set" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    func formatSex(_ gender: String?) -> String {
        switch gender {
        case "male": return "Male"
        case "female": return "Female"
        default: return "Not set"
        }
    }

    func formatHeight(_ cm: Double?) -> String {
        guard let cm else { return "Not set" }
        let totalInches = cm / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return "\(feet)' \(inches)\""
    }

    func formatWeight(_ user: User?) -> String {
        guard let user else { return "Not set" }
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
