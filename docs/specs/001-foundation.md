# Spec: OpenCharge Foundation and Finder Scaffold

Status: Draft for human review  
Target release: Foundation scaffold  
Target platform: macOS 26 or later

## Objective

OpenCharge is an open-source, native macOS utility that removes everyday friction from macOS. It is inspired by the category and breadth of Supercharge while using an original identity, interface, implementation, and documentation.

This specification covers the first vertical foundation only. It establishes a durable application architecture and proves that architecture with two small, safe capabilities:

1. Keep Awake, implemented across the menu, settings, persistent state, and system adapter.
2. Copy Path, implemented as the first Finder extension action.

The first scaffold is for the maintainer's personal use and for public open-source distribution. It must be approachable for contributors, safe by default, and structured so later Foundation and Finder features can be added without turning the app into a collection of global state and one-off system hooks.

### Users

- A Mac owner who wants small opt-in improvements without installing many separate utilities.
- A contributor who wants to add one feature without understanding every system integration.
- A maintainer who needs fragile macOS integrations to fail independently instead of destabilizing the whole app.

### Invariants

- Every capability is opt-in.
- The app can launch and show settings even when no optional permissions are granted.
- A failing feature cannot prevent unrelated features from loading.
- Destructive Finder operations are outside this scaffold.
- The Finder extension runs as a separate process and shares only explicit app-group state.
- Domain types do not import SwiftUI, AppKit, FinderSync, or IOKit.
- System integration is accessed through protocols so domain and presentation tests do not manipulate the real Mac.
- No private macOS API is used in this scaffold.
- User data and settings remain local.

### Included

- Native menu bar application using `MenuBarExtra`.
- Native settings window with General, Features, Finder, and Permissions sections.
- Launch-at-login setting and adapter.
- Typed feature registry with identifiers, metadata, availability, enablement, and health state.
- Shared app-group preferences suitable for the main app and Finder extension.
- Permission-status model and visible diagnostics surface, without requesting unrelated permissions.
- Global application composition root and dependency injection.
- Keep Awake as the first complete Foundation feature.
- Finder Sync extension with Copy Path as the first complete Finder feature.
- App Intent integration for getting and setting Keep Awake state.
- Unit, integration, and UI test targets.
- Formatting, build, test, and verification scripts.
- Open-source project documentation and MIT license.
- Universal app configuration for Apple Silicon and supported Intel Macs running macOS 26.

### Excluded

- The remaining Supercharge feature catalog.
- Command Palette, Profiles, Rules, Workspace Snapshots, Safety Center, and other differentiators.
- Privileged helpers, daemons, login-item agents, or root access.
- Private APIs and reverse-engineered system interfaces.
- Mission Control, Dock, Spaces, notification, window-button, media-key, and trackpad interception.
- Destructive Finder commands.
- Automatic update infrastructure, signing, notarization, and release publishing.
- Telemetry, accounts, cloud sync, or network services.

## Tech Stack

- Xcode 26.6, build 17F113.
- Swift 6.3.3 in complete concurrency-checking mode.
- macOS deployment target 26.0.
- SwiftUI for the menu bar and settings interface.
- AppKit only where SwiftUI has no suitable system integration.
- FinderSync for the Finder extension.
- AppIntents for Shortcuts integration.
- ServiceManagement for launch at login.
- IOKit power management assertions for Keep Awake.
- Swift Testing for domain and integration tests.
- XCTest and XCUITest for application lifecycle and UI tests.
- SwiftFormat for deterministic formatting.
- No third-party runtime dependencies in the scaffold.
- Manually maintained Xcode project, with project changes reviewed like source code.

## Commands

Run all commands from the repository root.

```sh
# format
swiftformat .

# verify formatting without changing files
swiftformat --lint .

# build the app and Finder extension
xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Debug -destination 'platform=macOS' build

# run all unit, integration, and UI tests
xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Debug -destination 'platform=macOS' test

# run only UI tests
xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Debug -destination 'platform=macOS' -only-testing:OpenChargeUITests test

# run the repository verification pipeline
./scripts/check.sh

# clean derived products
xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge clean
```

## Project Structure

```text
OpenCharge/
├── .agents/skills/                 project-local agent skills
├── .claude/skills/                 symlinks to canonical project-local skills
├── OpenCharge.xcodeproj/           native app, extension, and test targets
├── App/
│   ├── Application/                composition root and lifecycle
│   ├── Presentation/               menu bar and settings SwiftUI
│   ├── Resources/                  assets and app metadata
│   └── OpenCharge.entitlements     main app capabilities
├── Packages/OpenChargeKit/
│   ├── Sources/OpenChargeCore/     pure domain models and protocols
│   ├── Sources/OpenChargeSystem/   public-API macOS adapters
│   └── Tests/                      package unit and integration tests
├── FinderExtension/
│   ├── FinderSyncController.swift  Finder extension entry point
│   ├── CopyPathAction.swift        first safe Finder action
│   ├── Info.plist                  extension declaration
│   └── FinderExtension.entitlements
├── OpenChargeTests/                app composition and persistence tests
├── OpenChargeUITests/              launch, menu, and settings flows
├── docs/
│   ├── specs/                      living product specifications
│   └── architecture/               process boundaries and contributor guides
├── scripts/                        build and verification entry points
├── tasks/                          implementation plan and task list
├── README.md
├── CONTRIBUTING.md
├── LICENSE
└── .gitignore
```

### Component Boundaries

`OpenChargeCore` knows about feature identity, feature state, settings contracts, and permission status. It knows nothing about macOS frameworks or UI.

`OpenChargeSystem` implements core protocols with public macOS APIs. Each adapter owns one system concern, such as power assertions, shared defaults, or launch at login.

The application target owns composition and presentation. Views receive observable models and actions rather than reaching into global system APIs.

The Finder extension owns Finder-specific UI and translates Finder selections into core-compatible inputs. It must not import application presentation code or assume the main app is running.

## Code Style

Use focused types, explicit dependency injection, value semantics for state, and actors or `@MainActor` isolation at ownership boundaries.

```swift
public protocol KeepAwakeControlling: Sendable {
    var isActive: Bool { get async }
    func setActive(_ isActive: Bool) async throws
}

@MainActor
@Observable
final class KeepAwakeModel {
    private let controller: any KeepAwakeControlling

    private(set) var isActive = false
    private(set) var errorMessage: String?

    init(controller: any KeepAwakeControlling) {
        self.controller = controller
    }

    func refresh() async {
        isActive = await controller.isActive
    }
}
```

Conventions:

- Types and protocols use descriptive UpperCamelCase names.
- Methods and properties use lowerCamelCase names.
- Protocols describe capability, such as `KeepAwakeControlling`, instead of appending `Protocol`.
- Production code contains no force unwraps or `try!`.
- Errors are typed where recovery differs and converted to user-facing messages at the presentation boundary.
- Mutable shared state belongs to an actor or the main actor.
- Files normally contain one primary type.
- Comments are lowercase and explain constraints or intent, not syntax.
- Imports are minimal and alphabetized by SwiftFormat.
- Feature identifiers are stable, namespaced strings because persisted settings and App Intents depend on them.

## Testing Strategy

### Unit tests

- Use Swift Testing for feature registry, settings, model, and path-formatting behavior.
- Use in-memory fakes for power assertions, shared preferences, launch at login, and permissions.
- Cover success, disabled, unavailable, and adapter-error states.
- Every bug fix begins with a failing test at the closest user-observable level.

### Integration tests

- Verify shared app-group preference keys remain compatible between app and extension abstractions.
- Verify the real Keep Awake adapter creates and releases its assertion without leaking handles.
- Verify Copy Path correctly handles one item, multiple items, spaces, Unicode, and an empty selection.
- Verify feature failures do not stop registry construction.

### UI and end-to-end tests

- Launch the built `.app` as a user would.
- Verify the menu bar extra appears.
- Open Settings from the menu.
- Verify General, Features, Finder, and Permissions navigation.
- Enable and disable Keep Awake and verify visible state survives reopening Settings.
- Launch a deterministic test hook for the Finder Copy Path action because Finder Sync menu injection is owned and scheduled by macOS and is not reliable inside XCUITest.
- Manually verify the real Finder context menu before marking the scaffold complete.

### Quality expectations

- All deterministic core behavior introduced by the scaffold has tests.
- No known failing or flaky tests are accepted.
- The complete `scripts/check.sh` command must pass before every commit.
- The UI is inspected at normal and increased text sizes in light and dark appearance.

## Boundaries

### Always

- Keep every user-facing capability opt-in.
- Use public macOS APIs unless a later approved spec explicitly allows otherwise.
- Run formatting, build, unit tests, and relevant UI tests before commits.
- Add tests with each behavior change.
- Isolate OS-sensitive code behind a narrow protocol.
- Keep the app usable when permissions are missing.
- Validate file inputs and handle Unicode, spaces, aliases, and missing files.
- Document permissions and failure recovery in user-facing language.
- Preserve settings compatibility or provide an explicit migration.
- Use conventional lowercase commit messages without signatures or co-authors.

### Ask First

- Add any third-party runtime dependency.
- Add a privileged helper, daemon, login-item agent, or root operation.
- Use a private API, undocumented preference, or reverse-engineered system behavior.
- Add or broaden an entitlement.
- Add a destructive file operation.
- Change the bundle identifier, app group, deployment target, license, or distribution model.
- Add network access, telemetry, accounts, or cloud storage.
- Change CI or release-signing configuration.

### Never

- Copy Supercharge source code, binaries, assets, wording, or trade dress.
- Commit secrets, certificates, provisioning profiles, or developer-team identifiers.
- Hide a permission request or perform unrelated work under a granted permission.
- Permanently delete or overwrite user data without an approved spec and recovery design.
- Allow the Finder extension to execute arbitrary shell commands.
- Silence a failing test by deleting it or weakening its assertion.
- Manually edit generated changelogs or generated artifacts.
- Couple domain types to SwiftUI, AppKit, FinderSync, or IOKit.

## Success Criteria

The scaffold is complete when all of the following are true:

1. A clean checkout builds with the documented `xcodebuild` command on Xcode 26.6.
2. `OpenCharge.app` uses the bundle identifier `studio.orbitlabs.opencharge` and deployment target macOS 26.0.
3. The Finder extension uses `studio.orbitlabs.opencharge.finder`.
4. The shared app group is `group.studio.orbitlabs.opencharge`.
5. The app launches as a menu bar utility without an unwanted Dock icon.
6. Settings open from the menu and expose General, Features, Finder, and Permissions sections.
7. Launch at Login can be enabled and disabled, with errors visible to the user.
8. Keep Awake can be enabled and disabled from the menu and Settings.
9. Keep Awake state is exposed through Get and Set App Intents.
10. Keep Awake releases its system assertion when disabled and during clean app termination.
11. The Finder extension builds, registers, and adds a Copy Path context action for selected files and folders.
12. Copy Path writes newline-separated paths for multiple selections and does nothing for an empty selection.
13. The app and extension use one versioned shared-settings contract.
14. Missing permissions or extension activation do not prevent the main app from launching.
15. Unit, integration, and UI tests pass without known flakiness.
16. SwiftFormat lint passes.
17. Light mode, dark mode, increased text size, and basic VoiceOver labeling are manually inspected.
18. README and contributor documentation explain setup, architecture, build, test, privacy, and how to add a feature.
19. The repository contains an MIT license and no secrets or developer-specific signing identifiers.
20. The completed scaffold is committed with a conventional lowercase commit message.

## Open Questions

The following assumptions need human approval before planning and implementation:

1. Confirm `OpenCharge` as the working name despite its existing use in the EV charging industry.
2. Confirm MIT as the open-source license.
3. Confirm Universal 2 support for both Apple Silicon and the remaining Intel Macs supported by macOS 26.
4. Confirm Keep Awake and Finder Copy Path as the two small vertical slices that prove the foundation.
5. Confirm direct distribution only for the foreseeable future.

