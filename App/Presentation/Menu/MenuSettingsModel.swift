import Foundation
import Observation
import OpenChargeCore

enum MenuMoveDirection {
    case down
    case up
}

@MainActor
@Observable
final class MenuSettingsModel {
    let registry: FeatureRegistry

    private let settingsStore: any SettingsStore
    private var onSettingsChange: ((SettingsSchema) -> Void)?

    private(set) var errorMessage: String?
    private(set) var isSaving = false
    private(set) var preferences = MenuPreferences.default

    init(
        registry: FeatureRegistry,
        settingsStore: any SettingsStore
    ) {
        self.registry = registry
        self.settingsStore = settingsStore
    }

    var features: [FeatureDescriptor] {
        let order = Dictionary(
            uniqueKeysWithValues: preferences.orderedFeatureIDs.enumerated().map {
                ($0.element, $0.offset)
            }
        )
        return registry.descriptors.sorted { lhs, rhs in
            let lhsOrder = order[lhs.id] ?? Int.max
            let rhsOrder = order[rhs.id] ?? Int.max
            return lhsOrder == rhsOrder ? lhs.id < rhs.id : lhsOrder < rhsOrder
        }
    }

    func configure(onSettingsChange: @escaping (SettingsSchema) -> Void) {
        self.onSettingsChange = onSettingsChange
    }

    func load(from settings: SettingsSchema) {
        preferences = MenuPreferences(settings: settings).sanitized(
            for: registry.descriptors
        )
    }

    func isFavorite(_ id: FeatureID) -> Bool {
        preferences.favoriteFeatureIDs.contains(id)
    }

    func isVisible(_ id: FeatureID) -> Bool {
        !preferences.hiddenFeatureIDs.contains(id)
    }

    func setFavorite(_ isFavorite: Bool, for id: FeatureID) async {
        await updatePreferences { preferences in
            if isFavorite {
                preferences.favoriteFeatureIDs.insert(id)
            } else {
                preferences.favoriteFeatureIDs.remove(id)
            }
        }
    }

    func setVisible(_ isVisible: Bool, for id: FeatureID) async {
        await updatePreferences { preferences in
            if isVisible {
                preferences.hiddenFeatureIDs.remove(id)
            } else {
                preferences.hiddenFeatureIDs.insert(id)
            }
        }
    }

    func setIconChoice(_ iconChoice: MenuIconChoice) async {
        await updatePreferences { preferences in
            preferences.iconChoice = iconChoice
        }
    }

    func move(_ id: FeatureID, direction: MenuMoveDirection) async {
        var orderedFeatureIDs = features.map(\.id)
        guard let sourceIndex = orderedFeatureIDs.firstIndex(of: id) else {
            return
        }
        let destinationIndex = switch direction {
        case .down:
            sourceIndex + 1
        case .up:
            sourceIndex - 1
        }
        guard orderedFeatureIDs.indices.contains(destinationIndex) else {
            return
        }
        orderedFeatureIDs.swapAt(sourceIndex, destinationIndex)
        await setOrder(orderedFeatureIDs)
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) async {
        let currentFeatureIDs = features.map(\.id)
        let movingFeatureIDs = source.sorted().map { currentFeatureIDs[$0] }
        var remainingFeatureIDs = currentFeatureIDs.enumerated().compactMap { index, id in
            source.contains(index) ? nil : id
        }
        let removedBeforeDestination = source.count(where: { $0 < destination })
        let insertionIndex = max(
            0,
            min(destination - removedBeforeDestination, remainingFeatureIDs.count)
        )
        remainingFeatureIDs.insert(contentsOf: movingFeatureIDs, at: insertionIndex)
        await setOrder(remainingFeatureIDs)
    }

    func dismissError() {
        errorMessage = nil
    }

    private func setOrder(_ orderedFeatureIDs: [FeatureID]) async {
        await updatePreferences { preferences in
            preferences.orderedFeatureIDs = orderedFeatureIDs
        }
    }

    private func updatePreferences(
        _ mutation: (inout MenuPreferences) -> Void
    ) async {
        guard !isSaving else {
            return
        }

        let previousPreferences = preferences
        var candidate = preferences
        mutation(&candidate)
        candidate = candidate.sanitized(for: registry.descriptors)
        let persistedPreferences = candidate

        preferences = persistedPreferences
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        do {
            let updatedSettings = try await settingsStore.update { settings in
                persistedPreferences.write(to: &settings)
            }
            preferences = MenuPreferences(settings: updatedSettings).sanitized(
                for: registry.descriptors
            )
            onSettingsChange?(updatedSettings)
        } catch {
            preferences = previousPreferences
            errorMessage = String(
                localized: "OpenCharge could not save the menu configuration. Try again."
            )
        }
    }
}
