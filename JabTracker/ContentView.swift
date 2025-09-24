import StoreKit
import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @StateObject private var quickDoseViewModel = QuickDoseViewModel()
  @State private var showingQuickDoseSheet = false
  @State private var showingSuccessMessage = false
  @State private var selectedTab = "home"
  @State private var pkEngine = PharmacokineticsEngine()
  @State private var doseService: DoseService

  init() {
    let pkEngine = PharmacokineticsEngine()
    self._pkEngine = State(wrappedValue: pkEngine)
    self._doseService = State(wrappedValue: DoseService(pkEngine: pkEngine))
  }

  var body: some View {
    TabView(selection: self.$selectedTab) {
      DashboardView(doseService: self.doseService)
        .tabItem {
          Label("Home", systemImage: "house.fill")
        }
        .tag("home")

      // Empty view for Add tab - sheet presentation handled by onChange
      Color.clear
        .tabItem {
          Label("Add", systemImage: "plus.circle.fill")
        }
        .tag("add")

      HistoryView()
        .tabItem {
          Label("History", systemImage: "clock.fill")
        }
        .tag("history")

      AnalyticsView()
        .tabItem {
          Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
        }
        .tag("analytics")

      SettingsView()
        .tabItem {
          Label("Settings", systemImage: "gear")
        }
        .tag("settings")
    }
    .accessibilityIdentifier("main-tab-view")
    .sheet(
      isPresented: self.$showingQuickDoseSheet,
      content: {
        QuickDoseSheet(
          viewModel: self.quickDoseViewModel,
          doseService: self.doseService,
          showingSuccessMessage: self.$showingSuccessMessage)
      }
    )
    .onChange(of: self.selectedTab) { oldValue, newValue in
      print("🔍 ContentView: Tab changed from \(oldValue) to \(newValue)")
      if newValue == "add" {
        print("🔍 ContentView: Add tab selected, showing QuickDoseSheet")
        self.showingQuickDoseSheet = true
        // Reset tab selection to previous tab so + doesn't stay selected
        self.selectedTab = oldValue
        print("🔍 ContentView: Reset tab selection back to \(oldValue)")
      }
    }
    .onAppear {
      self.quickDoseViewModel.loadSmartDefaults(context: self.modelContext)
    }
    .overlay(alignment: .top) {
      if self.showingSuccessMessage {
        Text("Dose logged successfully!")
          .font(.caption)
          .foregroundColor(.white)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color.green.opacity(0.9))
          .cornerRadius(8)
          .accessibilityIdentifier("dose-logged-success")
          .transition(.move(edge: .top).combined(with: .opacity))
          .zIndex(1)
          .onAppear {
            // Auto-dismiss success message after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
              withAnimation {
                self.showingSuccessMessage = false
              }
            }
          }
      }
    }
  }
}

struct DashboardView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var users: [User]
  @State private var pkEngine = PharmacokineticsEngine()
  let doseService: DoseService

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 16) {
          if let currentUser = users.first {
            self.concentrationSection(for: currentUser)
          } else {
            self.noUserSection
          }
        }
        .padding()
      }
      .accessibilityIdentifier("dashboard-scroll-view")
      .navigationTitle("Home")
      .accessibilityIdentifier("dashboard-view")
    }
  }

  // MARK: - Concentration Section

  @ViewBuilder
  private func concentrationSection(for user: User) -> some View {
    if let medicationProfiles = user.medicationProfiles,
      !medicationProfiles.isEmpty
    {
      ConcentrationList(
        user: user,
        medicationProfiles: medicationProfiles,
        pkEngine: self.pkEngine,
        doseService: self.doseService)
    } else {
      self.noMedicationSection
    }
  }

  // MARK: - Empty States

  private var noUserSection: some View {
    DesignCard {
      VStack(spacing: 16) {
        Image(systemName: "person.crop.circle")
          .font(.system(size: 48))
          .foregroundColor(.secondary)

        Text("Set up your profile")
          .font(DesignTokens.Typography.headline)

        Text("Complete onboarding to start tracking your medication concentrations")
          .font(DesignTokens.Typography.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
      .padding()
    }
    .accessibilityIdentifier("no-user-message")
  }

  private var noMedicationSection: some View {
    DesignCard {
      VStack(spacing: 16) {
        Image(systemName: "chart.line.uptrend.xyaxis")
          .font(.system(size: 48))
          .foregroundColor(.secondary)

        Text("Add medication profiles")
          .font(DesignTokens.Typography.headline)

        Text("Set up your medications in Settings to view concentration tracking")
          .font(DesignTokens.Typography.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
      .padding()
    }
    .accessibilityIdentifier("no-medication-message")
  }
}

// MARK: - ConcentrationList

struct ConcentrationList: View {
  let user: User
  let medicationProfiles: [MedicationProfile]
  let pkEngine: PharmacokineticsEngine
  let doseService: DoseService

  var body: some View {
    let sortedProfiles = self.medicationProfiles.sorted(by: { $0.startDate > $1.startDate })
    ForEach(Array(sortedProfiles.enumerated()), id: \.element.id) { _, profile in
      ConcentrationCard(
        user: self.user,
        medicationProfile: profile,
        pkEngine: self.pkEngine,
        doseService: self.doseService
      )
      .accessibilityIdentifier("concentration-card-\(profile.genericName)")
    }
  }
}

// HistoryView moved to JabTracker/Views/History/HistoryView.swift

struct AnalyticsView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var users: [User]
  @State private var chartDataProcessor = ChartDataProcessor()
  @State private var analyticsService = AnalyticsService()

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 16) {
          if let currentUser = users.first,
            let medicationProfiles = currentUser.medicationProfiles,
            !medicationProfiles.isEmpty
          {
            concentrationChartSection(for: currentUser, profiles: medicationProfiles)
          } else {
            noDataSection
          }
        }
        .padding()
      }
      .navigationTitle("Analytics")
      .accessibilityIdentifier("analytics-view")
    }
  }

  // MARK: - Chart Section

  @ViewBuilder
  private func concentrationChartSection(for user: User, profiles: [MedicationProfile]) -> some View
  {
    VStack(spacing: 16) {
      // Generate chart dataset from user data
      if let chartDataset = generateChartDataset(for: user, profiles: profiles) {
        ConcentrationTimelineChart(dataset: chartDataset)
      } else {
        chartLoadingView()
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.systemBackground))
        .shadow(radius: 2)
    )
  }

  // MARK: - Empty States

  private var noDataSection: some View {
    VStack(spacing: 16) {
      Image(systemName: "chart.line.uptrend.xyaxis")
        .font(.system(size: 64))
        .foregroundColor(.secondary)

      Text("No Analytics Data")
        .font(.headline)
        .foregroundColor(.primary)

      VStack(spacing: 8) {
        Text("Start tracking doses to see your concentration timeline")
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)

        Text("Analytics will show medication concentration levels over time")
          .font(.caption)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.systemBackground))
        .shadow(radius: 2)
    )
    .accessibilityIdentifier("no-analytics-data")
  }

  @ViewBuilder
  private func chartLoadingView() -> some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.2)

      Text("Generating Concentration Chart...")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(height: 300)
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(.systemGray6))
    )
    .accessibilityIdentifier("chart-loading")
  }

  // MARK: - Data Generation

  /// Generates chart dataset from user medication data
  private func generateChartDataset(for user: User, profiles: [MedicationProfile])
    -> ConcentrationChartDataset?
  {
    guard let primaryProfile = profiles.first,
      let doses = primaryProfile.doses,
      !doses.isEmpty
    else {
      return nil
    }

    // Convert SwiftData to chart data types
    let advancedMarkers = doses.map { dose in
      AdvancedDoseMarker(from: dose)
    }

    // Generate concentration points using ChartDataProcessor
    let timeRange = (doses.map(\.timestamp).min() ?? Date())...(Date())
    let concentrationPoints = chartDataProcessor.generateConcentrationTimeline(
      for: primaryProfile,
      timeRange: timeRange
    )

    // Convert ConcentrationPoint to AdvancedConcentrationPoint
    let advancedPoints = concentrationPoints.map { point in
      AdvancedConcentrationPoint(from: point)
    }

    let concentrationCurve = ConcentrationCurve(
      points: advancedPoints,
      medication: primaryProfile.genericName
    )

    return ConcentrationChartDataset(
      concentrationCurves: [concentrationCurve],
      doseMarkers: advancedMarkers,
      configuration: .default
    )
  }
}

// SettingsView moved to JabTracker/Views/Settings/SettingsView.swift

#Preview {
  ContentView()
    .modelContainer(DataController.preview.container)
}
