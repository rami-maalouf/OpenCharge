import SwiftUI

struct SettingsView: View {
    let appModel: AppModel

    @State private var selection = SettingsSection.general

    var body: some View {
        NavigationSplitView {
            SettingsSidebar(selection: $selection)
                .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 230)
        } detail: {
            detailContent
        }
        .frame(minWidth: 720, minHeight: 480)
        .task {
            if appModel.loadState == .idle {
                await appModel.load()
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection {
        case .general:
            GeneralSettingsView(appModel: appModel)
        case .about:
            AboutSettingsView()
        case .permissions:
            PermissionsView(appModel: appModel)
        case .foundation:
            KeepAwakeSettingsView(model: appModel.keepAwake)
        case .finder:
            FinderSettingsView(model: appModel.finder)
        case .menu:
            MenuSettingsView(model: appModel.menu)
        }
    }

    private var sectionDescription: String {
        switch selection {
        case .general:
            String(localized: "Control how OpenCharge starts and appears.")
        case .menu:
            String(localized: "Choose which actions appear in the menu bar.")
        case .foundation:
            String(localized: "Configure everyday OpenCharge actions.")
        case .finder:
            String(localized: "Configure Finder actions and extension behavior.")
        case .permissions:
            String(localized: "Review permissions and recovery guidance.")
        case .about:
            String(localized: "Learn about OpenCharge, privacy, and this open-source project.")
        }
    }
}
