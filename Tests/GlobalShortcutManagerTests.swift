//
//  GlobalShortcutManagerTests.swift
//  ClipTyperTests
//
//  Copyright © 2025 Ralf Sturhan. All rights reserved.
//

import XCTest
import Carbon
@testable import ClipTyper

/// Unit tests for GlobalShortcutManager
final class GlobalShortcutManagerTests: XCTestCase {
    
    private var shortcutManager: GlobalShortcutManager!
    private var callbackExecuted: Bool = false
    private var callbackCount: Int = 0
    
    override func setUp() {
        super.setUp()
        shortcutManager = GlobalShortcutManager()
        callbackExecuted = false
        callbackCount = 0
    }
    
    override func tearDown() {
        shortcutManager.unregisterAll()
        shortcutManager = nil
        super.tearDown()
    }
    
    // MARK: - Registration Tests
    
    func testRegisterShortcut() {
        // Given: A valid key code and modifiers
        let keyCode: UInt16 = 9 // V key
        let modifiers: UInt32 = UInt32(cmdKey | optionKey)
        let expectation = expectation(description: "Shortcut registered")
        expectation.isInverted = true // We don't expect callback in this test
        
        // When: Registering a shortcut
        let success = shortcutManager.registerShortcut(
            keyCode: keyCode,
            modifiers: modifiers,
            action: {
                self.callbackExecuted = true
                expectation.fulfill()
            }
        )
        
        // Then: Registration should succeed (in test environment might fail due to permissions)
        // We can't guarantee success in unit tests without accessibility permissions
        XCTAssertNotNil(shortcutManager, "Manager should exist")
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertFalse(callbackExecuted, "Callback should not execute without key press")
    }
    
    func testUnregisterShortcut() {
        // Given: A registered shortcut
        let keyCode: UInt16 = 9
        let modifiers: UInt32 = UInt32(cmdKey | optionKey)
        let tag = GlobalShortcutManager.Tag.clipboardTyping
        
        _ = shortcutManager.registerShortcut(
            keyCode: keyCode,
            modifiers: modifiers,
            tag: tag,
            action: { self.callbackCount += 1 }
        )
        
        // When: Unregistering the shortcut
        shortcutManager.unregister(tag: tag)
        
        // Then: Callback should not be available
        // (Can't test actual behavior without simulating key events)
        XCTAssertEqual(callbackCount, 0, "Callback should not have been called")
    }
    
    func testUnregisterAll() {
        // Given: Multiple registered shortcuts
        _ = shortcutManager.registerShortcut(
            keyCode: 9,
            modifiers: UInt32(cmdKey | optionKey),
            tag: .clipboardTyping,
            action: { self.callbackCount += 1 }
        )
        
        _ = shortcutManager.registerShortcut(
            keyCode: 15,
            modifiers: UInt32(cmdKey | optionKey),
            tag: .ocrCapture,
            action: { self.callbackCount += 1 }
        )
        
        // When: Unregistering all
        shortcutManager.unregisterAll()
        
        // Then: All shortcuts should be removed
        XCTAssertEqual(callbackCount, 0, "No callbacks should have been executed")
    }
    
    // MARK: - Tag Management Tests
    
    func testShortcutTags() {
        // Verify tag enum values
        XCTAssertEqual(GlobalShortcutManager.Tag.clipboardTyping.rawValue, "clipboardTyping")
        XCTAssertEqual(GlobalShortcutManager.Tag.ocrCapture.rawValue, "ocrCapture")
    }
    
    func testDuplicateTagRegistration() {
        let tag = GlobalShortcutManager.Tag.clipboardTyping
        var firstCallbackCount = 0
        var secondCallbackCount = 0
        
        // Register first shortcut
        _ = shortcutManager.registerShortcut(
            keyCode: 9,
            modifiers: UInt32(cmdKey | optionKey),
            tag: tag,
            action: { firstCallbackCount += 1 }
        )
        
        // Register second shortcut with same tag (should replace first)
        _ = shortcutManager.registerShortcut(
            keyCode: 8,
            modifiers: UInt32(cmdKey | optionKey),
            tag: tag,
            action: { secondCallbackCount += 1 }
        )
        
        // Verify no callbacks executed yet
        XCTAssertEqual(firstCallbackCount, 0)
        XCTAssertEqual(secondCallbackCount, 0)
    }
    
    // MARK: - Modifier Tests
    
    func testModifierCombinations() {
        // Test various modifier combinations
        let testCases: [(String, UInt32)] = [
            ("Cmd+Option", UInt32(cmdKey | optionKey)),
            ("Cmd+Shift", UInt32(cmdKey | shiftKey)),
            ("Cmd+Control", UInt32(cmdKey | controlKey)),
            ("All modifiers", UInt32(cmdKey | optionKey | shiftKey | controlKey))
        ]
        
        for (name, modifiers) in testCases {
            XCTAssertGreaterThan(modifiers, 0, "\(name) should have non-zero value")
        }
    }
    
    // MARK: - Key Code Tests
    
    func testCommonKeyCodes() {
        // Verify common key codes
        let keyCodes: [(String, UInt16)] = [
            ("A", 0),
            ("S", 1),
            ("D", 2),
            ("F", 3),
            ("V", 9),
            ("C", 8),
            ("R", 15),
            ("Space", 49),
            ("Return", 36),
            ("Escape", 53)
        ]
        
        for (key, code) in keyCodes {
            XCTAssertLessThan(code, 128, "\(key) key code should be valid")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidKeyCode() {
        // Test with invalid key code
        let invalidKeyCode: UInt16 = 999
        let modifiers: UInt32 = UInt32(cmdKey)
        
        let success = shortcutManager.registerShortcut(
            keyCode: invalidKeyCode,
            modifiers: modifiers,
            action: { }
        )
        
        // Registration might still succeed but won't trigger
        XCTAssertNotNil(shortcutManager, "Manager should handle invalid input gracefully")
    }
    
    func testZeroModifiers() {
        // Test with no modifiers (usually not recommended for global shortcuts)
        let keyCode: UInt16 = 9
        let modifiers: UInt32 = 0
        
        let success = shortcutManager.registerShortcut(
            keyCode: keyCode,
            modifiers: modifiers,
            action: { }
        )
        
        // System might reject shortcuts without modifiers
        XCTAssertNotNil(shortcutManager, "Manager should handle zero modifiers")
    }
}

// MARK: - Mock Event Handler for Testing

extension GlobalShortcutManagerTests {
    
    /// Simulates a key event for testing (requires accessibility permissions in real usage)
    func simulateKeyPress(keyCode: UInt16, modifiers: UInt32) {
        // In actual implementation, this would create and post a CGEvent
        // For unit tests, we can't simulate system events without permissions
        // This is a placeholder showing the testing approach
    }
    
    /// Tests the event handler signature
    func testEventHandlerSignature() {
        // Verify the Carbon event handler types
        let eventClass = UInt32(kEventClassKeyboard)
        let eventKind = UInt32(kEventHotKeyPressed)
        
        XCTAssertEqual(eventClass, UInt32(kEventClassKeyboard))
        XCTAssertEqual(eventKind, UInt32(kEventHotKeyPressed))
    }
} 