# ClipTyper v2.0 - Project Specification

## Overview

ClipTyper is a macOS status bar utility that simulates keyboard typing of clipboard content, solving copy-paste restrictions when working through multiple secure remote sessions, VPNs, RDPs, and jump hosts.

## Version 2.0 Features

**Enhanced OCR Text Capture:**
- ✅ Proper line break preservation - OCR text maintains original formatting when typed
- ✅ Intelligent text region sorting for correct reading order
- ✅ Improved crosshair cursor behavior with immediate appearance
- ✅ Enhanced cursor stack management (push/pop) for reliable state handling
- ✅ ESC key handling with proper cursor restoration

**Keyboard Simulation Improvements:**
- ✅ Line breaks (`\n`) now trigger actual Enter key presses instead of literal characters
- ✅ Multi-line text from OCR types with proper paragraph structure
- ✅ Enhanced Unicode handling with special character support

## Target Users

**Primary Personas:**
- Security engineers hopping through VPN + RDP jump hosts 20× a day
- Managed service provider employees
- Computer engineers working in secure environments with restricted copy-paste functionality

## Core Features

### Clipboard Typing
- ✅ Simulates keyboard typing of clipboard contents
- ✅ Works regardless of keyboard language settings  
- ✅ Preserves all text formatting, capitalization, and special characters
- ✅ Full Unicode support
- ✅ Configurable delay before typing (0.5s-10s, default 2s)
- ✅ Optional auto-clear clipboard after typing (default off)
- ✅ Warning dialog for large text (>100 characters, configurable)
- ✅ Runs completely offline

### Screen Text Capture (OCR)
- 🔍 Perfect complement for VPN/RDP environments where text isn't selectable
- 🔍 Uses Apple's Vision Framework for offline OCR processing
- 🔍 Mimics Apple's ⇧⌘4 screenshot selection interface
- 🔍 Default shortcut: ⌥⌘R (Option+Command+R)
- 🔍 Configurable enable/disable (default off)
- 🔍 Optional preview dialog before clipboard (default off)
- 🔍 Requires Screen Recording permission (only when enabled)
- 🔍 Uses CGDisplayCreateImage for screen capture

**OCR Workflow:**
1. User triggers OCR capture (menu/shortcut ⌥⌘R)
2. Screen dims with selection overlay (Apple screenshot style)
3. User drags to select area
4. Vision framework processes the captured region
5. Recognized text goes to clipboard
6. Optional: Show preview/edit dialog before clipboard

## User Interface

### Menu Bar Integration
- Status bar icon with optional character count display
- Right-click: Activate typing function
- Left-click: Open settings menu
- OCR action appears when feature enabled

### Controls & Shortcuts
- **Primary shortcut:** ⌥⌘V (Option+Command+V) - Type clipboard
- **OCR shortcut:** ⌥⌘R (Option+Command+R) - Capture text from screen
- **Shortcut hint:** Press shortcut again during warning to proceed
- All settings accessible from menu

### Dialog Design
- Warning dialog for large clipboard content
- Countdown display (dialog or menu bar preference)
- Dialogs positioned directly under menu bar icon
- Always on top, focus-preserving design
- Modern styling following Apple Human Interface Guidelines

## Menu Layout

```
=== PRIMARY ACTIONS ===
📄 Type Clipboard (⌥⌘V)
👁 Capture Text from Screen (⌥⌘R) [when enabled]
───────────────────────────────
Clipboard: XX characters

=== TYPING SETTINGS ===
Typing Delay: [slider 0.5s-10s, default 2s]
⚠️ Character Warning Threshold: XXX
🗑 Auto-clear Clipboard After Typing [toggle]

=== SCREEN TEXT CAPTURE ===
👁 Enable Screen Text Capture [toggle] - always visible
🔍 Show OCR Preview Dialog [toggle] - dimmed when disabled

=== DISPLAY SETTINGS ===
🔄 Countdown Display [submenu: Dialog/Menu Bar]
🔢 Show Character Count in Menu Bar [toggle]

=== SYSTEM SETTINGS ===
⌘ Change Typing Shortcut…
⌘ Change OCR Shortcut… [dimmed when OCR disabled]
⚡ Start ClipTyper at Login [toggle]

ℹ️ About ClipTyper
❌ Quit ClipTyper
```

## Settings Configuration

| Setting | Default | Options | Description |
|---------|---------|---------|-------------|
| Typing Shortcut | ⌥⌘V | Configurable | Global hotkey for typing |
| OCR Shortcut | ⌥⌘R | Configurable | Global hotkey for screen capture |
| Typing Delay | 2s | 0.5s-10s | Countdown before typing begins |
| Character Warning | 100 | Any number | Threshold for warning dialog |
| Auto-clear Clipboard | Off | On/Off | Clear clipboard after typing |
| Show Character Count | Off | On/Off | Display count in menu bar |
| Countdown Display | Dialog | Dialog/Menu Bar | Where to show countdown |
| Autostart | Off | On/Off | Launch at login |
| OCR Feature | Off | On/Off | Enable Screen Text Capture |
| OCR Preview | Off | On/Off | Show preview before clipboard |

## Technical Requirements

### Platform Support
- **Target:** Apple Silicon + macOS 15.4+
- **Compatibility:** Broader macOS compatibility preferred
- **Architecture:** Native Swift application

### Permissions
- **Always Required:** Accessibility permissions (for keyboard simulation)
- **Conditionally Required:** Screen Recording permissions (only when OCR enabled)

### Security & Privacy
- ✅ Runs completely offline
- ✅ No persistent storage of clipboard contents
- ✅ No clipboard history
- ✅ No network connections
- ✅ Minimal resource usage

### Distribution
- **Primary:** Mac App Store
- **Fallback:** Notarized DMG

## UI/UX Mockups

### Menu Bar States
```
[Normal State]
┌─────────────────────────────────────────────┐
│ 📋 42          [other menu bar items...]    │
└─────────────────────────────────────────────┘

[During Countdown]
┌─────────────────────────────────────────────┐
│ 📋 2s          [other menu bar items...]    │
└─────────────────────────────────────────────┘
```

### Warning Dialog
```
┌───────────────────────────────────────────────┐
│                   ClipTyper                   │
│                                               │
│  The clipboard contains 142 characters.       │
│  Do you want to proceed with typing?          │
│                                               │
│  Tip: Press ⌥⌘V again to proceed              │
│                                               │
│           [Cancel]    [Proceed]               │
└───────────────────────────────────────────────┘
```

### Countdown Dialog
```
┌───────────────────────────────────────────────┐
│                   ClipTyper                   │
│                                               │
│             Typing will begin in              │
│                                               │
│                     2...                      │
│                                               │
│             [Cancel Typing]                   │
└───────────────────────────────────────────────┘
```

## Implementation Considerations

### Core Requirements
- Proper Unicode character handling across all languages
- Graceful accessibility permission management
- Reliable keyboard simulation in all contexts
- Clean, minimal UI matching macOS design language
- Focus-preserving dialogs that don't interfere with workflow

### Progressive Disclosure
- Core typing features always visible
- OCR discovery always possible via enable toggle
- OCR-specific options dimmed when disabled
- Logical feature grouping with clear separators

## Future Enhancements

- **Bitwarden Integration:** Password manager connectivity
- **Additional QoL Features:** User-requested improvements
- **Extended OCR:** Additional text recognition capabilities

## Hard Constraints

✅ **Must run fully offline** - No network dependencies
✅ **Accessibility permissions required** - For keyboard simulation  
✅ **Screen Recording permissions** - Only when OCR enabled
✅ **No open-source licensing requirements** - Dependencies can be proprietary
✅ **Security-first design** - No persistent data storage