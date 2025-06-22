# ClipTyper v2.0

A powerful macOS status bar utility that simulates keyboard typing of clipboard contents and captures text from screen using OCR. Designed for security engineers, MSP employees, and professionals working through VPN/RDP jump hosts with restricted copy-paste functionality.

**📜 License**: GNU General Public License v3.0 | **🔓 Open Source** | **🛡️ Security Focused** | **✨ v2.0 Enhanced**

## 🚀 What's New in v2.0

### ✨ Enhanced Screen Text Capture (OCR)
- **Instant crosshair cursor** - Appears immediately when starting OCR selection
- **Persistent cursor state** - Cursor remains consistent throughout selection process
- **Improved text recognition** - Better line break detection and preservation
- **Responsive selection UX** - More fluid rubber-band selection with visual feedback

### ⌨️ Advanced Typing Engine
- **Line break preservation** - Multi-line OCR text types with proper Enter key presses
- **Enhanced Unicode support** - Better handling of complex characters and emoji
- **Improved text formatting** - Maintains original text structure and layout

## Core Features

### 🎯 Primary Functions
- **📋 Keyboard Typing Simulation** - Unicode-based typing that works across any keyboard layout
- **👁️ Screen Text Capture (OCR)** - Extract and type text directly from screen using Apple Vision Framework
- **⌨️ Global Shortcuts** - Default ⌥⌘V for typing, ⌥⌘R for OCR (fully customizable)
- **⏱️ Smart Countdown** - Configurable 0.5s-10s delay before typing begins
- **⚠️ Character Warnings** - Alerts for large text with configurable thresholds
- **🔒 Security Features** - Optional auto-clear clipboard, no persistent storage

### 🖥️ User Experience
- **📊 Menu Bar Integration** - Clean status bar presence with optional character count
- **🎛️ Flexible Display Options** - Choose countdown display location (dialog/menu bar)
- **♿ Accessibility Compliant** - Follows macOS accessibility and design guidelines
- **🚀 System Integration** - Optional autostart, modern login item management

### 🛡️ Security & Privacy
- **🔐 No Data Retention** - Zero clipboard history or persistent storage
- **📱 Offline Operation** - All processing performed locally, no network required
- **✅ Code Signed** - Developer ID signed for security and trust
- **🎯 Target-Specific** - Built for environments with restricted copy-paste

## Installation

### 📦 Download (Recommended)
1. Download `ClipTyper-2.0-Notarized.dmg` from [GitHub Releases](https://github.com/regalleuchte/ClipTyper/releases)
2. Mount the DMG and drag ClipTyper to Applications
3. Launch ClipTyper from Applications folder
4. Grant **Accessibility permissions** when prompted (required)
5. Grant **Screen Recording permissions** when using OCR feature (optional)

### 🔨 Build from Source
```bash
# Clone repository
git clone https://github.com/regalleuchte/ClipTyper.git
cd ClipTyper

# Build notarized DMG (requires Apple Developer account)
./build-notarized.sh

# Build basic DMG with auto-signing detection
./build-dmg.sh

# Build app bundle only
./build.sh
```

## Usage Guide

### 📋 Basic Clipboard Typing
1. **Copy text** to your clipboard from any source
2. **Activate ClipTyper** using:
   - Global shortcut: `⌥⌘V` (Option+Command+V)
   - Right-click the menu bar icon
3. **Position cursor** where you want the text to appear
4. **Wait for countdown** - ClipTyper types automatically after delay

### 👁️ Screen Text Capture (OCR)
1. **Activate OCR** using:
   - Global shortcut: `⌥⌘R` (Option+Command+R)
   - Menu bar: "Capture Text from Screen"
2. **Select text area** - Drag to select the screen region containing text
3. **Text recognition** - Apple Vision Framework extracts text from selection
4. **Automatic typing** - Recognized text is typed with preserved formatting

## Settings & Configuration

Access all settings by **left-clicking** the ClipTyper menu bar icon:

### ⌨️ Typing Settings
- **Typing Delay** - Countdown duration before typing begins (0.5s-10s, default: 2s)
- **Character Warning Threshold** - Alert limit for large text (default: 100 characters)
- **Auto-clear Clipboard** - Security feature to clear clipboard after typing

### 👁️ Screen Text Capture Settings
- **Enable Screen Text Capture** - Master toggle for OCR functionality
- **OCR Preview Dialog** - Optional preview/edit step before typing (default: off)
- **OCR Shortcut** - Customize the global OCR activation shortcut

### 🖥️ Display Settings
- **Countdown Display** - Choose between dialog window or menu bar countdown
- **Show Character Count** - Display current clipboard size in menu bar
- **Menu Bar Icon** - Dynamic status indication with character counts

### ⚙️ System Settings
- **Change Typing Shortcut** - Customize global activation shortcut (default: ⌥⌘V)
- **Change OCR Shortcut** - Customize OCR activation shortcut (default: ⌥⌘R)
- **Start at Login** - Enable/disable autostart with macOS boot

## Technical Requirements

### 🖥️ System Requirements
- **macOS 15.4+** (Apple Silicon recommended, Intel supported)
- **Apple Silicon or Intel** processor with adequate performance
- **1GB+ RAM** available for Vision Framework processing
- **50MB disk space** for application and temporary files

### 🔐 Permissions
- **Accessibility** *(Required)* - Enables keyboard simulation functionality
- **Screen Recording** *(Optional)* - Required only when using OCR features
- **Notifications** *(Optional)* - For error alerts and status updates

### 📦 Distribution
- **Notarized DMG** - Apple-approved distribution for security
- **Developer ID Signed** - Verified code signing for system trust
- **Gatekeeper Compatible** - Passes all macOS security requirements

## Architecture & Development

### 🏗️ Core Components
- **`AppDelegate.swift`** - Main application controller and menu bar UI management
- **`KeyboardSimulator.swift`** - Unicode-based typing simulation with Enter key support
- **`ScreenTextCaptureManager.swift`** - OCR workflow coordination and user interaction
- **`OCRManager.swift`** - Apple Vision Framework integration for text recognition
- **`ScreenCaptureOverlay.swift`** - Transparent selection overlay with cursor management
- **`GlobalShortcutManager.swift`** - Global keyboard shortcut handling and registration
- **`ClipboardManager.swift`** - Clipboard monitoring via efficient timer polling
- **`PreferencesManager.swift`** - UserDefaults-based settings persistence

### 🎯 Design Patterns
- **Manager Coordination** - AppDelegate orchestrates specialized manager classes
- **Callback Communication** - Loose coupling between components via closures
- **Timer-Based Monitoring** - Efficient clipboard polling every 0.5 seconds
- **Unicode-First Typing** - Layout-independent text simulation using CGEvent
- **Vision Framework Integration** - Apple's advanced OCR with offline processing

### 🔧 Key Technical Features
- **Cursor Stack Management** - Proper AppKit cursor handling with push/pop operations
- **Mouse Tracking Areas** - Enhanced cursor responsiveness and immediate feedback
- **Memory Management** - Careful window lifecycle handling and autorelease pools
- **Cross-Layout Typing** - Works with any keyboard layout or input method
- **Retina Display Support** - Proper coordinate handling for high-DPI screens

## Development Commands

### 🏗️ Building
```bash
# Development build
swift build -c release

# Run directly from build
./.build/release/ClipTyper

# Create app bundle with icon
./build.sh

# Create DMG with auto-signing detection
./build-dmg.sh

# Create notarized DMG for distribution
./build-notarized.sh
```

### 🧪 Testing & Debugging
```bash
# Run with console output
./build.sh && open ./ClipTyper.app

# Check signing and notarization
spctl -a -vvv ./ClipTyper.app
stapler validate ./ClipTyper-2.0-Notarized.dmg

# Monitor logs
log stream --predicate 'subsystem CONTAINS "ClipTyper"'
```

## Troubleshooting

### ⌨️ Typing Issues
**Shortcut not working:**
1. Check Accessibility permissions: System Settings → Privacy & Security → Accessibility
2. Remove and re-add ClipTyper from the Accessibility list
3. Try changing shortcut to a different key combination
4. Restart ClipTyper after permission changes

**Text not typing correctly:**
- Ensure target application accepts keyboard input
- Check that cursor is positioned in an editable text field
- Verify no conflicting shortcuts with other applications

### 👁️ OCR Issues
**Screen capture not working:**
1. Enable Screen Recording permission: System Settings → Privacy & Security → Screen Recording
2. Restart ClipTyper after granting Screen Recording permission
3. Test with simple, high-contrast text first

**Poor text recognition:**
- Use high-contrast text (dark text on light background works best)
- Ensure text is large enough and clearly visible
- Avoid heavily stylized fonts or low-resolution text

### 🚀 Launch Issues
**App won't start:**
- Ensure you're running macOS 15.4 or later
- For unsigned builds: Right-click app → Open (first launch only)
- Check Console.app for detailed error messages
- Verify app integrity: `codesign -vvv ./ClipTyper.app`

## Contributing

Contributions are welcome! ClipTyper is open source under GPLv3.

### 🤝 Development Process
1. **Fork** the repository on GitHub
2. **Create** a feature branch with descriptive name
3. **Implement** changes with proper GPLv3 headers
4. **Test** thoroughly on multiple macOS versions
5. **Submit** a pull request with detailed description

### 📋 Code Standards
- Follow existing Swift coding conventions
- Add proper documentation for public methods
- Include GPLv3 license headers in new files
- Test on both Apple Silicon and Intel Macs
- Maintain compatibility with target macOS versions

## License

**GNU General Public License v3.0**

ClipTyper is free and open source software. You are free to use, modify, and distribute it under the terms of the GPLv3 license.

**Copyright © 2025 Ralf Sturhan**

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the [GNU General Public License](https://www.gnu.org/licenses/) for more details.

---

## 🎯 Perfect for Security Professionals

**Target Users**: Security engineers, MSP employees, and IT professionals working through VPN/RDP jump hosts, virtual machines, or any environment where traditional copy-paste functionality is restricted or disabled.

**Why ClipTyper?**
- ✅ Bypasses copy-paste restrictions in remote environments
- ✅ Extracts text from non-selectable interfaces via OCR
- ✅ Maintains security with no data persistence
- ✅ Works offline without network dependencies
- ✅ Handles complex Unicode text and multi-line content
- ✅ Integrates seamlessly with macOS workflow

*Made with ❤️ for the security community*