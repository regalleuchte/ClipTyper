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
    
    /// Injects a sequence of Unicode scalars via CGEvent so keyboard layout doesn't matter
    private func sendUnicode(_ text: String) {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            print("Failed to create event source")
            return
        }
        
        for scalar in text.unicodeScalars {
            var ch = UniChar(scalar.value)
            
            // Create key down event with Unicode character
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                keyDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: &ch)
                keyDown.post(tap: .cghidEventTap)
            }
            
            // Create key up event with Unicode character
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                keyUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: &ch)
                keyUp.post(tap: .cghidEventTap)
            }
            
            // Small delay between characters for more natural typing and reliability
            usleep(1000) // 1ms delay
        }
    }
} 