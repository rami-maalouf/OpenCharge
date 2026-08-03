# OpenCharge Privacy Contract

OpenCharge is designed to perform utility actions locally on the user's Mac.

## Data handling

- OpenCharge has no accounts, telemetry, advertising, analytics, or cloud service.
- Settings remain on the Mac and may be shared only between the main app and its Finder extension through the app group.
- Clipboard contents, captured text, captured images, file contents, and full file paths are not retained or logged by default.
- Screen captures used for OCR or code recognition remain in memory only for the requested operation.
- Temporary files created for safe file operations are removed after success, failure, or cancellation.
- OpenCharge does not access the network except to open a URL explicitly requested by the user.

## Permissions

OpenCharge does not request optional permissions at launch. Before a permission prompt, the app explains the exact capability it enables. Denying a permission affects only features that depend on it.

The approved scope may use:

- Screen Recording for user-requested screen-region capture.
- Accessibility for explicitly enabled Finder keyboard improvements.
- Finder extension activation for Finder context-menu actions.

## Logging

Diagnostic logs use privacy annotations. They describe operation type, state, duration, and sanitized errors without recording user content or full paths by default.

## Changes to this contract

Any feature that introduces accounts, telemetry, cloud storage, background network access, or broader data collection requires an approved specification change before implementation.
