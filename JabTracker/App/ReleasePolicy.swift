enum ReleaseFeature: CaseIterable {
    case subscriptions
    case aiFoodCapture
    case recipes
    case foodFavorites
    case shortcutCustomization
    case dashboardCustomization
    case foodLogCustomization
    case extendedBodyMetrics
    case progressPhotos
    case manualOnboarding
    case helpCenter
    case historicalTDEERecalculation
    case barcodeScannerExtras
}

enum ReleasePolicy {
    static func isEnabled(_ feature: ReleaseFeature) -> Bool {
        switch feature {
        case .subscriptions, .aiFoodCapture, .recipes, .foodFavorites,
            .shortcutCustomization, .dashboardCustomization, .foodLogCustomization,
            .extendedBodyMetrics, .progressPhotos, .manualOnboarding, .helpCenter,
            .historicalTDEERecalculation, .barcodeScannerExtras:
            return false
        }
    }
}
