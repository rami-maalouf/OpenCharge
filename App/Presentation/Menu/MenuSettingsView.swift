import OpenChargeCore
import SwiftUI

struct MenuSettingsView: View {
    let model: MenuSettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Menu", systemImage: "menubar.rectangle")
                .font(.title2.bold())
                .accessibilityIdentifier(AccessibilityID.Settings.section(.menu))

            Text("Choose favorites, visibility, order, and the menu bar icon.")
                .foregroundStyle(.secondary)

            Picker(
                "Menu bar icon",
                selection: Binding(
                    get: { model.preferences.iconChoice },
                    set: { iconChoice in
                        Task { @MainActor in
                            await model.setIconChoice(iconChoice)
                        }
                    }
                )
            ) {
                ForEach(MenuIconChoice.allCases, id: \.self) { iconChoice in
                    Label(iconChoice.title, systemImage: iconChoice.systemImage)
                        .tag(iconChoice)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 300, alignment: .leading)
            .disabled(model.isSaving)
            .accessibilityIdentifier(AccessibilityID.Settings.menuIcon)

            Divider()

            if model.features.isEmpty {
                ContentUnavailableView(
                    "No Configurable Actions",
                    systemImage: "slider.horizontal.3",
                    description: Text(
                        "Actions appear here when they are included in OpenCharge."
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Actions")
                    .font(.headline)

                Text("Drag rows or use the move buttons to set their menu order.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                List {
                    ForEach(model.features) { feature in
                        MenuSettingsRow(
                            feature: feature,
                            isFavorite: model.isFavorite(feature.id),
                            isVisible: model.isVisible(feature.id),
                            canMoveUp: feature.id != model.features.first?.id,
                            canMoveDown: feature.id != model.features.last?.id,
                            isSaving: model.isSaving,
                            onSetFavorite: { isFavorite in
                                Task { @MainActor in
                                    await model.setFavorite(isFavorite, for: feature.id)
                                }
                            },
                            onSetVisible: { isVisible in
                                Task { @MainActor in
                                    await model.setVisible(isVisible, for: feature.id)
                                }
                            },
                            onMove: { direction in
                                Task { @MainActor in
                                    await model.move(feature.id, direction: direction)
                                }
                            }
                        )
                    }
                    .onMove { source, destination in
                        Task { @MainActor in
                            await model.move(fromOffsets: source, toOffset: destination)
                        }
                    }
                    .moveDisabled(model.isSaving)
                }
                .listStyle(.inset)
            }

            if let errorMessage = model.errorMessage {
                HStack(spacing: 8) {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .accessibilityIdentifier(AccessibilityID.Settings.menuError)

                    Spacer()

                    Button("Dismiss") {
                        model.dismissError()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}

private struct MenuSettingsRow: View {
    let feature: FeatureDescriptor
    let isFavorite: Bool
    let isVisible: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let isSaving: Bool
    let onSetFavorite: (Bool) -> Void
    let onSetVisible: (Bool) -> Void
    let onMove: (MenuMoveDirection) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(feature.titleKey))
                    .font(.headline)
                Text(LocalizedStringKey(feature.descriptionKey))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)

            Button {
                onSetFavorite(!isFavorite)
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
            }
            .buttonStyle(.borderless)
            .disabled(isSaving)
            .accessibilityLabel(isFavorite ? "Remove from Favorites" : "Add to Favorites")
            .accessibilityValue(isFavorite ? "Favorite" : "Not Favorite")
            .accessibilityIdentifier(AccessibilityID.Settings.menuFavorite(feature.id))

            Button {
                onSetVisible(!isVisible)
            } label: {
                Label(
                    isVisible ? "Shown" : "Hidden",
                    systemImage: isVisible ? "eye" : "eye.slash"
                )
            }
            .buttonStyle(.borderless)
            .disabled(isSaving)
            .accessibilityLabel("Show \(Text(LocalizedStringKey(feature.titleKey))) in menu")
            .accessibilityValue(isVisible ? "Shown" : "Hidden")
            .accessibilityIdentifier(AccessibilityID.Settings.menuVisibility(feature.id))

            VStack(spacing: 2) {
                Button {
                    onMove(.up)
                } label: {
                    Image(systemName: "chevron.up")
                }
                .disabled(!canMoveUp || isSaving)
                .accessibilityLabel("Move \(Text(LocalizedStringKey(feature.titleKey))) up")
                .accessibilityIdentifier(AccessibilityID.Settings.menuMoveUp(feature.id))

                Button {
                    onMove(.down)
                } label: {
                    Image(systemName: "chevron.down")
                }
                .disabled(!canMoveDown || isSaving)
                .accessibilityLabel("Move \(Text(LocalizedStringKey(feature.titleKey))) down")
                .accessibilityIdentifier(AccessibilityID.Settings.menuMoveDown(feature.id))
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.Settings.menuRow(feature.id))
    }
}

extension MenuIconChoice {
    var title: String {
        switch self {
        case .bolt:
            String(localized: "Bolt")
        case .boltCircle:
            String(localized: "Bolt in Circle")
        case .gauge:
            String(localized: "Gauge")
        }
    }

    var systemImage: String {
        switch self {
        case .bolt:
            "bolt.fill"
        case .boltCircle:
            "bolt.circle.fill"
        case .gauge:
            "gauge.with.dots.needle.67percent"
        }
    }
}
