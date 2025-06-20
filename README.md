# ClipTyper

A free and open source macOS status bar utility that simulates keyboard typing of clipboard contents. Designed for security engineers, MSP employees, and professionals working through VPN/RDP jump hosts with restricted copy-paste functionality.

**📜 License**: GNU General Public License v3.0 | **🔓 Open Source** | **🛡️ Security Focused**

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
1. Download `ClipTyper-1.1-Signed.dmg` from releases
2. Mount the DMG and drag ClipTyper to Applications
3. Launch ClipTyper from Applications
4. Grant Accessibility permissions when prompted

The app includes a custom icon that will appear in your Applications folder and Dock.

### Build from Source
```bash
# Clone repository
git clone <repository-url>
cd ClipTyper

# Build signed DMG (requires Developer ID certificate)
./build-signed.sh

# Build DMG with auto-signing detection
./build-dmg.sh

# Basic app bundle only
./build.sh
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

# Create app bundle only
./build.sh

# Create DMG with auto-signing detection
./build-dmg.sh

# Create signed DMG for distribution (requires Developer ID)
./build-signed.sh
```

### Build Scripts
- `./build.sh` - Creates basic app bundle with icon support
- `./build-dmg.sh` - Creates DMG with auto-signing detection and ClipTyper.icns
- `./build-signed.sh` - Creates fully signed DMG for public distribution

### Icon Support
The app now includes custom icon support:
- App icon: `ClipTyper.icns` (converted from ClipTyper.iconset)
- Status bar: Uses SF Symbols (`doc.on.clipboard.fill`) with dynamic state changes
- All build scripts automatically include the custom icon

### Commands (see CLAUDE.md)
- Build: `swift build -c release`
- Create app bundle: `./build.sh`
- Run from build: `./.build/release/ClipTyper`
- Create DMG: `./build-dmg.sh`
- Create signed DMG: `./build-signed.sh`

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

ClipTyper is free and open source software licensed under the GNU General Public License v3.0.

Copyright © 2025 Ralf Sturhan

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

### Why GPLv3?

ClipTyper is now open source to benefit the security engineering and systems administration community. The GPLv3 license ensures that:

- ✅ **Free redistribution** - Anyone can share ClipTyper
- ✅ **Source code access** - Full source code is always available
- ✅ **Modification rights** - Users can adapt ClipTyper to their needs
- ✅ **Copyleft protection** - Derivative works must also be open source
- ✅ **Patent protection** - Protection against patent claims
- ✅ **Commercial use** - Organizations can use ClipTyper in commercial environments

### Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes with proper GPLv3 headers
4. Submit a pull request

All contributions must be compatible with GPLv3 licensing.

---

**Target Users**: Security engineers, MSP employees, and engineers working through VPN/RDP jump hosts with restricted copy-paste functionality.

**Distribution**: Mac App Store (preferred) or notarized DMG (fallback)