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

    private static let amountStep = 0.25

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

    @ViewBuilder
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

        self.doseAmountSection
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
            HStack(spacing: 8) {
                self.datePresetButton("Today", preset: .today, identifier: "date-preset-today")
                self.datePresetButton("This Week", preset: .thisWeek, identifier: "date-preset-this-week")
                self.datePresetButton("This Month", preset: .thisMonth, identifier: "date-preset-this-month")
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

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

    private func datePresetButton(
        _ title: String,
        preset: DoseDateRangePreset,
        identifier: String
    ) -> some View {
        let isActive = self.viewModel.activeDateRangePreset == preset
        return Group {
            if isActive {
                Button(title) {
                    self.viewModel.setDateRange(preset)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(title) {
                    self.viewModel.setDateRange(preset)
                }
                .buttonStyle(.bordered)
            }
        }
        .font(.caption)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel("\(title) date preset")
        .accessibilityAddTraits(isActive ? .isSelected : [])
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

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 120), spacing: 8)
                ], spacing: 8
            ) {
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

        if self.viewModel.isAmountFilterActive,
            let min = viewModel.filterAmountMin,
            let max = viewModel.filterAmountMax
        {
            filters.append(String(format: "Amount: %.2f–%.2f mg", min, max))
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
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .accessibilityIdentifier("filter-start-date")

                    Toggle(
                        "Use Start Date",
                        isOn: Binding(
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
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .accessibilityIdentifier("filter-end-date")

                    Toggle(
                        "Use End Date",
                        isOn: Binding(
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        self.showingDateRangePicker = false
                    }
                }
            }
        }
        .accessibilityIdentifier("dose-filter-sheet")
    }
}

// MARK: - Dose Amount Filter

private extension DoseSearchAndFilterView {
    private var doseAmountSection: some View {
        Section {
            Text("Dose Amount: \(self.formattedAmountRange)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            self.amountSlider(label: "Minimum", binding: self.amountMinBinding, identifier: "dose-amount-min-slider")
            self.amountSlider(label: "Maximum", binding: self.amountMaxBinding, identifier: "dose-amount-max-slider")
        } header: {
            Text("Dose Amount")
        }
        // No section-level identifier: it would override the slider identifiers
    }

    private func amountSlider(
        label: String, binding: Binding<Double>, identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Slider(
                value: binding,
                in: self.viewModel.doseAmountBounds,
                step: Self.amountStep
            )
            .accessibilityIdentifier(identifier)
        }
    }

    private var formattedAmountRange: String {
        let bounds = self.viewModel.doseAmountBounds
        let min = self.viewModel.filterAmountMin ?? bounds.lowerBound
        let max = self.viewModel.filterAmountMax ?? bounds.upperBound
        return String(format: "%.2f – %.2f mg", min, max)
    }

    private var amountMinBinding: Binding<Double> {
        Binding(
            get: {
                self.viewModel.filterAmountMin ?? self.viewModel.doseAmountBounds.lowerBound
            },
            set: { newValue in
                let bounds = self.viewModel.doseAmountBounds
                let currentMax = self.viewModel.filterAmountMax ?? bounds.upperBound
                let clampedMin = min(newValue, currentMax)
                self.updateAmountFilter(min: clampedMin, max: currentMax)
            })
    }

    private var amountMaxBinding: Binding<Double> {
        Binding(
            get: {
                self.viewModel.filterAmountMax ?? self.viewModel.doseAmountBounds.upperBound
            },
            set: { newValue in
                let bounds = self.viewModel.doseAmountBounds
                let currentMin = self.viewModel.filterAmountMin ?? bounds.lowerBound
                let clampedMax = max(newValue, currentMin)
                self.updateAmountFilter(min: currentMin, max: clampedMax)
            })
    }

    private func updateAmountFilter(min: Double, max: Double) {
        let bounds = self.viewModel.doseAmountBounds
        let atFullBounds = min <= bounds.lowerBound + DoseHistoryViewModel.amountBoundsEpsilon
            && max >= bounds.upperBound - DoseHistoryViewModel.amountBoundsEpsilon
        if atFullBounds {
            self.viewModel.filterAmountMin = nil
            self.viewModel.filterAmountMax = nil
        } else {
            self.viewModel.filterAmountMin = min
            self.viewModel.filterAmountMax = max
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DoseSearchAndFilterView(viewModel: DoseHistoryViewModel())
    }
}
