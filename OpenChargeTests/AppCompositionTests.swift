import AppKit
@testable import OpenCharge
import OpenChargeCore
import OpenChargeSystem
import XCTest

final class AppCompositionTests: XCTestCase {
    @MainActor
    func testModelLoadsInjectedSettingsWithoutRealPreferences() async throws {
        let featureID = try XCTUnwrap(FeatureID(rawValue: "foundation.keep-awake"))
        var settings = SettingsSchema.default
        settings.setFeature(featureID, enabled: true)
        let store: any SettingsStore = InMemorySettingsStore(initial: settings)
        let dependencies = AppDependencies(
            registry: FeatureRegistry(factories: []),
            settingsStore: store,
            hasPersistentSettings: false
        )
        let model = AppModel(dependencies: dependencies)

        await model.load()

        XCTAssertEqual(model.loadState, .loaded)
        XCTAssertTrue(model.settings.isFeatureEnabled(featureID))
        XCTAssertFalse(model.hasPersistentSettings)
    }

    @MainActor
    func testSettingsFailureDoesNotPreventModelConstruction() async {
        let dependencies = AppDependencies(
            registry: FeatureRegistry(factories: []),
            settingsStore: FailingSettingsStore(),
            hasPersistentSettings: false
        )
        let model = AppModel(dependencies: dependencies)

        await model.load()

        XCTAssertEqual(model.loadState, .failed)
        XCTAssertEqual(model.settings, .default)
        XCTAssertTrue(model.registry.descriptors.isEmpty)
    }

    @MainActor
    func testPreviewDependenciesUseInMemorySettings() async {
        let model = AppModel(dependencies: .preview)

        await model.load()

        XCTAssertEqual(model.loadState, .loaded)
        XCTAssertFalse(model.hasPersistentSettings)
    }

    @MainActor
    func testCompositionIncludesBaselineFeatureWithoutActivatingItsAction() async throws {
        let featureID = try XCTUnwrap(FeatureID(rawValue: "foundation.keep-awake"))
        let registry = FeatureRegistry(factories: [
            FeatureFactory(id: featureID) {
                FeatureDescriptor(
                    id: featureID,
                    category: .foundation,
                    titleKey: "Keep Awake",
                    descriptionKey: "Controls whether OpenCharge prevents system sleep.",
                    supportsGlobalShortcut: true,
                    supportsAppIntent: true
                )
            }
        ])
        let store = InMemorySettingsStore()
        let model = AppModel(
            dependencies: AppDependencies(
                registry: registry,
                baselineFeatureIDs: [featureID],
                settingsStore: store,
                hasPersistentSettings: false
            )
        )

        await model.load()

        XCTAssertTrue(model.settings.isFeatureEnabled(featureID))
        XCTAssertEqual(model.keepAwake.configuration, .disabled)
        XCTAssertEqual(model.menu.features.map(\.id), [featureID])
        let storedSettings = await store.snapshot()
        XCTAssertTrue(storedSettings.isFeatureEnabled(featureID))
    }

    @MainActor
    func testApplicationDelegateRunsLaunchHandlerOnlyOnce() {
        let dependencies = AppDependencies.preview
        let delegate = OpenChargeApplicationDelegate()
        var launchCount = 0
        delegate.configure(
            lifecycleController: AppLifecycleController(
                keepAwakeAction: dependencies.keepAwakeAction
            ),
            servicesProvider: ServicesProvider(),
            launchHandler: {
                launchCount += 1
            }
        )

        delegate.applicationDidFinishLaunching(
            Notification(name: NSApplication.didFinishLaunchingNotification)
        )
        delegate.applicationDidFinishLaunching(
            Notification(name: NSApplication.didFinishLaunchingNotification)
        )

        XCTAssertEqual(launchCount, 1)
    }
}

private actor FailingSettingsStore: SettingsStore {
    func snapshot() throws -> SettingsSchema {
        throw TestFailure.expected
    }

    func update(
        _: @Sendable (inout SettingsSchema) throws -> Void
    ) throws -> SettingsSchema {
        throw TestFailure.expected
    }
}

private enum TestFailure: Error {
    case expected
}
