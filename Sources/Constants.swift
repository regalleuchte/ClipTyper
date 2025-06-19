//
//  Constants.swift
//  ClipTyper
//
//  Copyright © 2025 Ralf Sturhan. All rights reserved.
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
    
    // MARK: - Preference Keys
    
    enum PreferenceKeys {
        static let typingDelay = "typingDelay"
        static let autoClearClipboard = "autoClearClipboard"
        static let showCharacterCount = "showCharacterCount"
        static let characterWarningThreshold = "characterWarningThreshold"
        static let showCountdownInMenuBar = "showCountdownInMenuBar"
        static let keyboardShortcutKeyCode = "keyboardShortcutKeyCode"
        static let keyboardShortcutModifiers = "keyboardShortcutModifiers"
        static let autostart = "autostart"
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
        static let version = "1.1"
    }
}