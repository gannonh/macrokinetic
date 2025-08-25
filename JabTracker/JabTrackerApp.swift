import SwiftData
import SwiftUI

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
