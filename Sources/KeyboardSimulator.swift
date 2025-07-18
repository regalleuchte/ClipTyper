//
//  KeyboardSimulator.swift
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

import Cocoa

/// Handles keyboard simulation using Core Graphics events
/// 
/// This class provides Unicode-based text typing that works across different
/// keyboard layouts and languages. It uses CGEvent API to simulate typing
/// at the system level, bypassing keyboard layout dependencies.
/// 
/// ## Special Handling
/// - Line breaks (`\n`) are converted to actual Enter key presses
/// - Unicode characters including emoji are supported
/// - Preserves text formatting and layout
/// 
/// ## Requirements
/// - Accessibility permissions must be granted
/// - macOS 12.0+
/// 
/// ## Usage
/// ```swift
/// let simulator = KeyboardSimulator()
/// simulator.typeText("Line 1\nLine 2") // Types with actual line break
/// simulator.typeText("Hello, World! 🌍") // Supports Unicode
/// ```
class KeyboardSimulator {
    
    /// Preferences manager for accessing typing speed settings
    private let preferencesManager: PreferencesManager
    
    /// Dispatch queue for typing operations
    private let typingQueue = DispatchQueue(label: "com.cliptyper.typing", qos: .userInitiated)
    
    /// Initialize with optional PreferencesManager (useful for testing)
    /// - Parameter preferencesManager: PreferencesManager instance to use (defaults to new instance)
    init(preferencesManager: PreferencesManager = PreferencesManager()) {
        self.preferencesManager = preferencesManager
    }
    
    /// Types the specified text using Unicode-based keyboard simulation
    /// 
    /// This method converts text to Unicode scalars and uses CGEvent to simulate
    /// typing character by character. It handles complex Unicode including emoji
    /// and multi-byte characters correctly. Line breaks (`\n`) are automatically
    /// converted to Enter key presses for proper text formatting.
    /// 
    /// - Parameter text: The text to type. Supports full Unicode including emoji and line breaks
    /// - Note: Requires accessibility permissions to function
    /// - Warning: Will silently fail if accessibility permissions are not granted
    func typeText(_ text: String) {
        // Check accessibility permissions
        guard AXIsProcessTrusted() else {
            print("Accessibility permissions are not granted")
            return
        }
        
        // Use the Unicode scalar approach for reliable typing
        sendUnicode(text)
    }
    
    /// Sends Unicode text via Core Graphics events
    /// 
    /// This private method handles the low-level details of converting text to
    /// Unicode scalars and creating CGEvent key events for each character.
    /// 
    /// - Parameter text: The text to convert and send as keyboard events
    /// - Implementation: Uses UTF-16 encoding and CGEvent keyboard events
    private func sendUnicode(_ text: String) {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            print("Failed to create event source")
            return
        }
        
        // Convert text to array of characters for processing
        let characters = Array(text)
        let totalCharacters = characters.count
        
        // Process characters asynchronously to avoid blocking the main thread
        typingQueue.async { [weak self] in
            guard let self = self else { return }
            
            for (index, character) in characters.enumerated() {
                let characterString = String(character)
                
                // Special handling for line breaks - simulate Enter key press instead of typing \n
                if character == "\n" {
                    print("KeyboardSimulator: Simulating Enter key for line break")
                    self.simulateEnterKey(using: source)
                } else {
                    // Convert to UTF-16 for proper Unicode handling
                    let utf16Array = Array(characterString.utf16)
                    
                    // Skip if conversion fails or produces invalid data
                    guard !utf16Array.isEmpty else {
                        print("Skipping invalid Unicode character")
                        continue
                    }
                    
                    // Create events for the entire character sequence
                    var unicharArray = utf16Array.map { UniChar($0) }
                    
                    // Post key events on main thread to ensure proper event handling
                    DispatchQueue.main.sync {
                        // Create key down event
                        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                            keyDown.keyboardSetUnicodeString(stringLength: utf16Array.count, unicodeString: &unicharArray)
                            keyDown.post(tap: .cghidEventTap)
                        }
                        
                        // Create key up event
                        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                            keyUp.keyboardSetUnicodeString(stringLength: utf16Array.count, unicodeString: &unicharArray)
                            keyUp.post(tap: .cghidEventTap)
                        }
                    }
                }
                
                // Delay between characters without blocking
                let delayMilliseconds = self.preferencesManager.typingSpeed
                if index < totalCharacters - 1 { // Don't delay after the last character
                    Thread.sleep(forTimeInterval: delayMilliseconds / 1000.0)
                }
            }
        }
    }
    
    /// Simulates pressing the Enter key
    /// - Parameter source: The CGEventSource to use for the key events
    private func simulateEnterKey(using source: CGEventSource) {
        // Virtual key code for Return/Enter key on macOS
        let returnKeyCode: CGKeyCode = 36
        
        // Post key events on main thread
        DispatchQueue.main.sync {
            // Create key down event for Enter
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: returnKeyCode, keyDown: true) {
                keyDown.post(tap: .cghidEventTap)
            }
            
            // Create key up event for Enter
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: returnKeyCode, keyDown: false) {
                keyUp.post(tap: .cghidEventTap)
            }
        }
        
        // Slightly longer delay for key presses vs character typing
        Thread.sleep(forTimeInterval: (preferencesManager.typingSpeed * 2.5) / 1000.0)
    }
} 