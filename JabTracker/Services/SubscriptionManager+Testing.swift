#if DEBUG

  // MARK: - DEBUG: Purchase Result Simulation (for unit tests)

  extension SubscriptionManager {
    enum PurchaseCaseTest {
      case userCancelled, pending, successVerified, successUnverified, unknown
    }

    typealias PurchaseHandlingResult = (errorMessage: String?, didFinish: Bool)

    /// Simulate purchase result handling for tests
    static func simulatePurchaseHandling(for purchaseCase: PurchaseCaseTest) throws
      -> PurchaseHandlingResult
    {
      switch purchaseCase {
      case .userCancelled:
        return (nil, false)
      case .pending:
        return ("Purchase is pending approval", false)
      case .successVerified:
        return (nil, true)
      case .successUnverified:
        throw SubscriptionError.verificationFailed
      case .unknown:
        throw SubscriptionError.purchaseFailed("Unknown result")
      }
    }
  }

#endif
