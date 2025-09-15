//
//  DoseHistoryView.swift
//  JabTracker
//
//  Main dose history list view with search, filtering, and CRUD operations
//

import SwiftUI
import SwiftData

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
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field for E2E test compatibility
            searchFieldView

            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredDoses.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                searchFilterButton
            }
        }
        .refreshable {
            await viewModel.refreshData(context: modelContext)
        }
        .alert("Delete Dose", isPresented: $showingDeleteConfirmation) {
            deleteConfirmationAlert
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $showingSearchAndFilter) {
            searchAndFilterSheet
        }
        .sheet(item: $editingDose) { editData in
            QuickDoseSheet(
                editingDose: editData,
                onSave: { updatedDose in
                    // Update the dose with edited data
                    if let originalDose = allDoses.first(where: { $0.id == editData.id }) {
                        try? viewModel.updateDose(originalDose, with: updatedDose, context: modelContext)
                    }
                    editingDose = nil
                },
                onCancel: {
                    editingDose = nil
                }
            )
        }
        .sheet(isPresented: $showingNewDoseSheet) {
            QuickDoseSheet(
                viewModel: quickDoseViewModel,
                showingSuccessMessage: $showingSuccessMessage
            )
        }
        .onAppear {
            viewModel.setDoses(allDoses)
            quickDoseViewModel.loadSmartDefaults(context: modelContext)
        }
        .onChange(of: allDoses) { _, newDoses in
            viewModel.setDoses(newDoses)
        }
        .accessibilityIdentifier("dose-history-view")
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
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
            
            TextField("Search doses...", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("dose-history-search")
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
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
                
                if viewModel.hasActiveFilters {
                    Text("No doses match your current filters.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Button("Clear Filters") {
                        viewModel.clearAllFilters()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Text("Start tracking your medication doses to see your history here.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Log Your First Dose") {
                        showingNewDoseSheet = true
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
            ForEach(viewModel.groupedDoses, id: \.0) { dateString, doses in
                Section(header: sectionHeader(dateString: dateString)) {
                    ForEach(doses, id: \.id) { dose in
                        Button {
                            // TODO: Handle row tap if needed
                        } label: {
                            DoseHistoryRow(dose: dose)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            trailingSwipeActions(for: dose)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            leadingSwipeActions(for: dose)
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
            doseToDelete = dose
            showingDeleteConfirmation = true
        }
        .tint(.red)
        
        Button("Edit") {
            editingDose = viewModel.getDoseForEditing(dose)
        }
        .tint(.blue)
    }
    
    @ViewBuilder
    private func leadingSwipeActions(for dose: Dose) -> some View {
        Button("Duplicate") {
            try? viewModel.duplicateDose(dose, context: modelContext)
        }
        .tint(.green)
        
        Button(dose.skipped ? "Mark Taken" : "Mark as Skipped") {
            try? viewModel.toggleSkippedStatus(for: dose, context: modelContext)
        }
        .tint(dose.skipped ? .green : .orange)
    }
    
    // MARK: - Toolbar Items
    
    private var searchFilterButton: some View {
        Button {
            showingSearchAndFilter = true
        } label: {
            Image(systemName: viewModel.hasActiveFilters 
                    ? "line.3.horizontal.decrease.circle.fill" 
                    : "line.3.horizontal.decrease.circle")
                .foregroundColor(viewModel.hasActiveFilters ? .accentColor : .primary)
        }
        .accessibilityIdentifier("filter-button")
        .accessibilityLabel("Search and filter")
        .accessibilityHint(viewModel.hasActiveFilters ? "Filters are active" : "No active filters")
    }
    
    // MARK: - Alerts and Sheets
    
    @ViewBuilder
    private var deleteConfirmationAlert: some View {
        Button("Delete", role: .destructive) {
            if let dose = doseToDelete {
                try? viewModel.deleteDose(dose, context: modelContext)
                doseToDelete = nil
            }
        }
        
        Button("Cancel", role: .cancel) {
            doseToDelete = nil
        }
    }
    
    private var searchAndFilterSheet: some View {
        NavigationStack {
            DoseSearchAndFilterView(viewModel: viewModel)
                .navigationTitle("Search & Filter")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingSearchAndFilter = false
                        }
                    }
                }
        }
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
