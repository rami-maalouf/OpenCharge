public struct ActionProgress: Hashable, Codable, Sendable {
    public let completedUnitCount: Int64
    public let totalUnitCount: Int64?
    public let messageKey: String?

    public init?(
        completedUnitCount: Int64,
        totalUnitCount: Int64? = nil,
        messageKey: String? = nil
    ) {
        guard completedUnitCount >= 0 else {
            return nil
        }
        if let totalUnitCount {
            guard totalUnitCount >= 0, completedUnitCount <= totalUnitCount else {
                return nil
            }
        }

        self.completedUnitCount = completedUnitCount
        self.totalUnitCount = totalUnitCount
        self.messageKey = messageKey
    }

    public var fractionCompleted: Double? {
        guard let totalUnitCount else {
            return nil
        }
        guard totalUnitCount > 0 else {
            return 1
        }
        return Double(completedUnitCount) / Double(totalUnitCount)
    }
}

public enum ActionResult<Output: Hashable & Codable & Sendable>: Hashable, Codable, Sendable {
    case cancelled
    case failure(ActionError)
    case partialSuccess(successes: [Output], failures: [ActionError])
    case success(Output)

    public var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    public var isPartialSuccess: Bool {
        if case .partialSuccess = self {
            return true
        }
        return false
    }

    public var isCancelled: Bool {
        if case .cancelled = self {
            return true
        }
        return false
    }

    public var error: ActionError? {
        if case let .failure(error) = self {
            return error
        }
        return nil
    }
}
