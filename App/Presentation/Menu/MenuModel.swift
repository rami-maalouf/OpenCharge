import OpenChargeCore
import OpenChargeFeatures

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
    let favoriteFeatures: [FeatureDescriptor]
    let featureSections: [MenuFeatureSection]
    let health: MenuHealth
    let staticItems = MenuStaticItem.allCases

    init(
        registry: FeatureRegistry,
        settings: SettingsSchema,
        preferences: MenuPreferences = .default,
        loadState: AppLoadState
    ) {
        let configuration = MenuConfiguration(
            registry: registry,
            settings: settings,
            preferences: preferences
        )
        favoriteFeatures = configuration.favoriteFeatures
        featureSections = configuration.sections.map { section in
            MenuFeatureSection(category: section.category, features: section.features)
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
