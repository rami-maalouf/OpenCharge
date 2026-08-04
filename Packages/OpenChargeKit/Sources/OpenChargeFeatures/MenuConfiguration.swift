import OpenChargeCore

public struct MenuConfigurationSection: Identifiable, Equatable, Sendable {
    public let category: FeatureCategory
    public let features: [FeatureDescriptor]

    public init(category: FeatureCategory, features: [FeatureDescriptor]) {
        self.category = category
        self.features = features
    }

    public var id: FeatureCategory {
        category
    }
}

public struct MenuConfiguration: Equatable, Sendable {
    public let preferences: MenuPreferences
    public let favoriteFeatures: [FeatureDescriptor]
    public let sections: [MenuConfigurationSection]

    public init(
        registry: FeatureRegistry,
        settings: SettingsSchema,
        preferences: MenuPreferences
    ) {
        let sanitizedPreferences = preferences.sanitized(for: registry.descriptors)
        let order = Dictionary(
            uniqueKeysWithValues: sanitizedPreferences.orderedFeatureIDs.enumerated().map {
                ($0.element, $0.offset)
            }
        )
        let visibleFeatures = registry.descriptors
            .filter { descriptor in
                settings.isFeatureEnabled(descriptor.id)
                    && !sanitizedPreferences.hiddenFeatureIDs.contains(descriptor.id)
            }
            .sorted { lhs, rhs in
                let lhsOrder = order[lhs.id] ?? Int.max
                let rhsOrder = order[rhs.id] ?? Int.max
                return lhsOrder == rhsOrder ? lhs.id < rhs.id : lhsOrder < rhsOrder
            }
        let favoriteFeatureIDs = sanitizedPreferences.favoriteFeatureIDs

        self.preferences = sanitizedPreferences
        favoriteFeatures = visibleFeatures.filter { favoriteFeatureIDs.contains($0.id) }
        sections = FeatureCategory.allCases.compactMap { category in
            let features = visibleFeatures.filter {
                $0.category == category && !favoriteFeatureIDs.contains($0.id)
            }
            guard !features.isEmpty else {
                return nil
            }
            return MenuConfigurationSection(category: category, features: features)
        }
    }
}
