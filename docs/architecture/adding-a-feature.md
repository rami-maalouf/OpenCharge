# Adding a Feature

Add features as complete vertical slices. A feature is not complete when only its view or system call exists. Its identity, pure behavior, adapters, surfaces, failure states, tests, documentation, and manual evidence must agree.

## 1. Start from an approved task

Confirm the behavior and safety contract in the product specification, then work on a dependency-ready item in `tasks/todo.md`. If implementation needs a new entitlement, privileged component, private API, network access, destructive behavior, or retention of user content, stop and update the specification before coding.

## 2. Define stable identity and state

Create or reuse a namespaced `FeatureID`, for example `finder.copy-path`. Describe the feature with its category, availability, default enablement, permissions, health, and menu placement.

Persist only user choices that must survive a restart. Add typed `SettingsKey` values and a schema migration when the serialized shape changes. New settings must have safe defaults, and stale identifiers must be sanitized rather than trusted.

## 3. Put contracts in OpenChargeCore

Add only the value types and protocols needed to express behavior across a process or system boundary. Core types should be `Sendable`, deterministic, and independent of AppKit and SwiftUI.

Use the common action vocabulary:

- `ActionRequest` for stable identity and typed input;
- `ActionResult` for success, partial success, cancellation, or failure;
- `ActionError` for content-free, recoverable errors;
- capability protocols for system effects.

Do not add a general abstraction until at least one approved feature needs it.

## 4. Implement pure behavior in OpenChargeFeatures

Feature rules belong in a small action or transformer that depends on core protocols. It must not know whether input came from a menu, Settings, App Intent, Finder extension, or Service.

Test edge cases before wiring UI. Include empty input, multiple input, Unicode, cancellation, unavailable adapters, partial failures, and repeated calls when relevant. File behavior must also cover packages, aliases, symbolic links, missing selections, collision policy, and recoverability as applicable.

## 5. Isolate macOS APIs in OpenChargeSystem

Wrap the narrowest public macOS API behind the core protocol. The adapter owns resource handles and cleanup for anything it creates.

Every live adapter needs a deterministic substitute for tests and previews. Translate framework errors into typed, content-free errors. Never log full paths, clipboard values, captured text, file contents, or other user content by default.

## 6. Compose once

Create live dependencies in `AppDependencies` or the Finder extension entry point. Inject them into the feature model or handler. A view must never select between a live and fake dependency.

If the feature crosses the Finder boundary:

1. filter its enablement into `FinderSettingsSnapshot`;
2. translate Finder selection into the shared action input;
3. expose a Service fallback when the action can operate as a Service;
4. verify both surfaces produce identical output from the same fixture;
5. keep the main app usable when the extension is disabled.

## 7. Add user surfaces

Expose one shared action through only the surfaces approved by the specification. Presentation models may coordinate asynchronous calls and observable state, but they must not duplicate action rules.

User-facing requirements:

- the feature defaults to off unless the specification explicitly says otherwise;
- progress, cancellation, partial failure, and recovery are visible when applicable;
- optional permissions are explained before an explicit request;
- controls have stable accessibility identifiers;
- strings use the string catalog;
- layouts work in Light and Dark appearances, with increased text size, keyboard navigation, and VoiceOver.

## 8. Verify from the inside out

Run the focused check named by the task, then expand verification:

```sh
swiftformat --lint .
swift test --package-path Packages/OpenChargeKit
xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Debug -destination 'platform=macOS' build-for-testing
xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Debug -destination 'platform=macOS' -skip-testing:OpenChargeUITests test-without-building
```

Run `./scripts/check.sh` only in a dedicated desktop session because it includes macOS UI automation and can take focus or move the pointer. For a release checkpoint, also run:

```sh
xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Release -destination 'generic/platform=macOS' build
./scripts/verify-universal.sh
```

Manual evidence must exercise the real integration surface, not only a preview or fake. Record any intentionally unavailable hardware or permission state instead of reporting an unperformed check as passed.

## 9. Commit the complete slice

Update `tasks/todo.md` only after the acceptance criteria and required verification pass. Commit one coherent task with its prescribed lowercase conventional message, then push it before starting the next dependency.
