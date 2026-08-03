import SwiftUI

struct AboutSettingsView: View {
    private let licenseURL = URL(string: "https://github.com/rami-maalouf/OpenCharge/blob/main/LICENSE")!
    private let orbitLabsURL = URL(string: "https://orbitlabs.studio")!
    private let privacyURL = URL(string: "https://github.com/rami-maalouf/OpenCharge/blob/main/PRIVACY.md")!
    private let repositoryURL = URL(string: "https://github.com/rami-maalouf/OpenCharge")!

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text("OpenCharge")
                    .font(.title.bold())
                Text("Version \(version)")
                    .foregroundStyle(.secondary)
            }

            Text("An open-source macOS utility from Orbit Labs.")
                .foregroundStyle(.secondary)

            HStack(spacing: 18) {
                Link("MIT License", destination: licenseURL)
                Link("Privacy", destination: privacyURL)
                Link("OpenCharge Repository", destination: repositoryURL)
                Link("Orbit Labs", destination: orbitLabsURL)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .navigationTitle("About")
        .accessibilityIdentifier("settings.section.about")
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }
}
