import Cocoa

class KeyboardSimulator {
    
    func typeText(_ text: String) {
        // Check accessibility permissions
        guard AXIsProcessTrusted() else {
            print("Accessibility permissions are not granted")
            return
        }
        
        // Use the Unicode scalar approach for reliable typing
        sendUnicode(text)
    }
    
    /// Injects text via CGEvent handling complex Unicode including emoji
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