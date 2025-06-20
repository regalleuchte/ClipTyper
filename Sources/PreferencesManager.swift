//
//  PreferencesManager.swift
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

/// Manages user preferences and application settings
/// 
/// This class provides a centralized interface for managing all user preferences,
/// including typing delays, keyboard shortcuts, and display options.
class PreferencesManager {
    private let defaults: UserDefaults
    
    // Preference keys (using constants for consistency)
    private let typingDelayKey = Constants.PreferenceKeys.typingDelay
    private let autoClearClipboardKey = Constants.PreferenceKeys.autoClearClipboard
    private let showCharacterCountKey = Constants.PreferenceKeys.showCharacterCount
    private let characterWarningThresholdKey = Constants.PreferenceKeys.characterWarningThreshold
    private let showCountdownInMenuBarKey = Constants.PreferenceKeys.showCountdownInMenuBar
    private let keyboardShortcutKeyCodeKey = Constants.PreferenceKeys.keyboardShortcutKeyCode
    private let keyboardShortcutModifiersKey = Constants.PreferenceKeys.keyboardShortcutModifiers
    private let autostartKey = Constants.PreferenceKeys.autostart
    
    // Default values (using constants for consistency)
    private let defaultTypingDelay = Constants.defaultTypingDelay
    private let defaultAutoClearClipboard = false
    private let defaultShowCharacterCount = false
    private let defaultCharacterWarningThreshold = Constants.defaultCharacterWarningThreshold
    private let defaultShowCountdownInMenuBar = false
    private let defaultKeyboardShortcutKeyCode = Constants.defaultKeyCode
    private let defaultKeyboardShortcutModifiers = Constants.defaultModifiers
    private let defaultAutostart = false
    
    /// Initialize with optional UserDefaults instance (useful for testing)
    /// - Parameter userDefaults: UserDefaults instance to use (defaults to .standard)
    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        registerDefaults()
    }
    
    private func registerDefaults() {
        let defaultValues: [String: Any] = [
            typingDelayKey: defaultTypingDelay,
            autoClearClipboardKey: defaultAutoClearClipboard,
            showCharacterCountKey: defaultShowCharacterCount,
            characterWarningThresholdKey: defaultCharacterWarningThreshold,
            showCountdownInMenuBarKey: defaultShowCountdownInMenuBar,
            keyboardShortcutKeyCodeKey: defaultKeyboardShortcutKeyCode,
            keyboardShortcutModifiersKey: defaultKeyboardShortcutModifiers,
            autostartKey: defaultAutostart
        ]
        
        defaults.register(defaults: defaultValues)
    }
    
    // MARK: - Computed Properties
    
    /// Typing delay in seconds before text is typed
    var typingDelay: Double {
        get { defaults.double(forKey: typingDelayKey) }
        set { defaults.set(newValue, forKey: typingDelayKey) }
    }
    
    /// Whether to automatically clear clipboard after typing
    var autoClearClipboard: Bool {
        get { defaults.bool(forKey: autoClearClipboardKey) }
        set { defaults.set(newValue, forKey: autoClearClipboardKey) }
    }
    
    /// Whether to show character count in menu bar
    var showCharacterCount: Bool {
        get { defaults.bool(forKey: showCharacterCountKey) }
        set { defaults.set(newValue, forKey: showCharacterCountKey) }
    }
    
    /// Character count threshold for showing warnings
    var characterWarningThreshold: Int {
        get { defaults.integer(forKey: characterWarningThresholdKey) }
        set { defaults.set(newValue, forKey: characterWarningThresholdKey) }
    }
    
    /// Whether to show countdown in menu bar instead of dialog
    var showCountdownInMenuBar: Bool {
        get { defaults.bool(forKey: showCountdownInMenuBarKey) }
        set { defaults.set(newValue, forKey: showCountdownInMenuBarKey) }
    }
    
    /// Keyboard shortcut key code
    var keyboardShortcutKeyCode: UInt16 {
        get { 
            let value = defaults.integer(forKey: keyboardShortcutKeyCodeKey)
            // If value is 0, it might mean the key doesn't exist - use default
            return value == 0 ? defaultKeyboardShortcutKeyCode : UInt16(value)
        }
        set { defaults.set(Int(newValue), forKey: keyboardShortcutKeyCodeKey) }
    }
    
    /// Keyboard shortcut modifier flags
    var keyboardShortcutModifiers: UInt32 {
        get { 
            let value = defaults.integer(forKey: keyboardShortcutModifiersKey)
            // If value is 0, it might mean the key doesn't exist - use default
            return value == 0 ? defaultKeyboardShortcutModifiers : UInt32(value)
        }
        set { defaults.set(Int(newValue), forKey: keyboardShortcutModifiersKey) }
    }
    
    /// Whether to start app automatically at login
    var autostart: Bool {
        get { defaults.bool(forKey: autostartKey) }
        set { defaults.set(newValue, forKey: autostartKey) }
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    
    @available(*, deprecated, message: "Use typingDelay property instead")
    func getTypingDelay() -> Double { return typingDelay }
    
    @available(*, deprecated, message: "Use typingDelay property instead")
    func setTypingDelay(_ delay: Double) { typingDelay = delay }
    
    @available(*, deprecated, message: "Use autoClearClipboard property instead")
    func getAutoClearClipboard() -> Bool { return autoClearClipboard }
    
    @available(*, deprecated, message: "Use autoClearClipboard property instead")
    func setAutoClearClipboard(_ autoClear: Bool) { autoClearClipboard = autoClear }
    
    @available(*, deprecated, message: "Use showCharacterCount property instead")
    func getShowCharacterCount() -> Bool { return showCharacterCount }
    
    @available(*, deprecated, message: "Use showCharacterCount property instead")
    func setShowCharacterCount(_ show: Bool) { showCharacterCount = show }
    
    @available(*, deprecated, message: "Use characterWarningThreshold property instead")
    func getCharacterWarningThreshold() -> Int { return characterWarningThreshold }
    
    @available(*, deprecated, message: "Use characterWarningThreshold property instead")
    func setCharacterWarningThreshold(_ threshold: Int) { characterWarningThreshold = threshold }
    
    @available(*, deprecated, message: "Use showCountdownInMenuBar property instead")
    func getShowCountdownInMenuBar() -> Bool { return showCountdownInMenuBar }
    
    @available(*, deprecated, message: "Use showCountdownInMenuBar property instead")
    func setShowCountdownInMenuBar(_ show: Bool) { showCountdownInMenuBar = show }
    
    @available(*, deprecated, message: "Use keyboardShortcutKeyCode and keyboardShortcutModifiers properties instead")
    func getKeyboardShortcutKeyCode() -> UInt16 { return keyboardShortcutKeyCode }
    
    @available(*, deprecated, message: "Use keyboardShortcutKeyCode and keyboardShortcutModifiers properties instead")
    func getKeyboardShortcutModifiers() -> UInt32 { return keyboardShortcutModifiers }
    
    @available(*, deprecated, message: "Use keyboardShortcutKeyCode and keyboardShortcutModifiers properties instead")
    func setKeyboardShortcut(keyCode: UInt16, modifiers: UInt32) {
        keyboardShortcutKeyCode = keyCode
        keyboardShortcutModifiers = modifiers
    }
    
    @available(*, deprecated, message: "Use autostart property instead")
    func getAutostart() -> Bool { return autostart }
    
    @available(*, deprecated, message: "Use autostart property instead")
    func setAutostart(_ autostart: Bool) { self.autostart = autostart }
} 