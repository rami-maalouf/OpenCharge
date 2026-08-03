# Contributing to OpenCharge

OpenCharge welcomes focused, well-tested contributions that stay within the approved product specification.

## Source of truth

Read these documents before changing behavior:

1. [Foundation + Finder specification](docs/specs/001-opencharge-foundation-finder.md)
2. [Implementation plan](tasks/plan.md)
3. [Executable task list](tasks/todo.md)

If the documents conflict with the implementation, stop and surface the conflict. Product scope and safety decisions are updated in the specification before code changes.

## Development rules

- Work on a dependency-ready task from `tasks/todo.md`.
- Keep changes within the files owned by that task.
- Preserve unrelated work in a dirty working tree.
- Add or update tests before completing behavior.
- Use public and supported macOS APIs.
- Keep user-facing capabilities opt-in.
- Never log clipboard contents, captured text, file contents, or full paths by default.
- Never commit secrets, certificates, provisioning profiles, or developer-team identifiers.
- Do not add runtime dependencies, entitlements, privileged components, private APIs, network access, telemetry, or destructive behavior without approval.

## Style

- Prefer readable, focused types over clever abstractions.
- Use explicit dependency injection at system boundaries.
- Keep mutable shared state isolated to an actor or the main actor.
- Do not use force unwraps or `try!` in production code.
- Keep source comments lowercase and focused on intent or constraints.
- Use SwiftFormat before committing.

## Verification

Each task defines its focused checks. When repository tooling is available, complete changes must also pass `./scripts/check.sh`.

## Commits

Use a lowercase conventional commit message such as:

```text
feat: add keep awake action
fix: release power assertion on failure
test: cover finder selection normalization
docs: explain permission recovery
```

Do not add signatures or co-author lines.

## Reporting security issues

Do not publish secrets, exploit details, or private user data in a public issue. Until a dedicated security policy is added, contact Orbit Labs through [orbitlabs.studio](https://orbitlabs.studio).
