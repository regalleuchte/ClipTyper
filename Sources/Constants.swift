//
//  Constants.swift
//  ClipTyper
//
//  Copyright © 2025 Ralf Sturhan
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import Foundation
import Carbon

/// Application-wide constants and default values
enum Constants {
    
    // MARK: - Timing Constants
    
    /// Default typing delay in seconds
    static let defaultTypingDelay: Double = 2.0
    
    /// Minimum typing delay in seconds
    static let minimumTypingDelay: Double = 0.5
    
    /// Maximum typing delay in seconds
    static let maximumTypingDelay: Double = 10.0
    
    /// Default typing speed in milliseconds (delay between characters)
    static let defaultTypingSpeed: Double = 20.0
    
    /// Minimum typing speed in milliseconds (fastest)
    static let minimumTypingSpeed: Double = 2.0
    
    /// Maximum typing speed in milliseconds (slowest)
    static let maximumTypingSpeed: Double = 200.0
    
    /// Clipboard monitoring interval in seconds
    static let clipboardMonitoringInterval: TimeInterval = 0.5
    
    // MARK: - UI Constants
    
    /// Default character warning threshold
    static let defaultCharacterWarningThreshold = 100
    
    /// Status bar icon size in points
    static let statusBarIconSize: CGFloat = 16
    
    /// Status bar icon weight
    static let statusBarIconWeight: CGFloat = 0.5 // medium
    
    /// Status bar icon scale
    static let statusBarIconScale: CGFloat = 0.5 // medium
    
    // MARK: - Keyboard Constants
    
    /// Default keyboard shortcut key code (V key)
    static let defaultKeyCode: UInt16 = 9
    
    /// Default keyboard shortcut modifiers (Option + Command)
    static let defaultModifiers: UInt32 = UInt32(optionKey) | UInt32(cmdKey)
    
    /// Default OCR shortcut key code (R key)
    static let defaultOCRKeyCode: UInt16 = 15
    
    /// Default OCR shortcut modifiers (Option + Command)
    static let defaultOCRModifiers: UInt32 = UInt32(optionKey) | UInt32(cmdKey)
    
    // MARK: - Preference Keys
    
    enum PreferenceKeys {
        static let typingDelay = "typingDelay"
        static let typingSpeed = "typingSpeed"
        static let autoClearClipboard = "autoClearClipboard"
        static let showCharacterCount = "showCharacterCount"
        static let characterWarningThreshold = "characterWarningThreshold"
        static let showCountdownInMenuBar = "showCountdownInMenuBar"
        static let keyboardShortcutKeyCode = "keyboardShortcutKeyCode"
        static let keyboardShortcutModifiers = "keyboardShortcutModifiers"
        static let autostart = "autostart"
        
        // OCR Feature Keys
        static let ocrEnabled = "ocrEnabled"
        static let ocrShowPreview = "ocrShowPreview"
        static let ocrShortcutKeyCode = "ocrShortcutKeyCode"
        static let ocrShortcutModifiers = "ocrShortcutModifiers"
    }
    
    // MARK: - SF Symbols
    
    enum SFSymbols {
        /// Main clipboard icon (filled)
        static let clipboardFilled = "doc.on.clipboard.fill"
        
        /// Empty clipboard icon (outline)
        static let clipboardEmpty = "doc.on.clipboard"
        
        /// Timer icon for countdown
        static let timer = "timer"
        
        /// Gear icon for settings
        static let gear = "gear"
        
        /// Checkmark icon
        static let checkmark = "checkmark"
        
        // Menu Icons
        static let typeClipboard = "square.and.arrow.up"
        static let characterWarning = "square.and.arrow.up.trianglebadge.exclamationmark"
        static let autoClear = "clear"
        static let countdownDisplay = "arrow.counterclockwise.square"
        static let showNumbers = "numbers"
        static let command = "command"
        static let power = "power"
        static let info = "info.square"
        static let quit = "xmark.square"
        
        // OCR Icons
        static let viewfinder = "viewfinder"
        static let magnifyingGlass = "magnifyingglass"
    }
    
    // MARK: - System URLs
    
    enum SystemURLs {
        /// Login Items settings in macOS 13+
        static let loginItemsModern = "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
        
        /// Users & Groups in older macOS versions
        static let usersAndGroups = "x-apple.systempreferences:com.apple.preference.users"
    }
    
    // MARK: - Bundle Constants
    
    enum Bundle {
        /// App bundle identifier
        static let identifier = "de.sturhan.ClipTyper"
        
        /// App name
        static let name = "ClipTyper"
        
        /// App version
        static let version = "2.1"
    }
}