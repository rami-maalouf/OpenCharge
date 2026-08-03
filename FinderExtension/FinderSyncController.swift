import AppKit
import FinderSync
import OpenChargeCore
import OpenChargeFeatures
import OpenChargeSystem

final class FinderSyncController: FIFinderSync {
    private static let copyPathFeatureID = FeatureID(
        rawValue: "finder.copy-path"
    )

    private let copyPathHandler: FinderCopyPathHandler
    private let selectionNormalizer: FileSelectionNormalizer

    override init() {
        let finderController = FIFinderSyncController.default()
        finderController.directoryURLs = [
            URL(filePath: "/", directoryHint: .isDirectory)
        ]
        copyPathHandler = FinderCopyPathHandler(
            selectionProvider: {
                finderController.selectedItemURLs() ?? []
            }
        )
        selectionNormalizer = FileSelectionNormalizer()
        super.init()
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "OpenCharge")
        guard menuKind == .contextualMenuForItems,
              isCopyPathEnabled,
              hasValidSelection
        else {
            return menu
        }

        let item = NSMenuItem(
            title: String(localized: "Copy Path"),
            action: #selector(FinderCopyPathHandler.copyPath(_:)),
            keyEquivalent: ""
        )
        item.target = copyPathHandler
        item.image = NSImage(
            systemSymbolName: "doc.on.doc",
            accessibilityDescription: String(localized: "Copy Path")
        )
        menu.addItem(item)
        return menu
    }

    private var hasValidSelection: Bool {
        let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
        return !selectionNormalizer.normalize(urls).isEmpty
    }

    private var isCopyPathEnabled: Bool {
        guard let featureID = Self.copyPathFeatureID,
              let defaults = UserDefaults(
                  suiteName: AppGroupSettingsStore.appGroupIdentifier
              )
        else {
            return false
        }

        do {
            let data = defaults.data(
                forKey: AppGroupSettingsStore.settingsKey
            )
            let settings = try SettingsCodec().decode(data)
            let snapshot = try FinderSettingsSnapshot(settings: settings)
            return snapshot.isFeatureEnabled(featureID)
        } catch {
            return false
        }
    }
}
