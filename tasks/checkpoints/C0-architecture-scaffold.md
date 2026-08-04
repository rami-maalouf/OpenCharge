# C0 Architecture Scaffold Checkpoint

Status: complete

Last updated: 2026-08-04

Milestone 0 is implemented and verified. Automated, foreground, Finder, Services, App Intents, appearance, accessibility, power-lifecycle, Release, and Universal 2 checks pass on the target platform.

## Automated evidence

| Check | Command | Result |
| --- | --- | --- |
| Full check | `./scripts/check.sh` | Passed on 2026-08-04, including formatting, package tests, debug test build, app-hosted tests, and all 9 UI tests. |
| Formatting | `swiftformat --lint .` | Passed with 0 of 109 files requiring formatting. |
| Package tests | `swift test --package-path Packages/OpenChargeKit` | Passed all package tests, including cross-surface Keep Awake observation. |
| Debug test build | `xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Debug -destination 'platform=macOS' build-for-testing` | Passed, including the app, Finder extension, app tests, and UI test bundle. |
| App-hosted unit tests | `xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Debug -destination 'platform=macOS' -skip-testing:OpenChargeUITests test-without-building` | Passed all app-hosted tests, including external Keep Awake action synchronization and termination cleanup. |
| Release build | `xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Release -destination 'generic/platform=macOS' build` | Passed again after the final C0 fix on 2026-08-04. |
| Universal binaries | `./scripts/verify-universal.sh` | Passed after the final Release build for the app and Finder extension with `arm64` and `x86_64` slices. |

## Automated behavior coverage

- [x] Shared settings migrate, round-trip, and update atomically.
- [x] Feature identity, registry ordering, availability, health, and permission state are typed and deterministic.
- [x] Keep Awake uses one action across the app and App Intents.
- [x] Keep Awake releases owned assertions on disable, failure rollback, deinitialization, and application termination.
- [x] Copy Path normalizes Finder and Services selections through shared logic.
- [x] Copy Path preserves input order, spaces, Unicode, packages, aliases, and symbolic links.
- [x] Pasteboard writes clear stale types and retain no copied values or history.
- [x] Finder extension disabled, enabled, unavailable, and not-installed models are covered.
- [x] Permission checks do not request access until the user explicitly acts.
- [x] The main app remains constructible with an unavailable persistent settings container.

## Foreground verification checklist

Foreground verification ran on macOS 26.5.2 (25F84), on a MacBook Pro with one active built-in 3456 x 2234 Liquid Retina XDR display. No external display was online.

- [x] Menu inspection exposed Keep Awake, permission health, Settings, About, and Quit. Static-item assertions and the real status item passed UI automation.
- [x] General, Menu, Foundation, Finder, Permissions, and About opened by Command-1 through Command-6. Sidebar state, window bounds, focus behavior, truncation, and scroll reachability passed automated checks and screenshot inspection.
- [x] Keep Awake changed between Off, System Sleep, and System and Display Sleep. Settings and the menu immediately reported the same observed state.
- [x] Shortcuts discovered Get Keep Awake Mode and Set Keep Awake Mode from a signed app. Get returned Off, Set created the named `OpenCharge Keep Awake` assertion, and Set Off removed it. The app now observes changes applied through App Intents, covered by commit `b7c9f97`.
- [x] Finder Sync was enabled for a disposable fixture and copied a file, folder, app package, names with spaces, Unicode names, and an ordered multiple selection exactly.
- [x] Services > Copy Path copied the same local fixture with exactly the same newline-delimited output and input order.
- [x] The Services fallback copied an iCloud Drive fixture where the Finder Sync action was unavailable.
- [x] With Finder Sync disabled, the app, every Settings route, Keep Awake, and the Services fallback remained usable. Finder guidance reported the disabled state and its recovery route.
- [x] Screen Recording and Accessibility were left denied or unresolved. Their explanations and recovery actions remained visible while General, Foundation, Finder, and About stayed usable.
- [x] The menu and all six Settings routes passed UI automation and screenshot inspection in Light appearance without illegible contrast, clipping, or unreachable controls.
- [x] The menu and all six Settings routes passed UI automation and screenshot inspection in Dark appearance without illegible contrast, clipping, or unreachable controls.
- [x] Preferred reading size was increased from Default to 13 pt. All six routes remained reachable and readable; the system setting was restored to Default afterward.
- [x] The Quit command terminated the app, and Keep Awake lifecycle coverage terminated an enabled app. A final `pmset -g assertions` check contained no OpenCharge-owned power assertion.

## Session cleanup

- The temporary Shortcuts workflow was deleted and the Shortcuts library returned from 24 to 23 items.
- Finder Sync and Services > Files and Folders > Copy Path were restored to their original disabled state.
- System appearance was restored to Dark and preferred reading size to Default.
- Disposable local, iCloud Drive, signed-build, and screenshot fixtures were moved to Trash after evidence was recorded.

## Completion rule

`C0-01` is complete because every foreground item above has evidence, `./scripts/check.sh` passes in a dedicated desktop session, and the final Release and Universal 2 checks pass.
