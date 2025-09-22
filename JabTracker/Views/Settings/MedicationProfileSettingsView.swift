// swiftlint:disable file_length
import SwiftData
import SwiftUI

struct MedicationProfileSettingsView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var authManager: AuthenticationManager
  @Query(sort: \MedicationProfile.startDate, order: .reverse) private var allMedicationProfiles:
    [MedicationProfile]
  @ObservedObject var medicationManager: MedicationManager

  private var medicationProfiles: [MedicationProfile] {
    guard let currentUser = authManager.currentUser else { return [] }
    return self.allMedicationProfiles.filter { $0.user?.id == currentUser.id }
  }

  @State private var showingAddProfile = false
  @State private var showingError = false
  @State private var errorMessage = ""

  init(medicationManager: MedicationManager) {
    self.medicationManager = medicationManager
  }

  var body: some View {
    NavigationStack {
      List {
        if self.medicationProfiles.isEmpty {
          Section {
            VStack(spacing: 16) {
              Image(systemName: "pills.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)

              Text("No medication profiles yet")
                .font(DesignTokens.Typography.headline)
                .foregroundColor(.secondary)

              Text(
                "Add your first medication profile to get started with "
                  + "dose tracking and calculations."
              )
              .font(DesignTokens.Typography.body)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
          }
        } else {
          Section("Your Medications") {
            ForEach(self.medicationProfiles, id: \.id) { profile in
              MedicationProfileRow(profile: profile, medicationManager: self.medicationManager)
                .accessibilityIdentifier(
                  "medication-profile-\(profile.medicationType.lowercased())-"
                    + "\(profile.brandName.lowercased())-"
                    + "\(String(format: "%.2f", profile.currentDose))mg"
                )
            }
            .onDelete(perform: self.deleteProfiles)
          }
        }
      }
      .navigationTitle("Medication Profiles")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Add", systemImage: "plus") {
            self.showingAddProfile = true
          }
          .accessibilityIdentifier("Add Medication Profile")
        }
      }
      .sheet(isPresented: self.$showingAddProfile) {
        if let currentUser = authManager.currentUser {
          AddMedicationProfileView(
            medicationManager: self.medicationManager, currentUser: currentUser)
        }
      }
      .alert("Error", isPresented: self.$showingError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(self.errorMessage)
      }
    }
  }

  private func deleteProfiles(at offsets: IndexSet) {
    for index in offsets {
      let profile = self.medicationProfiles[index]
      self.modelContext.delete(profile)
    }

    do {
      try self.modelContext.save()
    } catch {
      self.errorMessage = "Failed to delete medication profile: \(error.localizedDescription)"
      self.showingError = true
    }
  }
}

struct MedicationProfileRow: View {
  let profile: MedicationProfile
  let medicationManager: MedicationManager

  var body: some View {
    NavigationLink(
      destination: MedicationProfileDetailView(
        profile: self.profile, medicationManager: self.medicationManager)
    ) {
      HStack {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("\(self.profile.medicationType.capitalized) (\(self.profile.brandName))")
              .font(DesignTokens.Typography.headline)
              .foregroundColor(.primary)

            if self.profile.isCompounded {
              Text("Compounded")
                .font(DesignTokens.Typography.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(DesignTokens.Colors.info.opacity(0.1))
                .foregroundColor(DesignTokens.Colors.info)
                .cornerRadius(4)
            }
          }

          HStack {
            Text("\(String(format: "%.2f", self.profile.currentDose)) mg")
              .font(DesignTokens.Typography.body)
              .foregroundColor(.secondary)

            Text("•")
              .foregroundColor(.secondary)

            Text(self.frequencyDisplay)
              .font(DesignTokens.Typography.body)
              .foregroundColor(.secondary)
          }
        }

        Spacer()
      }
    }
    .buttonStyle(PlainButtonStyle())
  }

  private var frequencyDisplay: String {
    guard let medication = Medication(rawValue: profile.medicationType) else {
      return "Unknown"
    }

    switch medication.frequency {
    case .daily:
      return "Daily"
    case .weekly:
      return "Weekly"
    }
  }
}

struct AddMedicationProfileView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let medicationManager: MedicationManager
  let currentUser: User

  @State private var selectedMedication: Medication = .semaglutide
  @State private var selectedBrand: String = Medication.semaglutide.brands.first ?? ""
  @State private var selectedDose: Double = Medication.semaglutide.availableDoses.first ?? 0.25
  @State private var startDate: Date = .init()
  @State private var preferredInjectionSites: [String] = ["Thigh"]
  @State private var isInitialized = false
  @State private var isCompounded = false
  @State private var vialStrength: Double = 10.0
  @State private var reconstitutionVolume: Double = 1.0
  @State private var concentration: Double?
  @State private var unitsPerDose: Double?
  @State private var notes = ""

  @State private var showingError = false
  @State private var errorMessage = ""
  @State private var showingReconstitutionCalculator = false

  // Computed properties to ensure valid selections
  private var validBrand: String {
    if self.selectedMedication.brands.contains(self.selectedBrand) {
      return self.selectedBrand
    } else {
      return self.selectedMedication.brands.first ?? ""
    }
  }

  private var validDose: Double {
    if self.selectedMedication.availableDoses.contains(where: { abs($0 - selectedDose) < 0.01 }) {
      return self.selectedDose
    } else {
      return self.selectedMedication.availableDoses.first ?? 0.0
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Medication Type") {
          Picker("Medication", selection: self.$selectedMedication) {
            ForEach(Medication.allCases, id: \.self) { medication in
              Text(medication.displayName)
                .tag(medication)
                .accessibilityIdentifier("medication-\(medication.rawValue)")
            }
          }
          .accessibilityIdentifier("medication-picker")
          .onChange(of: self.selectedMedication) { _, newValue in
            // Reset brand and dose when medication changes to prevent invalid picker selections
            DispatchQueue.main.async {
              self.selectedBrand = newValue.brands.first ?? ""
              self.selectedDose = newValue.availableDoses.first ?? 0.0
            }
          }
        }

        MedicationBrandSection(
          selectedMedication: self.selectedMedication,
          selectedBrand: Binding(
            get: { self.validBrand },
            set: { self.selectedBrand = $0 }),
          isCompounded: self.isCompounded,
          accessibilityPrefix: "add")

        MedicationDosingSection(
          selectedMedication: self.selectedMedication,
          selectedDose: Binding(
            get: { self.validDose },
            set: { self.selectedDose = $0 }),
          isCompounded: self.$isCompounded,
          vialStrength: self.$vialStrength,
          accessibilityPrefix: "add",
          onCalculateReconstitution: {
            self.showingReconstitutionCalculator = true
          })

        Section("Start Date") {
          DatePicker("Start Date", selection: self.$startDate, displayedComponents: .date)
            .accessibilityIdentifier("add-start-date-picker")
        }

        Section("Preferred Injection Sites") {
          ForEach(["Thigh", "Abdomen", "Upper Arm", "Buttocks"], id: \.self) { site in
            HStack {
              Text(site)
              Spacer()
              if self.preferredInjectionSites.contains(site) {
                Image(systemName: "checkmark")
                  .foregroundColor(.accentColor)
              }
            }
            .contentShape(Rectangle())
            .onTapGesture {
              if self.preferredInjectionSites.contains(site) {
                self.preferredInjectionSites.removeAll { $0 == site }
              } else {
                self.preferredInjectionSites.append(site)
              }
            }
            .accessibilityIdentifier("add-injection-site-\(site.lowercased())")
          }
        }

        Section("Notes") {
          TextField("Optional notes about your medication...", text: self.$notes, axis: .vertical)
            .lineLimit(3...6)
        }
      }
      .navigationTitle("Add Medication")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            self.dismiss()
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Save") {
            self.saveMedicationProfile()
          }
          .accessibilityIdentifier("save-medication-profile")
        }
      }
      .alert("Error", isPresented: self.$showingError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(self.errorMessage)
      }
      .reconstitutionCalculatorSheet(
        isPresented: self.$showingReconstitutionCalculator,
        vialStrength: self.vialStrength,
        targetDose: self.selectedDose,
        waterVolume: 1.0,
        onSave: { vialStrength, targetDose, waterVolume in
          self.vialStrength = vialStrength
          self.selectedDose = targetDose
          self.reconstitutionVolume = waterVolume

          // Calculate and store concentration and units per dose
          do {
            let result = try ReconstitutionCalculator.calculate(
              vialStrength: vialStrength,
              targetDose: targetDose,
              waterVolume: waterVolume)
            self.concentration = result.concentration
            self.unitsPerDose = result.unitsPerDose
          } catch {
            // If calculation fails, clear the values
            self.concentration = nil
            self.unitsPerDose = nil
          }
        })
    }
  }

  private func saveMedicationProfile() {
    do {
      // Use "Generic" brand for compounded medications
      let brandName = self.isCompounded ? "Generic" : self.selectedBrand

      _ = try self.medicationManager.createProfile(
        for: self.currentUser,
        medication: self.selectedMedication,
        brandName: brandName,
        currentDose: self.selectedDose,
        startDate: self.startDate,
        preferredInjectionSites: self.preferredInjectionSites,
        isCompounded: self.isCompounded,
        vialStrength: self.isCompounded ? self.vialStrength : nil,
        reconstitutionVolume: self.isCompounded ? self.reconstitutionVolume : nil,
        concentration: self.isCompounded ? self.concentration : nil,
        unitsPerDose: self.isCompounded ? self.unitsPerDose : nil,
        notes: self.notes.isEmpty ? "" : self.notes)

      self.dismiss()
    } catch {
      self.errorMessage = error.localizedDescription
      self.showingError = true
    }
  }
}

struct MedicationProfileDetailView: View {
  let profile: MedicationProfile
  @ObservedObject var medicationManager: MedicationManager
  @State private var showingEditSheet = false
  @State private var showingReconstitutionCalculator = false
  @State private var showingDoseTitration = false
  @Environment(\.modelContext) private var modelContext

  init(profile: MedicationProfile, medicationManager: MedicationManager) {
    self.profile = profile
    self.medicationManager = medicationManager
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Profile Header
        DesignCard {
          VStack(alignment: .leading, spacing: 16) {
            Text("Medication Details")
              .font(DesignTokens.Typography.headline)

            VStack(alignment: .leading, spacing: 8) {
              DetailRow(title: "Medication", value: self.profile.medicationType.capitalized)
              DetailRow(title: "Brand", value: self.profile.brandName)
              DetailRow(
                title: "Current Dose",
                value: "\(String(format: "%.2f", self.profile.currentDose)) mg")
              DetailRow(
                title: "Start Date",
                value: self.profile.startDate.formatted(date: .abbreviated, time: .omitted))
              DetailRow(
                title: "Preferred Sites",
                value: self.profile.preferredInjectionSites.joined(separator: ", "))

              // Show reconstitution data for compounded medications
              if self.profile.isCompounded {
                if let concentration = self.profile.concentration {
                  DetailRow(
                    title: "Concentration",
                    value: "\(String(format: "%.2f", concentration)) mg/ml")
                }
                if let unitsPerDose = self.profile.unitsPerDose {
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

        // Calculator Tools
        if self.profile.isCompounded {
          Button {
            self.showingReconstitutionCalculator = true
          } label: {
            CalculatorCard(
              title: "Reconstitution Calculator",
              description: "Calculate water volume and units per dose",
              icon: "drop.fill")
          }
          .accessibilityIdentifier("detail-reconstitution-calculator")
        }

        // Dose Titration Management
        Button {
          self.showingDoseTitration = true
        } label: {
          CalculatorCard(
            title: "Dose Titration Plan",
            description: "Schedule and track dose increases",
            icon: "chart.line.uptrend.xyaxis")
        }
        .accessibilityIdentifier("dose-escalation-button")

        Spacer()
      }
      .padding(.horizontal, 16)
    }
    .navigationTitle(self.profile.brandName)
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button("Edit") {
          self.showingEditSheet = true
        }
        .accessibilityIdentifier("edit-medication-profile")
      }
    }
    .sheet(isPresented: self.$showingEditSheet) {
      EditMedicationProfileView(profile: self.profile, medicationManager: self.medicationManager)
    }
    .reconstitutionCalculatorSheet(
      isPresented: self.$showingReconstitutionCalculator,
      vialStrength: self.profile.vialStrength ?? 1.0,
      targetDose: self.profile.currentDose,
      waterVolume: self.profile.reconstitutionVolume ?? 1.0,
      onSave: { vialStrength, targetDose, waterVolume in
        // Calculate and store concentration and units per dose
        do {
          let result = try ReconstitutionCalculator.calculate(
            vialStrength: vialStrength,
            targetDose: targetDose,
            waterVolume: waterVolume)

          // Update the profile with new values
          try self.medicationManager.updateProfile(
            self.profile,
            medication: self.profile.medication,
            brandName: self.profile.brandName,
            currentDose: targetDose,
            isCompounded: self.profile.isCompounded,
            vialStrength: vialStrength,
            reconstitutionVolume: waterVolume,
            concentration: result.concentration,
            unitsPerDose: result.unitsPerDose,
            notes: self.profile.notes)
        } catch {
          print("Failed to update profile with reconstitution values: \(error)")
        }
      }
    )
    .sheet(isPresented: self.$showingDoseTitration) {
      DoseTitrationView(profile: self.profile)
    }
  }
}

struct DetailRow: View {
  let title: String
  let value: String

  var body: some View {
    HStack {
      Text(self.title)
        .font(DesignTokens.Typography.body)
        .foregroundColor(.secondary)

      Spacer()

      Text(self.value)
        .font(DesignTokens.Typography.body)
        .foregroundColor(.primary)
    }
  }
}

struct CalculatorCard: View {
  let title: String
  let description: String
  let icon: String

  var body: some View {
    DesignCard {
      HStack {
        Image(systemName: self.icon)
          .font(.title2)
          .foregroundColor(DesignTokens.Colors.primary)

        VStack(alignment: .leading, spacing: 4) {
          Text(self.title)
            .font(DesignTokens.Typography.headline)
            .foregroundColor(.primary)

          Text(self.description)
            .font(DesignTokens.Typography.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .foregroundColor(.secondary)
          .font(.caption)
      }
    }
  }
}

struct EditMedicationProfileView: View {
  @Environment(\.dismiss) private var dismiss
  let profile: MedicationProfile
  let medicationManager: MedicationManager

  @State private var selectedMedication: Medication
  @State private var selectedBrand: String
  @State private var selectedDose: Double
  @State private var startDate: Date
  @State private var preferredInjectionSites: [String]
  @State private var isCompounded: Bool
  @State private var notes: String
  @State private var vialStrength: Double
  @State private var reconstitutionVolume: Double
  @State private var concentration: Double?
  @State private var unitsPerDose: Double?

  @State private var showingError = false
  @State private var errorMessage = ""
  @State private var showingReconstitutionCalculator = false

  init(profile: MedicationProfile, medicationManager: MedicationManager) {
    self.profile = profile
    self.medicationManager = medicationManager
    self._selectedMedication = State(
      initialValue: Medication(rawValue: profile.medicationType) ?? .semaglutide)
    self._selectedBrand = State(initialValue: profile.brandName)
    self._selectedDose = State(initialValue: profile.currentDose)
    self._startDate = State(initialValue: profile.startDate)
    self._preferredInjectionSites = State(initialValue: profile.preferredInjectionSites)
    self._isCompounded = State(initialValue: profile.isCompounded)
    self._notes = State(initialValue: profile.notes)
    self._vialStrength = State(initialValue: profile.vialStrength ?? 10.0)
    self._reconstitutionVolume = State(initialValue: profile.reconstitutionVolume ?? 1.0)
    self._concentration = State(initialValue: profile.concentration)
    self._unitsPerDose = State(initialValue: profile.unitsPerDose)
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Medication Information") {
          Picker("Medication", selection: self.$selectedMedication) {
            ForEach(Medication.allCases, id: \.self) { medication in
              Text(medication.displayName)
                .tag(medication)
            }
          }
          .accessibilityIdentifier("edit-medication-picker")
          .onChange(of: self.selectedMedication) { _, newValue in
            // Reset brand and dose when medication changes to prevent invalid picker selections
            let newBrand = newValue.brands.first ?? ""
            let newDose = newValue.availableDoses.first ?? 0.0

            // Update immediately to prevent console errors
            self.selectedBrand = newBrand
            self.selectedDose = newDose
          }
        }

        MedicationBrandSection(
          selectedMedication: self.selectedMedication,
          selectedBrand: self.$selectedBrand,
          isCompounded: self.isCompounded,
          accessibilityPrefix: "edit")

        MedicationDosingSection(
          selectedMedication: self.selectedMedication,
          selectedDose: self.$selectedDose,
          isCompounded: self.$isCompounded,
          vialStrength: self.$vialStrength,
          accessibilityPrefix: "edit",
          onCalculateReconstitution: {
            self.showingReconstitutionCalculator = true
          })

        Section("Start Date") {
          DatePicker("Start Date", selection: self.$startDate, displayedComponents: .date)
            .accessibilityIdentifier("edit-start-date-picker")
        }

        Section("Preferred Injection Sites") {
          ForEach(["Thigh", "Abdomen", "Upper Arm", "Buttocks"], id: \.self) { site in
            HStack {
              Text(site)
              Spacer()
              if self.preferredInjectionSites.contains(site) {
                Image(systemName: "checkmark")
                  .foregroundColor(.accentColor)
              }
            }
            .contentShape(Rectangle())
            .onTapGesture {
              if self.preferredInjectionSites.contains(site) {
                self.preferredInjectionSites.removeAll { $0 == site }
              } else {
                self.preferredInjectionSites.append(site)
              }
            }
            .accessibilityIdentifier("edit-injection-site-\(site.lowercased())")
          }
        }

        Section("Notes") {
          TextField("Optional notes about your medication...", text: self.$notes, axis: .vertical)
            .lineLimit(3...6)
            .accessibilityIdentifier("edit-notes-field")
        }
      }
      .navigationTitle("Edit Medication")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            self.dismiss()
          }
          .accessibilityIdentifier("edit-cancel-button")
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Save") {
            self.updateMedicationProfile()
          }
          .accessibilityIdentifier("edit-save-button")
        }
      }
      .alert("Error", isPresented: self.$showingError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(self.errorMessage)
      }
      .reconstitutionCalculatorSheet(
        isPresented: self.$showingReconstitutionCalculator,
        vialStrength: self.vialStrength,
        targetDose: self.selectedDose,
        waterVolume: 1.0,
        onSave: { vialStrength, targetDose, waterVolume in
          self.vialStrength = vialStrength
          self.selectedDose = targetDose
          self.reconstitutionVolume = waterVolume

          // Calculate and store concentration and units per dose
          do {
            let result = try ReconstitutionCalculator.calculate(
              vialStrength: vialStrength,
              targetDose: targetDose,
              waterVolume: waterVolume)
            self.concentration = result.concentration
            self.unitsPerDose = result.unitsPerDose
          } catch {
            // If calculation fails, clear the values
            self.concentration = nil
            self.unitsPerDose = nil
          }
        })
    }
  }

  private func updateMedicationProfile() {
    do {
      // Use "Generic" brand for compounded medications
      let brandName = self.isCompounded ? "Generic" : self.selectedBrand

      try self.medicationManager.updateProfile(
        self.profile,
        medication: self.selectedMedication,
        brandName: brandName,
        currentDose: self.selectedDose,
        startDate: self.startDate,
        preferredInjectionSites: self.preferredInjectionSites,
        isCompounded: self.isCompounded,
        vialStrength: self.isCompounded ? self.vialStrength : nil,
        reconstitutionVolume: self.isCompounded ? self.reconstitutionVolume : nil,
        concentration: self.isCompounded ? self.concentration : nil,
        unitsPerDose: self.isCompounded ? self.unitsPerDose : nil,
        notes: self.notes.isEmpty ? "" : self.notes)

      self.dismiss()
    } catch {
      self.errorMessage = error.localizedDescription
      self.showingError = true
    }
  }
}

#Preview {
  let container = DataController.preview.container
  let medicationManager = MedicationManager(modelContext: container.mainContext)

  return MedicationProfileSettingsView(medicationManager: medicationManager)
    .modelContainer(container)
}
