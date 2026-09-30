extension MetricKey {
    var isAvailableInRelease: Bool {
        switch self {
        case .neck, .chest, .waist, .hip:
            return true
        case .shoulders, .bust,
            .leftBicep, .rightBicep, .leftForearm, .rightForearm, .leftWrist, .rightWrist,
            .leftThigh, .rightThigh, .leftCalf, .rightCalf, .leftAnkle, .rightAnkle,
            .waistToHeight, .waistToHip:
            return ReleasePolicy.isEnabled(.extendedBodyMetrics)
        }
    }
}
