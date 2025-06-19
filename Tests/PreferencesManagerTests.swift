//
//  PreferencesManagerTests.swift
//  ClipTyperTests
//
//  Copyright © 2025 Ralf Sturhan. All rights reserved.
//

import XCTest
@testable import ClipTyper

/// Unit tests for PreferencesManager
final class PreferencesManagerTests: XCTestCase {
    
    private var preferencesManager: PreferencesManager!
    private let testDefaults = UserDefaults(suiteName: "com.cliptyper.tests")!
    
    override func setUp() {
        super.setUp()
        // Use test-specific UserDefaults to avoid contaminating real preferences
        preferencesManager = PreferencesManager(userDefaults: testDefaults)
    }
    
    override func tearDown() {
        // Clean up test defaults
        testDefaults.removePersistentDomain(forName: "com.cliptyper.tests")
        preferencesManager = nil
        super.tearDown()
    }
    
    // MARK: - Typing Delay Tests
    
    func testDefaultTypingDelay() {
        XCTAssertEqual(preferencesManager.typingDelay, 2.0, "Default typing delay should be 2.0 seconds")
    }
    
    func testSetTypingDelay() {
        let testDelay = 5.0
        preferencesManager.typingDelay = testDelay
        XCTAssertEqual(preferencesManager.typingDelay, testDelay, "Typing delay should be updated")
    }
    
    func testTypingDelayRange() {
        // Test minimum
        preferencesManager.typingDelay = 0.5
        XCTAssertEqual(preferencesManager.typingDelay, 0.5)
        
        // Test maximum
        preferencesManager.typingDelay = 10.0
        XCTAssertEqual(preferencesManager.typingDelay, 10.0)
    }
    
    // MARK: - Auto Clear Clipboard Tests
    
    func testDefaultAutoClearClipboard() {
        XCTAssertFalse(preferencesManager.autoClearClipboard, "Auto clear clipboard should be false by default")
    }
    
    func testSetAutoClearClipboard() {
        preferencesManager.autoClearClipboard = true
        XCTAssertTrue(preferencesManager.autoClearClipboard, "Auto clear clipboard should be updated")
    }
    
    // MARK: - Character Warning Threshold Tests
    
    func testDefaultCharacterWarningThreshold() {
        XCTAssertEqual(preferencesManager.characterWarningThreshold, 100, "Default character warning threshold should be 100")
    }
    
    func testSetCharacterWarningThreshold() {
        let testThreshold = 500
        preferencesManager.characterWarningThreshold = testThreshold
        XCTAssertEqual(preferencesManager.characterWarningThreshold, testThreshold, "Character warning threshold should be updated")
    }
    
    // MARK: - Show Character Count Tests
    
    func testDefaultShowCharacterCount() {
        XCTAssertFalse(preferencesManager.showCharacterCount, "Show character count should be false by default")
    }
    
    func testSetShowCharacterCount() {
        preferencesManager.showCharacterCount = true
        XCTAssertTrue(preferencesManager.showCharacterCount, "Show character count should be updated")
    }
    
    // MARK: - Keyboard Shortcut Tests
    
    func testDefaultKeyboardShortcut() {
        XCTAssertEqual(preferencesManager.keyboardShortcutKeyCode, 9, "Default key code should be 9 (V key)")
        XCTAssertEqual(preferencesManager.keyboardShortcutModifiers, 1048840, "Default modifiers should be Option+Command")
    }
    
    func testSetKeyboardShortcut() {
        let testKeyCode: UInt16 = 8 // C key
        let testModifiers: UInt32 = 1048576 // Command only
        
        preferencesManager.keyboardShortcutKeyCode = testKeyCode
        preferencesManager.keyboardShortcutModifiers = testModifiers
        
        XCTAssertEqual(preferencesManager.keyboardShortcutKeyCode, testKeyCode)
        XCTAssertEqual(preferencesManager.keyboardShortcutModifiers, testModifiers)
    }
    
    // MARK: - Autostart Tests
    
    func testDefaultAutostart() {
        XCTAssertFalse(preferencesManager.autostart, "Autostart should be false by default")
    }
    
    func testSetAutostart() {
        preferencesManager.autostart = true
        XCTAssertTrue(preferencesManager.autostart, "Autostart should be updated")
    }
    
    // MARK: - Integration Tests
    
    func testPreferencePersistence() {
        // Set multiple preferences
        preferencesManager.typingDelay = 3.5
        preferencesManager.autoClearClipboard = true
        preferencesManager.characterWarningThreshold = 200
        
        // Create new instance with same UserDefaults
        let newPreferencesManager = PreferencesManager(userDefaults: testDefaults)
        
        // Verify persistence
        XCTAssertEqual(newPreferencesManager.typingDelay, 3.5)
        XCTAssertTrue(newPreferencesManager.autoClearClipboard)
        XCTAssertEqual(newPreferencesManager.characterWarningThreshold, 200)
    }
}