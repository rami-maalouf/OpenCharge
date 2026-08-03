public enum KeepAwakeConfiguration: String, CaseIterable, Codable, Hashable, Sendable {
    case disabled
    case idleSystem
    case idleSystemAndDisplay

    public var isEnabled: Bool {
        self != .disabled
    }

    public var preventsIdleSystemSleep: Bool {
        self != .disabled
    }

    public var preventsDisplaySleep: Bool {
        self == .idleSystemAndDisplay
    }
}

public struct KeepAwakeState: Hashable, Codable, Sendable {
    public let configuration: KeepAwakeConfiguration

    public init(configuration: KeepAwakeConfiguration) {
        self.configuration = configuration
    }

    public var isEnabled: Bool {
        configuration.isEnabled
    }

    public var preventsIdleSystemSleep: Bool {
        configuration.preventsIdleSystemSleep
    }

    public var preventsDisplaySleep: Bool {
        configuration.preventsDisplaySleep
    }
}

public protocol KeepAwakeControlling: Sendable {
    func currentConfiguration() async -> KeepAwakeConfiguration

    @discardableResult
    func apply(
        _ configuration: KeepAwakeConfiguration
    ) async throws -> KeepAwakeConfiguration
}
