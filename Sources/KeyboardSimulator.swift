//
//  KeyboardSimulator.swift
//  ClipTyper
//
//  Copyright © 2025 Ralf Sturhan. All rights reserved.
//

import Cocoa

/// Handles keyboard simulation using Core Graphics events
/// 
/// This class provides Unicode-based text typing that works across different
/// keyboard layouts and languages. It uses CGEvent API to simulate typing
/// at the system level, bypassing keyboard layout dependencies.
/// 
/// ## Requirements
/// - Accessibility permissions must be granted
/// - macOS 12.0+
/// 
/// ## Usage
/// ```swift
/// let simulator = KeyboardSimulator()
/// simulator.typeText("Hello, World! 🌍")
/// ```
class KeyboardSimulator {
    
    /// Types the specified text using Unicode-based keyboard simulation
    /// 
    /// This method converts text to Unicode scalars and uses CGEvent to simulate
    /// typing character by character. It handles complex Unicode including emoji
    /// and multi-byte characters correctly.
    /// 
    /// - Parameter text: The text to type. Supports full Unicode including emoji
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
        
        // Process text as composed character sequences to handle emoji and complex Unicode properly
        for character in text {
            let characterString = String(character)
            
            // Convert to UTF-16 for proper Unicode handling
            let utf16Array = Array(characterString.utf16)
            
            // Skip if conversion fails or produces invalid data
            guard !utf16Array.isEmpty else {
                print("Skipping invalid Unicode character")
                continue
            }
            
            // Create events for the entire character sequence
            var unicharArray = utf16Array.map { UniChar($0) }
            
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
            
            // Small delay between characters for more natural typing and reliability
            usleep(2000) // 2ms delay for complex characters
        }
    }
} 