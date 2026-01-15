import Foundation
import os

private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "DeeplinkHandler")

/// Notification name for deeplink navigation requests
extension Notification.Name {
    static let showQuickDoseSheet = Notification.Name("showQuickDoseSheet")
    /// Posted when weekly check-in is completed (accept or decline)
    static let checkInCompleted = Notification.Name("checkInCompleted")
    /// Posted when onboarding is restarted from settings
    static let restartOnboarding = Notification.Name("restartOnboarding")
}

/// Result of deeplink parsing
enum DeeplinkResult {
    case doseLog(scheduledDoseId: UUID)
    case unsupported
}

/// Handles parsing and routing of deeplink URLs for JabTracker
/// Supports jab-tracker:// URL scheme for notification actions
struct DeeplinkHandler {

    /// Parse a deeplink URL and return the appropriate result
    /// - Parameter url: The URL to parse (e.g., jab-tracker://dose/log?scheduledDoseId=<UUID>)
    /// - Returns: DeeplinkResult indicating the action to take
    static func parse(url: URL) -> DeeplinkResult {
        // Validate scheme
        guard url.scheme == "jab-tracker" else {
            logger.warning("Invalid URL scheme: \(url.scheme ?? "nil")")
            return .unsupported
        }

        // Validate host
        guard url.host == "dose" else {
            logger.warning("Invalid URL host: \(url.host ?? "nil")")
            return .unsupported
        }

        // Validate path
        guard url.path == "/log" else {
            logger.warning("Invalid URL path: \(url.path)")
            return .unsupported
        }

        // Parse query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems
        else {
            logger.warning("No query parameters found in URL: \(url)")
            return .unsupported
        }

        // Extract scheduledDoseId
        guard let scheduledDoseIdString = queryItems.first(where: { $0.name == "scheduledDoseId" })?.value,
            !scheduledDoseIdString.isEmpty
        else {
            logger.warning("Missing or empty scheduledDoseId parameter")
            return .unsupported
        }

        // Parse UUID
        guard let scheduledDoseId = UUID(uuidString: scheduledDoseIdString) else {
            logger.warning("Invalid UUID format: \(scheduledDoseIdString)")
            return .unsupported
        }

        logger.info("Successfully parsed dose log deeplink with scheduledDoseId: \(scheduledDoseId)")
        return .doseLog(scheduledDoseId: scheduledDoseId)
    }

    /// Handle a deeplink URL by parsing it and performing the appropriate action
    /// - Parameter url: The URL to handle
    static func handle(url: URL) {
        let result = parse(url: url)

        switch result {
        case .doseLog(let scheduledDoseId):
            logger.info("Handling dose log deeplink for scheduledDoseId: \(scheduledDoseId)")

            // Post notification to trigger QuickDoseSheet presentation
            // ContentView will listen for this notification and present the sheet
            NotificationCenter.default.post(
                name: .showQuickDoseSheet,
                object: nil,
                userInfo: ["scheduledDoseId": scheduledDoseId]
            )

            logger.info("Posted notification to show QuickDoseSheet for scheduled dose: \(scheduledDoseId)")

        case .unsupported:
            logger.warning("Unsupported deeplink: \(url.absoluteString)")
        }
    }
}
