# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Version 2.0 Highlights

**Major Features Added:**
- Enhanced OCR with proper line break preservation in typing output
- Improved crosshair cursor behavior for screen text capture
- KeyboardSimulator now converts `\n` characters to actual Enter key presses
- Robust cursor stack management with push/pop mechanics
- ESC key handling with proper cursor restoration

**Key Improvements:**
- OCR text maintains original formatting when typed
- Crosshair cursor appears immediately and persists during selection
- Multi-line text from OCR types with proper line breaks
- Enhanced cursor state management between OCR sessions

## Commands

### Building and Development
- Build the project: `swift build -c release`
- Create app bundle: `./build.sh`
- Run directly from build: `./.build/release/ClipTyper`

## Target Requirements & Constraints

**Target Users:** Security engineers, MSP employees, and engineers working through VPN/RDP jump hosts with restricted copy-paste functionality.

**Hard Constraints:**
- Must run fully offline
- Requires Accessibility permissions (always)
- Requires Screen Recording permissions (only when OCR feature enabled)
- Target: Apple Silicon + macOS 15.4+ (broader compatibility preferred)
- Distribution: Mac App Store (preferred) or notarized DMG (fallback)
- No clipboard history or persistent storage for security
- No open-source licensing requirements for dependencies

**Core UX Requirements:**
- Default global shortcut: ⌥⌘V (Option+Command+V)
- Configurable typing delay: 0.5s-10s (default 2s)
- Character warning threshold: default 100 characters
- Auto-clear clipboard option (default off)
- Countdown display: dialog or menu bar (user preference)
- Dialog/window positioning: directly under menu bar icon, always on top
- Autostart with system (default off, configurable)

**Screen Text Capture (OCR) Requirements:**
- Default OCR shortcut: ⌥⌘R (Option+Command+R)
- Configurable whether Screen Text Capture is enabled (default off)
- Configurable OCR shortcut
- Configurable preview/edit dialog before clipboard (default off)
- Mimics Apple's partial screenshot UX (⇧⌘4 style)
- Only requests Screen Recording permission when feature enabled

## Project Structure

ClipTyper is a macOS status bar utility that simulates keyboard typing of clipboard contents. The app runs as an accessory application (no dock icon) and provides a menu bar interface.

**Core Components:**
- `main.swift` - Entry point, sets app as accessory and runs main loop
- `AppDelegate.swift` - Main application controller, handles status bar UI, menu creation, and coordinates all managers
- `ClipboardManager.swift` - Monitors clipboard changes via timer polling (0.5s intervals)  
- `KeyboardSimulator.swift` - Uses CGEvent and Unicode scalars to simulate typing, bypassing keyboard layout dependencies
- `PreferencesManager.swift` - UserDefaults wrapper for app settings (typing delay, auto-clear, shortcuts, etc.)
- `GlobalShortcutManager.swift` - Handles global keyboard shortcuts (default: ⌥⌘V)
- `LoginItemManager.swift` - Manages autostart functionality using modern macOS APIs

**Key Architecture Patterns:**
- Manager pattern: AppDelegate coordinates specialized manager classes
- Callback-based communication: ClipboardManager uses closure callbacks to notify AppDelegate of changes
- Timer-based clipboard monitoring: Polling NSPasteboard.general.changeCount every 0.5 seconds
- Unicode-based typing: Uses CGEvent with Unicode scalars for reliable cross-layout typing

**macOS Integration:**
- Requires Accessibility permissions for keyboard simulation
- Uses NSStatusBar for menu bar presence
- Leverages Carbon framework for global shortcuts
- App bundle structure includes Info.plist and entitlements for proper macOS integration

The app's core workflow: clipboard monitoring → user activation (click/shortcut) → countdown delay → Unicode-based typing simulation.

**UI Flow & Interactions:**
- Right-click menu bar icon or ⌥⌘V: triggers typing process
- Left-click menu bar icon: opens settings menu
- Warning dialog for text >threshold with Cancel/Proceed options
- Pressing shortcut again during warning dialog: auto-proceeds
- Menu bar can optionally show character count (e.g., "📋 42")
- During countdown: menu bar shows countdown timer (e.g., "📋 2s")

## UI Design Notes

- Follows contemporary macOS design and Apple's current Human Interface Guidelines
- Modern styling with proper materials, typography, and spacing
- Focus-preserving dialogs that don't interfere with typing workflow

## Screen Text Capture (OCR) Feature

**Purpose:** A perfect complement to ClipTyper's typing functionality for target users working through VPN/RDP environments where text might not be selectable.

**Technical Implementation:**
- Uses Apple's Vision Framework for offline OCR
- Uses CGDisplayCreateImage for screen capture
- Mimics Apple's ⇧⌘4 screenshot selection UX
- Menu item: "Capture Text from Screen" with `viewfinder` SF Symbol

**Workflow:**
1. User triggers OCR capture (menu/shortcut ⌥⌘R)
2. Screen dims with selection overlay (Apple screenshot style)
3. User drags to select area
4. Vision framework processes the captured region
5. Recognized text goes to clipboard
6. Optional: Show preview/edit dialog before clipboard (configurable, default off)

**Settings:**
- Enable/disable Screen Text Capture feature (default off)
- OCR keyboard shortcut (default ⌥⌘R)
- Preview dialog before clipboard (default off)

## Menu Layout Design

**Progressive Disclosure Strategy:**
- Core features always visible
- OCR discovery always possible via "Enable Screen Text Capture" toggle
- OCR-specific options dimmed when disabled, active when enabled
- Logical grouping with clear separators

**Menu Structure:**
```
=== PRIMARY ACTIONS ===
📄 Type Clipboard (⌥⌘V)
👁 Capture Text from Screen (⌥⌘R) [when enabled]
───────────────────────────────
Clipboard: XX characters

=== TYPING SETTINGS ===
Typing Delay: [slider]
⚠️ Character Warning Threshold: XXX
🗑 Auto-clear Clipboard After Typing [toggle]

=== SCREEN TEXT CAPTURE ===
👁 Enable Screen Text Capture [toggle] - always visible
🔍 Show OCR Preview Dialog [toggle] - dimmed when disabled

=== DISPLAY SETTINGS ===
🔄 Countdown Display [submenu]
🔢 Show Character Count in Menu Bar [toggle]

=== SYSTEM SETTINGS ===
⌘ Change Typing Shortcut…
⌘ Change OCR Shortcut… [dimmed when OCR disabled]
⚡ Start ClipTyper at Login [toggle]

ℹ️ About ClipTyper
❌ Quit ClipTyper
```

## Critical Implementation Notes

### NSWindow Memory Management Issue
**IMPORTANT:** When creating NSWindow instances for screen capture overlays:
- ALWAYS set `window.isReleasedWhenClosed = false` immediately after creation
- This prevents automatic release when `window.close()` is called
- Without this, NSWindow gets over-released causing crashes in autorelease pool cleanup
- The crash manifests as: `*** -[NSWindow release]: message sent to deallocated instance`

### OCR Feature Components
- `ScreenCaptureOverlay.swift` - Manages transparent fullscreen window for area selection
- `ScreenTextCaptureManager.swift` - Coordinates selection → OCR → clipboard workflow  
- `OCRManager.swift` - Handles Apple Vision Framework integration for text recognition

**Future Enhancement Ideas:**
- Bitwarden integration
- Additional quality-of-life features