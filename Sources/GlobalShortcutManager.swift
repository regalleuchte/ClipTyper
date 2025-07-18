//
//  GlobalShortcutManager.swift
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
import Carbon
import ApplicationServices

/// Manages global keyboard shortcuts using Core Graphics event taps
/// 
/// This class provides system-wide keyboard shortcut functionality that works
/// even when the application is not in focus. It uses CGEvent taps to monitor
/// keyboard events and trigger callbacks when registered shortcuts are detected.
/// 
/// ## Default Shortcut
/// - Key: V (key code 9)
/// - Modifiers: Option + Command
/// 
/// ## Requirements
/// - Accessibility permissions
/// - macOS 12.0+
class GlobalShortcutManager {
    private var eventHandler: Any?
    private var shortcutCallback: (() -> Void)?
    private var ocrCallback: (() -> Void)?
    
    /// Current shortcut key code (default: 9 for V key)
    private var keyCode: UInt16 = Constants.defaultKeyCode
    /// Current shortcut modifier flags (default: Option + Command)
    private var modifiers: UInt32 = Constants.defaultModifiers
    
    /// OCR shortcut key code (default: 15 for R key)
    private var ocrKeyCode: UInt16 = Constants.defaultOCRKeyCode
    /// OCR shortcut modifier flags (default: Option + Command)
    private var ocrModifiers: UInt32 = Constants.defaultOCRModifiers
    
    /// Whether OCR shortcut is enabled
    private var ocrShortcutEnabled: Bool = false
    
    deinit {
        unregisterShortcut()
    }
    
    /// Registers a global keyboard shortcut with the system
    /// 
    /// - Parameters:
    ///   - callback: Closure to execute when shortcut is triggered
    ///   - keyCode: Optional key code (defaults to current value)
    ///   - modifiers: Optional modifier flags (defaults to current value)
    /// - Returns: True if registration succeeded, false otherwise
    /// - Note: Requires accessibility permissions to function
    func registerShortcut(callback: @escaping () -> Void, keyCode: UInt16? = nil, modifiers: UInt32? = nil) -> Bool {
        shortcutCallback = callback
        
        // Update shortcut if provided
        if let keyCode = keyCode {
            self.keyCode = keyCode
        }
        
        if let modifiers = modifiers {
            self.modifiers = modifiers
        }
        
        // Unregister existing shortcut first
        unregisterShortcut()
        
        print("GlobalShortcutManager: Attempting to register shortcut...")
        
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
            print("GlobalShortcutManager: Failed to create event tap - this usually means accessibility permissions are not granted")
            return false
        }
        
        // Create a run loop source from the event tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        
        // Add the run loop source to the current run loop
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        // Store the eventTap to be able to unregister later
        eventHandler = eventTap
        
        print("GlobalShortcutManager: Successfully registered global shortcut: \(getCurrentShortcutString())")
        return true
    }
    
    /// Registers the OCR shortcut alongside the existing typing shortcut
    /// - Parameters:
    ///   - callback: Closure to execute when OCR shortcut is triggered  
    ///   - keyCode: OCR shortcut key code
    ///   - modifiers: OCR shortcut modifier flags
    /// - Returns: True if registration succeeded, false otherwise
    func registerOCRShortcut(callback: @escaping () -> Void, keyCode: UInt16, modifiers: UInt32) -> Bool {
        ocrCallback = callback
        ocrKeyCode = keyCode
        ocrModifiers = modifiers
        ocrShortcutEnabled = true
        
        print("GlobalShortcutManager: OCR shortcut registered: \(getOCRShortcutString())")
        return true // OCR uses the same event monitoring as the main shortcut
    }
    
    /// Unregisters the OCR shortcut
    func unregisterOCRShortcut() {
        ocrCallback = nil
        ocrShortcutEnabled = false
        print("GlobalShortcutManager: OCR shortcut unregistered")
    }
    
    /// Unregisters the current global shortcut and cleans up resources
    /// 
    /// This method should be called before the manager is deallocated
    /// to properly clean up the event tap and release system resources.
    func unregisterShortcut() {
        guard let eventTap = eventHandler else { return }
        
        if CFGetTypeID(eventTap as CFTypeRef) == CFMachPortGetTypeID() {
            let machPort = eventTap as! CFMachPort
            CGEvent.tapEnable(tap: machPort, enable: false)
            CFMachPortInvalidate(machPort)
            eventHandler = nil
        }
    }
    
    /// Updates the registered shortcut to use new key code and modifiers
    /// 
    /// - Parameters:
    ///   - keyCode: New key code to use
    ///   - modifiers: New modifier flags to use
    /// - Returns: True if update succeeded, false otherwise
    func updateShortcut(keyCode: UInt16, modifiers: UInt32) -> Bool {
        // Save new values
        self.keyCode = keyCode
        self.modifiers = modifiers
        
        // Re-register with new values if we have a callback
        if let callback = shortcutCallback {
            return registerShortcut(callback: callback)
        }
        return false
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
            
            // Check typing shortcut
            if UInt16(keycode) == self.keyCode && pressedModifiers == self.modifiers {
                shortcutCallback?()
                return nil // Consume the event
            }
            
            // Check OCR shortcut (if enabled)
            if ocrShortcutEnabled && UInt16(keycode) == self.ocrKeyCode && pressedModifiers == self.ocrModifiers {
                ocrCallback?()
                return nil // Consume the event
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
    
    // Get the current shortcut as a string
    func getCurrentShortcutString() -> String {
        return modifiersToString()
    }
    
    // Check if shortcut is currently registered
    func isShortcutRegistered() -> Bool {
        return eventHandler != nil
    }
    
    // Get the current OCR shortcut as a string
    func getOCRShortcutString() -> String {
        return formatOCRShortcut()
    }
    
    private func formatOCRShortcut() -> String {
        var result = ""
        
        if ocrModifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if ocrModifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if ocrModifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if ocrModifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        
        // Add key character
        let keyChar = keyCodeToChar(ocrKeyCode)
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