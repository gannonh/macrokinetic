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
    @StateObject private var viewModel = DoseHistoryViewModel()
    @State private var showingSearchAndFilter = false
    @State private var showingDeleteConfirmation = false
    @State private var doseToDelete: Dose?
    @State private var editingDose: DoseEditData?
    @State private var showingEditSheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredDoses.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
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
            .sheet(isPresented: $showingEditSheet) {
                editDoseSheet
            }
            .onAppear {
                viewModel.loadData(context: modelContext)
            }
            .accessibilityIdentifier("dose-history-view")
        }
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
                Text("No Dose History")
                    .font(.headline)
                    .fontWeight(.medium)
                
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
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("empty-state")
    }
    
    private var historyListView: some View {
        List {
            ForEach(viewModel.groupedDoses, id: \.0) { dateString, doses in
                Section(header: sectionHeader(dateString: dateString)) {
                    ForEach(doses, id: \.id) { dose in
                        DoseHistoryRow(dose: dose)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                trailingSwipeActions(for: dose)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                leadingSwipeActions(for: dose)
                            }
                            .accessibilityIdentifier("dose-row-\(dose.id.uuidString)")
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
        .accessibilityIdentifier("section-header-\(dateString)")
    }
    
    // MARK: - Swipe Actions
    
    @ViewBuilder
    private func trailingSwipeActions(for dose: Dose) -> some View {
        Button {
            doseToDelete = dose
            showingDeleteConfirmation = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .tint(.red)
        .accessibilityIdentifier("delete-action-\(dose.id.uuidString)")
        
        Button {
            editingDose = viewModel.getDoseForEditing(dose)
            showingEditSheet = true
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .tint(.blue)
        .accessibilityIdentifier("edit-action-\(dose.id.uuidString)")
    }
    
    @ViewBuilder
    private func leadingSwipeActions(for dose: Dose) -> some View {
        Button {
            try? viewModel.duplicateDose(dose, context: modelContext)
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        .tint(.green)
        .accessibilityIdentifier("duplicate-action-\(dose.id.uuidString)")
        
        Button {
            try? viewModel.toggleSkippedStatus(for: dose, context: modelContext)
        } label: {
            Label(dose.skipped ? "Mark Taken" : "Mark Skipped", 
                  systemImage: dose.skipped ? "checkmark.circle" : "xmark.circle")
        }
        .tint(dose.skipped ? .green : .orange)
        .accessibilityIdentifier("toggle-skipped-action-\(dose.id.uuidString)")
    }
    
    // MARK: - Toolbar Items
    
    private var searchFilterButton: some View {
        Button {
            showingSearchAndFilter = true
        } label: {
            Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundColor(viewModel.hasActiveFilters ? .accentColor : .primary)
        }
        .accessibilityIdentifier("search-filter-button")
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
    
    @ViewBuilder
    private var editDoseSheet: some View {
        if let editData = editingDose {
            NavigationStack {
                // TODO: Replace with actual DoseEntrySheet when available
                // For now, use a placeholder that will be replaced in Stream C integration
                VStack {
                    Text("Edit Dose")
                        .font(.headline)
                    Text("Amount: \(editData.amount, specifier: "%.1f")")
                    Text("Date: \(editData.timestamp, formatter: DateFormatter.mediumDateTime)")
                    if let site = editData.site {
                        Text("Site: \(site)")
                    }
                    if let notes = editData.notes {
                        Text("Notes: \(notes)")
                    }
                }
                .padding()
                .navigationTitle("Edit Dose")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            editingDose = nil
                            showingEditSheet = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            // TODO: Implement save functionality in Stream C
                            editingDose = nil
                            showingEditSheet = false
                        }
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