import OpenChargeCore

public enum FeatureFixtureError: Error, Equatable, Sendable {
    case expectedFactoryFailure
}

public enum FeatureFixtures {
    public static func descriptor(
        id: FeatureID,
        category: FeatureCategory = .foundation,
        titleKey: String = "feature.fixture.title",
        descriptionKey: String = "feature.fixture.description",
        supportsGlobalShortcut: Bool = false,
        supportsAppIntent: Bool = false
    ) -> FeatureDescriptor {
        FeatureDescriptor(
            id: id,
            category: category,
            titleKey: titleKey,
            descriptionKey: descriptionKey,
            supportsGlobalShortcut: supportsGlobalShortcut,
            supportsAppIntent: supportsAppIntent
        )
    }

    public static func factory(
        id: FeatureID,
        category: FeatureCategory = .foundation
    ) -> FeatureFactory {
        FeatureFactory(id: id) {
            descriptor(id: id, category: category)
        }
    }

    public static func failingFactory(id: FeatureID) -> FeatureFactory {
        FeatureFactory(id: id) {
            throw FeatureFixtureError.expectedFactoryFailure
        }
    }
}
