import AuthenticationServices
import LocalAuthentication
import SwiftUI

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

            Text(
              self.authManager.authenticationState == .authenticated
                ? "Profile information"
                : "Sign in to save your data"
            )
            .font(DesignTokens.Typography.body)
            .foregroundColor(.secondary)
          }

          Spacer()

          if self.authManager.authenticationState == .authenticated, !self.editMode {
            Button("Edit") {
              self.startEditing()
            }
            .font(DesignTokens.Typography.body)
            .buttonStyle(.bordered)
            .accessibilityIdentifier("edit-profile-button")
          }
        }

        // Authentication Section
        if self.authManager.authenticationState != .authenticated {
          VStack(spacing: 12) {
            SignInWithAppleButton(
              onRequest: { request in
                request.requestedScopes = [.fullName, .email]
              },
              onCompletion: { result in
                Task {
                  await self.handleSignInResult(result)
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
          self.profileInformationSection
        }

        // Biometric Authentication Section
        if self.authManager.authenticationState == .authenticated, self.biometricManager.isAvailable
        {
          Divider()
          self.biometricAuthSection
        }

        // Sign Out Section
        if self.authManager.authenticationState == .authenticated, !self.editMode {
          Divider()
          self.signOutSection
        }

        // Edit Mode Actions
        if self.editMode {
          Divider()
          self.editModeActions
        }
      }
    }
    .alert("Error", isPresented: self.$showingError) {
      Button("OK") {}
    } message: {
      Text(self.errorMessage)
    }
  }

  @ViewBuilder
  private var profileInformationSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let user = authManager.currentUser {
        // Email (read-only)
        ProfileField(label: "Email", value: user.displayEmail) {
          EmptyView()
        }

        // Name
        if self.editMode {
          ProfileField(label: "Name") {
            TextField("Enter your name", text: self.$editingName)
              .textFieldStyle(.roundedBorder)
              .accessibilityIdentifier("name-input")
          }
        } else {
          ProfileField(label: "Name", value: user.name ?? "Not set") {
            EmptyView()
          }
        }

        // Weight
        if self.editMode {
          ProfileField(label: "Weight") {
            HStack {
              TextField("Weight", text: self.$editingWeight)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
                .accessibilityIdentifier("weight-input")

              Picker("Unit", selection: self.$editingWeightUnit) {
                Text("kg").tag("kg")
                Text("lbs").tag("lbs")
              }
              .pickerStyle(.segmented)
              .frame(width: 100)
              .accessibilityIdentifier("weight-unit-picker")
            }

            if !ProfileValidation.isValidWeight(self.editingWeight) {
              Text("Please enter a valid weight (10-500)")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.danger)
                .accessibilityIdentifier("weight-error-message")
            }
          }
        } else {
          ProfileField(label: "Weight", value: user.weightDisplay) {
            EmptyView()
          }
        }

        // Date of Birth
        if self.editMode {
          ProfileField(label: "Date of Birth") {
            DatePicker("", selection: self.$editingDateOfBirth, displayedComponents: .date)
              .datePickerStyle(.compact)
              .accessibilityIdentifier("date-of-birth-picker")
          }
        } else {
          let dobDisplay =
            user.dateOfBirth?.formatted(date: .abbreviated, time: .omitted) ?? "Not set"
          ProfileField(label: "Date of Birth", value: dobDisplay) {
            EmptyView()
          }
        }

        // Timezone
        if self.editMode {
          ProfileField(label: "Timezone") {
            Picker("Timezone", selection: self.$editingTimezone) {
              ForEach(self.commonTimezones, id: \.self) { timezone in
                Text(timezone).tag(timezone)
              }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("timezone-picker")
          }
        } else {
          ProfileField(label: "Timezone", value: user.timezone) {
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
        Image(systemName: self.biometricIconName)
          .foregroundColor(DesignTokens.Colors.info)

        VStack(alignment: .leading, spacing: 2) {
          Text(self.biometricManager.biometricTypeDisplayName)
            .font(DesignTokens.Typography.body)

          Text("Secure app access")
            .font(DesignTokens.Typography.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        Toggle("", isOn: self.$biometricManager.isBiometricEnabled)
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
            await self.signOut()
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
        self.cancelEditing()
      }
      .accessibilityIdentifier("cancel-edit-button")

      PrimaryButton(title: "Save") {
        Task {
          await self.saveProfile()
        }
      }
      .disabled(!self.isValidProfile)
      .accessibilityIdentifier("save-profile-button")
    }
  }

  // MARK: - Helper Methods

  private func startEditing() {
    guard let user = authManager.currentUser else { return }

    self.editingName = user.name ?? ""
    self.editingWeight = String(user.weight)
    self.editingWeightUnit = user.weightUnit
    self.editingTimezone = user.timezone
    self.editingDateOfBirth = user.dateOfBirth ?? Date()

    self.editMode = true
  }

  private func cancelEditing() {
    self.editMode = false
  }

  private var isValidProfile: Bool {
    ProfileValidation.isValidProfile(name: self.editingName, weight: self.editingWeight)
  }

  private func saveProfile() async {
    guard let user = authManager.currentUser,
      let weight = Double(editingWeight)
    else { return }

    // Update user properties
    user.name = self.editingName.trimmingCharacters(in: .whitespacesAndNewlines)
    user.weight = weight
    user.weightUnit = self.editingWeightUnit
    user.timezone = self.editingTimezone
    user.dateOfBirth = self.editingDateOfBirth
    user.updatedAt = Date()

    do {
      try self.modelContext.save()
      self.editMode = false
    } catch {
      self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
      self.showingError = true
    }
  }

  private func handleSignInResult(_ result: Result<ASAuthorization, Error>) async {
    switch result {
    case let .success(authorization):
      do {
        _ = try await self.authManager.handleSignInWithAppleResult(authorization)
      } catch {
        await MainActor.run {
          self.errorMessage = "Sign in failed: \(error.localizedDescription)"
          self.showingError = true
        }
      }

    case let .failure(error):
      await MainActor.run {
        self.errorMessage = "Sign in failed: \(error.localizedDescription)"
        self.showingError = true
      }
    }
  }

  private func signOut() async {
    do {
      try await self.authManager.signOut()
    } catch {
      self.errorMessage = "Sign out failed: \(error.localizedDescription)"
      self.showingError = true
    }
  }

  private var biometricIconName: String {
    switch self.biometricManager.biometricType {
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
      TimeZone.current.identifier,
    ].uniqued()
  }
}

#Preview {
  UserProfileView()
    .modelContainer(DataController.preview.container)
    .environmentObject(AuthenticationManager())
    .environmentObject(BiometricAuthManager())
}
