import AppKit
import Observation
import OpenChargeCore
import OpenChargeSystem

struct PermissionCapability: Identifiable {
    let kind: PermissionKind
    let title: String
    let explanation: String
    let checkState: @Sendable () async -> PermissionState
    let requestAccess: (@Sendable () async -> PermissionState)?
    let recoveryTitle: String?
    let recover: (@MainActor @Sendable () -> Void)?

    var id: PermissionKind {
        kind
    }
}

struct PermissionDiagnostic: Identifiable {
    let capability: PermissionCapability
    let state: PermissionState

    var id: PermissionKind {
        capability.kind
    }
}

@MainActor
@Observable
final class PermissionsModel {
    private let capabilities: [PermissionCapability]
    private(set) var states: [PermissionKind: PermissionState]
    private(set) var isRefreshing = false

    var diagnostics: [PermissionDiagnostic] {
        capabilities.map { capability in
            PermissionDiagnostic(
                capability: capability,
                state: states[capability.kind]
                    ?? .unavailable(reasonKey: "permission.status.pending")
            )
        }
    }

    init(capabilities: [PermissionCapability]) {
        self.capabilities = capabilities
        states = [:]
    }

    func refresh() async {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        for capability in capabilities {
            states[capability.kind] = await capability.checkState()
        }
    }

    func requestAccess(for kind: PermissionKind) async {
        guard let capability = capability(for: kind),
              let requestAccess = capability.requestAccess
        else {
            return
        }

        states[kind] = await requestAccess()
    }

    func openRecovery(for kind: PermissionKind) {
        capability(for: kind)?.recover?()
    }

    private func capability(for kind: PermissionKind) -> PermissionCapability? {
        capabilities.first { $0.kind == kind }
    }
}

extension PermissionCapability {
    private static let displayKinds: [PermissionKind] = [
        .screenRecording,
        .accessibility,
        .finderSync,
        .automation
    ]

    static func live(arguments: [String]) -> [Self] {
        let overrides = PermissionStateOverrides(arguments: arguments)
        return displayKinds.map { kind in
            if let state = overrides[kind] {
                return deterministic(kind: kind, state: state)
            }
            return live(kind: kind)
        }
    }

    static var preview: [Self] {
        displayKinds.map { kind in
            deterministic(kind: kind, state: .notDetermined)
        }
    }

    private static func live(kind: PermissionKind) -> Self {
        switch kind {
        case .screenRecording:
            let provider = ScreenRecordingPermissionProvider()
            return capability(
                kind: kind,
                checkState: { await provider.currentState() },
                requestAccess: { await provider.requestAccess() },
                recoveryTitle: String(localized: "Open Screen Recording Settings"),
                recover: {
                    NSWorkspace.shared.open(ScreenRecordingPermissionProvider.recoveryURL)
                }
            )
        case .accessibility:
            let provider = AccessibilityPermissionProvider()
            return capability(
                kind: kind,
                checkState: { await provider.currentState() },
                requestAccess: { await provider.requestAccess() },
                recoveryTitle: String(localized: "Open Accessibility Settings"),
                recover: {
                    NSWorkspace.shared.open(AccessibilityPermissionProvider.recoveryURL)
                }
            )
        case .automation:
            return capability(
                kind: kind,
                checkState: {
                    .unavailable(reasonKey: "permission.automation.notRequired")
                },
                requestAccess: nil,
                recoveryTitle: nil,
                recover: nil
            )
        case .finderSync:
            let provider = FinderExtensionStatusProvider()
            return capability(
                kind: kind,
                checkState: { await provider.currentState() },
                requestAccess: nil,
                recoveryTitle: String(localized: "Manage Finder Extensions"),
                recover: {
                    provider.openManagementInterface()
                }
            )
        }
    }

    private static func deterministic(
        kind: PermissionKind,
        state: PermissionState
    ) -> Self {
        switch kind {
        case .accessibility, .screenRecording:
            capability(
                kind: kind,
                checkState: { state },
                requestAccess: { state },
                recoveryTitle: recoveryTitle(for: kind),
                recover: {}
            )
        case .automation:
            capability(
                kind: kind,
                checkState: { state },
                requestAccess: nil,
                recoveryTitle: nil,
                recover: nil
            )
        case .finderSync:
            capability(
                kind: kind,
                checkState: { state },
                requestAccess: nil,
                recoveryTitle: recoveryTitle(for: kind),
                recover: {}
            )
        }
    }

    private static func capability(
        kind: PermissionKind,
        checkState: @escaping @Sendable () async -> PermissionState,
        requestAccess: (@Sendable () async -> PermissionState)?,
        recoveryTitle: String?,
        recover: (@MainActor @Sendable () -> Void)?
    ) -> Self {
        Self(
            kind: kind,
            title: title(for: kind),
            explanation: explanation(for: kind),
            checkState: checkState,
            requestAccess: requestAccess,
            recoveryTitle: recoveryTitle,
            recover: recover
        )
    }

    private static func title(for kind: PermissionKind) -> String {
        switch kind {
        case .accessibility:
            String(localized: "Accessibility")
        case .automation:
            String(localized: "Automation")
        case .finderSync:
            String(localized: "Finder Integration")
        case .screenRecording:
            String(localized: "Screen Recording")
        }
    }

    private static func explanation(for kind: PermissionKind) -> String {
        switch kind {
        case .accessibility:
            String(
                localized: "Allows explicitly enabled keyboard improvements outside text entry."
            )
        case .automation:
            String(
                localized: "Allows a specific feature to control another app only when that feature needs it."
            )
        case .finderSync:
            String(
                localized: "Adds OpenCharge actions to Finder. Finder controls whether the extension is enabled."
            )
        case .screenRecording:
            String(
                localized: "Allows screen selection, OCR, and QR recognition when you run those actions."
            )
        }
    }

    private static func recoveryTitle(for kind: PermissionKind) -> String? {
        switch kind {
        case .accessibility:
            String(localized: "Open Accessibility Settings")
        case .automation:
            nil
        case .finderSync:
            String(localized: "Manage Finder Extensions")
        case .screenRecording:
            String(localized: "Open Screen Recording Settings")
        }
    }
}

private struct PermissionStateOverrides {
    private let states: [PermissionKind: PermissionState]

    init(arguments: [String]) {
        var values: [PermissionKind: PermissionState] = [:]
        for kind in PermissionKind.allCases {
            let flag = "--ui-permission-\(kind.rawValue)"
            guard let index = arguments.firstIndex(of: flag),
                  arguments.indices.contains(index + 1),
                  let state = Self.state(from: arguments[index + 1])
            else {
                continue
            }
            values[kind] = state
        }
        states = values
    }

    subscript(kind: PermissionKind) -> PermissionState? {
        states[kind]
    }

    private static func state(from value: String) -> PermissionState? {
        switch value {
        case "denied":
            .denied
        case "granted":
            .granted
        case "notDetermined":
            .notDetermined
        case "restricted":
            .restricted
        case "unavailable":
            .unavailable(reasonKey: "permission.test.unavailable")
        default:
            nil
        }
    }
}
