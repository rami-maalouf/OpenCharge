# Spec: OpenCharge Foundation + Finder

Status: Draft for human review  
Spec version: 1  
Target platform: macOS 26 or later  
Distribution: Direct download  

## Objective

OpenCharge is an open-source, native macOS utility that removes repetitive friction from everyday Mac use. It is inspired by the utility category and publicly documented capabilities of Supercharge, but it must have an original identity, interface, implementation, copy, defaults, and documentation.

This specification defines the Foundation + Finder product scope. The work begins with a small end-to-end scaffold, then expands into a coherent set of safe foundation actions, Finder actions, macOS Services, settings, permissions, and automation surfaces.

OpenCharge is built for both the maintainer's personal use and public use. The repository must therefore be understandable by new contributors, safe by default, testable without changing the developer's actual Mac settings, and resilient to macOS updates.

### Users

- A Mac owner who wants common utility actions without installing many separate apps.
- A keyboard-oriented user who wants fast access through a menu, global shortcut, Finder, Services, and Apple Shortcuts.
- A contributor who wants to add one feature without understanding every system integration.
- A maintainer who needs OS-sensitive features to fail independently instead of destabilizing the app.

### Primary user stories

1. As a user, I can enable only the capabilities I want.
2. As a user, I can quickly run enabled actions from the menu bar.
3. As a user, I can understand which permissions are needed and recover when one is missing.
4. As a user, I can run safe file actions from Finder and macOS Services.
5. As a user, I can automate stable actions through App Intents.
6. As a contributor, I can implement and test a feature behind a narrow capability boundary.

### Product invariants

- Every capability is opt-in unless it is purely navigational or informational.
- The app launches and opens Settings with no optional permissions granted.
- A failing or unavailable feature cannot prevent unrelated features from loading.
- Features use public and supported macOS APIs unless the user explicitly approves an exception.
- The Finder extension is a separate process and shares only a versioned app-group contract.
- Domain types do not import SwiftUI, AppKit, FinderSync, IOKit, Vision, or ScreenCaptureKit.
- System integrations are accessed through protocols so tests do not manipulate the real Mac.
- Settings and user data stay local. OpenCharge has no accounts, telemetry, or cloud service.
- A user-visible failure provides a useful explanation and recovery action.
- OpenCharge must not copy Supercharge code, binaries, assets, wording, or trade dress.

## Product Identity

- Product name: `OpenCharge`
- Organization: Orbit Labs
- Website namespace: `orbitlabs.studio`
- Main bundle identifier: `studio.orbitlabs.opencharge`
- Finder extension identifier: `studio.orbitlabs.opencharge.finder`
- App group: `group.studio.orbitlabs.opencharge`
- URL scheme: `opencharge://`
- Settings document type: `studio.orbitlabs.opencharge.app-settings`
- License: MIT, pending final human confirmation

The name is a working identity. Existing use of OpenCharge in the electric-vehicle industry must be evaluated before public release.

## Release Scope

The scope is split into milestones so agents can deliver verified vertical slices. A milestone is complete only when its behavior, tests, documentation, and manual verification all pass.

### Milestone 0: Architecture scaffold

- Native menu bar app using `MenuBarExtra`.
- Settings window with General, Menu, Foundation, Finder, Permissions, and About sections.
- Launch at Login using ServiceManagement.
- Typed feature registry with identity, category, availability, enablement, permissions, health, and menu placement.
- Versioned app-group settings shared by the app and Finder extension.
- Permission status and diagnostics model.
- Application composition root with explicit dependency injection.
- Keep Awake as the first complete Foundation feature.
- Copy Path as the first complete Finder and Services feature.
- Get and Set Keep Awake App Intents.
- Unit, integration, and UI test targets.
- Formatting, build, test, and verification scripts.
- README, contributing guide, architecture notes, privacy statement, and MIT license.

### Milestone 1: Foundation actions

| Capability | Required behavior | Integration surface |
| --- | --- | --- |
| Keep Awake | Prevent idle system sleep while enabled, optionally prevent display sleep, show current state, and release all assertions on disable or termination. | Menu, Settings, App Intents |
| Clear Clipboard | Clear all pasteboard contents immediately and report success without retaining clipboard history. | Menu, global shortcut, App Intent |
| Pick Color | Present the native screen color sampler and copy the selected value in a user-selected format: Hex, RGB, or OKLCH. | Menu, global shortcut, App Intent |
| Capture Text | Let the user select a screen region, recognize text on-device, optionally preserve line breaks, and copy the result. | Menu, global shortcut, App Intent |
| Scan Code | Read QR codes and supported barcodes from a selected screen region or clipboard image and present all detected values. | Menu, global shortcut, App Intent |
| Show Desktop | Reveal the desktop and provide a clear unsupported state if no approved implementation is available. | Menu, global shortcut, App Intent |
| Sleep Displays | Sleep connected displays without sleeping the Mac and provide a clear unsupported state if no approved implementation is available. | Menu, global shortcut, App Intent |

Foundation infrastructure also includes:

- One configurable global shortcut to open the OpenCharge menu.
- Per-action global shortcuts where supported.
- Shortcut conflict detection before saving a shortcut.
- Configurable menu order, visibility, favorites, and icon choice.
- A safeguard that prevents hiding the menu bar icon unless another reliable way to open OpenCharge is configured.
- App Intents for stable non-interactive actions, with Get and Set intents for stateful capabilities.
- Settings search for finding features and preferences. This is not the future Universal Command Palette.

### Milestone 2: Finder and Services actions

Safe read-only or additive actions are the initial Finder set:

| Group | Capability | Required behavior |
| --- | --- | --- |
| Copy | Copy Path | Copy absolute POSIX paths, newline-separated for multiple selections. |
| Copy | Copy Filename | Copy names including extensions, newline-separated for multiple selections. |
| Copy | Copy File URL | Copy properly escaped `file://` URLs. |
| Copy | Copy Markdown Link | Copy Markdown links using display names and encoded file URLs. |
| Copy | Copy Contents | Copy the decoded contents of supported text files with a documented size limit. |
| Inspect | File Information | Show file size, image or video dimensions, and created, modified, and added dates when available. |
| Verify | Copy Checksum | Support SHA-256 and SHA-512 initially, stream large files, and report per-file failures. |
| Open | Open in Terminal | Open the selected directory, or the containing directory for files, in a configured supported terminal. |
| Open | Open With | Open selected files or folders in an explicitly configured application. |
| Create | New Text File | Create a uniquely named text file in the selected directory and optionally begin renaming it. |
| Create | New From Template | Copy a user-selected file or directory template without overwriting existing items. |
| Git | Go to Repository Root | Find the nearest containing Git worktree and open its root in Finder. |
| Git | Copy Repository-Relative Path | Copy each selected item's path relative to its Git worktree root. |
| Git | Show on GitHub | Open an HTTPS GitHub remote URL for a tracked selection only after validating the remote and path. |
| Copy | Copy Folder Tree | Copy a deterministic text tree with configurable depth and hidden-file handling. |

Actions that change file location or metadata require stronger safety behavior:

| Capability | Required safety behavior |
| --- | --- |
| Copy To | Never overwrite silently, expose collision policy, show progress for long operations, and support cancellation. |
| Move To | Validate source and destination, never cross volumes without an explicit copy-then-trash strategy, expose collision policy, and support cancellation. |
| Remove Location Metadata | Create a recoverable replacement, preserve the original until success, and report which metadata changed. |
| Remove All Metadata | Show a confirmation describing the data removed, create a recoverable replacement, and preserve image quality where the framework permits. |

Every action that can work as a macOS Service must also be available through Services so it remains usable where Finder Sync does not appear, including many synced folders.

### Milestone 3: Finder keyboard behavior

These capabilities are part of Foundation + Finder, but they follow the safe Finder actions because they require broader event handling and more regression testing:

- Open selected Finder items with Return and rename with `Shift-Return`.
- Cut selected files with `Command-X` and move them with `Command-V`.
- Paste a clipboard image as a PNG file.
- Paste clipboard plain text as a text file.
- Reopen the last closed Finder tab with `Shift-Command-T` when a supported implementation exists.

Each keyboard behavior must be independently enabled per feature, clearly disclose required permissions, avoid intercepting text entry, preserve standard Finder behavior when disabled, and expose a kill switch from Settings.

### Explicitly deferred

- Universal Command Palette.
- Profiles and Rules Engine.
- Workspace Snapshots.
- Safety Center and generalized undo log.
- File Drop Shelf.
- Quick Action Builder.
- Clipboard Workbench.
- Meeting Guardian and Smart Link Router.
- Window button modification and window lifecycle interception.
- Dock, Mission Control, Spaces, notification, media-key, trackpad, Spotlight, and menu bar popover manipulation.
- Auto-quit rules and app activity monitoring.
- Permanent deletion, Flatten Folder, Combine Folders, Unquarantine, and Empty Trash.
- Settings import and export.
- Automatic updates, signing automation, notarization automation, and release publishing.
- App Store distribution or a sandboxed companion.
- Accounts, telemetry, cloud sync, and network services other than opening user-requested URLs.

## Experience Requirements

### Menu bar

- The menu shows enabled favorites first, then enabled actions grouped by category.
- Stateful actions show their current state and never rely on color alone.
- Unavailable actions remain discoverable when useful and explain why they cannot run.
- Settings, permission health, About, and Quit are always reachable.
- Interactive actions show progress or a busy state and support cancellation where meaningful.

### Settings

- General: launch at login, appearance, menu bar icon, and global menu shortcut.
- Menu: search, favorites, visibility, order, and per-action shortcuts.
- Foundation: enablement and configuration for Foundation actions.
- Finder: extension status, action enablement, terminals, applications, destinations, and templates.
- Permissions: status, reason, request or System Settings link, and recovery guidance for every permission.
- About: version, open-source license, privacy statement, repository, and website.

### Permissions

- Never request a permission at launch without direct user intent.
- Explain the exact capability unlocked before presenting a system prompt.
- Re-check status after the app becomes active from System Settings.
- A denied permission affects only dependent features.
- Screen capture, Accessibility, Automation, and Finder extension activation are modeled separately.
- Permission diagnostics must not claim success based only on a previously shown prompt.

### Accessibility and localization

- All controls have useful accessibility labels, values, and hints.
- Keyboard navigation and VoiceOver can reach every setting and action.
- UI supports increased text size without clipping primary controls.
- UI works in light, dark, increased-contrast, and reduced-motion configurations.
- User-facing strings are isolated in a String Catalog from the first release, even if English is initially the only localization.

## Architecture

### Process boundaries

```text
OpenCharge.app
  -> composition and lifecycle
  -> menu bar and Settings UI
  -> App Intents and macOS Services
  -> system capability adapters

OpenChargeFinder.appex
  -> Finder Sync menu construction
  -> selection normalization
  -> dispatch to extension-safe actions

shared app group
  -> versioned settings and feature enablement only
  -> no arbitrary command execution or unbounded operation history
```

The Finder extension must not assume that the main app is running. Long operations that cannot safely finish within the extension process must be handed to the main app through an explicit, validated request contract.

### Modules

`OpenChargeCore` contains pure domain models, feature descriptors, settings contracts, errors, and capability protocols. It has no UI or OS-framework dependencies.

`OpenChargeSystem` implements core protocols using public macOS APIs. Each adapter owns one system concern and is independently replaceable in tests.

`OpenChargeFeatures` contains feature-specific application logic that composes core contracts and system capabilities.

The app target owns composition and SwiftUI presentation. Views receive observable models and actions instead of accessing global system APIs.

The Finder extension owns Finder-specific presentation and translates selections into validated feature inputs. It shares core domain code but does not import app presentation code.

### Core model

```swift
public struct FeatureDescriptor: Identifiable, Sendable {
    public let id: FeatureID
    public let category: FeatureCategory
    public let requiredPermissions: Set<PermissionKind>
    public let supportsGlobalShortcut: Bool
    public let supportsAppIntent: Bool
}

public protocol FeatureAvailabilityChecking: Sendable {
    func availability(for feature: FeatureID) async -> FeatureAvailability
}
```

Stable feature identifiers and shared preference keys are public compatibility contracts. They are changed only with a migration and tests covering older stored values.

### Error model

- Domain errors distinguish invalid input, unavailable capability, missing permission, cancellation, conflict, partial success, and system failure.
- Presentation converts typed errors into concise user-facing messages and recovery actions.
- File batches report successes and failures separately instead of discarding partial results.
- Expected cancellation is not logged as an error.
- Logs use Apple's unified logging with privacy annotations and never include clipboard contents, captured text, file contents, or full paths by default.

## Tech Stack

- Xcode 26.6 or the repository-documented compatible Xcode 26 release.
- Swift 6 in complete concurrency-checking mode.
- macOS deployment target 26.0.
- SwiftUI for menu bar and Settings presentation.
- AppKit only where SwiftUI has no suitable integration.
- FinderSync for the Finder extension.
- AppIntents for Apple Shortcuts integration.
- ServiceManagement for Launch at Login.
- IOKit power assertions for Keep Awake.
- ScreenCaptureKit and Vision for region capture, OCR, and code recognition where applicable.
- CryptoKit for supported cryptographic checksums.
- Swift Testing for domain and integration tests.
- XCTest and XCUITest for application lifecycle and UI tests.
- SwiftFormat for deterministic formatting.
- No third-party runtime dependencies in v1.
- A reviewed, repository-owned Xcode project.

## Commands

Run commands from `/Users/rami/Documents/code/swift/OpenCharge`.

```sh
# format
swiftformat .

# verify formatting without modifying files
swiftformat --lint .

# build the app and embedded extension
xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Debug -destination 'platform=macOS' build

# run unit, integration, and UI tests
xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Debug -destination 'platform=macOS' test

# run package tests while developing core behavior
swift test --package-path Packages/OpenChargeKit

# run only UI tests
xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Debug -destination 'platform=macOS' -only-testing:OpenChargeUITests test

# run the complete repository verification pipeline
./scripts/check.sh

# clean derived products
xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge clean
```

## Project Structure

```text
OpenCharge/
|-- .agents/skills/                  canonical project-local agent skills
|-- .claude/skills/                  relative symlinks to canonical skills
|-- OpenCharge.xcodeproj/            app, extension, and test targets
|-- App/
|   |-- Application/                 composition root and lifecycle
|   |-- Presentation/                menu bar and Settings SwiftUI
|   |-- Intents/                     App Intent declarations
|   |-- Services/                    macOS Service entry points
|   |-- Resources/                   assets, strings, and app metadata
|   `-- OpenCharge.entitlements
|-- Packages/OpenChargeKit/
|   |-- Sources/OpenChargeCore/       pure domain models and contracts
|   |-- Sources/OpenChargeSystem/     public macOS capability adapters
|   |-- Sources/OpenChargeFeatures/   feature application logic
|   `-- Tests/                        package unit and integration tests
|-- FinderExtension/
|   |-- FinderSyncController.swift
|   |-- Actions/
|   |-- Resources/
|   `-- FinderExtension.entitlements
|-- OpenChargeTests/                  app composition tests
|-- OpenChargeUITests/                end-to-end UI flows
|-- docs/
|   |-- specs/                        living product specifications
|   |-- research/                     non-authoritative source research
|   `-- architecture/                 process and capability notes
|-- scripts/                          build and verification entry points
|-- tasks/                            approved implementation plan and task list
|-- README.md
|-- CONTRIBUTING.md
|-- PRIVACY.md
|-- LICENSE
`-- .gitignore
```

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
- Protocols describe capability, such as `KeepAwakeControlling`, instead of ending in `Protocol`.
- Production code contains no force unwraps or `try!`.
- Mutable shared state belongs to an actor or the main actor.
- Files normally contain one primary type.
- Comments are lowercase and explain constraints or intent, not syntax.
- Imports are minimal and alphabetized by SwiftFormat.
- Feature identifiers are stable, namespaced strings.
- Dependencies flow from presentation and system implementations toward domain contracts, never the reverse.

## Testing Strategy

### Unit tests

- Use Swift Testing for feature registry, settings migrations, feature models, text formatting, path handling, checksums, template naming, collision policies, and permission mapping.
- Use in-memory fakes for power assertions, pasteboard, screen capture, preferences, Launch at Login, permissions, workspace opening, and filesystem operations.
- Cover success, disabled, unavailable, denied, cancelled, partial-success, and adapter-error states.
- Every bug fix begins with a failing test at the closest user-observable level.

### Integration tests

- Verify app-group keys and encoded values remain compatible between app and extension.
- Verify Keep Awake creates and releases assertions without leaking handles.
- Verify App Intents and menu actions execute the same feature logic.
- Verify Finder and Services actions normalize identical selections consistently.
- Verify file behavior with one item, multiple items, spaces, Unicode, aliases, packages, hidden files, missing files, large files, and empty selections.
- Verify copy and move collision policies on the same and different volumes without touching user data.
- Verify denied permissions do not stop registry or Settings construction.

### UI and end-to-end tests

- Launch the built `.app` as a user would.
- Verify the menu bar item appears and the app has no unwanted Dock icon.
- Open each Settings section from the menu.
- Enable, configure, execute, and disable representative Foundation and Finder features.
- Verify persisted state survives app restart.
- Verify permission explanations and denied states.
- Verify keyboard navigation, VoiceOver labels, light mode, dark mode, and increased text size.
- Use deterministic test hooks for feature execution that macOS does not reliably expose to XCUITest.
- Manually verify Finder Sync menus, Services, global shortcuts, screen selection, and real permission prompts before the relevant milestone is complete.

### Quality gates

- All deterministic behavior introduced by a task has automated coverage.
- No known failing or flaky tests are accepted.
- `./scripts/check.sh` passes before every task commit.
- Each milestone ends with a clean-checkout build and documented manual test pass.

## Boundaries

### Always

- Keep user-facing capabilities opt-in.
- Use public macOS APIs and document availability constraints.
- Start behavior changes with a user-observable failing test when technically possible.
- Run formatting, build, tests, and relevant manual checks before commits.
- Isolate OS-sensitive behavior behind a narrow protocol and availability check.
- Keep the app usable when permissions or extensions are unavailable.
- Validate file inputs and handle Unicode, spaces, aliases, packages, and missing files.
- Provide collision policies and recovery for file mutations.
- Preserve settings compatibility or provide a tested migration.
- Keep source comments lowercase.
- Use conventional lowercase commits without signatures or co-authors.

### Ask First

- Add a third-party runtime dependency.
- Add a privileged helper, daemon, login-item agent, or root operation.
- Use a private API, undocumented preference, reverse-engineered interface, or shell command as a system integration.
- Add or broaden an entitlement.
- Add permanent deletion, recursive mutation, quarantine removal, or settings import.
- Change bundle identifiers, app group, deployment target, license, or distribution model.
- Add network access, telemetry, accounts, or cloud storage.
- Change CI, signing, notarization, or release publishing.
- Broaden Foundation + Finder scope or implement a deferred differentiator.

### Never

- Copy Supercharge source code, binaries, assets, wording, or trade dress.
- Commit secrets, certificates, provisioning profiles, or developer-team identifiers.
- Request a permission without explaining the exact user-facing reason.
- Perform unrelated work under a granted permission.
- Permanently delete or silently overwrite user data.
- Allow the Finder extension to execute arbitrary shell commands or unvalidated requests.
- Log clipboard contents, captured text, file contents, or full file paths by default.
- Silence a failing test by deleting it or weakening its assertion.
- Manually edit generated changelogs or generated artifacts.
- Couple domain types to UI or OS integration frameworks.

## Success Criteria

The Foundation + Finder release is complete when all conditions below are true:

1. A clean checkout builds with the documented command on the supported Xcode 26 toolchain.
2. The app uses `studio.orbitlabs.opencharge`, the Finder extension uses `studio.orbitlabs.opencharge.finder`, and both use `group.studio.orbitlabs.opencharge` for the versioned shared contract.
3. The app targets macOS 26, launches as a menu bar utility, and does not show an unwanted Dock icon.
4. Launch at Login can be enabled and disabled with visible recovery for errors.
5. Users can search, enable, disable, favorite, reorder, and configure included features.
6. Users cannot make the app unreachable by hiding its menu bar icon without a configured shortcut.
7. Permissions are requested only in response to user intent, and denied permissions affect only dependent features.
8. Every Milestone 1 action satisfies the behavior in its capability table or is removed through an approved spec revision after a documented feasibility result.
9. Every Milestone 2 action satisfies its behavior and safety requirements through both Finder and Services where supported.
10. Every Milestone 3 keyboard behavior is independently opt-in, permission-aware, conflict-tested, and immediately disableable.
11. Keep Awake always releases power assertions when disabled and during clean termination.
12. Clipboard, OCR, QR, and file contents are never retained or logged by OpenCharge.
13. File mutations never overwrite silently and expose partial failures.
14. App Intents and visible UI use the same application logic rather than duplicated implementations.
15. Missing permissions, a disabled Finder extension, or one failing feature never prevents the main app and Settings from launching.
16. Unit, integration, and UI tests pass without known flakiness.
17. SwiftFormat lint passes and all source builds with strict Swift 6 concurrency checks.
18. Light mode, dark mode, increased text size, keyboard navigation, and basic VoiceOver behavior are manually inspected.
19. README and contributor documentation explain setup, architecture, commands, privacy, permissions, feature addition, and Finder debugging.
20. The repository contains the approved open-source license and no secrets or developer-specific signing identifiers.
21. All work is committed in small conventional lowercase commits matching the approved task list.

## Agent Execution Contract

Agents implementing this spec must:

1. Read this specification and the approved `tasks/plan.md` and `tasks/todo.md` before modifying code.
2. Work on one unchecked task at a time and honor its listed files.
3. Surface any conflict between the spec, plan, code, or macOS behavior instead of guessing.
4. Update this living spec first when an approved product decision changes.
5. Add or update tests before completing behavior.
6. Run the task verification command and `./scripts/check.sh` before committing.
7. Mark a task complete only after its acceptance criteria pass.
8. Stop and request approval for every Ask First boundary.

## Open Questions

The following proposed decisions require human confirmation before Phase 2 planning:

1. Confirm `OpenCharge` as the working name while accepting that a naming review is required before public release.
2. Confirm the MIT license.
3. Confirm Universal 2 output for Apple Silicon and Intel Macs that support macOS 26.
4. Confirm direct distribution only for v1.
5. Confirm that Milestones 0 through 3 represent the intended Foundation + Finder scope.
6. Confirm deferring Empty Trash and other destructive actions even though Empty Trash appeared in the original Foundation recommendation.
7. Confirm that Finder keyboard behavior remains in scope after safe Finder actions, rather than being deferred with other fragile integrations.
8. Confirm that Show Desktop and Sleep Displays receive short public-API feasibility tasks and are removed from v1 if no compliant approach is available.

## Research Reference

The feature inventory that informed this scope is stored at `docs/research/supercharge-feature-research-2026-08-02.md`. It is non-authoritative background. This specification is the source of truth for what OpenCharge will build.
