Fix theswe failing tests:

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/DataControllerBasicTests.swift:22 dataControllerSharedInstance(): Expectation failed: (shared1.container.schema.entities.count → 6) == 4 - Should have 4 entities (User, Dose, MedicationProfile, DoseTitration)

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/DataControllerBasicTests.swift:37 dataControllerTestContainer(): Expectation failed: (testController.container.schema.entities.count → 6) == 4 - // Test container should have correct schema - Should have 4 entities

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/DataControllerBasicTests.swift:61 dataControllerCloudKitInit(): Expectation failed: (productionStyleController.container.schema.entities.count → 6) == 4 - // Should attempt CloudKit setup - Should have 4 entities

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/DataControllerBasicTests.swift:87 dataControllerSchemaValidation(): Expectation failed: (schema.entities.count → 6) == 4 - // Test schema has correct number of entities - Should have exactly 4 entities in schema

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/DataControllerCloudKitTests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/DataControllerCloudKitTests.swift:102 dataControllerContainerSchemaValidation(): Expectation failed: (controller.container.schema.entities.count → 6) == 4 - // Test that container has correct schema regardless of CloudKit state - Container should have 4 entities

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/DoseEventTests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/DoseEventTests.swift:156 createFromSkippedScheduledDose(): Expectation failed: !((event → DoseEvent(id: 5CA4590B-6147-47A4-A135-37AE0027E9AE, timestamp: 2025-10-05 18:13:48 +0000, type: JabTracker.DoseEventType.skipped, scheduledDose: Optional(JabTracker.ScheduledDose), actualDose: nil, doseAmount: 0.5, adherenceStatus: JabTracker.DoseAdherenceStatus.adherent)).isAdherent → true → true)

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/JabTrackerTests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/JabTrackerTests.swift:20 appComponentInitialization(): Expectation failed: (dataController.container.schema.entities.count → 6) == 4 - // Test that the data controller has the expected schema (User, Dose, MedicationProfile, DoseTitration)

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/PersistenceTests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/PersistenceTests.swift:16 dataControllerInit(): Expectation failed: (controller.container.schema.entities.count → 6) == 4

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/PersistenceTests.swift:43 previewDataController(): Expectation failed: (previewStyleController.container.schema.entities.count → 6) == 4

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/ScheduledDoseTests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/ScheduledDoseTests.swift:195 testIsInWindowEdgeEnd(): Expectation failed: (scheduledDose.isInWindow → false) == true

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/ScheduledDoseTests.swift:422 testInstantaneousWindow(): Expectation failed: (scheduledDose.isInWindow → false) == true
