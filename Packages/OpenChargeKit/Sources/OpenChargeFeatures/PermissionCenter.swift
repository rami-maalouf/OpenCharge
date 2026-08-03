import OpenChargeCore

public struct PermissionResult: Hashable, Sendable {
    public let kind: PermissionKind
    public let state: PermissionState
    public let health: FeatureHealth

    public init(
        kind: PermissionKind,
        state: PermissionState,
        health: FeatureHealth
    ) {
        self.kind = kind
        self.state = state
        self.health = health
    }
}

public struct PermissionSnapshot: Hashable, Sendable {
    public let results: [PermissionResult]

    public init(results: [PermissionResult]) {
        let groupedResults = Dictionary(grouping: results, by: \.kind)
        self.results = groupedResults.keys.sorted(by: Self.sortKinds).map { kind in
            guard let matches = groupedResults[kind], matches.count == 1 else {
                return Self.duplicateProviderResult(for: kind)
            }
            return matches[0]
        }
    }

    public subscript(kind: PermissionKind) -> PermissionResult? {
        results.first { $0.kind == kind }
    }

    private static func duplicateProviderResult(
        for kind: PermissionKind
    ) -> PermissionResult {
        let key = "permission.\(kind.rawValue).duplicateProvider"
        return PermissionResult(
            kind: kind,
            state: .unavailable(reasonKey: key),
            health: .failed(messageKey: key, recovery: nil)
        )
    }

    private static func sortKinds(_ lhs: PermissionKind, _ rhs: PermissionKind) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct FeaturePermissionEvaluation: Hashable, Sendable {
    public let availability: FeatureAvailability
    public let health: FeatureHealth

    public init(
        availability: FeatureAvailability,
        health: FeatureHealth
    ) {
        self.availability = availability
        self.health = health
    }
}

public struct PermissionCenter: Sendable {
    private let providers: [any PermissionProviding]

    public init(providers: [any PermissionProviding]) {
        self.providers = providers
    }

    public func snapshot() async -> PermissionSnapshot {
        await withTaskGroup(of: PermissionResult.self) { group in
            for provider in providers {
                group.addTask {
                    await Self.check(provider)
                }
            }

            var results: [PermissionResult] = []
            for await result in group {
                results.append(result)
            }
            return PermissionSnapshot(results: results)
        }
    }

    public func evaluate(
        descriptor: FeatureDescriptor,
        isEnabled: Bool,
        snapshot: PermissionSnapshot
    ) -> FeaturePermissionEvaluation {
        guard isEnabled else {
            return FeaturePermissionEvaluation(
                availability: .disabled,
                health: .healthy
            )
        }

        let requiredKinds = descriptor.requiredPermissions.sorted {
            $0.rawValue < $1.rawValue
        }
        var requiredResults: [PermissionResult] = []
        for kind in requiredKinds {
            guard let result = snapshot[kind] else {
                let key = "permission.\(kind.rawValue).providerMissing"
                return FeaturePermissionEvaluation(
                    availability: .unsupported(reasonKey: key),
                    health: .failed(messageKey: key, recovery: nil)
                )
            }
            requiredResults.append(result)
        }

        let health = requiredResults.first { !$0.health.isHealthy }?.health ?? .healthy
        guard let missing = requiredResults.first(where: { !$0.state.isGranted }) else {
            return FeaturePermissionEvaluation(
                availability: .available,
                health: health
            )
        }

        if case let .unavailable(reasonKey) = missing.state,
           missing.health.recovery == nil
        {
            return FeaturePermissionEvaluation(
                availability: .unsupported(reasonKey: reasonKey),
                health: health
            )
        }

        return FeaturePermissionEvaluation(
            availability: .missingPermission(
                reasonKey: Self.reasonKey(for: missing),
                recovery: Self.recovery(for: missing)
            ),
            health: health
        )
    }

    private static func check(
        _ provider: any PermissionProviding
    ) async -> PermissionResult {
        let kind = provider.kind
        do {
            let state = try await provider.currentState()
            return PermissionResult(
                kind: kind,
                state: state,
                health: .healthy
            )
        } catch {
            let key = "permission.\(kind.rawValue).checkFailed"
            return PermissionResult(
                kind: kind,
                state: .unavailable(reasonKey: key),
                health: .failed(
                    messageKey: key,
                    recovery: FeatureRecovery(
                        kind: .retry,
                        titleKey: "permission.\(kind.rawValue).retry"
                    )
                )
            )
        }
    }

    private static func reasonKey(for result: PermissionResult) -> String {
        let prefix = "permission.\(result.kind.rawValue)"
        switch result.state {
        case .denied:
            return "\(prefix).denied"
        case .granted:
            return "\(prefix).granted"
        case .notDetermined:
            return "\(prefix).notDetermined"
        case .restricted:
            return "\(prefix).restricted"
        case let .unavailable(reasonKey):
            return reasonKey
        }
    }

    private static func recovery(for result: PermissionResult) -> FeatureRecovery {
        if let recovery = result.health.recovery {
            return recovery
        }
        return FeatureRecovery(
            kind: .openSystemSettings,
            titleKey: "permission.\(result.kind.rawValue).openSettings"
        )
    }
}
