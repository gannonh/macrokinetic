//
//  DataController.swift
//  JabTracker
//

import CloudKit
import Foundation
import OSLog
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

    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "DataController")

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
            email: "preview@example.com",
            name: "Preview User",
            weight: 70.0,
            weightUnit: "kg",
            timezone: "UTC")

        let sampleMedication = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60)  // 30 days ago
        )

        let sampleDose = Dose(
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-7 * 24 * 60 * 60),  // 1 week ago
            site: "Abdomen",
            skipped: false)

        context.insert(sampleUser)
        context.insert(sampleMedication)
        context.insert(sampleDose)

        // Set relationships after insertion to avoid duplicate registration
        sampleDose.user = sampleUser
        sampleDose.medication = sampleMedication

        try? context.save()

        return controller
    }()

    let container: ModelContainer

    init(inMemory: Bool = false) {
        let schema = Schema([
            User.self,
            Dose.self,
            MedicationProfile.self,
            DoseTitration.self,
            DoseSchedule.self,
            ScheduledDose.self,
            Food.self,
            FoodEntry.self,
            WeightEntry.self,
        ])

        // Configure CloudKit database for production vs in-memory/testing
        let cloudKitContainerIdentifier = "iCloud.com.gannonhall.JabTracker"

        // Enhanced test environment detection
        let isTestEnvironment =
            ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil

        _ = ProcessInfo.processInfo.arguments.contains("--ui-testing")
        let isCloudKitTesting = ProcessInfo.processInfo.arguments.contains("--cloudkit-testing")

        // CloudKit enabled ONLY for CloudKit integration tests (not regular unit tests)
        let shouldEnableCloudKit = isCloudKitTesting && !isTestEnvironment

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: (inMemory || isTestEnvironment || !shouldEnableCloudKit)
                ? .none
                : .private(cloudKitContainerIdentifier))

        do {
            self.container = try ModelContainer(for: schema, configurations: [configuration])
            if shouldEnableCloudKit {
                self.isCloudKitEnabled = true
                self.checkCloudKitStatus()
            } else {
                self.isCloudKitEnabled = false
                self.syncStatus = .unavailable
            }
        } catch {
            // If CloudKit setup fails, try without CloudKit as fallback
            Self.logger.warning("CloudKit setup failed, falling back to local storage: \(error.localizedDescription)")
            let fallbackConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory,
                cloudKitDatabase: .none)
            do {
                self.container = try ModelContainer(for: schema, configurations: [fallbackConfiguration])
                self.isCloudKitEnabled = false
                self.syncStatus = .unavailable
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
            await self.checkiCloudStatus()
        }
    }

    /// Check if iCloud is available and user is signed in
    @MainActor
    private func checkiCloudStatus() async {
        guard self.isCloudKitEnabled else {
            self.syncStatus = .unavailable
            return
        }

        let container = CKContainer(identifier: "iCloud.com.gannonhall.JabTracker")

        do {
            let accountStatus = try await container.accountStatus()

            switch accountStatus {
            case .available:
                self.syncStatus = .available
            case .noAccount:
                self.syncStatus = .accountNotSignedIn
            case .restricted:
                self.syncStatus = .restricted
            case .couldNotDetermine:
                self.syncStatus = .unknown
            case .temporarilyUnavailable:
                self.syncStatus = .noNetwork
            @unknown default:
                self.syncStatus = .unknown
            }
        } catch {
            Self.logger.error("Error checking CloudKit status: \(error.localizedDescription)")
            self.syncStatus = .unavailable
        }
    }

    /// Retry CloudKit setup - useful when user fixes iCloud issues
    func retryCloudKitSetup() {
        guard self.isCloudKitEnabled else { return }
        self.checkCloudKitStatus()
    }

    /// Get user-friendly sync status message
    var syncStatusMessage: String {
        switch self.syncStatus {
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
        self.syncStatus == .available
    }

    /// Seed test data for titration workflow testing
    /// Creates medication profile with titrations at various stages for manual testing
    @MainActor
    func seedTitrationTestData() {
        let context = container.mainContext

        // Check if titration test data already exists
        let titrationDescriptor = FetchDescriptor<DoseTitration>()
        if let existingTitrations = try? context.fetch(titrationDescriptor), !existingTitrations.isEmpty {
            Self.logger.info("Titration test data already exists, skipping seed")
            return
        }

        // Get existing user (created by --ui-testing or other means)
        let userDescriptor = FetchDescriptor<User>()
        guard let existingUsers = try? context.fetch(userDescriptor),
            let testUser = existingUsers.first
        else {
            Self.logger.warning("No user found - cannot seed titration data")
            return
        }

        Self.logger.info("Seeding titration test data for user: \(testUser.email ?? "unknown")")

        let medication = createTestMedicationProfile(context: context, user: testUser)
        guard let yesterdayDose = createTestDose(context: context, user: testUser, medication: medication) else {
            return
        }
        createTestSchedule(context: context, medication: medication, firstDose: yesterdayDose)
        createTestTitrations(context: context, medication: medication)

        saveTestData(context: context)
    }

    private func createTestMedicationProfile(context: ModelContext, user: User) -> MedicationProfile {
        // Gracefully handle date calculation failure by using current date as fallback
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let medication = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            startDate: startDate
        )
        medication.user = user
        context.insert(medication)
        return medication
    }

    private func createTestDose(context: ModelContext, user: User, medication: MedicationProfile) -> Dose? {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else {
            return nil
        }

        let yesterdayDose = Dose(
            amount: 1.0,
            timestamp: yesterday,
            site: "Abdomen",
            skipped: false
        )
        yesterdayDose.user = user
        yesterdayDose.medication = medication
        context.insert(yesterdayDose)
        return yesterdayDose
    }

    private func createTestSchedule(context: ModelContext, medication: MedicationProfile, firstDose: Dose) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: firstDose.timestamp)

        // Create weekly schedule configuration
        let scheduleConfig = ScheduleConfiguration(
            dayOfWeek: calendar.component(.weekday, from: firstDose.timestamp),
            timeOfDay: TimeComponents(hour: components.hour ?? 9, minute: components.minute ?? 0),
            secondTimeOfDay: nil,  // Not used in sample data
            interval: 7,  // Weekly
            doseAmount: 1.0,
            windowMinutesBefore: 120,  // 2 hours before
            windowMinutesAfter: 120,  // 2 hours after
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        // Encode configuration
        let encoder = JSONEncoder()
        guard let scheduleData = try? encoder.encode(scheduleConfig) else {
            Self.logger.warning("Failed to encode schedule configuration")
            return
        }

        // Create DoseSchedule
        let schedule = DoseSchedule(
            medicationProfile: medication,
            patternType: .weekly,
            baseSchedule: scheduleData,
            isActive: true
        )
        schedule.createdAt = firstDose.timestamp  // Start date = yesterday
        context.insert(schedule)
    }

    private func createTestTitrations(context: ModelContext, medication: MedicationProfile) {
        // Create TODAY titration at start of day (midnight) to trigger confirmation dialog
        // Dialog requires scheduledDate <= Date(), so must be in past/present
        let today = Calendar.current.startOfDay(for: Date())

        let titrationToday = DoseTitration(
            fromDose: 1.0,
            toDose: 2.0,
            scheduledDate: today,
            isCompleted: false
        )
        titrationToday.medicationProfile = medication
        context.insert(titrationToday)

        // Create tomorrow titration at midnight (start of day)
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else {
            Self.logger.warning("Failed to calculate tomorrow's date, skipping remaining titrations")
            return
        }
        let tomorrowMidnight = Calendar.current.startOfDay(for: tomorrow)

        let titrationTomorrow = DoseTitration(
            fromDose: 2.0,
            toDose: 3.0,
            scheduledDate: tomorrowMidnight,
            isCompleted: false
        )
        titrationTomorrow.medicationProfile = medication
        context.insert(titrationTomorrow)

        // Create next week titration at midnight (start of day)
        guard let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) else {
            Self.logger.warning("Failed to calculate next week's date, skipping remaining titrations")
            return
        }
        let nextWeekMidnight = Calendar.current.startOfDay(for: nextWeek)

        let titrationNextWeek = DoseTitration(
            fromDose: 3.0,
            toDose: 4.0,
            scheduledDate: nextWeekMidnight,
            isCompleted: false
        )
        titrationNextWeek.medicationProfile = medication
        context.insert(titrationNextWeek)
    }

    private func saveTestData(context: ModelContext) {
        do {
            try context.save()
            Self.logger.info("Titration test data seeded successfully")
            Self.logger.debug(
                "Seeded: Ozempic 1.0mg, yesterday dose, TODAY (1.0→2.0mg), TOMORROW (2.0→3.0mg), +7d (3.0→4.0mg)"
            )
        } catch {
            Self.logger.error("Failed to seed titration test data: \(error.localizedDescription)")
        }
    }
}
