import OpenChargeCore
import SwiftUI

struct FeatureSettingsRow: View {
    let model: FeatureRowModel
    let onSetEnabled: @Sendable (Bool) -> Void
    let onRecover: @Sendable (FeatureRecovery) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(LocalizedStringKey(model.titleKey))
                        .font(.headline)
                    Text(LocalizedStringKey(model.descriptionKey))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 16)

                Toggle(
                    "",
                    isOn: Binding(
                        get: { model.isEnabled },
                        set: onSetEnabled
                    )
                )
                .labelsHidden()
                .disabled(!model.canChangeEnablement)
                .accessibilityLabel(Text(LocalizedStringKey(model.titleKey)))
                .accessibilityIdentifier("feature.toggle.\(model.id.rawValue)")
            }

            if let availabilityMessageKey = model.availabilityMessageKey {
                statusLabel(
                    key: availabilityMessageKey,
                    systemImage: "exclamationmark.triangle"
                )
            }

            if let healthMessageKey = model.healthMessageKey {
                statusLabel(key: healthMessageKey, systemImage: "waveform.path.ecg")
            }

            if let recovery = model.recovery {
                Button {
                    onRecover(recovery)
                } label: {
                    Text(LocalizedStringKey(recovery.titleKey))
                }
                .accessibilityIdentifier("feature.recovery.\(model.id.rawValue)")
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("feature.row.\(model.id.rawValue)")
    }

    private func statusLabel(key: String, systemImage: String) -> some View {
        Label {
            Text(LocalizedStringKey(key))
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
