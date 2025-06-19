# ClipTyper

A macOS utility that simulates keyboard typing of clipboard contents. Perfect for scenarios where copy-paste is restricted, such as secure remote sessions, VPNs, RDPs, and jump hosts.

## Features

- Simulates keyboard typing of clipboard contents
- Works regardless of keyboard language settings
- Preserves all text formatting, capitalization, and special characters
- Fully supports Unicode characters
- Configurable delay before typing begins (0.5s-10s)
- Optional auto-clearing of clipboard after typing
- Warning dialog for large text
- Runs completely offline

## Usage

1. Copy text to clipboard
2. Click the ClipTyper menu bar icon or press ⌥⌘V (Option+Command+V)
3. Position your cursor where you want the text to appear
4. Wait for the countdown to complete
5. The text will be typed automatically

## Settings

Right-click on the ClipTyper menu bar icon to access settings:

- Adjust typing delay (0.5s-10s)
- Toggle auto-clear clipboard after typing
- Toggle character count display in menu bar
- Choose countdown display method (dialog or menu bar)
- Set character warning threshold

## Requirements

- macOS 12.0 or later
- Apple Silicon (M-series) or Intel processor

## Installation

### Option 1: Build From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourname/ClipTyper.git
   cd ClipTyper
   ```

2. Build using Swift Package Manager:
   ```bash
   swift build -c release
   ```

3. Run the build script to create the app:
   ```bash
   ./build.sh
   ```

4. Move the app to your Applications folder:
   ```bash
   mv ClipTyper.app /Applications/
   ```

### Option 2: Download Pre-built App

1. Download the latest release from the Releases page
2. Move ClipTyper.app to your Applications folder
3. Launch ClipTyper
4. Grant Accessibility permissions when prompted

## Permissions

ClipTyper requires Accessibility permissions to simulate keyboard input. When you first launch the app, you'll be prompted to grant these permissions in System Preferences > Security & Privacy > Privacy > Accessibility.

## Development

### Project Structure

- `main.swift` - Application entry point
- `AppDelegate.swift` - Core application logic and UI
- `PreferencesManager.swift` - Manages user preferences
- `ClipboardManager.swift` - Handles clipboard monitoring and operations
- `KeyboardSimulator.swift` - Simulates keyboard typing
- `GlobalShortcutManager.swift` - Manages global keyboard shortcuts

### Building a DMG for Distribution

To create a distributable DMG file:

1. Build the app using `./build.sh`
2. Use a tool like `create-dmg` to package the app:
   ```bash
   create-dmg \
     --volname "ClipTyper Installer" \
     --volicon "AppIcon.icns" \
     --window-pos 200 120 \
     --window-size 800 400 \
     --icon-size 100 \
     --icon "ClipTyper.app" 200 190 \
     --hide-extension "ClipTyper.app" \
     --app-drop-link 600 185 \
     "ClipTyper.dmg" \
     "ClipTyper.app"
   ```

## License

This software is provided "as is" without warranty of any kind.

---

Developed for professionals who work across multiple secure systems where traditional copy-paste functionality is restricted. 