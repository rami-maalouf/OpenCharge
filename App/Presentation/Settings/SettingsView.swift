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
        case .menu, .foundation, .finder, .permissions:
            VStack(alignment: .leading, spacing: 12) {
                Label(selection.title, systemImage: selection.systemImage)
                    .font(.title2.bold())
                    .accessibilityIdentifier("settings.section.\(selection.rawValue)")

                Text(sectionDescription)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
        }
    }

    private var sectionDescription: String {
        switch selection {
        case .general:
            "Control how OpenCharge starts and appears."
        case .menu:
            "Choose which actions appear in the menu bar."
        case .foundation:
            "Configure everyday OpenCharge actions."
        case .finder:
            "Configure Finder actions and extension behavior."
        case .permissions:
            "Review permissions and recovery guidance."
        case .about:
            "Learn about OpenCharge, privacy, and this open-source project."
        }
    }
}
