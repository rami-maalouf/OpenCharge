import AppKit
import OpenChargeCore
import SwiftUI

struct MenuContentView: View {
    @Environment(\.openSettings) private var openSettings

    let appModel: AppModel

    private var model: MenuModel {
        MenuModel(
            registry: appModel.registry,
            settings: appModel.settings,
            loadState: appModel.loadState
        )
    }

    var body: some View {
        Section("Foundation") {
            Button {
                Task { @MainActor in
                    await appModel.keepAwake.toggle()
                }
            } label: {
                Label(keepAwakeMenuTitle, systemImage: keepAwakeSystemImage)
            }
            .accessibilityLabel("Keep Awake")
            .accessibilityValue(keepAwakeModeTitle)
            .accessibilityIdentifier(AccessibilityID.Menu.keepAwake)
            .disabled(appModel.keepAwake.isUpdating)
        }

        ForEach(model.featureSections) { section in
            Section(section.category.menuTitle) {
                ForEach(section.features) { feature in
                    Button(String(localized: .init(feature.titleKey))) {}
                        .disabled(true)
                }
            }
        }

        if !model.featureSections.isEmpty {
            Divider()
        }

        Button {
            openSettings()
        } label: {
            Label(healthTitle, systemImage: healthSystemImage)
        }
        .accessibilityIdentifier(AccessibilityID.Menu.health)

        Divider()

        Button("Settings...") {
            openSettings()
        }
        .keyboardShortcut(",")
        .accessibilityIdentifier(AccessibilityID.Menu.settings)

        Button("About OpenCharge") {
            NSApplication.shared.orderFrontStandardAboutPanel(nil)
        }
        .accessibilityIdentifier(AccessibilityID.Menu.about)

        Divider()

        Button("Quit OpenCharge") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
        .accessibilityIdentifier(AccessibilityID.Menu.quit)
        .task {
            if appModel.loadState == .idle {
                await appModel.load()
            }
        }
    }

    private var keepAwakeModeTitle: String {
        switch appModel.keepAwake.configuration {
        case .disabled:
            String(localized: "Off")
        case .idleSystem:
            String(localized: "System Sleep")
        case .idleSystemAndDisplay:
            String(localized: "System and Display Sleep")
        }
    }

    private var keepAwakeMenuTitle: String {
        String(localized: "Keep Awake: \(keepAwakeModeTitle)")
    }

    private var keepAwakeSystemImage: String {
        appModel.keepAwake.isEnabled ? "moon.fill" : "moon"
    }

    private var healthTitle: String {
        switch model.health {
        case let .degraded(issueCount):
            if issueCount == 1 {
                String(localized: "Permissions and Health (1 issue)")
            } else {
                String(localized: "Permissions and Health (\(issueCount) issues)")
            }
        case .healthy:
            String(localized: "Permissions and Health")
        case .settingsUnavailable:
            String(localized: "Permissions and Health (Settings Unavailable)")
        }
    }

    private var healthSystemImage: String {
        switch model.health {
        case .degraded, .settingsUnavailable:
            "exclamationmark.shield"
        case .healthy:
            "checkmark.shield"
        }
    }
}

private extension FeatureCategory {
    var menuTitle: String {
        switch self {
        case .developer:
            String(localized: "Developer")
        case .finder:
            String(localized: "Finder")
        case .foundation:
            String(localized: "Foundation")
        case .system:
            String(localized: "System")
        }
    }
}
