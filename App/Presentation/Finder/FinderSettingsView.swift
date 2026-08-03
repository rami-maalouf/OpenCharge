import AppKit
import OpenChargeSystem
import SwiftUI

struct FinderSettingsView: View {
    let model: FinderSettingsModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                copyPathCard
                extensionCard
                servicesCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .task {
            await model.load()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSApplication.didBecomeActiveNotification
            )
        ) { _ in
            Task { @MainActor in
                await model.refreshStatus()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(SettingsSection.finder.title, systemImage: "folder")
                .font(.title2.bold())
                .accessibilityIdentifier(
                    AccessibilityID.Settings.section(.finder)
                )

            Text("Configure Finder actions and extension behavior.")
                .foregroundStyle(.secondary)
        }
    }

    private var copyPathCard: some View {
        settingsCard {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Copy Path")
                        .font(.headline)
                    Text(
                        "Copies absolute paths for selected files, folders, and apps. Multiple paths use separate lines."
                    )
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle(
                    "Enable Copy Path",
                    isOn: Binding(
                        get: { model.isCopyPathEnabled },
                        set: { enabled in
                            Task { @MainActor in
                                await model.setCopyPathEnabled(enabled)
                            }
                        }
                    )
                )
                .labelsHidden()
                .disabled(model.isUpdating)
                .accessibilityLabel("Enable Copy Path")
                .accessibilityValue(
                    model.isCopyPathEnabled ? "Enabled" : "Disabled"
                )
                .accessibilityIdentifier(
                    AccessibilityID.Settings.finderCopyPathToggle
                )
            }

            if model.settingsError != nil {
                HStack {
                    Text("OpenCharge could not update the Copy Path setting.")
                        .font(.callout)
                        .foregroundStyle(.orange)

                    Spacer()

                    Button("Try Again") {
                        Task { @MainActor in
                            await model.load()
                        }
                    }
                }
            }
        }
    }

    private var extensionCard: some View {
        settingsCard {
            HStack(alignment: .firstTextBaseline) {
                Text("Finder Extension")
                    .font(.headline)

                Spacer()

                Label(extensionStatusTitle, systemImage: extensionStatusImage)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(extensionStatusColor)
                    .accessibilityLabel("Finder extension status")
                    .accessibilityValue(extensionStatusTitle)
                    .accessibilityIdentifier(
                        AccessibilityID.Settings.finderExtensionStatus
                    )
            }

            Text(extensionGuidance)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Manage Finder Extensions") {
                model.openExtensionManagement()
            }
            .accessibilityIdentifier(
                AccessibilityID.Settings.finderManageExtensions
            )
        }
    }

    private var servicesCard: some View {
        settingsCard {
            Label("Services Fallback", systemImage: "arrow.triangle.branch")
                .font(.headline)

            Text(
                "Finder Sync actions may not appear in iCloud Drive, Dropbox, OneDrive, or other synced folders. Use Services > Copy Path instead."
            )
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier(
                AccessibilityID.Settings.finderServicesFallback
            )

            Text(
                "If Copy Path is missing, enable it in System Settings > Keyboard > Keyboard Shortcuts > Services > Files and Folders."
            )
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier(
                AccessibilityID.Settings.finderServicesSetup
            )
        }
    }

    private func settingsCard(
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                .quaternary.opacity(0.55),
                in: RoundedRectangle(cornerRadius: 12)
            )
    }

    private var extensionStatusTitle: String {
        guard let status = model.extensionStatus else {
            return String(localized: "Checking")
        }
        switch status.installation {
        case .notInstalled:
            return String(localized: "Not Installed")
        case .unavailable:
            return String(localized: "Unavailable")
        case .installed:
            switch status.activation {
            case .enabled:
                return String(localized: "Enabled")
            case .disabled:
                return String(localized: "Disabled")
            case .unavailable:
                return String(localized: "Unavailable")
            }
        }
    }

    private var extensionGuidance: String {
        guard let status = model.extensionStatus else {
            return String(localized: "Checking the Finder extension status.")
        }
        switch status.installation {
        case .notInstalled:
            return String(
                localized: "The Finder extension is not installed in this build. Copy Path remains available through Services."
            )
        case .unavailable:
            return String(
                localized: "OpenCharge could not check the Finder extension. You can review it in System Settings."
            )
        case .installed:
            switch status.activation {
            case .enabled:
                return String(
                    localized: "The extension is enabled. Finder still controls where its menu appears."
                )
            case .disabled:
                return String(
                    localized: "Enable the extension in System Settings to add OpenCharge actions to Finder."
                )
            case .unavailable:
                return String(
                    localized: "OpenCharge could not read extension enablement. Review it in System Settings."
                )
            }
        }
    }

    private var extensionStatusImage: String {
        guard let status = model.extensionStatus else {
            return "clock"
        }
        if status.activation == .enabled {
            return "checkmark.circle.fill"
        }
        return "exclamationmark.circle.fill"
    }

    private var extensionStatusColor: Color {
        model.extensionStatus?.activation == .enabled ? .green : .orange
    }
}
