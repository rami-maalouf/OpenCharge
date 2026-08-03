import AppKit
import OpenChargeCore
import SwiftUI

struct PermissionsView: View {
    let appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                ForEach(appModel.permissions.diagnostics) { diagnostic in
                    PermissionDiagnosticView(
                        diagnostic: diagnostic,
                        requestAccess: {
                            await appModel.permissions.requestAccess(
                                for: diagnostic.capability.kind
                            )
                        },
                        openRecovery: {
                            appModel.permissions.openRecovery(
                                for: diagnostic.capability.kind
                            )
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .task {
            await appModel.refreshPermissions()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSApplication.didBecomeActiveNotification
            )
        ) { _ in
            Task {
                await appModel.didBecomeActive()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(SettingsSection.permissions.title, systemImage: "checkmark.shield")
                .font(.title2.bold())
                .accessibilityIdentifier(
                    AccessibilityID.Settings.section(.permissions)
                )

            Text("OpenCharge checks status silently and requests access only after you choose an action.")
                .foregroundStyle(.secondary)

            Text("Permission issues affect only related features.")
                .font(.callout.weight(.medium))
        }
    }
}

private struct PermissionDiagnosticView: View {
    let diagnostic: PermissionDiagnostic
    let requestAccess: () async -> Void
    let openRecovery: () -> Void

    private var kind: PermissionKind {
        diagnostic.capability.kind
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(diagnostic.capability.title)
                    .font(.headline)

                Spacer()

                Label(statusTitle, systemImage: statusSystemImage)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(statusColor)
                    .accessibilityIdentifier(
                        AccessibilityID.Permissions.status(kind, state: diagnostic.state)
                    )
            }

            Text(diagnostic.capability.explanation)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(
                    AccessibilityID.Permissions.explanation(kind)
                )

            Text(stateGuidance)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)

            if shouldShowActions {
                HStack {
                    if canRequest {
                        Button("Request Access") {
                            Task {
                                await requestAccess()
                            }
                        }
                        .accessibilityIdentifier(
                            AccessibilityID.Permissions.request(kind)
                        )
                    }

                    if let recoveryTitle = diagnostic.capability.recoveryTitle,
                       diagnostic.capability.recover != nil
                    {
                        Button(recoveryTitle, action: openRecovery)
                            .accessibilityIdentifier(
                                AccessibilityID.Permissions.recovery(kind)
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.Permissions.row(kind))
    }

    private var canRequest: Bool {
        guard diagnostic.capability.requestAccess != nil else {
            return false
        }
        return diagnostic.state == .denied || diagnostic.state == .notDetermined
    }

    private var shouldShowActions: Bool {
        diagnostic.state != .granted && (
            canRequest || (
                diagnostic.capability.recoveryTitle != nil
                    && diagnostic.capability.recover != nil
            )
        )
    }

    private var statusTitle: String {
        switch diagnostic.state {
        case .denied:
            String(localized: "Denied")
        case .granted:
            String(localized: "Granted")
        case .notDetermined:
            String(localized: "Not Requested")
        case .restricted:
            String(localized: "Restricted")
        case let .unavailable(reasonKey):
            if reasonKey == "permission.automation.notRequired" {
                String(localized: "Not Currently Required")
            } else if reasonKey == "permission.status.pending" {
                String(localized: "Checking")
            } else {
                String(localized: "Unavailable")
            }
        }
    }

    private var stateGuidance: String {
        switch diagnostic.state {
        case .denied:
            String(localized: "Access is off. Request access or review the setting in System Settings.")
        case .granted:
            String(localized: "Access is available for features that need it.")
        case .notDetermined:
            String(localized: "Review the explanation above, then request access when you are ready.")
        case .restricted:
            String(localized: "This Mac restricts access. Other OpenCharge features remain available.")
        case let .unavailable(reasonKey):
            if reasonKey == "permission.automation.notRequired" {
                String(localized: "No current feature needs Automation. OpenCharge will ask for a specific app only when required.")
            } else if reasonKey == "permission.status.pending" {
                String(localized: "Checking current status without requesting access.")
            } else {
                String(localized: "Status is unavailable. Try the recovery action or return after changing System Settings.")
            }
        }
    }

    private var statusSystemImage: String {
        switch diagnostic.state {
        case .granted:
            "checkmark.circle.fill"
        case .notDetermined:
            "questionmark.circle"
        case .denied, .restricted, .unavailable:
            "exclamationmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch diagnostic.state {
        case .granted:
            .green
        case .notDetermined:
            .secondary
        case .denied, .restricted, .unavailable:
            .orange
        }
    }
}
