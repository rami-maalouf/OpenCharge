# OpenCharge

OpenCharge is an open-source macOS utility for reducing repetitive friction in everyday Foundation and Finder workflows.

The project is in its initial implementation stage. The approved first scope includes a native menu bar app, safe Foundation actions, Finder and Services actions, App Intents, permission diagnostics, and opt-in Finder keyboard improvements.

OpenCharge is inspired by the broader macOS utility category. It uses its own implementation, identity, interface, copy, defaults, and documentation.

## Project status

The product specification and implementation plan are approved. Application scaffolding is in progress.

- [Foundation + Finder specification](docs/specs/001-opencharge-foundation-finder.md)
- [Implementation plan](tasks/plan.md)
- [Executable task list](tasks/todo.md)
- [Feature research](docs/research/supercharge-feature-research-2026-08-02.md)

## Requirements

- macOS 26 or later
- Xcode 26
- Swift 6
- SwiftFormat

Build and test commands will become available with the application scaffold.

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
