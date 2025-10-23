import SwiftData
import SwiftUI

struct MedicationScheduleSection: View {
    @Bindable var viewModel: MedicationProfileViewModel

    var body: some View {
        DesignCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Dose Schedule")
                    .font(DesignTokens.Typography.headline)

                if let schedule = viewModel.activeSchedule {
                    // Schedule summary
                    ScheduleSummaryView(
                        patternType: schedule.patternType,
                        frequency: schedule.patternType == .weekly ? "Once weekly" : "Custom",
                        nextDose: schedule.nextScheduledDose,
                        reminderMinutes: 30,  // Issue #285: Add reminderMinutes to model
                        isPaused: schedule.pausedAt != nil,
                        titrationWarning: viewModel.getTitrationWarning(),
                        onTitrationWarningTap: { viewModel.navigateToTitrationPlan() }
                    )

                    Divider()

                    // Schedule actions
                    VStack(spacing: 12) {
                        Button {
                            viewModel.showScheduleEditSheet = true
                        } label: {
                            Label("Edit Schedule", systemImage: "calendar.badge.clock")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .accessibilityIdentifier("edit-schedule-button")

                        if schedule.pausedAt == nil {
                            Button {
                                viewModel.showPauseScheduleSheet = true
                            } label: {
                                Label("Pause Schedule", systemImage: "pause.circle")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.orange)
                            }
                            .accessibilityIdentifier("pause-schedule-button")
                        } else {
                            Button {
                                Task {
                                    await viewModel.resumeSchedule()
                                }
                            } label: {
                                Label("Resume Schedule", systemImage: "play.circle")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.green)
                            }
                            .accessibilityIdentifier("resume-schedule-button")
                        }

                        Button(role: .destructive) {
                            viewModel.showDeactivateConfirmation = true
                        } label: {
                            Label("Deactivate Schedule", systemImage: "trash")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .accessibilityIdentifier("deactivate-schedule-button")
                    }
                } else {
                    // No schedule
                    Button {
                        viewModel.showScheduleEditSheet = true
                    } label: {
                        Label("Create Dose Schedule", systemImage: "calendar.badge.plus")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityIdentifier("create-schedule-button")
                }
            }
        }
    }
}

struct ScheduleHistorySection: View {
    let historyItems: [ScheduleHistoryItem]

    var body: some View {
        DesignCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Schedule History")
                    .font(DesignTokens.Typography.headline)

                VStack(spacing: 8) {
                    ForEach(historyItems) { historyItem in
                        ScheduleHistoryRow(item: historyItem)
                    }
                }
            }
        }
    }
}
