import OpenChargeCore

enum MenuStaticItem: CaseIterable, Equatable {
    case settings
    case permissions
    case about
    case quit
}

enum MenuHealth: Equatable {
    case degraded(issueCount: Int)
    case healthy
    case settingsUnavailable
}

struct MenuFeatureSection: Identifiable, Equatable {
    let category: FeatureCategory
    let features: [FeatureDescriptor]

    var id: FeatureCategory {
        category
    }
}

struct MenuModel {
    let featureSections: [MenuFeatureSection]
    let health: MenuHealth
    let staticItems = MenuStaticItem.allCases

    init(
        registry: FeatureRegistry,
        settings: SettingsSchema,
        loadState: AppLoadState
    ) {
        featureSections = FeatureCategory.allCases.compactMap { category in
            let features = registry.descriptors.filter { descriptor in
                descriptor.category == category && settings.isFeatureEnabled(descriptor.id)
            }
            guard !features.isEmpty else {
                return nil
            }
            return MenuFeatureSection(category: category, features: features)
        }

        if loadState == .failed {
            health = .settingsUnavailable
        } else if registry.issues.isEmpty {
            health = .healthy
        } else {
            health = .degraded(issueCount: registry.issues.count)
        }
    }
}
