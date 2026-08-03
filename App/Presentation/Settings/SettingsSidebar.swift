import SwiftUI

struct SettingsSidebar: View {
    @Binding var selection: SettingsSection

    var body: some View {
        List(SettingsSection.allCases) { section in
            Button {
                selection = section
            } label: {
                Label(section.title, systemImage: section.systemImage)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(section.keyboardKey, modifiers: .command)
            .accessibilityIdentifier("settings.sidebar.\(section.rawValue)")
            .listRowBackground(
                selection == section
                    ? Color.accentColor.opacity(0.16)
                    : Color.clear
            )
        }
        .navigationTitle("OpenCharge")
        .listStyle(.sidebar)
    }
}
