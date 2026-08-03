# Process Boundaries

OpenCharge has two executable process boundaries and one shared Swift package. Every feature must keep user content local, keep system calls behind adapters, and remain useful when an optional integration is unavailable.

## Main application

The `OpenCharge` process owns:

- the menu bar scene and Settings scene;
- application lifecycle and termination cleanup;
- App Intent registration and execution;
- macOS Services registration;
- live power, login item, permission, pasteboard, and extension-management adapters;
- presentation models isolated to the main actor.

`AppDependencies` is the composition root. It selects live or deterministic dependencies once, then injects them into `AppModel` and the feature-specific presentation models. Views never create system adapters and never call IOKit, ServiceManagement, permission APIs, or the pasteboard directly.

## Finder extension

`OpenChargeFinder` runs independently inside Finder. It may be enabled, disabled, terminated, or unavailable without the main application process.

The extension owns only Finder-specific concerns:

- reading the current Finder selection;
- deciding whether a Finder menu item can be offered;
- translating the selection into shared action input;
- presenting the Finder menu item.

It does not depend on the main app being open. It reads the Finder-safe settings snapshot from the shared app-group container and invokes pure logic from `OpenChargeFeatures`. System output is written through an adapter from `OpenChargeSystem`.

Finder Sync is not available in every location, especially some cloud-synced folders. Any compatible Finder action must also expose a macOS Service from the main app. The Service and Finder extension must translate inputs into the same shared action rather than reimplementing behavior.

## Shared Swift package

`OpenChargeKit` is split by responsibility:

| Module | May know about | Must not know about |
| --- | --- | --- |
| `OpenChargeCore` | Stable identifiers, value types, protocols, settings schema, action contracts, permission state | AppKit, SwiftUI, concrete system APIs, presentation state |
| `OpenChargeFeatures` | Pure feature behavior and orchestration through `OpenChargeCore` protocols | SwiftUI, Finder UI, concrete system adapters |
| `OpenChargeSystem` | Concrete macOS adapters that satisfy core protocols | Product navigation, view state, duplicated feature rules |

Dependencies flow inward: application and extension targets may import all three modules, `OpenChargeSystem` and `OpenChargeFeatures` may import `OpenChargeCore`, and `OpenChargeCore` imports neither outer module.

## Shared settings

The app-group settings snapshot is the only durable state shared with the Finder extension.

Invariants:

- a versioned `SettingsSchema` is encoded as one complete snapshot;
- updates are serialized and committed atomically;
- migrations are explicit and idempotent;
- malformed or future-version data never mutates a valid in-memory snapshot;
- all features use stable `FeatureID` and `SettingsKey` values;
- the Finder extension receives only its filtered, Finder-relevant settings;
- safe defaults keep every optional capability disabled.

The pasteboard is an output boundary, not shared application state. OpenCharge clears stale types on successful writes and retains no clipboard history or copied values.

## Permissions and capability state

Permission status is observed without prompting. A prompt or System Settings navigation occurs only after an explicit user action.

Each OS-sensitive integration exposes a typed capability boundary with:

- an observable status;
- a recoverable unavailable or denied state;
- an explicit request or management action when macOS supports one;
- a deterministic test implementation.

A denied permission, disabled Finder extension, or unavailable adapter must degrade only the affected feature. Menu access, Settings, and unrelated actions remain available.

## Lifecycle ownership

The component that creates a system resource owns its cleanup. Keep Awake is the first example: the power adapter owns assertion handles, the shared action owns state transitions, and the application lifecycle controller requests shutdown cleanup. Release failures retain ownership so cleanup can be retried instead of silently losing the handle.

No extension or service may assume the main app will clean up resources it created.

## Data and privacy boundaries

OpenCharge has no account, telemetry, cloud service, or network requirement. Feature inputs such as file paths, clipboard values, captured text, and selected content must not be logged or retained by default. Error values describe the failed operation or type without embedding private content.
