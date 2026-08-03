# OpenCharge Foundation + Finder Implementation Plan

- Status: Draft for human review
- Plan version: 1
- Created: August 3, 2026
- Source specification: `docs/specs/001-opencharge-foundation-finder.md`
- Target: macOS 26, Swift 6, Universal 2

## Outcome

Deliver the approved OpenCharge Foundation + Finder scope as a native, open-source macOS menu bar app with a Finder Sync extension, macOS Services, App Intents, permission diagnostics, safe file operations, and opt-in Finder keyboard improvements.

The implementation is organized as verified vertical slices. Each phase must leave the repository buildable and tested. Agents must not build every abstraction first and integrate only at the end.

## Planning Principles

1. Build one working path through domain, adapter, presentation, persistence, and tests before multiplying features.
2. Keep pure policy and formatting logic in Swift packages. Keep macOS framework calls in narrow system adapters.
3. Use one application action layer for menu items, Settings, Services, Finder, global shortcuts, and App Intents.
4. Treat permissions, feature availability, and failure isolation as product behavior.
5. Keep Finder extension work bounded. Route long or stateful operations to the main app through a validated request envelope.
6. Add file mutation only after collision policy, cancellation, partial failure, and recovery primitives exist.
7. Run public-API feasibility work before committing architecture to uncertain macOS integrations.
8. Complete safe Foundation and Finder actions before permission-heavy Finder keyboard interception.

## System Boundaries

### OpenChargeCore

Owns stable domain contracts only:

- `FeatureID`, `FeatureDescriptor`, categories, availability, enablement, and health.
- `PermissionKind` and permission state.
- Settings schema and migration contracts.
- Action requests, results, progress, cancellation, and typed errors.
- File selection, collision policy, and operation request value types.
- Protocols implemented by system adapters.

It must not import UI or macOS integration frameworks.

### OpenChargeSystem

Owns replaceable macOS adapters:

- App-group preferences.
- Launch at Login.
- IOKit power assertions.
- Pasteboard.
- Screen capture and Vision recognition.
- Permission status and System Settings navigation.
- Global keyboard shortcuts.
- Finder and workspace opening.
- File metadata, hashing, copying, moving, and replacement.
- Unified logging with privacy annotations.

Each adapter receives its system dependencies or handles through an initializer and has an in-memory or deterministic fake.

### OpenChargeFeatures

Owns user-visible application behavior:

- One action type or cohesive action family per feature.
- Input validation and permission requirements.
- Result formatting and partial failure handling.
- No SwiftUI views and no direct global framework calls.

### OpenCharge.app

Owns:

- Composition root and application lifecycle.
- `MenuBarExtra` and Settings UI.
- App Intents and macOS Service entry points.
- Interactive flows, progress presentation, and recovery messages.
- Validated request consumption from the Finder extension.

### OpenChargeFinder.appex

Owns:

- Finder menu construction and extension status.
- Finder selection normalization.
- Fast, extension-safe read actions.
- Creation of bounded requests for main-app operations.

It does not own long-running file operations, arbitrary process execution, or app presentation code.

## Interprocess Request Design

Long Finder actions use a bounded app-group request envelope:

1. The extension writes a versioned, Codable request keyed by a random UUID.
2. The request contains an allowlisted action identifier, normalized file URLs, creation time, and action-specific bounded configuration.
3. The extension opens `opencharge://request/<uuid>` without putting file paths or user content in the URL.
4. The app looks up the request in the shared app group, validates schema version, age, identifier, count, path form, and payload size, then consumes it once.
5. Expired and consumed requests are deleted.
6. Invalid requests are rejected without invoking a feature.

This mechanism is implemented only when the first routed Finder action needs it. Copy Path and other fast read actions remain inside the extension.

## Dependency Graph

```text
P0 repository bootstrap
 |
 v
P1 core contracts and test harness
 |
 +-----------> P2 shared settings and migrations
 |                    |
 |                    v
 |              P3 app shell and Settings
 |                    |
 |                    v
 |              P4 permissions and diagnostics
 |                    |
 +--------------------+
 |
 +-----------> P5 Keep Awake vertical slice
 |
 +-----------> P6 Copy Path Finder and Services vertical slice
                      |
                      v
              C0 architecture scaffold checkpoint
                      |
          +-----------+-----------+
          |                       |
          v                       v
   P7 menu and shortcut       P8 Foundation actions
   infrastructure                 |
          |                       |
          +-----------+-----------+
                      v
              C1 Foundation checkpoint
                      |
                      v
              P9 Finder action platform
                      |
          +-----------+-----------+
          |           |           |
          v           v           v
       P10 copy    P11 inspect  P12 open/create/git
       actions     and verify   and folder tree
          |           |           |
          +-----------+-----------+
                      |
                      v
              P13 safe file mutations
                      |
                      v
              C2 Finder checkpoint
                      |
                      v
              P14 Finder keyboard layer
                      |
                      v
              C3 keyboard checkpoint
                      |
                      v
              P15 release hardening
```

## Implementation Phases

### P0: Repository and toolchain bootstrap

Create the minimum buildable repository foundation:

- `.gitignore`, MIT `LICENSE`, README skeleton, contribution guide, privacy statement, and architecture directory.
- SwiftFormat configuration and `scripts/check.sh`.
- `OpenCharge.xcodeproj` with app, Finder extension, unit test, and UI test targets.
- `Packages/OpenChargeKit` with Core, System, and Features library products and package tests.
- macOS 26 deployment target, Swift 6 strict concurrency, Universal 2 release architecture, `LSUIElement`, bundle identifiers, URL scheme, and app-group entitlements.
- Empty but buildable app and extension entry points.
- Shared Xcode scheme with build and test actions.

Verification:

- Package tests run.
- App and extension build from a clean checkout without a development-team identifier.
- A placeholder UI test launches the app.
- Release build contains `arm64` and `x86_64` slices.

### P1: Core contracts and deterministic test harness

Implement the smallest stable domain vocabulary:

- Feature identity, descriptor, category, availability, enablement, and health.
- Permission kinds and states.
- Action request, result, progress, cancellation, and typed error forms.
- `FeatureRegistry` with isolated feature construction failures.
- Shared test fixtures and in-memory capability fakes.

Avoid speculative feature-specific abstractions. Add contracts when Milestone 0 needs them.

Verification:

- Registry tests cover enabled, disabled, unavailable, unhealthy, and construction-failure states.
- Core package has no imports from UI or OS integration frameworks.
- Swift 6 concurrency checks pass without unchecked annotations.

### P2: Versioned settings and app-group contract

Implement:

- Versioned settings schema with stable feature and preference keys.
- App-group `UserDefaults` adapter plus in-memory fake.
- Default values that keep every capability disabled.
- Migration runner with idempotence and rollback-safe write ordering.
- Extension-safe read snapshot containing only Finder-relevant settings.

Verification:

- App and extension encode and decode the same fixtures.
- Missing, corrupt, older, and newer schemas have defined behavior.
- Migration tests prove repeated runs do not change results.

### P3: App shell, menu, and Settings navigation

Build the first real user experience:

- Composition root constructs the registry, settings, adapters, and presentation models.
- Menu bar item with Settings, permission health, About, and Quit.
- Settings sections for General, Menu, Foundation, Finder, Permissions, and About.
- Launch at Login adapter and setting with visible error recovery.
- Feature rows driven from the registry rather than hardcoded duplicated lists.
- String Catalog and initial accessibility labels.

Verification:

- App launches without a Dock icon and without requesting permissions.
- UI tests open every Settings section.
- Launch at Login model tests use a fake adapter.
- Increased text size and light and dark appearances are visually inspected.

### P4: Permissions and diagnostics

Implement permission state as an independent capability:

- Status providers for Screen Recording, Accessibility, Automation where needed, and Finder extension activation.
- Explanation-before-request flow.
- System Settings deep links and status refresh when the app becomes active.
- Feature availability derived from OS support plus permission state.
- Test-only permission providers for deterministic UI states.

Verification:

- Denied, restricted, not determined, granted, and unavailable states render correctly.
- No permission prompt appears during launch or ordinary Settings navigation.
- A denied permission disables only dependent features.

### P5: Keep Awake vertical slice

Prove the Foundation architecture end to end:

- Domain controller and state model.
- IOKit adapter that owns and releases assertion handles.
- Menu and Settings controls.
- Persisted configuration for idle sleep and optional display sleep prevention.
- Get and Set Keep Awake App Intents using the same feature logic.
- Termination cleanup and recoverable adapter errors.

Verification:

- Adapter integration tests prove assertion creation and release.
- Menu, Settings, and intents observe the same state.
- Restart behavior matches the approved persistence policy.
- No assertion remains after disable or clean termination.

### P6: Copy Path Finder and Services vertical slice

Prove the Finder architecture end to end:

- Selection normalization shared by Finder and Services.
- Pure Copy Path formatting behavior.
- Finder Sync menu item controlled by shared enablement settings.
- Copy Path macOS Service.
- Pasteboard adapter and visible partial-failure behavior.
- Extension activation guidance in Settings.

Verification:

- Tests cover empty, single, multiple, Unicode, spaces, packages, and missing selections.
- Finder and Services produce identical results from the same fixture.
- Real Finder context menu and Services menu are manually verified.
- Main app remains usable with the extension disabled.

### C0: Architecture scaffold checkpoint

Stop feature expansion until all Milestone 0 criteria pass:

- Clean build and all tests pass.
- Menu bar and Settings UI are inspected.
- Keep Awake works through UI and App Intents.
- Copy Path works through Finder and Services.
- Permission denial and extension-disabled paths are verified.
- Architecture notes describe process boundaries and how to add a feature.

### P7: Menu configuration and shortcut infrastructure

Implement:

- Favorites, visibility, ordering, and menu icon selection.
- Settings search over feature metadata and preferences.
- Global shortcut registration behind a capability protocol.
- A bounded feasibility check comparing public shortcut mechanisms on macOS 26.
- Conflict detection and clear save-time errors.
- Safeguard against hiding the icon without a reliable configured shortcut.
- Per-action shortcut dispatch through the common action layer.

Verification:

- Configuration persists and menu output is deterministic.
- Shortcut registration and conflicts are tested through fakes and a real manual pass.
- Removing the only alternate opener automatically preserves the menu icon.

### P8: Foundation action slices

Implement each capability as a separate vertical slice with its own tests and UI:

1. Clear Clipboard.
2. Pick Color with Hex, RGB, and OKLCH formatting.
3. Region capture infrastructure.
4. Capture Text using Vision OCR.
5. Scan Code from a region and clipboard image.
6. App Intents for stable actions.
7. Show Desktop public-API feasibility and implementation only if compliant.
8. Sleep Displays public-API feasibility and implementation only if compliant.

Capture Text and Scan Code share region selection and Vision adapters but keep separate feature logic. Interactive App Intents may request foreground continuation instead of duplicating UI inside intents.

If Show Desktop or Sleep Displays has no compliant public implementation, record findings, update the spec, remove the capability through human-approved revision, and continue without a private fallback.

Verification:

- Clipboard and captured content are not persisted or logged.
- OCR tests use deterministic fixture images and cover line-break preference.
- Code scanning returns all supported detected values in stable order.
- Color conversions have numeric unit tests and copy the selected format.
- Permission denial and user cancellation are non-fatal.

### C1: Foundation checkpoint

- Milestone 1 capability table is satisfied or approved feasibility removals are recorded.
- Menu, shortcuts, Settings, and App Intents call the same action layer.
- Screen Recording is requested only from Capture Text or Scan Code user intent.
- Manual tests cover real screen selection, global shortcuts, and App Intents.

### P9: Finder action platform

Generalize only what the next Finder slices share:

- Finder action descriptor, selection requirements, menu grouping, and availability.
- Services adapter over the same selection and action contracts.
- Terminal and application configuration models.
- File operation progress, cancellation, collision policy, and partial result types.
- Bounded app-group request envelope and `opencharge://request/<uuid>` consumer.
- Test filesystem fixtures created only inside temporary directories.

Verification:

- Invalid or expired interprocess requests are rejected and removed.
- URL invocations without a valid app-group envelope cannot execute actions.
- Finder menus are deterministic for empty space, files, folders, packages, and mixed selections.

### P10: Finder copy actions

Implement Copy Filename, Copy File URL, Copy Markdown Link, and Copy Contents.

Verification:

- Multiple results use the specified newline format.
- URLs and Markdown labels are escaped correctly.
- Copy Contents accepts only supported text types, enforces a documented size limit, and reports mixed-batch failures.
- Finder and Services outputs match.

### P11: Finder inspection and verification

Implement File Information plus SHA-256 and SHA-512 checksums.

Verification:

- Metadata handles unavailable dates and dimensions without false values.
- Checksums stream rather than loading whole files into memory.
- Known test vectors, empty files, large fixtures, cancellation, and unreadable items are covered.
- Multi-file output clearly associates results with files without logging private paths.

### P12: Finder open, create, Git, and tree actions

Implement:

- Open in Terminal.
- Open With configured application.
- New Text File.
- New From Template.
- Go to Repository Root.
- Copy Repository-Relative Path.
- Show on GitHub.
- Copy Folder Tree.

Use direct APIs for configured applications and terminals where available. Any proposed shell execution crosses an Ask First boundary and is not assumed by this plan.

Verification:

- New items never overwrite and use deterministic unique naming.
- Template recursion rejects unsafe links and destination escape.
- Git repository discovery handles worktrees and nested repositories.
- GitHub URLs accept only validated HTTPS GitHub remotes and tracked relative paths.
- Folder trees have stable ordering, depth limits, and cycle protection.

### P13: Safe file mutations

Implement shared operation infrastructure first, then Copy To, Move To, Remove Location Metadata, and Remove All Metadata.

Implementation order:

1. Collision policy and destination validation.
2. Progress, cancellation, partial results, and temporary staging.
3. Same-volume Copy To and Move To.
4. Explicit cross-volume copy-then-trash behavior.
5. Recoverable metadata replacement.
6. Finder and Services integration.

Verification:

- No overwrite occurs without an explicit non-default policy.
- Cancellation leaves original files intact and cleans temporary artifacts.
- Cross-volume tests verify copy before Trash movement.
- Metadata operations retain the original until replacement succeeds.
- Batch reports distinguish success, skipped, cancelled, and failed items.

### C2: Finder checkpoint

- All Milestone 2 actions satisfy their behavior and safety tables.
- Finder and Services share results for equivalent invocations.
- Real Finder tests cover local and synced folders, with documented Finder Sync limitations.
- Long operations remain responsive, cancellable, and recoverable.
- Disabled extension and main-app-not-running states are verified.

### P14: Finder keyboard layer

Start with a feasibility harness and kill switch before individual behaviors:

1. Accessibility explanation and permission flow.
2. Finder-only event observation and active-context validation.
3. Immediate global kill switch and per-feature toggles.
4. Open with Return and rename with `Shift-Return`.
5. Cut with `Command-X` and move with `Command-V`.
6. Paste clipboard image as PNG.
7. Paste clipboard text as a text file.
8. Reopen closed Finder tab only if a supported implementation exists.

The layer must ignore text fields, rename mode, sheets, dialogs, non-Finder apps, and disabled features. It must preserve original events whenever OpenCharge does not fully handle them.

Verification:

- Tests model context decisions independently of live event taps.
- Manual E2E passes cover list, icon, column, and gallery views plus rename mode and dialogs.
- Killing the feature restores normal Finder behavior immediately.
- Accessibility denial never affects the rest of OpenCharge.

### C3: Finder keyboard checkpoint

- Every behavior is independently enabled and disabled.
- No known key interception occurs outside validated Finder contexts.
- Cut and paste preserves data through failures and collisions.
- Unsupported reopen-tab behavior is removed through an approved spec revision rather than a fragile workaround.

### P15: Release hardening and contributor handoff

Complete the public open-source quality bar:

- Full accessibility, appearance, permission, and localization audit.
- Clean-checkout and Universal 2 verification.
- Performance and memory checks for menu construction, OCR, hashing, folder trees, and batch operations.
- Privacy audit of unified logs and temporary files.
- Settings migration fixture from schema version 1.
- Finder extension troubleshooting guide.
- Feature-development guide and architecture decision records.
- Manual test matrix for supported macOS 26 hardware available to the project.
- Naming review before public release.

Signing, notarization automation, update infrastructure, and publishing remain deferred unless separately approved.

## Parallel Work Strategy

Parallel work begins only after the shared contracts it depends on are merged. Agents working in parallel must own disjoint files and may not redesign shared contracts independently.

| Work | Can run in parallel with | Must wait for |
| --- | --- | --- |
| Documentation and architecture notes | Most implementation phases | Approved relevant behavior |
| P2 settings | P1 test fixtures after core key types settle | P1 initial contracts |
| P3 presentation skeleton | P2 adapter implementation | P1 registry interfaces |
| P5 Keep Awake | P6 Copy Path | P1 through P4 shared foundation |
| Clear Clipboard | Pick Color | P7 action and shortcut dispatch |
| OCR fixture preparation | QR fixture preparation | P4 permission contracts |
| Copy actions | Inspection and checksums | P9 Finder action contracts |
| Open and create actions | Git and folder tree actions | P9 Finder action contracts |
| UI test expansion | Feature implementation | Stable accessibility identifiers |
| Contributor documentation | Release hardening tests | Completed architecture decisions |

Sequential work that must not be parallelized:

- Settings schema definition and migrations.
- Xcode project target and entitlement changes.
- Interprocess request schema and validation.
- Shared file mutation engine and collision semantics.
- Global event interception and kill-switch ownership.
- Spec changes that alter scope or approved safety boundaries.

## Verification Checkpoints

Every phase runs its focused tests plus:

```sh
swiftformat --lint .
swift test --package-path Packages/OpenChargeKit
xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Debug -destination 'platform=macOS' build
```

Every checkpoint runs:

```sh
./scripts/check.sh
xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Release -destination 'platform=macOS' build
```

Checkpoint evidence is recorded in the implementation task or milestone document:

- Commands and exit status.
- Automated test count and failures.
- Manual scenarios exercised.
- UI appearances and accessibility settings inspected.
- Permissions granted or denied for the test.
- Known macOS limitations.

## Major Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Show Desktop or Sleep Displays lacks a compliant public API | Feature cannot meet policy | Run bounded feasibility work before implementation, document evidence, and revise the spec instead of using private fallback. |
| Finder Sync menus are absent in synced folders | Users perceive missing features | Provide equivalent Services where supported and explain the system limitation in Settings. |
| Finder extension is terminated during work | Partial or lost operation | Keep only fast reads in the extension and route long work to the main app with one-time validated requests. |
| Global shortcuts conflict or rely on legacy APIs | Unreliable access | Isolate registration, test conflicts, perform an early feasibility comparison, and retain a visible menu opener. |
| Screen capture permission creates confusing states | OCR and QR appear broken | Explain before request, re-check status on activation, and display a direct recovery action. |
| Finder keyboard interception affects typing or dialogs | Data loss or broken interaction | Use strict Finder-context validation, per-feature opt-in, event pass-through, and an immediate kill switch. |
| Cross-volume Move To loses data | Severe user harm | Copy fully, verify completion, then move source to Trash. Never permanently delete. |
| Metadata rewrite reduces image quality or strips unintended data | Irreversible content change | Stage a recoverable replacement, preserve original until success, show confirmation, and test formats explicitly. |
| Large files or trees exhaust memory | App or extension termination | Stream hashing and file copies, cap text content and tree depth, report progress, and support cancellation. |
| App Intents duplicate or diverge from UI behavior | Inconsistent results | Route every surface through the same feature action layer. |
| Universal 2 cannot be runtime-tested on available Intel hardware | Architecture-specific regression | Compile and inspect both slices on every release, use CI or borrowed hardware when approved, and document the untested runtime boundary. |
| Product name conflicts with existing OpenCharge uses | Public-release delay | Keep identity assets replaceable and complete a naming review before release hardening. |

## Plan Completion Criteria

This plan is ready for Phase 3 task breakdown when the human confirms:

1. The phase order matches the intended Foundation + Finder priorities.
2. Milestone 0 remains the first buildable bare-bones application.
3. Safe Foundation and Finder vertical slices precede mutation and keyboard interception.
4. The bounded app-group request design is acceptable for Finder-to-app handoff.
5. Public-API feasibility can remove Show Desktop, Sleep Displays, or reopen-tab behavior only through an approved spec revision.
6. The parallel work boundaries and sequential ownership rules are appropriate for AI agents.
7. The risk mitigations meet the expected safety and quality bar.

After approval, Phase 3 will convert this plan into `tasks/todo.md`. Each task will be sized for one focused agent session, list no more than about five files, state acceptance criteria, include exact verification commands, and name its dependencies.
