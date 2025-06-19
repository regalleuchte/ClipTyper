import Cocoa
import Carbon

class GlobalShortcutManager {
    private var eventHandler: Any?
    private var shortcutCallback: (() -> Void)?
    
    // Shortcut settings - will be replaced with preferences
    private var keyCode: UInt16 = 9 // V key
    private var modifiers: UInt32 = UInt32(optionKey) | UInt32(cmdKey)
    
    deinit {
        unregisterShortcut()
    }
    
    func registerShortcut(callback: @escaping () -> Void, keyCode: UInt16? = nil, modifiers: UInt32? = nil) {
        shortcutCallback = callback
        
        // Update shortcut if provided
        if let keyCode = keyCode {
            self.keyCode = keyCode
        }
        
        if let modifiers = modifiers {
            self.modifiers = modifiers
        }
        
        // Create event tap to listen for keydown events
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if let refcon = refcon {
                    let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(refcon).takeUnretainedValue()
                    return manager.handleEvent(proxy: proxy, type: type, event: event)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }
        
        // Create a run loop source from the event tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        
        // Add the run loop source to the current run loop
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        // Store the eventTap to be able to unregister later
        eventHandler = eventTap
    }
    
    func unregisterShortcut() {
        guard let eventTap = eventHandler else { return }
        
        if CFGetTypeID(eventTap as CFTypeRef) == CFMachPortGetTypeID() {
            let machPort = eventTap as! CFMachPort
            CGEvent.tapEnable(tap: machPort, enable: false)
            CFMachPortInvalidate(machPort)
            eventHandler = nil
        }
    }
    
    func updateShortcut(keyCode: UInt16, modifiers: UInt32) {
        // Unregister current shortcut
        unregisterShortcut()
        
        // Save new values
        self.keyCode = keyCode
        self.modifiers = modifiers
        
        // Re-register with new values if we have a callback
        if let callback = shortcutCallback {
            registerShortcut(callback: callback)
        }
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .keyDown {
            let keycode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            
            // Check if our shortcut was pressed
            let isCommandPressed = flags.contains(.maskCommand)
            let isOptionPressed = flags.contains(.maskAlternate)
            let isShiftPressed = flags.contains(.maskShift)
            let isControlPressed = flags.contains(.maskControl)
            
            // Create a modifiers value to match against our stored modifiers
            var pressedModifiers: UInt32 = 0
            if isCommandPressed { pressedModifiers |= UInt32(cmdKey) }
            if isOptionPressed { pressedModifiers |= UInt32(optionKey) }
            if isShiftPressed { pressedModifiers |= UInt32(shiftKey) }
            if isControlPressed { pressedModifiers |= UInt32(controlKey) }
            
            if UInt16(keycode) == self.keyCode && pressedModifiers == self.modifiers {
                shortcutCallback?()
                
                // Return nil to consume the event (prevent it from being passed to the application)
                return nil
            }
        }
        
        // Let other events through
        return Unmanaged.passUnretained(event)
    }
    
    // Helper function to convert modifiers to readable string
    func modifiersToString() -> String {
        var result = ""
        
        if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        
        // Add key character
        let keyChar = keyCodeToChar(keyCode)
        result += keyChar
        
        return result
    }
    
    // Helper function to convert key code to character
    private func keyCodeToChar(_ keyCode: UInt16) -> String {
        // This is a simplified version - in a real app you'd want a more complete mapping
        let keyCodes: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 10: "§", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
            24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O",
            32: "U", 33: "[", 34: "I", 35: "P", 36: "Return", 37: "L", 38: "J", 39: "'",
            40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
            48: "Tab", 49: "Space", 50: "`", 51: "Delete", 52: "⌘⏎", 53: "Escape",
            // Function keys and other special keys would continue...
        ]
        
        return keyCodes[keyCode] ?? "?"
    }
} 