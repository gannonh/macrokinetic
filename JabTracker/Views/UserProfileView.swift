import SwiftUI
import AuthenticationServices
import LocalAuthentication

struct UserProfileView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var biometricManager: BiometricAuthManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingSignInSheet = false
    @State private var editMode = false
    
    // Profile editing states
    @State private var editingName = ""
    @State private var editingWeight = ""
    @State private var editingWeightUnit = "kg"
    @State private var editingTimezone = TimeZone.current.identifier
    @State private var editingDateOfBirth = Date()
    
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        DesignCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("User Profile")
                            .font(DesignTokens.Typography.headline)
                            .accessibilityIdentifier("user-profile-header")
                        
                        Text(authManager.authenticationState == .authenticated ? "Profile information" : "Sign in to save your data")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if authManager.authenticationState == .authenticated && !editMode {
                        Button("Edit") {
                            startEditing()
                        }
                        .font(DesignTokens.Typography.body)
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("edit-profile-button")
                    }
                }
                
                // Authentication Section
                if authManager.authenticationState != .authenticated {
                    VStack(spacing: 12) {
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                Task {
                                    await handleSignInResult(result)
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 45)
                        .accessibilityIdentifier("sign-in-with-apple-button")
                        
                        Text("Your data will be synced securely across your devices")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    // Profile Information Section
                    profileInformationSection
                }
                
                // Biometric Authentication Section
                if authManager.authenticationState == .authenticated && biometricManager.isAvailable {
                    Divider()
                    biometricAuthSection
                }
                
                // Sign Out Section
                if authManager.authenticationState == .authenticated && !editMode {
                    Divider()
                    signOutSection
                }
                
                // Edit Mode Actions
                if editMode {
                    Divider()
                    editModeActions
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    @ViewBuilder
    private var profileInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let user = authManager.currentUser {
                // Email (read-only)
                ProfileField(label: "Email", value: user.email ?? "Not provided") {
                    EmptyView()
                }
                
                // Name
                if editMode {
                    ProfileField(label: "Name") {
                        TextField("Enter your name", text: $editingName)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("name-input")
                    }
                } else {
                    ProfileField(label: "Name", value: user.name ?? "Not set") {
                        EmptyView()
                    }
                }
                
                // Weight
                if editMode {
                    ProfileField(label: "Weight") {
                        HStack {
                            TextField("Weight", text: $editingWeight)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .accessibilityIdentifier("weight-input")
                            
                            Picker("Unit", selection: $editingWeightUnit) {
                                Text("kg").tag("kg")
                                Text("lbs").tag("lbs")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 100)
                            .accessibilityIdentifier("weight-unit-picker")
                        }
                        
                        if !isValidWeight(editingWeight) {
                            Text("Please enter a valid weight (10-500)")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.danger)
                                .accessibilityIdentifier("weight-error-message")
                        }
                    }
                } else {
                    let weightDisplay = user.weight.map { String(format: "%.1f %@", $0, user.weightUnit ?? "kg") } ?? "Not set"
                    ProfileField(label: "Weight", value: weightDisplay) {
                        EmptyView()
                    }
                }
                
                // Date of Birth
                if editMode {
                    ProfileField(label: "Date of Birth") {
                        DatePicker("", selection: $editingDateOfBirth, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .accessibilityIdentifier("date-of-birth-picker")
                    }
                } else {
                    let dobDisplay = user.dateOfBirth?.formatted(date: .abbreviated, time: .omitted) ?? "Not set"
                    ProfileField(label: "Date of Birth", value: dobDisplay) {
                        EmptyView()
                    }
                }
                
                // Timezone
                if editMode {
                    ProfileField(label: "Timezone") {
                        Picker("Timezone", selection: $editingTimezone) {
                            ForEach(commonTimezones, id: \.self) { timezone in
                                Text(timezone).tag(timezone)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityIdentifier("timezone-picker")
                    }
                } else {
                    ProfileField(label: "Timezone", value: user.timezone ?? TimeZone.current.identifier) {
                        EmptyView()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var biometricAuthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: biometricIconName)
                    .foregroundColor(DesignTokens.Colors.info)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(biometricManager.biometricTypeDisplayName)
                        .font(DesignTokens.Typography.body)
                    
                    Text("Secure app access")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $biometricManager.isBiometricEnabled)
                    .accessibilityIdentifier("biometric-auth-toggle")
            }
        }
    }
    
    @ViewBuilder
    private var signOutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(DesignTokens.Colors.danger)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign Out")
                        .font(DesignTokens.Typography.body)
                    
                    Text("Data will remain on this device")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Sign Out") {
                    Task {
                        await signOut()
                    }
                }
                .font(DesignTokens.Typography.body)
                .buttonStyle(.bordered)
                .tint(DesignTokens.Colors.danger)
                .accessibilityIdentifier("sign-out-button")
            }
        }
    }
    
    @ViewBuilder
    private var editModeActions: some View {
        HStack(spacing: 12) {
            SecondaryButton(title: "Cancel") {
                cancelEditing()
            }
            .accessibilityIdentifier("cancel-edit-button")
            
            PrimaryButton(title: "Save") {
                Task {
                    await saveProfile()
                }
            }
            .disabled(!isValidProfile)
            .accessibilityIdentifier("save-profile-button")
        }
    }
    
    // MARK: - Helper Methods
    
    private func startEditing() {
        guard let user = authManager.currentUser else { return }
        
        editingName = user.name ?? ""
        editingWeight = user.weight.map { String($0) } ?? ""
        editingWeightUnit = user.weightUnit ?? "kg"
        editingTimezone = user.timezone ?? TimeZone.current.identifier
        editingDateOfBirth = user.dateOfBirth ?? Date()
        
        editMode = true
    }
    
    private func cancelEditing() {
        editMode = false
    }
    
    private var isValidProfile: Bool {
        !editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidWeight(editingWeight)
    }
    
    private func isValidWeight(_ weight: String) -> Bool {
        guard let weightValue = Double(weight) else { return false }
        return weightValue >= 10 && weightValue <= 500
    }
    
    private func saveProfile() async {
        guard let user = authManager.currentUser,
              let weight = Double(editingWeight) else { return }
        
        // Update user properties
        user.name = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        user.weight = weight
        user.weightUnit = editingWeightUnit
        user.timezone = editingTimezone
        user.dateOfBirth = editingDateOfBirth
        user.updatedAt = Date()
        
        do {
            try modelContext.save()
            editMode = false
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            do {
                _ = try await authManager.handleSignInWithAppleResult(authorization)
            } catch {
                await MainActor.run {
                    errorMessage = "Sign in failed: \(error.localizedDescription)"
                    showingError = true
                }
            }
            
        case .failure(let error):
            await MainActor.run {
                errorMessage = "Sign in failed: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private func signOut() async {
        do {
            try await authManager.signOut()
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private var biometricIconName: String {
        switch biometricManager.biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "lock.shield"
        }
    }
    
    private var commonTimezones: [String] {
        [
            "America/New_York",
            "America/Chicago", 
            "America/Denver",
            "America/Los_Angeles",
            "Europe/London",
            "Europe/Paris",
            "Asia/Tokyo",
            TimeZone.current.identifier
        ].uniqued()
    }
}

// MARK: - ProfileField Component
struct ProfileField<Content: View>: View {
    let label: String
    let value: String?
    let content: Content
    
    init(label: String, value: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.value = value
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            if let value = value {
                Text(value)
                    .font(DesignTokens.Typography.body)
            } else {
                content
            }
        }
    }
}

// MARK: - Array Extension
extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

#Preview {
    UserProfileView()
        .modelContainer(DataController.preview.container)
        .environmentObject(AuthenticationManager())
        .environmentObject(BiometricAuthManager())
}