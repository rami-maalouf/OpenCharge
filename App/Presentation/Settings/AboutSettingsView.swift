import SwiftUI

struct AboutSettingsView: View {
    @Environment(\.openURL) private var openURL

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
                    .accessibilityIdentifier(AccessibilityID.Settings.section(.about))
                Text("Version \(version)")
                    .foregroundStyle(.secondary)
            }

            Text("An open-source macOS utility from Orbit Labs.")
                .foregroundStyle(.secondary)

            HStack(spacing: 18) {
                Button("MIT License") {
                    openURL(licenseURL)
                }
                .buttonStyle(.link)
                .accessibilityAddTraits(.isLink)
                .accessibilityLabel("MIT License")
                .accessibilityIdentifier(AccessibilityID.Settings.aboutLicense)
                Button("Privacy") {
                    openURL(privacyURL)
                }
                .buttonStyle(.link)
                .accessibilityAddTraits(.isLink)
                .accessibilityLabel("Privacy")
                .accessibilityIdentifier(AccessibilityID.Settings.aboutPrivacy)
                Button("OpenCharge Repository") {
                    openURL(repositoryURL)
                }
                .buttonStyle(.link)
                .accessibilityAddTraits(.isLink)
                .accessibilityLabel("OpenCharge Repository")
                .accessibilityIdentifier(AccessibilityID.Settings.aboutRepository)
                Button("Orbit Labs") {
                    openURL(orbitLabsURL)
                }
                .buttonStyle(.link)
                .accessibilityAddTraits(.isLink)
                .accessibilityLabel("Orbit Labs")
                .accessibilityIdentifier(AccessibilityID.Settings.aboutWebsite)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .navigationTitle("About")
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }
}
