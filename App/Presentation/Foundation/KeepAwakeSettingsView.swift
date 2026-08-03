import OpenChargeCore
import SwiftUI

struct KeepAwakeSettingsView: View {
    let model: KeepAwakeModel

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Keep Awake mode")
                        .font(.headline)
                        .accessibilityIdentifier(AccessibilityID.Settings.keepAwakeMode)

                    modeButton(
                        title: "Off",
                        configuration: .disabled
                    )
                    modeButton(
                        title: "Prevent system sleep",
                        configuration: .idleSystem
                    )
                    modeButton(
                        title: "Prevent system and display sleep",
                        configuration: .idleSystemAndDisplay
                    )
                }
                .disabled(model.isUpdating)

                Text(
                    "Choose whether OpenCharge prevents idle system sleep, or both idle system and display sleep."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } header: {
                Text("Keep Awake")
            } footer: {
                Label(
                    "Available without additional permissions.",
                    systemImage: "checkmark.circle"
                )
            }

            Section("Current Status") {
                HStack(spacing: 10) {
                    if model.isUpdating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: model.isEnabled ? "moon.fill" : "moon")
                            .foregroundStyle(model.isEnabled ? Color.accentColor : Color.gray)
                    }

                    Text(statusTitle)
                        .accessibilityLabel("Keep Awake status")
                        .accessibilityValue(statusTitle)
                        .accessibilityIdentifier(AccessibilityID.Settings.keepAwakeStatus)

                    Spacer()
                }

                if model.error != nil {
                    HStack {
                        Label(
                            "OpenCharge could not update Keep Awake.",
                            systemImage: "exclamationmark.triangle"
                        )
                        .foregroundStyle(.red)

                        Spacer()

                        Button("Try Again") {
                            Task { @MainActor in
                                await model.retry()
                            }
                        }
                        .accessibilityIdentifier(AccessibilityID.Settings.keepAwakeRetry)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Foundation")
        .accessibilityIdentifier(AccessibilityID.Settings.section(.foundation))
    }

    private var statusTitle: String {
        switch model.configuration {
        case .disabled:
            String(localized: "Off")
        case .idleSystem:
            String(localized: "Preventing system sleep")
        case .idleSystemAndDisplay:
            String(localized: "Preventing system and display sleep")
        }
    }

    private func modeButton(
        title: LocalizedStringKey,
        configuration: KeepAwakeConfiguration
    ) -> some View {
        Button {
            setConfiguration(configuration)
        } label: {
            HStack(spacing: 8) {
                Image(
                    systemName: model.configuration == configuration
                        ? "largecircle.fill.circle"
                        : "circle"
                )
                .foregroundStyle(
                    model.configuration == configuration
                        ? Color.accentColor
                        : Color.gray
                )
                Text(title)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.Settings.keepAwakeMode(configuration))
        .accessibilityAddTraits(
            model.configuration == configuration ? .isSelected : []
        )
        .accessibilityValue(
            model.configuration == configuration ? "Selected" : "Not selected"
        )
    }

    private func setConfiguration(
        _ configuration: KeepAwakeConfiguration
    ) {
        guard configuration != model.configuration else {
            return
        }
        Task { @MainActor in
            await model.setConfiguration(configuration)
        }
    }
}
