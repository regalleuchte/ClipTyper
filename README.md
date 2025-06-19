# ClipTyper

A macOS status bar utility that simulates keyboard typing of clipboard contents. Designed for security engineers, MSP employees, and professionals working through VPN/RDP jump hosts with restricted copy-paste functionality.

## Features

### Core Functionality
- **Unicode-based typing simulation** - Works regardless of keyboard layout or language
- **Global keyboard shortcut** - Default ⌥⌘V (Option+Command+V), fully customizable
- **Configurable typing delay** - 0.5s to 10s countdown before typing begins
- **Character warning system** - Alerts for large text (configurable threshold)
- **Auto-clear clipboard** - Optional security feature to clear clipboard after typing
- **Offline operation** - No network connectivity required

### User Experience
- **Menu bar integration** - Clean status bar presence with optional character count display
- **Countdown display options** - Choose between dialog window or menu bar countdown
- **Accessibility compliance** - Follows macOS accessibility guidelines
- **Login item support** - Optional autostart with system boot

### Security & Privacy
- **No persistent storage** - No clipboard history or data retention
- **Local processing only** - All operations performed locally
- **Developer ID signed** - Code signed for security and trust

## Installation

### Download (Recommended)
1. Download `ClipTyper-1.0-Signed.dmg` from releases
2. Mount the DMG and drag ClipTyper to Applications
3. Launch ClipTyper from Applications
4. Grant Accessibility permissions when prompted

### Build from Source
```bash
# Clone repository
git clone <repository-url>
cd ClipTyper

# Build signed app (requires Developer ID certificate)
./build-signed.sh

# Or build unsigned version
./build-dmg.sh
```

## Usage

1. **Copy text** to your clipboard
2. **Activate ClipTyper** using:
   - Global shortcut: ⌥⌘V (Option+Command+V)
   - Right-click menu bar icon
3. **Position cursor** where you want text to appear
4. **Wait for countdown** - ClipTyper will type automatically

## Settings

Access settings by left-clicking the ClipTyper menu bar icon:

### Typing Settings
- **Typing Delay** - Adjustable countdown before typing begins (0.5s-10s)
- **Character Warning Threshold** - Set limit for large text warnings (default: 100)
- **Auto-clear Clipboard** - Automatically clear clipboard after typing (security feature)

### Display Settings  
- **Countdown Display** - Choose between dialog window or menu bar countdown
- **Show Character Count** - Display clipboard character count in menu bar

### System Settings
- **Change Keyboard Shortcut** - Customize the global activation shortcut
- **Start at Login** - Enable/disable autostart with macOS

## Requirements

- **macOS 15.4+** (broader compatibility available)
- **Apple Silicon or Intel** processor
- **Accessibility permissions** - Required for keyboard simulation
- **Code signing** - Developer ID Application certificate for distribution builds

## Architecture

### Core Components
- `AppDelegate.swift` - Main application controller and UI management
- `KeyboardSimulator.swift` - Unicode-based typing simulation engine
- `GlobalShortcutManager.swift` - Global keyboard shortcut handling
- `ClipboardManager.swift` - Clipboard monitoring via timer polling
- `PreferencesManager.swift` - UserDefaults-based settings management
- `LoginItemManager.swift` - Autostart functionality using modern macOS APIs

### Key Design Patterns
- **Manager pattern** - Specialized classes coordinated by AppDelegate
- **Timer-based monitoring** - Polls clipboard changes every 0.5 seconds
- **Unicode-based typing** - Bypasses keyboard layout dependencies using CGEvent
- **Callback-based communication** - Loose coupling between components

## Development

### Building
```bash
# Development build
swift build -c release

# Create app bundle
./build.sh

# Create signed DMG for distribution
./build-signed.sh
```

### Commands (see CLAUDE.md)
- Build: `swift build -c release`
- Create app bundle: `./build.sh`
- Run from build: `./.build/release/ClipTyper`
- Create signed DMG: `./build-signed.sh`

### Distribution
The project includes automated build scripts for creating distributable DMGs:
- `build-dmg.sh` - Creates unsigned DMG for development/testing
- `build-signed.sh` - Creates code-signed DMG for public distribution

## Troubleshooting

### Shortcut Not Working
1. Check Accessibility permissions in System Settings → Privacy & Security → Accessibility
2. Remove and re-add ClipTyper from Accessibility list
3. Try changing shortcut to different key combination

### App Won't Launch
- Ensure you're running macOS 12.0 or later
- For unsigned builds: Right-click app → Open (first launch only)
- Check Console.app for error messages

## License

Copyright © 2025 Ralf Sturhan. All rights reserved.

This software is provided "as is" without warranty of any kind.

---

**Target Users**: Security engineers, MSP employees, and engineers working through VPN/RDP jump hosts with restricted copy-paste functionality.

**Distribution**: Mac App Store (preferred) or notarized DMG (fallback)