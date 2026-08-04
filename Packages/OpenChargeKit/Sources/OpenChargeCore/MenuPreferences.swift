public enum MenuIconChoice: String, CaseIterable, Codable, Sendable {
    case bolt
    case boltCircle = "bolt-circle"
    case gauge
}

public struct MenuShortcutReference: RawRepresentable, Hashable, Codable, Sendable,
    Comparable, CustomStringConvertible
{
    public let rawValue: String

    public init?(rawValue: String) {
        guard FeatureID(rawValue: rawValue) != nil else {
            return nil
        }
        self.rawValue = rawValue
    }

    public var description: String {
        rawValue
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let value = Self(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid menu shortcut reference."
            )
        }
        self = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct MenuPreferences: Equatable, Codable, Sendable {
    public static let `default` = Self(
        favoriteFeatureIDs: [],
        hiddenFeatureIDs: [],
        orderedFeatureIDs: [],
        iconChoice: .bolt,
        shortcutReferences: [:]
    )

    public var favoriteFeatureIDs: Set<FeatureID>
    public var hiddenFeatureIDs: Set<FeatureID>
    public var orderedFeatureIDs: [FeatureID]
    public var iconChoice: MenuIconChoice
    public var shortcutReferences: [FeatureID: MenuShortcutReference]

    public init(
        favoriteFeatureIDs: Set<FeatureID>,
        hiddenFeatureIDs: Set<FeatureID>,
        orderedFeatureIDs: [FeatureID],
        iconChoice: MenuIconChoice,
        shortcutReferences: [FeatureID: MenuShortcutReference]
    ) {
        self.favoriteFeatureIDs = favoriteFeatureIDs
        self.hiddenFeatureIDs = hiddenFeatureIDs
        self.orderedFeatureIDs = orderedFeatureIDs
        self.iconChoice = iconChoice
        self.shortcutReferences = shortcutReferences
    }

    public init(settings: SettingsSchema) {
        favoriteFeatureIDs = Self.featureIDs(from: settings[.menuFavoriteFeatureIDs])
        hiddenFeatureIDs = Self.featureIDs(from: settings[.menuHiddenFeatureIDs])
        orderedFeatureIDs = Self.orderedFeatureIDs(from: settings[.menuOrderedFeatureIDs])
        if case let .string(rawIconChoice) = settings[.menuIconChoice],
           let iconChoice = MenuIconChoice(rawValue: rawIconChoice)
        {
            self.iconChoice = iconChoice
        } else {
            iconChoice = Self.default.iconChoice
        }
        shortcutReferences = Self.shortcutReferences(
            from: settings[.menuShortcutReferences]
        )
    }

    public func sanitized(for descriptors: [FeatureDescriptor]) -> Self {
        let knownFeatureIDs = Set(descriptors.map(\.id))
        let shortcutFeatureIDs = Set(
            descriptors.lazy
                .filter(\.supportsGlobalShortcut)
                .map(\.id)
        )
        var seenOrderedFeatureIDs: Set<FeatureID> = []

        return Self(
            favoriteFeatureIDs: favoriteFeatureIDs.intersection(knownFeatureIDs),
            hiddenFeatureIDs: hiddenFeatureIDs.intersection(knownFeatureIDs),
            orderedFeatureIDs: orderedFeatureIDs.filter { id in
                knownFeatureIDs.contains(id) && seenOrderedFeatureIDs.insert(id).inserted
            },
            iconChoice: iconChoice,
            shortcutReferences: shortcutReferences.filter { featureID, _ in
                shortcutFeatureIDs.contains(featureID)
            }
        )
    }

    public func write(to settings: inout SettingsSchema) {
        settings[.menuFavoriteFeatureIDs] = .stringList(
            favoriteFeatureIDs.sorted().map(\.rawValue)
        )
        settings[.menuHiddenFeatureIDs] = .stringList(
            hiddenFeatureIDs.sorted().map(\.rawValue)
        )
        settings[.menuOrderedFeatureIDs] = .stringList(
            orderedFeatureIDs.map(\.rawValue)
        )
        settings[.menuIconChoice] = .string(iconChoice.rawValue)
        settings[.menuShortcutReferences] = .stringList(
            shortcutReferences.keys.sorted().compactMap { featureID in
                shortcutReferences[featureID].map {
                    "\(featureID.rawValue)=\($0.rawValue)"
                }
            }
        )
    }

    private static func featureIDs(from value: SettingsValue?) -> Set<FeatureID> {
        Set(orderedFeatureIDs(from: value))
    }

    private static func orderedFeatureIDs(from value: SettingsValue?) -> [FeatureID] {
        guard case let .stringList(rawFeatureIDs) = value else {
            return []
        }
        return rawFeatureIDs.compactMap(FeatureID.init(rawValue:))
    }

    private static func shortcutReferences(
        from value: SettingsValue?
    ) -> [FeatureID: MenuShortcutReference] {
        guard case let .stringList(rawReferences) = value else {
            return [:]
        }

        return rawReferences.reduce(into: [:]) { references, rawReference in
            let components = rawReference.split(
                separator: "=",
                maxSplits: 1,
                omittingEmptySubsequences: false
            )
            guard components.count == 2,
                  let featureID = FeatureID(rawValue: String(components[0])),
                  let shortcutReference = MenuShortcutReference(
                      rawValue: String(components[1])
                  )
            else {
                return
            }
            references[featureID] = shortcutReference
        }
    }
}
