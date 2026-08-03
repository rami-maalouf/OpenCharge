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

        Divider()

        Button("Settings...") {
            openSettings()
        }
        .keyboardShortcut(",")

        Button("About OpenCharge") {
            NSApplication.shared.orderFrontStandardAboutPanel(nil)
        }

        Divider()

        Button("Quit OpenCharge") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
        .task {
            await appModel.load()
        }
    }

    private var healthTitle: String {
        switch model.health {
        case let .degraded(issueCount):
            "Permissions and Health (\(issueCount) issue\(issueCount == 1 ? "" : "s"))"
        case .healthy:
            "Permissions and Health"
        case .settingsUnavailable:
            "Permissions and Health (Settings Unavailable)"
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
            "Developer"
        case .finder:
            "Finder"
        case .foundation:
            "Foundation"
        case .system:
            "System"
        }
    }
}
