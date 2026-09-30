import SwiftUI

struct FoodDataSettingsView: View {
    private let notices = FoodDataNotices.load()
    @State private var provenance: FoodDatabaseProvenance?

    var body: some View {
        List {
            if let notices {
                ForEach(notices.sources) { source in
                    Section(source.title) {
                        Text(source.notice)
                            .accessibilityIdentifier("food-data-\(source.id)-notice")
                        ForEach(source.links, id: \.url) { link in
                            Link(link.label, destination: link.url)
                        }
                    }
                }
                Section("Images and other rights") {
                    Text(notices.imageNotice)
                        .accessibilityIdentifier("food-data-image-notice")
                }
            } else {
                Section("Sources") {
                    Text("Food-source notices are unavailable in this build.")
                }
            }
            Section("Bundled database") {
                if let provenance {
                    switch provenance {
                    case .matched(let manifest):
                        Text("The database checksum matches the bundled build manifest.")
                            .accessibilityIdentifier("food-data-provenance-status")
                        detail("Dataset built", manifest.createdAt)
                        detail("Build mode", manifest.buildMode)
                        detail("Food records", String(manifest.totalRows))
                        detail("Source commit", manifest.commitSHA)
                        detail("Workflow run", manifest.workflowRunID)
                        detail("SHA-256", manifest.databaseSHA256)
                        ForEach(manifest.usdaURLs.keys.sorted(), id: \.self) { source in
                            if let url = manifest.usdaURLs[source] {
                                let name = source == "sr_legacy" ? "SR Legacy" : "Foundation"
                                Link("USDA \(name) source dataset", destination: url)
                            }
                        }
                        Link("Open Food Facts source export", destination: manifest.offFullExportURL)
                    case .unavailable(let checksum, let reason):
                        Text(reason)
                            .accessibilityIdentifier("food-data-provenance-status")
                        if let checksum { detail("SHA-256", checksum) }
                    }
                } else {
                    ProgressView("Checking database checksum…")
                        .accessibilityIdentifier("food-data-provenance-loading")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Food data")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("food-data-settings-view")
        .task {
            let databaseURL = Bundle.main.url(forResource: "usda_foods", withExtension: "sqlite")
            let manifestURL = Bundle.main.url(forResource: "food-db-manifest", withExtension: "json")
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            let inspection = Task.detached(priority: .utility) {
                FoodDatabaseProvenance.inspect(
                    databaseURL: databaseURL, manifestURL: manifestURL, version: version, build: build
                )
            }
            let result = await withTaskCancellationHandler {
                await inspection.value
            } onCancel: {
                inspection.cancel()
            }
            guard !Task.isCancelled else { return }
            provenance = result
        }
    }

    private func detail(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).textSelection(.enabled)
        }
        .accessibilityElement(children: .combine)
    }
}
