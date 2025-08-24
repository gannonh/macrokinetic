import SwiftUI
import SwiftData

@main
struct JabTrackerApp: App {
    let dataController = DataController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(dataController.container)
        }
    }
}
