//
//  DoseSearchAndFilterView.swift
//  JabTracker
//
//  Search and filter controls UI for dose history with comprehensive filtering options
//

import SwiftUI

struct DoseSearchAndFilterView: View {
    @ObservedObject var viewModel: DoseHistoryViewModel
    @State private var showingDateRangePicker = false

    var body: some View {
        Form {
            self.searchSection
            self.filtersSection
            self.dateRangeSection
            self.actionsSection
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: self.$showingDateRangePicker) {
            self.dateRangePickerSheet
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        Section {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search notes, medications...", text: self.$viewModel.searchText)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("dose-history-search")

                if !self.viewModel.searchText.isEmpty {
                    Button {
                        self.viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Clear search")
                    .accessibilityIdentifier("clear-search-button")
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Search")
        }
    }

    // MARK: - Filters Section

    private var filtersSection: some View {
        Section {
            // Medication filter
            self.medicationFilterPicker

            // Injection site filter
            self.injectionSiteFilterPicker

            // Show skipped doses toggle
            self.showSkippedToggle

        } header: {
            Text("Filters")
        }
    }

    private var medicationFilterPicker: some View {
        HStack {
            Text("Medication")
                .foregroundColor(.primary)

            Spacer()

            Picker("Medication", selection: self.$viewModel.selectedMedicationFilter) {
                Text("All Medications")
                    .tag(String?.none)

                ForEach(self.viewModel.availableMedications, id: \.self) { medication in
                    Text(medication)
                        .tag(String?.some(medication))
                }
            }
            .pickerStyle(.menu)
            .tint(.accentColor)
            .accessibilityIdentifier("medication-filter-picker")
        }
    }

    private var injectionSiteFilterPicker: some View {
        HStack {
            Text("Injection Site")
                .foregroundColor(.primary)

            Spacer()

            Picker("Injection Site", selection: self.$viewModel.selectedInjectionSiteFilter) {
                Text("All Sites")
                    .tag(String?.none)

                ForEach(self.viewModel.availableInjectionSites, id: \.self) { site in
                    Text(site)
                        .tag(String?.some(site))
                }
            }
            .pickerStyle(.menu)
            .tint(.accentColor)
            .accessibilityIdentifier("injection-site-filter-picker")
        }
    }

    private var showSkippedToggle: some View {
        Toggle("Show Skipped Doses", isOn: self.$viewModel.showSkippedDoses)
            .accessibilityIdentifier("show-skipped-toggle")
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        Section {
            Button {
                self.showingDateRangePicker = true
            } label: {
                HStack {
                    Text("Date Range")
                        .foregroundColor(.primary)

                    Spacer()

                    Text(self.dateRangeDisplayText)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityIdentifier("date-range-button")
            .accessibilityLabel("Date range filter: \(self.dateRangeDisplayText)")

        } header: {
            Text("Date Range")
        }
    }

    private var dateRangeDisplayText: String {
        switch (self.viewModel.filterStartDate, self.viewModel.filterEndDate) {
        case let (start?, end?):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"

        case (let start?, nil):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "From \(formatter.string(from: start))"

        case (nil, let end?):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "Until \(formatter.string(from: end))"

        case (nil, nil):
            return "All dates"
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        Section {
            // Active filters summary
            if self.viewModel.hasActiveFilters {
                self.activeFiltersSummary
            }

            // Clear all filters button
            Button("Apply Filters") {
                // Filters are applied automatically via @Published properties
                // This button exists for E2E test compatibility
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("apply-filters-button")

            Button {
                self.viewModel.clearAllFilters()
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Clear All Filters")
                }
                .foregroundColor(self.viewModel.hasActiveFilters ? .red : .secondary)
            }
            .disabled(!self.viewModel.hasActiveFilters)
            .accessibilityIdentifier("clear-all-filters-button")

        } header: {
            Text("Actions")
        }
    }

    @ViewBuilder
    private var activeFiltersSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Active Filters:")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 120), spacing: 8),
            ], spacing: 8) {
                ForEach(self.activeFiltersArray, id: \.self) { filter in
                    Text(filter)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .cornerRadius(8)
                }
            }
        }
        .accessibilityIdentifier("active-filters-indicator")
    }

    private var activeFiltersArray: [String] {
        var filters: [String] = []

        if !self.viewModel.searchText.isEmpty {
            filters.append("Search: \(self.viewModel.searchText)")
        }

        if let medication = viewModel.selectedMedicationFilter {
            filters.append("Medication: \(medication)")
        }

        if let site = viewModel.selectedInjectionSiteFilter {
            filters.append("Site: \(site)")
        }

        if self.viewModel.filterStartDate != nil || self.viewModel.filterEndDate != nil {
            filters.append("Date range")
        }

        if !self.viewModel.showSkippedDoses {
            filters.append("Hide skipped")
        }

        return filters
    }

    // MARK: - Date Range Picker Sheet

    private var dateRangePickerSheet: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Start Date",
                        selection: Binding(
                            get: { self.viewModel.filterStartDate ?? Date() },
                            set: { self.viewModel.filterStartDate = $0 }),
                        displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .accessibilityIdentifier("filter-start-date")

                    Toggle("Use Start Date", isOn: Binding(
                        get: { self.viewModel.filterStartDate != nil },
                        set: { if !$0 { self.viewModel.filterStartDate = nil } }))
                } header: {
                    Text("Start Date")
                }

                Section {
                    DatePicker(
                        "End Date",
                        selection: Binding(
                            get: { self.viewModel.filterEndDate ?? Date() },
                            set: { self.viewModel.filterEndDate = $0 }),
                        displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .accessibilityIdentifier("filter-end-date")

                    Toggle("Use End Date", isOn: Binding(
                        get: { self.viewModel.filterEndDate != nil },
                        set: { if !$0 { self.viewModel.filterEndDate = nil } }))
                } header: {
                    Text("End Date")
                }

                Section {
                    Button("Clear Date Range") {
                        self.viewModel.filterStartDate = nil
                        self.viewModel.filterEndDate = nil
                    }
                    .foregroundColor(.red)
                    .disabled(self.viewModel.filterStartDate == nil && self.viewModel.filterEndDate == nil)
                }
            }
            .navigationTitle("Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        self.showingDateRangePicker = false
                    }
                }
            }
        }
        .accessibilityIdentifier("dose-filter-sheet")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DoseSearchAndFilterView(viewModel: DoseHistoryViewModel())
    }
}
