//
//  DataController.swift
//  JabTracker
//

import Foundation
import SwiftData

@MainActor
class DataController: ObservableObject {
    static let shared = DataController()
    
    /// Preview container for SwiftUI previews
    static var preview: DataController = {
        let controller = DataController(inMemory: true)
        
        // Add sample data for previews with unique IDs to avoid conflicts
        let context = controller.container.mainContext
        
        // Use predictable but unique IDs for previews
        let previewUserID = UUID(uuidString: "12345678-1234-1234-1234-123456789000")!
        let previewMedicationID = UUID(uuidString: "12345678-1234-1234-1234-123456789001")!
        let previewDoseID = UUID(uuidString: "12345678-1234-1234-1234-123456789002")!
        
        let sampleUser = User(
            id: previewUserID,
            email: "preview@example.com",
            name: "Preview User",
            weight: 70.0,
            weightUnit: "kg",
            timezone: "UTC",
            createdAt: Date()
        )
        
        let sampleMedication = MedicationProfile(
            id: previewMedicationID,
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        )
        
        let sampleDose = Dose(
            id: previewDoseID,
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-7 * 24 * 60 * 60), // 1 week ago
            site: "Abdomen",
            skipped: false,
            user: sampleUser,
            medication: sampleMedication
        )
        
        context.insert(sampleUser)
        context.insert(sampleMedication)
        context.insert(sampleDose)
        
        try? context.save()
        
        return controller
    }()
    
    let container: ModelContainer
    
    init(inMemory: Bool = false) {
        let schema = Schema([
            User.self,
            Dose.self,
            MedicationProfile.self
        ])
        
        // Configure CloudKit database for production vs in-memory
        let cloudKitContainerIdentifier = "iCloud.com.gannonhall.JabTracker"
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : .private(cloudKitContainerIdentifier)
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    /// Create a test container with isolated context for testing
    static func testContainer() -> DataController {
        return DataController(inMemory: true)
    }
}