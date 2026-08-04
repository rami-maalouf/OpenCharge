# OpenCharge

OpenCharge is an open-source macOS utility for reducing repetitive friction in everyday Foundation and Finder workflows.

The project is in its initial implementation stage. The approved first scope includes a native menu bar app, safe Foundation actions, Finder and Services actions, App Intents, permission diagnostics, and opt-in Finder keyboard improvements.

OpenCharge is inspired by the broader macOS utility category. It uses its own implementation, identity, interface, copy, defaults, and documentation.

## Project status

Milestone 0 and its architecture checkpoint are complete. Automated package, application, UI, Release, and Universal 2 verification passes, together with foreground Finder, Services, App Intents, appearance, accessibility, and power-lifecycle checks. Implementation now proceeds through the approved task list in dependency order.

- [Foundation + Finder specification](docs/specs/001-opencharge-foundation-finder.md)
- [Implementation plan](tasks/plan.md)
- [Executable task list](tasks/todo.md)
- [Architecture scaffold checkpoint](tasks/checkpoints/C0-architecture-scaffold.md)
- [Process boundaries](docs/architecture/process-boundaries.md)
- [Adding a feature](docs/architecture/adding-a-feature.md)
- [Feature research](docs/research/supercharge-feature-research-2026-08-02.md)

## Requirements

- macOS 26 or later
- Xcode 26
- Swift 6
- SwiftFormat

## Build and test

```sh
swiftformat --lint .
swift test --package-path Packages/OpenChargeKit
xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Debug -destination 'platform=macOS' build-for-testing
xcodebuild -project OpenCharge.xcodeproj -scheme OpenCharge -configuration Debug -destination 'platform=macOS' -skip-testing:OpenChargeUITests test-without-building
```

`./scripts/check.sh` adds UI automation. Run it only in a dedicated desktop session because macOS UI tests can take focus and move the system pointer.

## Principles

- Every user-facing capability is opt-in.
- OpenCharge remains usable when optional permissions are denied.
- OS-sensitive integrations are isolated behind testable capability boundaries.
- User settings and content remain local.
- File mutations are recoverable and never overwrite silently.
- Public and supported macOS APIs are required unless a later specification explicitly approves an exception.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before proposing changes. Product behavior is governed by the approved specification, plan, and task list.

## Privacy

OpenCharge has no accounts, telemetry, or cloud service. Read [PRIVACY.md](PRIVACY.md) for the project privacy contract.

## License

OpenCharge is available under the [MIT License](LICENSE).
