# Supercharge feature research

Research snapshot: August 2, 2026  
Current public version inspected: 1.29.4, released July 26, 2026  
Current requirement: macOS 26 or later

## Goal and boundary

This document inventories the publicly observable capabilities of Supercharge so a new macOS utility can make informed product and scope decisions.

The sensible target is feature parity, not identity cloning. A new product should use its own name, icon, interface, copy, defaults, and implementation. It should not redistribute Supercharge, copy its binary, or imitate its trade dress.

## Sources and method

Primary sources:

- [Official Supercharge product page](https://sindresorhus.com/supercharge)
- [Official release notes](https://sindresorhus.com/supercharge/release-notes)
- [Official Gumroad listing](https://sindresorhus.gumroad.com/l/supercharge)
- Public Supercharge 1.29.4 trial bundle, inspected locally for declared Services, App Intents, app extensions, entitlements, and minimum OS version
- [Apple Finder Sync documentation](https://developer.apple.com/documentation/findersync)
- [Apple App Intents documentation](https://developer.apple.com/documentation/appintents)
- [Apple Vision OCR documentation](https://developer.apple.com/documentation/vision/recognizing-text-in-images)

The product page and release notes are the source of truth for user-facing behavior. Trial metadata was used only to find automation and integration surfaces that the marketing page summarizes or omits. No source code was available or used.

## Product-level behavior

- Every tweak is opt-in.
- The app runs as a menu bar utility and can launch at login.
- The main menu bar icon is optional and has multiple icon choices.
- Menu actions and sections can be shown, hidden, and reordered.
- A global keyboard shortcut can open the menu.
- Favorite Apple Shortcuts can appear in the main menu or a submenu.
- Shortcuts can be limited to appearing only while selected apps are frontmost.
- Configured keyboard shortcuts can play custom feedback sounds, even when another app handles the shortcut.
- Most actions are also exposed through Apple Shortcuts via App Intents.
- The app is English-only.
- The current build requires macOS 26. Version 1.26.0 is the last public macOS 15 build.
- The main app is directly distributed and unsandboxed. The Finder context menu is implemented by a separate Finder Sync extension.

## Complete user-facing feature inventory

### 1. Windows and app lifecycle

1. Mission Control actions on the hovered window: close, minimize, hide its app, or quit its app.
2. Mission Control actions work through right-click or `Command-W`, `Command-M`, `Command-H`, and `Command-Q`.
3. Navigate Mission Control windows with arrow keys and activate one with Return.
4. Make the red traffic-light button quit an app when its last window closes.
5. Prevent accidental `Command-Q` using `Shift-Command-Q`, double-tap Q while holding Command, or press-and-hold with a visual timer.
6. Prevent accidental `Command-W` per app using the same three protection styles.
7. Disable the red traffic-light button for selected apps. Option-click preserves the normal close behavior.
8. Make the green traffic-light button fill the available screen instead of entering fullscreen. Option-click preserves fullscreen, and clicking again restores the prior size.
9. Make the yellow traffic-light button hide the app instead of minimizing one window. Option-click preserves normal minimize behavior.
10. Show the classic poof animation when a window closes through the red button.
11. Unminimize one or all windows when an app becomes active, including activation through the app switcher.
12. Unminimize all windows across all apps.
13. Hide all windows, also presented as a boss mode.
14. Isolate the frontmost window by hiding other apps and minimizing other windows from the same app.
15. Automatically quit or hide selected inactive apps after per-app timeouts.
16. Pause auto-quit rules while the app is active, using the microphone, while a camera is in use, or during screen capture, with an override option.
17. Quit all apps, with an exclusion list.
18. Quit all apps except the frontmost app, with an exclusion list.
19. Minimize all windows.
20. Minimize all windows except the frontmost window.
21. Minimize all windows of the active app except its frontmost window.
22. Show the desktop.
23. Sleep all displays.

### 2. Dock, Spaces, and pointer behavior

1. Clicking the active app's Dock icon can hide the app, minimize all its windows, or cycle its windows.
2. Middle-clicking a running Dock app can quit, hide, minimize all windows, or cycle windows.
3. Shift-clicking a running Dock app opens a new window by simulating `Command-N`.
4. Clicking the Finder Dock icon can use system behavior, open a new window after focus, always open a new window, or launch an alternative file manager.
5. Clicking a Dock folder can reveal it in Finder instead of opening the folder popover.
6. Prevent the Dock from appearing when the pointer reaches the screen edge.
7. Remove or customize the Dock show delay.
8. Dim Dock icons for hidden apps.
9. Add regular or small Dock spacers.
10. Instantly switch to the next or previous Space without the standard slide animation.
11. Center the pointer on the primary display after wake and unlock, or on demand.
12. Hide the pointer after inactivity or with a keyboard shortcut, then reveal it on movement.

### 3. Finder behavior and keyboard improvements

1. Cut files with `Command-X` and move them with `Command-V`.
2. Open files with Return and rename with `Shift-Return` or F2.
3. Move files to Trash with Delete instead of `Command-Delete`.
4. Go back to the previous folder with Delete and highlight the folder that was left.
5. Reopen the last Finder tab closed with `Shift-Command-T`.
6. Create a new text file with `Option-N`, with a configurable extension, optional auto-open, and configurable opening app.
7. Paste an image from the clipboard as a PNG file with `Command-V`.
8. Paste clipboard plain text as a text file with `Command-V`.
9. Middle-click Finder sidebar folders to open them in a new tab.
10. Automatically fit column widths to filenames in column view, or run the adjustment once with a shortcut.
11. Invert the current Finder selection.
12. Move or copy selected files using a keyboard shortcut and a destination picker.
13. Open a new Finder window when Finder is activated without any windows.
14. Make `Command-Q` close all Finder windows and hide Finder.
15. Toggle Finder with a global keyboard shortcut.
16. Add visual spacer folders to the Finder sidebar.
17. Add Finder actions through both Finder Sync context menus and macOS Services.
18. Exclude AirDrop, Mail, and Messages from the system Share menu.

### 4. Finder context menu additions

Supercharge currently documents 57 configurable Finder context-menu additions. Finder Sync places them at the bottom of the menu. They do not appear in iCloud, Dropbox, OneDrive, or other sync folders, although many equivalents are available through Services.

| Group | Action | Behavior and variations |
| --- | --- | --- |
| Create | New Text File | Creates a text file in empty Finder space. |
| Create | New From Template | Creates files or folder structures from templates, supports template subfolders, dynamic filename placeholders, and optional auto-open. |
| Open | Open in New Window | Opens a folder in a new window even when Finder normally prefers tabs. |
| Inspect | Image/Video Dimensions | Displays media dimensions. |
| Inspect | File Size | Displays file size. |
| Inspect | Date Created | Displays creation date and copies it when clicked. |
| Inspect | Date Modified | Displays modification date and copies it when clicked. |
| Inspect | Date Added | Displays the date the item entered the current folder and copies it when clicked. |
| Copy | Copy Path | Copies filesystem paths. |
| Copy | Copy Filename | Copies filenames. |
| Copy | Copy File URL | Copies deep-linkable file URLs. |
| Copy | Copy Markdown Link | Copies Finder items as Markdown links. |
| Copy | Copy Contents | Copies the contents of text files. |
| Open | Open Folder With | Opens folders in apps that declare folder support. |
| Filesystem | Make Symlink | Creates symbolic links. |
| Filesystem | Cut & Paste | Adds context-menu cut and paste for moving files. |
| Filesystem | Move To... | Chooses a destination for each invocation. |
| Filesystem | Move To | Moves to a saved destination or one of its direct child folders. |
| Filesystem | Move To - Inline | Shows saved destinations directly in the menu, with source limits and optional icons. |
| Filesystem | Copy To... | Chooses a copy destination for each invocation. |
| Filesystem | Copy To | Copies to a saved destination or one of its direct child folders. |
| Filesystem | Copy To - Inline | Shows saved copy destinations directly in the menu, with source limits and optional icons. |
| Filesystem | Copy Here... | Selects items elsewhere and copies them into the clicked folder. |
| Filesystem | Move Here... | Selects items elsewhere and moves them into the clicked folder. |
| Share | Share | Restores the old submenu-style Share interface. |
| Share | Inline Share Services | Places selected share extensions directly in the context menu. |
| Open | Open in App | Adds configured app-specific open actions for supported files and folders. |
| Open | Open in Terminal | Supports Terminal, iTerm, Ghostty, kitty, WezTerm, Alacritty, Warp, and Prompt. |
| Share | AirDrop | Shares selected files through AirDrop. |
| Share | Email | Creates a new message with files attached in supported email clients. |
| Automate | Run Shortcut | Passes selected files to an Apple Shortcut. |
| Metadata | Update Modified Date | Updates modification time to now. |
| Appearance | Folder Color | Changes folder color. |
| Finder | Toggle Hidden Files | Toggles hidden item visibility. |
| Create | New Folder Inside | Creates a child folder and begins renaming it. |
| Filesystem | Flatten Folder | Moves nested files to the root and resolves duplicate names. |
| Developer | Make Executable | Applies executable permission, similar to `chmod +x`. |
| Finder | Invert Selection | Selects everything currently unselected. |
| Destructive | Delete Immediately | Permanently deletes without using Trash. |
| Verify | Copy Checksum | Supports SHA-1, SHA-256, SHA-384, SHA-512, MD5, and CRC32. |
| Security | Unquarantine | Removes the quarantine attribute from trusted items. |
| Scan | Scan QR Code | Scans QR or barcode content from selected images. |
| Output | Print | Prints through the default printer without a dialog. |
| Privacy | Remove Location Metadata | Removes image GPS metadata. |
| Privacy | Remove All Metadata | Removes image metadata including EXIF and GPS. |
| Filesystem | Lock / Unlock | Changes Finder's Locked property. |
| Git | Git: Go to Root | Navigates the current Finder window to the repository root. |
| Git | Git: Show on GitHub | Opens the selected item on GitHub at the current commit for origin or upstream remotes. |
| App | App: Bundle Identifier | Displays and copies an app bundle identifier. |
| App | App: Version | Displays and copies an app version. |
| App | App: Show on App Store | Opens the selected app's App Store page. |
| App | App: Copy App Store URL | Copies shareable App Store URLs. |
| Verify | Is Identical | Checks whether two or more files have identical contents. |
| Verify | Is Identical (Interactive) | Opens a drag-and-drop comparison window that groups identical files and lists unique files. |
| Copy | Copy Folder Tree | Copies a visual tree using box-drawing characters. |
| Filesystem | Combine Contents of Folders | Moves direct contents into the alphabetically first folder and deletes empty sources. |
| Filesystem | Show Symlink Original | Reveals a symlink's target. |

### 5. macOS Services

The public 1.29.4 bundle declares 36 Services. These work in more places than Finder Sync, including many synced folders.

- Copy Path
- Copy File URL
- Copy Filename
- Copy Markdown Link
- Copy File Contents
- Make File Executable
- Update Modified Date
- Make Symlink
- Unquarantine
- Open in Terminal
- Copy MD5 Checksum
- Copy SHA-1 Checksum
- Copy SHA-256 Checksum
- Copy SHA-384 Checksum
- Copy SHA-512 Checksum
- Copy CRC32 Checksum
- AirDrop
- Run Shortcut
- Invert Selection in Finder
- Toggle Hidden Files in Finder
- New Text File in Finder
- New Folder Inside
- Flatten Folder
- Copy Folder Tree
- Combine Contents of Folders
- Show Symlink Original
- Copy To...
- Move To...
- Scan QR Code
- Email
- Open URLs detected in text
- Copy URLs detected in text
- Lock
- Unlock
- Are Files Identical?
- Are Files Identical? (Interactive)

### 6. Screenshots, OCR, translation, codes, and color

1. Automatically copy screenshots to the clipboard while still saving them.
2. Show markup tools by default in the system screenshot preview.
3. Automatically open the screenshot preview after capture.
4. Show or hide the mouse pointer in screenshots.
5. Automatically archive old screenshots, including screenshots made by third-party apps.
6. Capture text from a selected screen region using on-device macOS OCR.
7. Optionally preserve line breaks when capturing text.
8. Capture and translate text from a selected screen region through macOS translation UI.
9. Scan QR codes and barcodes from a screen region.
10. Scan QR codes and barcodes from a clipboard image.
11. Detect multiple codes in one scan.
12. Pick a screen color and copy it as CSS Hex, CSS RGB, CSS OKLCH, RGB bytes, or unit RGB.

### 7. Clipboard and privacy

1. Clear the clipboard immediately from the menu, a shortcut, or App Intent.
2. Automatically clear the clipboard about one minute after copying, restarting the timer on a new copy.
3. Automatically clear the clipboard when the Mac sleeps or locks.
4. Disable Universal Clipboard without disabling Handoff.
5. Clear recent files, apps, and servers lists while leaving the actual files untouched. This is exposed through the current App Intents metadata.
6. Reset privacy permissions for a selected app.
7. Remove image location metadata.
8. Remove all image metadata.

### 8. Notifications and Focus-adjacent behavior

1. Clear visible notifications from the menu, a shortcut, or App Intent.
2. Clear only the top visible notification.
3. Click the top visible notification with a shortcut.
4. Automatically dismiss Shortcuts' "Running your automation" notifications.
5. Toggle notifications mirrored from iOS when the Mac supports them.

### 9. Audio, microphone, media, and display controls

1. Prevent Music from auto-launching when media keys are pressed or devices connect.
2. Optionally apply Music-launch prevention only when media keys trigger it.
3. Optionally launch a different media app such as Spotify.
4. Route play/pause and next/previous media keys to Music, Podcasts, or Spotify.
5. Automatically mute Quick Look video previews without muting other Mac audio.
6. Toggle system sound mute through menu, keyboard shortcut, or Shortcuts.
7. Toggle microphone mute through menu, keyboard shortcut, or Shortcuts.
8. Show a dedicated menu bar state icon for microphone mute.
9. Play optional sounds when microphone mute changes.
10. Automatically mute the microphone while typing and unmute shortly after typing stops, only while the microphone is in use.
11. Cycle audio output devices.
12. Cycle audio input devices.
13. Expose input devices in the system Sound menu bar menu.
14. Show the system Sound menu icon only while muted or only while unmuted.
15. Limit output volume to a configured maximum after wake and unlock without raising or unmuting it.
16. Use half-step or quarter-step volume adjustments.
17. Use smaller brightness-key increments.
18. Adjust volume through configurable multi-finger or edge trackpad gestures.
19. Adjust display brightness through configurable multi-finger or edge trackpad gestures.
20. Control built-in keyboard brightness with global shortcuts.

### 10. Keyboard, trackpad, and interaction tweaks

1. Remap Caps Lock to a Hyper key that presses Control, Option, Shift, and Command together.
2. Remove the normal Caps Lock activation delay.
3. Simulate middle-click with a 3-, 4-, or 5-finger trackpad tap or physical click.
4. Configure trackpad gesture sensitivity and optionally require Shift for edge gestures.
5. Prevent accidental text dragging that creates `.textClipping` files.
6. Disable the `Command-Tab` app switcher.
7. Inspect which apps listen for or register a global keyboard shortcut.
8. Use Delete and `Shift-Delete` for Safari back and forward navigation.
9. Switch between standard function keys and media-key behavior for supported Apple keyboards.
10. Add a sound to any specified keyboard shortcut without changing its behavior.

### 11. Files, Downloads, AirDrop, calendar, and installers

1. Automatically move files received through AirDrop to a configured folder.
2. Prevent Finder from opening a new window and stealing focus after receiving AirDrop files.
3. Automatically select a named device in the AirDrop dialog.
4. Automatically archive old items from local and iCloud Downloads folders based on date added.
5. Lowercase file extensions in local and iCloud Downloads folders.
6. Automatically open downloaded `.ics` files, import them, and move them to Trash.
7. Optionally remove alarms from auto-imported calendar events.
8. Offer to install apps found on mounted DMG images.
9. Export settings for selected native apps to editable `.app-settings` property-list files.
10. Export all compatible app settings to a timestamped folder.
11. Import settings by opening `.app-settings` files.
12. Eject all disks, with an exclusion list and Time Machine handling.
13. Empty Trash.

### 12. System toggles and direct actions

1. Keep the Mac awake, with an option to prevent display dimming and show a state icon.
2. Cleaning Mode blacks out the screen and disables keyboard and mouse input.
3. Cat Mode disables keyboard and mouse input without blacking out the screen.
4. Toggle Dark Mode.
5. Toggle Night Shift.
6. Toggle True Tone.
7. Toggle Low Power Mode.
8. Toggle Grayscale Mode.
9. Toggle desktop icons.
10. Toggle desktop widgets.
11. Toggle Hot Corners globally.
12. Get or set individual Hot Corner actions through Shortcuts.
13. Toggle Stage Manager directly from its menu bar item.
14. Open the Passwords menu bar window with a shortcut.
15. Open the Weather menu bar window with a shortcut.
16. Open the Now Playing menu bar window with a shortcut.
17. Open Spotlight directly to Apps, Files, Actions, or Clipboard History with shortcuts.
18. Toggle Terminal with a shortcut.
19. Change the default browser without the normal confirmation prompt.
20. Open Hide My Email settings directly.
21. Open Private Relay settings directly.
22. Open VPN & Filters settings directly.
23. Open Apple Account Subscriptions settings through the current App Intent.
24. Flush the DNS cache.
25. Apply hidden iMac 2021, iMac 2024, and MacBook Neo accent colors to supported Macs.

### 13. App-specific integrations

1. Copy deep links to one or more selected Apple Mail messages.
2. Get Mail message links as Shortcuts output.
3. Copy deep links to one or more selected Apple Notes notes.
4. Get Notes links as Shortcuts output.
5. Override the Maps app language independently of the system language.
6. Make TextEdit open a blank document instead of a file picker at launch.

## Complete App Intents inventory

The public 1.29.4 trial metadata contains 72 discoverable actions. Some are direct actions; others are separate Get and Set actions that make state composable in automations.

| Category | Actions |
| --- | --- |
| Capture and scan | Capture & Translate Text (Interactive); Capture Text (Interactive); Scan QR Code (Interactive); Pick Color |
| Pointer and notifications | Center Mouse Pointer; Clear Top Notification; Clear Notifications; Click Top Notification; Get Mouse Pointer Visibility; Set Mouse Pointer Visibility |
| Clipboard and history | Clear Clipboard; Clear Recent Lists |
| Mail and Notes | Get Links to Selected Mail Messages; Copy Links to Selected Mail Messages; Get Links to Selected Notes; Copy Links to Selected Notes |
| Files and Finder | Create Email with Files; Create New Text File in Finder; Invert Selection in Finder; Toggle Hidden Files in Finder; Set Folder Color |
| App and window management | Get Auto-Quit State; Set Auto-Quit State; Hide All Windows; Isolate Window; Minimize All Windows; Quit All Apps; Unminimize Windows of Active App |
| Power and displays | Get Keep Awake State; Set Keep Awake State; Toggle Show Desktop; Sleep Displays; Switch Space; Set Grayscale Mode |
| Audio and media | Cycle Audio Device (Interactive); Get Media Keys App Control Target; Set Media Keys App Control Target; Get Microphone Mute State; Set Microphone Mute State; Get Sound Mute State; Set Sound Mute State |
| System appearance | Get Accent Color; Set Accent Color; Get Desktop Icons Visibility; Set Desktop Icons Visibility; Get Desktop Widgets Visibility; Set Desktop Widgets Visibility |
| Keyboard and hardware | Get Function Keys Enabled; Set Function Keys Enabled; Get Keyboard Brightness; Set Keyboard Brightness |
| Display features | Get Night Shift; Get True Tone |
| Hot Corners and notifications | Get Hot Corner; Set Hot Corner; Toggle Hot Corners; Get iOS Notifications Enabled; Set iOS Notifications Enabled |
| Default browser and settings | Get Default Browser; Set Default Browser; Open System Setting |
| Utility modes | Start Cat Mode; Start Cleaning Mode; Eject All Disks; Empty Trash; Export App Settings |
| App toggles | Toggle Finder; Toggle Terminal; Toggle Passwords Menu Bar Window; Toggle Weather Menu Bar Window; Toggle Now Playing Window; Toggle Spotlight |

The app also emits the distributed notification `com.sindresorhus.defaultBrowserDidChange` after changing the default browser.

## Known constraints and unsupported requests

The official FAQ explicitly says these are not possible or not supported by Supercharge:

- Remove the Trash icon or Finder icon from the Dock.
- Disable Stage Manager animations.
- Fill a Finder row with its tag color.
- Name Spaces.
- Remove or modify existing Finder context menu items. Finder Sync can only add items.
- Add colored Finder sidebar icons.
- Move Stage Manager to the right without placing the Dock on the left.
- Apply Mission Control tweaks to Stage Manager.
- Toggle the system's automatic brightness setting.
- Show Finder Sync actions inside iCloud, Dropbox, OneDrive, or other sync folders.
- Support Alt-Tab-style window previews. The developer recommends the separate AltTab app.
- Hide arbitrary menu bar items. The developer recommends Ice.
- Apply default-browser routing rules. The developer recommends Velja.

The official FAQ also declines memory cleaners, app uninstallers, and app thinners.

## Engineering feasibility map

The interface makes many features look like switches, but their implementation risk differs sharply.

| Class | Typical mechanisms | Representative features | Risk |
| --- | --- | --- | --- |
| Public APIs | SwiftUI/AppKit, App Intents, Vision, pasteboard, NSWorkspace, file APIs, IOPM assertions | Keep Awake, OCR, color picker, clipboard clearing, file metadata, checksums, settings UI, Shortcuts actions | Low to medium |
| Supported extensions | Finder Sync, NSServices, Share services | Finder context additions and Services | Medium, with system-imposed placement and sync-folder limits |
| Permission-heavy automation | Accessibility API, Apple Events, screen capture, Core Audio, global event taps | Window actions, notifications, app control, keyboard shortcuts, pointer control, microphone and media behavior | Medium to high |
| Fragile system integration | Dock and Mission Control observation, Spaces switching, Spotlight tab control, menu bar popover control, hidden preferences | Dock behavior, Mission Control actions, animation-free Spaces, hidden accent colors | High and OS-version sensitive |
| Safety-sensitive operations | Permanent deletion, unquarantine, recursive flatten/combine, settings import | Finder destructive actions and app-settings restore | High consequence even when technically simple |

Important architectural implications:

- Exact parity is not Mac App Store compatible. The official app states that sandboxing would prevent much of its functionality.
- Build the main app for direct notarized distribution and isolate Finder Sync in a separate extension.
- Treat Accessibility, Automation, Screen Recording, and related permissions as a first-class onboarding and diagnostics system.
- Put fragile integrations behind capability adapters and OS-version gates so one macOS update does not destabilize the entire app.
- Give destructive actions confirmation, dry-run previews where possible, collision policies, progress, cancellation, and an operation log.
- Expose stable actions through App Intents from the beginning instead of adding automation after the fact.

## Original feature suggestions

These are ideas for the new product, not Supercharge features.

| Priority | Feature | Why it saves time | Suggested first version |
| --- | --- | --- | --- |
| 1 | Context Profiles | One switch can configure a whole situation such as Work, Meeting, Presentation, Deep Focus, Travel, or Low Battery. | Profiles that compose existing toggles and actions, triggered manually or by Focus mode. |
| 2 | Universal Command Palette | A searchable palette solves discoverability once the app contains over 100 actions. | Fuzzy search, recent actions, favorites, keyboard-first navigation, and per-app results. |
| 3 | Rules Engine | Automates repetitive state changes based on context instead of requiring one shortcut per condition. | Triggers for time, active app, Focus mode, power source, battery level, display connection, audio device, and network name. |
| 4 | Workspace Snapshots | Restores a working context after meetings, restarts, or switching projects. | Save and restore app launches, window positions, display assignment, and selected files or URLs. |
| 5 | Clipboard Workbench | Common text cleanup currently takes multiple apps or manual edits. | Paste without formatting, strip tracking parameters, case conversion, whitespace cleanup, JSON formatting, Markdown conversion, and privacy exclusions. |
| 6 | File Drop Shelf | Moving files between deeply nested folders is awkward even with Finder windows. | A temporary global shelf with copy, move, link, and saved-destination actions. |
| 7 | Quick Action Builder | Lets the product grow with the user's workflow instead of waiting for built-in features. | Create named actions from shell scripts, AppleScript, Shortcuts, URLs, or app launches with file/text input and per-app visibility. |
| 8 | Safety Center and Undo Log | Utility apps can cause wide system changes, so trust is a product feature. | Show recent operations, affected files/settings, reversibility, permissions health, and undo when technically possible. |
| 9 | Developer Project Actions | Removes frequent context switching for Swift and Git work. | Copy repo-relative path, copy GitHub permalink, open Xcode project/workspace, open terminal at repo root, and run a configured project command. |
| 10 | Meeting Guardian | Bundles the small recurring chores around calls. | On microphone or camera activation, select audio devices, enable Do Not Disturb, keep awake, hide notifications, and restore previous state afterward. |
| 11 | Smart Link Router | Opens work, personal, meeting, and development links in the right browser or app. | Rules by domain, source app, Focus profile, and modifier key, with a one-time chooser fallback. |
| 12 | Selection Actions | Makes useful transformations available anywhere text is selected. | Search, translate, summarize locally where possible, create task, open URLs, normalize text, or send to a configured Shortcut. |

My recommended differentiator is not a larger pile of toggles. It is a coherent system built around three ideas:

1. Search everything through a command palette.
2. Compose actions into profiles and context rules.
3. Make risky changes transparent and reversible through a safety center.

That turns a collection of tweaks into a personal operating layer for macOS.

## Recommended implementation shortlist

This is a product recommendation, not yet an implementation plan.

### Foundation release

- Original menu bar app and settings experience
- Launch at login, feature registry, search, favorites, and configurable menu
- Permission onboarding and health diagnostics
- Global shortcut infrastructure and shortcut conflict detection
- App Intents for every stable action
- Keep Awake, Show Desktop, Sleep Displays, Clear Clipboard, Empty Trash, Pick Color, OCR, QR scanning, and basic system toggles
- Safe file Services such as copy path, filename, file URL, Markdown link, checksum, open in terminal, and create text file
- Command Palette, Safety Center, and operation log as original differentiators

### Finder release

- Finder Sync extension
- Templates, saved Copy To and Move To destinations, Open in App, metadata inspection, Git actions, folder tree, and safe metadata removal
- Finder keyboard behavior such as Return to open, cut/paste, and paste clipboard content as files
- File Drop Shelf

### Automation release

- Profiles and Rules Engine
- Workspace Snapshots
- Quick Action Builder
- Clipboard Workbench
- Developer Project Actions

### Fragile-integration release

- Window button changes
- Dock click and middle-click behavior
- Mission Control controls
- Notification manipulation
- Media-key routing and Music launch prevention
- Trackpad gesture synthesis
- Animation-free Space switching
- Spotlight and menu bar popover controls

These should come last because they need the largest macOS-version test matrix and the strongest recovery behavior.

## Decisions for the next phase

Before architecture or implementation, choose:

1. Target OS: macOS 26 only, or macOS 15 and 26.
2. Product goal: personal utility for one Mac, or a distributable product for other users.
3. Initial scope: Foundation only, Foundation plus Finder, or broad parity.
4. Distribution: direct notarized download only, or a limited sandboxed App Store companion as well.
5. Product identity and working name.
6. Which original differentiator should lead: Command Palette, Profiles and Rules, or Safety Center.

