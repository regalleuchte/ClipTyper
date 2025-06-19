import Foundation

class PreferencesManager {
    private let defaults = UserDefaults.standard
    
    // Preference keys
    private let typingDelayKey = "typingDelay"
    private let autoClearClipboardKey = "autoClearClipboard"
    private let showCharacterCountKey = "showCharacterCount"
    private let characterWarningThresholdKey = "characterWarningThreshold"
    private let showCountdownInMenuBarKey = "showCountdownInMenuBar"
    private let keyboardShortcutKeyCodeKey = "keyboardShortcutKeyCode"
    private let keyboardShortcutModifiersKey = "keyboardShortcutModifiers"
    
    // Default values
    private let defaultTypingDelay = 2.0
    private let defaultAutoClearClipboard = false
    private let defaultShowCharacterCount = false
    private let defaultCharacterWarningThreshold = 100
    private let defaultShowCountdownInMenuBar = false
    private let defaultKeyboardShortcutKeyCode: UInt16 = 9 // V key
    private let defaultKeyboardShortcutModifiers: UInt32 = 1048840 // Option+Command
    
    init() {
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
            keyboardShortcutModifiersKey: defaultKeyboardShortcutModifiers
        ]
        
        defaults.register(defaults: defaultValues)
    }
    
    // MARK: - Getters
    
    func getTypingDelay() -> Double {
        return defaults.double(forKey: typingDelayKey)
    }
    
    func getAutoClearClipboard() -> Bool {
        return defaults.bool(forKey: autoClearClipboardKey)
    }
    
    func getShowCharacterCount() -> Bool {
        return defaults.bool(forKey: showCharacterCountKey)
    }
    
    func getCharacterWarningThreshold() -> Int {
        return defaults.integer(forKey: characterWarningThresholdKey)
    }
    
    func getShowCountdownInMenuBar() -> Bool {
        return defaults.bool(forKey: showCountdownInMenuBarKey)
    }
    
    func getKeyboardShortcutKeyCode() -> UInt16 {
        return UInt16(defaults.integer(forKey: keyboardShortcutKeyCodeKey))
    }
    
    func getKeyboardShortcutModifiers() -> UInt32 {
        return UInt32(defaults.integer(forKey: keyboardShortcutModifiersKey))
    }
    
    // MARK: - Setters
    
    func setTypingDelay(_ delay: Double) {
        defaults.set(delay, forKey: typingDelayKey)
    }
    
    func setAutoClearClipboard(_ autoClear: Bool) {
        defaults.set(autoClear, forKey: autoClearClipboardKey)
    }
    
    func setShowCharacterCount(_ show: Bool) {
        defaults.set(show, forKey: showCharacterCountKey)
    }
    
    func setCharacterWarningThreshold(_ threshold: Int) {
        defaults.set(threshold, forKey: characterWarningThresholdKey)
    }
    
    func setShowCountdownInMenuBar(_ show: Bool) {
        defaults.set(show, forKey: showCountdownInMenuBarKey)
    }
    
    func setKeyboardShortcut(keyCode: UInt16, modifiers: UInt32) {
        defaults.set(Int(keyCode), forKey: keyboardShortcutKeyCodeKey)
        defaults.set(Int(modifiers), forKey: keyboardShortcutModifiersKey)
    }
} 