//
//  DataController.swift
//  JabTracker
//

import CloudKit
import Foundation
import SwiftData

enum SyncStatus {
    case unknown
    case available
    case unavailable
    case accountNotSignedIn
    case restricted
    case noNetwork
}

@MainActor
class DataController: ObservableObject {
    static let shared = DataController()

    @Published var syncStatus: SyncStatus = .unknown
    @Published var isCloudKitEnabled: Bool = false

    /// Preview container for SwiftUI previews
    static var preview: DataController = {
        let controller = DataController(inMemory: true)

        // Add sample data for previews with unique IDs to avoid conflicts
        let context = controller.container.mainContext

        // Use predictable but unique IDs for previews
        let previewUserID = UUID(uuidString: "12345678-1234-1234-1234-123456789000") ?? UUID()
        let previewMedicationID = UUID(uuidString: "12345678-1234-1234-1234-123456789001") ?? UUID()
        let previewDoseID = UUID(uuidString: "12345678-1234-1234-1234-123456789002") ?? UUID()

        let sampleUser = User(
            id: previewUserID,
            email: "preview@example.com",
            name: "Preview User",
            weight: 70.0,
            weightUnit: "kg",
            timezone: "UTC",
            createdAt: Date())

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
            medication: sampleMedication)

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
            MedicationProfile.self,
        ])

        // Configure CloudKit database for production vs in-memory/testing
        let cloudKitContainerIdentifier = "iCloud.com.gannonhall.JabTracker"
        let isTestEnvironment = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
            ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil
        
        // TEMPORARY: Disable CloudKit to fix authentication issues
        // TODO: Re-enable CloudKit after fixing sync conflicts
        let shouldEnableCloudKit = false // Change to true when CloudKit sync issues are resolved

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: (inMemory || isTestEnvironment || !shouldEnableCloudKit) ? .none : .private(cloudKitContainerIdentifier))

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
            if !inMemory, !isTestEnvironment, shouldEnableCloudKit {
                isCloudKitEnabled = true
                checkCloudKitStatus()
            } else {
                isCloudKitEnabled = false
                syncStatus = .unavailable
            }
        } catch {
            // If CloudKit setup fails, try without CloudKit as fallback
            print("CloudKit setup failed, falling back to local storage: \(error)")
            let fallbackConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory,
                cloudKitDatabase: .none)
            do {
                container = try ModelContainer(for: schema, configurations: [fallbackConfiguration])
                isCloudKitEnabled = false
                syncStatus = .unavailable
            } catch {
                fatalError("Failed to create ModelContainer even without CloudKit: \(error)")
            }
        }
    }

    /// Create a test container with isolated context for testing
    static func testContainer() -> DataController {
        DataController(inMemory: true)
    }

    /// Check CloudKit availability status
    private func checkCloudKitStatus() {
        Task {
            await checkiCloudStatus()
        }
    }

    /// Check if iCloud is available and user is signed in
    @MainActor
    private func checkiCloudStatus() async {
        guard isCloudKitEnabled else {
            syncStatus = .unavailable
            return
        }

        let container = CKContainer(identifier: "iCloud.com.gannonhall.JabTracker")

        do {
            let accountStatus = try await container.accountStatus()

            switch accountStatus {
            case .available:
                syncStatus = .available
            case .noAccount:
                syncStatus = .accountNotSignedIn
            case .restricted:
                syncStatus = .restricted
            case .couldNotDetermine:
                syncStatus = .unknown
            case .temporarilyUnavailable:
                syncStatus = .noNetwork
            @unknown default:
                syncStatus = .unknown
            }
        } catch {
            print("Error checking CloudKit status: \(error)")
            syncStatus = .unavailable
        }
    }

    /// Retry CloudKit setup - useful when user fixes iCloud issues
    func retryCloudKitSetup() {
        guard isCloudKitEnabled else { return }
        checkCloudKitStatus()
    }

    /// Get user-friendly sync status message
    var syncStatusMessage: String {
        switch syncStatus {
        case .unknown:
            return "Checking sync status..."
        case .available:
            return "Syncing with iCloud"
        case .unavailable:
            return "Sync unavailable - using local storage"
        case .accountNotSignedIn:
            return "Sign in to iCloud to sync across devices"
        case .restricted:
            return "iCloud sync restricted"
        case .noNetwork:
            return "No network connection for sync"
        }
    }

    /// Check if data will sync across devices
    var willSyncAcrossDevices: Bool {
        syncStatus == .available
    }
}
