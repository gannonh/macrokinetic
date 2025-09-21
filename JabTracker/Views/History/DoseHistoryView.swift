//
//  DoseHistoryView.swift
//  JabTracker
//
//  Main dose history list view with search, filtering, and CRUD operations
//

import SwiftData
import SwiftUI

struct DoseHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Dose.timestamp, order: .reverse) private var allDoses: [Dose]
    @StateObject private var viewModel = DoseHistoryViewModel()
    @State private var showingSearchAndFilter = false
    @State private var showingDeleteConfirmation = false
    @State private var doseToDelete: Dose?
    @State private var editingDose: DoseEditData?
    @State private var showingNewDoseSheet = false
    @State private var showingSuccessMessage = false
    @StateObject private var quickDoseViewModel = QuickDoseViewModel()
    @State private var pkEngine = PharmacokineticsEngine()
    @State private var doseService: DoseService

    init() {
        let engine = PharmacokineticsEngine()
        self._pkEngine = State(wrappedValue: engine)
        self._doseService = State(wrappedValue: DoseService(pkEngine: engine))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field for E2E test compatibility
            self.searchFieldView

            Group {
                if self.viewModel.isLoading {
                    self.loadingView
                } else if self.viewModel.filteredDoses.isEmpty {
                    self.emptyStateView
                } else {
                    self.historyListView
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                self.searchFilterButton
            }
        }
        .refreshable {
            await self.viewModel.refreshData(context: self.modelContext)
        }
        .alert("Delete Dose", isPresented: self.$showingDeleteConfirmation) {
            self.deleteConfirmationAlert
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: self.$showingSearchAndFilter) {
            self.searchAndFilterSheet
        }
        .sheet(item: self.$editingDose) { editData in
            self.editDoseSheet(for: editData)
        }
        .sheet(isPresented: self.$showingNewDoseSheet) {
            QuickDoseSheet(
                viewModel: self.quickDoseViewModel,
                doseService: self.doseService,
                showingSuccessMessage: self.$showingSuccessMessage)
        }
        .onAppear {
            self.viewModel.setDoses(self.allDoses)
            self.quickDoseViewModel.loadSmartDefaults(context: self.modelContext)
        }
        .onChange(of: self.allDoses) { _, newDoses in
            self.viewModel.setDoses(newDoses)
        }
        .accessibilityIdentifier("dose-history-view")
        .alert("Error", isPresented: .constant(self.viewModel.errorMessage != nil)) {
            Button("OK") {
                self.viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Subviews

    private var searchFieldView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search doses...", text: self.$viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("dose-history-search")

            if !self.viewModel.searchText.isEmpty {
                Button {
                    self.viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear text")
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading dose history...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("loading-indicator")
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("No doses logged yet")
                    .font(.headline)
                    .fontWeight(.medium)
                    .accessibilityIdentifier("empty-state-message")

                if self.viewModel.hasActiveFilters {
                    Text("No doses match your current filters.")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Button("Clear Filters") {
                        self.viewModel.clearAllFilters()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Text("Start tracking your medication doses to see your history here.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Log Your First Dose") {
                        self.showingNewDoseSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("log-first-dose-button")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("dose-history-empty-state")
    }

    private var historyListView: some View {
        List {
            ForEach(self.viewModel.groupedDoses, id: \.0) { dateString, doses in
                Section(header: self.sectionHeader(dateString: dateString)) {
                    ForEach(doses, id: \.id) { dose in
                        Button {
                            // TODO: Handle row tap if needed
                        } label: {
                            DoseHistoryRow(dose: dose)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            self.trailingSwipeActions(for: dose)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            self.leadingSwipeActions(for: dose)
                        }
                        .accessibilityIdentifier("dose-history-row")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("dose-history-list")
    }

    private func sectionHeader(dateString: String) -> some View {
        HStack {
            Text(dateString)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("dose-date-section-header")
    }

    // MARK: - Swipe Actions

    @ViewBuilder
    private func trailingSwipeActions(for dose: Dose) -> some View {
        Button("Delete") {
            self.doseToDelete = dose
            self.showingDeleteConfirmation = true
        }
        .tint(.red)

        Button("Edit") {
            self.editingDose = self.viewModel.getDoseForEditing(dose)
        }
        .tint(.blue)
    }

    @ViewBuilder
    private func leadingSwipeActions(for dose: Dose) -> some View {
        Button("Duplicate") {
            try? self.viewModel.duplicateDose(dose, context: self.modelContext)
        }
        .tint(.green)

        Button(dose.skipped ? "Mark Taken" : "Mark as Skipped") {
            try? self.viewModel.toggleSkippedStatus(for: dose, context: self.modelContext)
        }
        .tint(dose.skipped ? .green : .orange)
    }

    // MARK: - Toolbar Items

    private var searchFilterButton: some View {
        Button {
            self.showingSearchAndFilter = true
        } label: {
            Image(systemName: self.viewModel.hasActiveFilters
                ? "line.3.horizontal.decrease.circle.fill"
                : "line.3.horizontal.decrease.circle")
                .foregroundColor(self.viewModel.hasActiveFilters ? .accentColor : .primary)
        }
        .accessibilityIdentifier("filter-button")
        .accessibilityLabel("Search and filter")
        .accessibilityHint(self.viewModel.hasActiveFilters ? "Filters are active" : "No active filters")
    }

    // MARK: - Alerts and Sheets

    @ViewBuilder
    private var deleteConfirmationAlert: some View {
        Button("Delete", role: .destructive) {
            if let dose = doseToDelete {
                try? self.viewModel.deleteDose(dose, context: self.modelContext)
                self.doseToDelete = nil
            }
        }

        Button("Cancel", role: .cancel) {
            self.doseToDelete = nil
        }
    }

    private var searchAndFilterSheet: some View {
        NavigationStack {
            DoseSearchAndFilterView(viewModel: self.viewModel)
                .navigationTitle("Search & Filter")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            self.showingSearchAndFilter = false
                        }
                    }
                }
        }
    }

    private func editDoseSheet(for editData: DoseEditData) -> some View {
        QuickDoseSheet(
            editingDose: editData,
            onSave: { updatedDose in
                self.handleDoseUpdate(editData: editData, updatedDose: updatedDose)
            },
            onCancel: {
                self.editingDose = nil
            })
    }

    private func handleDoseUpdate(editData: DoseEditData, updatedDose: DoseEditData) {
        // Update the dose with edited data
        if let originalDose = self.viewModel.allDoses.first(where: { $0.id == editData.id }) {
            try? self.viewModel.updateDose(originalDose, with: updatedDose, context: self.modelContext)
        }
        self.editingDose = nil
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let mediumDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    NavigationStack {
        DoseHistoryView()
    }
    .modelContainer(DataController.preview.container)
}
