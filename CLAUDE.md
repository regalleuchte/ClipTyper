# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Building and Development
- Build the project: `swift build -c release`
- Create app bundle: `./build.sh`
- Run directly from build: `./.build/release/ClipTyper`

## Target Requirements & Constraints

**Target Users:** Security engineers, MSP employees, and engineers working through VPN/RDP jump hosts with restricted copy-paste functionality.

**Hard Constraints:**
- Must run fully offline
- Requires Accessibility permissions 
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

**Future Enhancement Ideas:**
- Bitwarden integration
- OCR functionality for screen text capture
- Additional quality-of-life features