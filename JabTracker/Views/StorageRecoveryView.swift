import SwiftUI

struct StorageRecoveryView: View {
    let failure: StorageFailure
    let retry: () -> Void
    @State private var showingSupport = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.largeTitle)
                    .accessibilityHidden(true)
                Text("Can't open saved data")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("storage-recovery-title")
                Text(
                    "You can't log changes until storage is available. JabTracker hasn't deleted your existing data. "
                        + "Try again, or close and reopen the app."
                )
                .accessibilityIdentifier("storage-recovery-message")
                if failure.attemptCount > 1 {
                    Text("Still unable to open saved data after \(failure.attemptCount) attempts.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("storage-retry-failure")
                }
                Button("Try Again", action: retry)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("storage-retry")
                Button("Support Information") { showingSupport = true }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("storage-support")
            }
            .frame(maxWidth: 540, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("storage-recovery")
        .sheet(isPresented: $showingSupport) {
            StorageSupportView(information: failure.supportInformation)
        }
    }
}

private struct StorageSupportView: View {
    let information: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(
                        "Copy or share this information when you contact support. "
                            + "It contains app and storage error details."
                    )
                    Text(information)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                        .accessibilityIdentifier("storage-support-info")
                    Button(copied ? "Copied" : "Copy Information") {
                        UIPasteboard.general.string = information
                        copied = true
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("storage-support-copy")
                    ShareLink("Share Information", item: information)
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("storage-support-share")
                }
                .padding(24)
            }
            .navigationTitle("Support Information")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("storage-support-done")
                }
            }
        }
    }
}
