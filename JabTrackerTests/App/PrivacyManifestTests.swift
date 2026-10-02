//
//  PrivacyManifestTests.swift
//  JabTrackerTests
//
//  Verifies the privacy manifest and permission purpose strings shipped in the app bundle (KAT-3585).
//

import Foundation
import Testing

@testable import JabTracker

struct PrivacyManifestTests {
    private let appBundle = Bundle(for: DataController.self)

    @Test func appBundleShipsOneRootPrivacyManifestWithAuditedDeclarations() throws {
        let url = try #require(appBundle.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let data = try Data(contentsOf: url)
        let manifest = try #require(
            try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )

        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
        #expect((manifest["NSPrivacyTrackingDomains"] as? [String]) == nil)

        let apis = try #require(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        #expect(apis.count == 1)
        #expect(apis.first?["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults")
        #expect(apis.first?["NSPrivacyAccessedAPITypeReasons"] as? [String] == ["CA92.1"])

        // Collected-data declarations stay absent until the CloudKit policy decision (KAT-3584).
        #expect(manifest["NSPrivacyCollectedDataTypes"] == nil)
    }

    @Test func healthPurposeStringsNameEveryRequestedReadAndWriteType() throws {
        let read = try #require(appBundle.object(forInfoDictionaryKey: "NSHealthShareUsageDescription") as? String)
        for term in ["weight", "height", "body fat", "waist", "biological sex", "date of birth", "active energy"] {
            #expect(read.contains(term), "Health read string is missing \(term)")
        }

        let write = try #require(appBundle.object(forInfoDictionaryKey: "NSHealthUpdateUsageDescription") as? String)
        for term in ["weight", "height", "body fat", "waist"] {
            #expect(write.contains(term), "Health write string is missing \(term)")
        }
        #expect(!write.contains("active energy"))
    }

    @Test func cameraPurposeStringDescribesBarcodeScanning() throws {
        let camera = try #require(appBundle.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String)
        #expect(camera == "MacroKinetic uses your camera to scan food barcodes so you can find nutrition information and log foods.")
    }
}
