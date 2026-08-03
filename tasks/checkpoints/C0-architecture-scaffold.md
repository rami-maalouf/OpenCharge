# C0 Architecture Scaffold Checkpoint

Status: foreground verification pending

Last updated: 2026-08-03

Milestone 0 is implemented and its non-interactive verification passes. This checkpoint remains open because Finder, Services, and appearance checks require control of the active macOS session. Those checks are intentionally deferred while the computer is in use.

## Automated evidence

| Check | Command | Result |
| --- | --- | --- |
| Formatting | `swiftformat --lint .` | Passed with 0 files requiring formatting. |
| Package tests | `swift test --package-path Packages/OpenChargeKit` | Passed all 94 tests in 21 suites. |
| Debug test build | `xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Debug -destination 'platform=macOS' build-for-testing` | Passed, including the app, Finder extension, app tests, and UI test bundle. |
| App-hosted unit tests | `xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Debug -destination 'platform=macOS' -skip-testing:OpenChargeUITests test-without-building` | Passed all app-hosted tests without running UI automation. |
| Release build | `xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Release -destination 'generic/platform=macOS' build` | Passed. |
| Universal binaries | `./scripts/verify-universal.sh` | Passed for the app and Finder extension with `arm64` and `x86_64` slices. |

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

Run these checks in one dedicated session when foreground control is acceptable. Record the macOS build, display arrangement, result, and any issue link beside each item.

- [ ] Open the menu bar item and inspect its static actions, Keep Awake state, Settings action, and Quit action.
- [ ] Open every Settings section and confirm window sizing, sidebar selection, keyboard navigation, focus rings, truncation, and scrolling.
- [ ] Enable and disable Keep Awake from the menu and Settings, then confirm both surfaces immediately show the same state.
- [ ] Run Get Keep Awake Mode and Set Keep Awake Mode from Shortcuts and confirm they observe the same state as the app.
- [ ] Enable the Finder extension in System Settings and copy paths for a file, folder, app package, selection with spaces, Unicode selection, and multiple selection.
- [ ] Invoke Services > Copy Path for the same fixture and confirm its output exactly matches the Finder action.
- [ ] Verify the Services fallback from at least one supported synced folder where Finder Sync actions are absent.
- [ ] Disable the Finder extension and confirm the main app, Settings, Keep Awake, and Services remain usable.
- [ ] Deny or leave optional permissions unresolved and confirm every Settings recovery path remains visible without blocking unrelated features.
- [ ] Inspect the menu and every Settings section in Light appearance.
- [ ] Inspect the menu and every Settings section in Dark appearance.
- [ ] Increase the system text size and confirm labels remain readable without clipped controls or unreachable content.
- [ ] Quit OpenCharge while Keep Awake is enabled and confirm no power assertion remains.

## Completion rule

Do not mark `C0-01` complete until every foreground item above has evidence and `./scripts/check.sh` passes in a session where UI automation may control focus and the pointer. The full check script includes `OpenChargeUITests` and therefore must not run while another person is using the desktop.
