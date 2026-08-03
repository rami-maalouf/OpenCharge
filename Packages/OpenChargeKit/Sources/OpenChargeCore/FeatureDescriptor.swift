public enum FeatureCategory: String, CaseIterable, Codable, Sendable {
    case developer
    case finder
    case foundation
    case system
}

public struct FeatureDescriptor: Identifiable, Hashable, Codable, Sendable {
    public let id: FeatureID
    public let category: FeatureCategory
    public let titleKey: String
    public let descriptionKey: String
    public let requiredPermissions: Set<PermissionKind>
    public let supportsGlobalShortcut: Bool
    public let supportsAppIntent: Bool

    public init(
        id: FeatureID,
        category: FeatureCategory,
        titleKey: String,
        descriptionKey: String,
        requiredPermissions: Set<PermissionKind> = [],
        supportsGlobalShortcut: Bool,
        supportsAppIntent: Bool
    ) {
        self.id = id
        self.category = category
        self.titleKey = titleKey
        self.descriptionKey = descriptionKey
        self.requiredPermissions = requiredPermissions
        self.supportsGlobalShortcut = supportsGlobalShortcut
        self.supportsAppIntent = supportsAppIntent
    }
}
