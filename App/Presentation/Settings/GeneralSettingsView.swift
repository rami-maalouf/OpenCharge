import OpenChargeCore
import SwiftUI

struct GeneralSettingsView: View {
    let appModel: AppModel

    @State private var appearance: String
    @State private var launchAtLoginEnabled: Bool

    init(appModel: AppModel) {
        self.appModel = appModel
        _appearance = State(
            initialValue: Self.appearanceValue(from: appModel.settings)
        )
        _launchAtLoginEnabled = State(
            initialValue: appModel.launchAtLogin.isEnabled
        )
    }

    var body: some View {
        Form {
            Section("Startup") {
                Toggle(
                    "Launch OpenCharge at login",
                    isOn: $launchAtLoginEnabled
                )
                .accessibilityLabel("Launch OpenCharge at login")
                .accessibilityIdentifier(AccessibilityID.Settings.launchAtLogin)
                .disabled(
                    appModel.launchAtLogin.isUpdating
                        || isLaunchAtLoginUnavailable
                )

                if appModel.launchAtLogin.requiresApproval {
                    Label(
                        "Approval is required in System Settings before OpenCharge can launch at login.",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if appModel.launchAtLogin.error != nil {
                    HStack {
                        Label(
                            "OpenCharge could not update Launch at Login.",
                            systemImage: "xmark.circle"
                        )
                        Spacer()
                        Button("Try Again") {
                            appModel.launchAtLogin.retry()
                        }
                    }
                    .foregroundStyle(.red)
                }
            }

            Section("Appearance") {
                Picker("Appearance", selection: $appearance) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Appearance")
                .accessibilityIdentifier(AccessibilityID.Settings.appearance)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
        .accessibilityIdentifier(AccessibilityID.Settings.section(.general))
        .onChange(of: appModel.launchAtLogin.status) { _, _ in
            launchAtLoginEnabled = appModel.launchAtLogin.isEnabled
        }
        .onChange(of: appModel.settings) { _, settings in
            let value = Self.appearanceValue(from: settings)
            if appearance != value {
                appearance = value
            }
        }
        .onChange(of: launchAtLoginEnabled) { _, enabled in
            guard enabled != appModel.launchAtLogin.isEnabled else { return }
            appModel.launchAtLogin.setEnabled(enabled)
            launchAtLoginEnabled = appModel.launchAtLogin.isEnabled
        }
        .onChange(of: appearance) { _, value in
            guard appModel.settings[.appearance] != .string(value) else { return }
            Task { @MainActor in
                await appModel.setSetting(.string(value), for: .appearance)
            }
        }
    }

    private var isLaunchAtLoginUnavailable: Bool {
        if case .unavailable = appModel.launchAtLogin.status {
            return true
        }
        return false
    }

    private static func appearanceValue(
        from settings: SettingsSchema
    ) -> String {
        guard case let .string(value) = settings[.appearance] else {
            return "system"
        }
        return value
    }
}
