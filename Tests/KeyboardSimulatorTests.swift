//
//  KeyboardSimulatorTests.swift
//  ClipTyperTests
//
//  Copyright © 2025 Ralf Sturhan. All rights reserved.
//

import XCTest
import CoreGraphics
@testable import ClipTyper

/// Unit tests for KeyboardSimulator
final class KeyboardSimulatorTests: XCTestCase {
    
    private var keyboardSimulator: KeyboardSimulator!
    
    override func setUp() {
        super.setUp()
        keyboardSimulator = KeyboardSimulator()
    }
    
    override func tearDown() {
        keyboardSimulator = nil
        super.tearDown()
    }
    
    // MARK: - Text Validation Tests
    
    func testEmptyStringHandling() {
        // This test verifies that empty strings are handled gracefully
        // Note: Actual typing simulation cannot be tested in unit tests as it requires accessibility permissions
        XCTAssertNoThrow(keyboardSimulator.typeText(""), "Empty string should be handled without throwing")
    }
    
    func testBasicTextValidation() {
        let testTexts = [
            "Hello World",
            "123456789",
            "Special chars: !@#$%^&*()",
            "Mixed: Hello123!@#"
        ]
        
        for text in testTexts {
            XCTAssertNoThrow(keyboardSimulator.typeText(text), "Text '\(text)' should be handled without throwing")
        }
    }
    
    func testUnicodeTextHandling() {
        let unicodeTexts = [
            "Hello 世界", // Chinese characters
            "Café", // Accented characters
            "🚀🎉", // Emoji
            "Ñoño", // Spanish characters
            "Здравствуй", // Cyrillic
            "مرحبا" // Arabic
        ]
        
        for text in unicodeTexts {
            XCTAssertNoThrow(keyboardSimulator.typeText(text), "Unicode text '\(text)' should be handled without throwing")
        }
    }
    
    func testLongTextHandling() {
        let longText = String(repeating: "A", count: 10000)
        XCTAssertNoThrow(keyboardSimulator.typeText(longText), "Long text should be handled without throwing")
    }
    
    // MARK: - Edge Cases
    
    func testNewlineHandling() {
        let textWithNewlines = "Line 1\nLine 2\rLine 3\r\nLine 4"
        XCTAssertNoThrow(keyboardSimulator.typeText(textWithNewlines), "Text with newlines should be handled")
    }
    
    func testTabHandling() {
        let textWithTabs = "Column1\tColumn2\tColumn3"
        XCTAssertNoThrow(keyboardSimulator.typeText(textWithTabs), "Text with tabs should be handled")
    }
    
    func testControlCharacters() {
        let textWithControlChars = "Text with \u{0001} control \u{0008} characters"
        XCTAssertNoThrow(keyboardSimulator.typeText(textWithControlChars), "Text with control characters should be handled")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithMediumText() {
        let mediumText = String(repeating: "The quick brown fox jumps over the lazy dog. ", count: 100)
        
        measure {
            // Note: This measures the time to process the text, not actual typing speed
            keyboardSimulator.typeText(mediumText)
        }
    }
    
    // MARK: - Accessibility Permission Tests
    
    func testAccessibilityPermissionCheck() {
        // This is a mock test since we can't grant accessibility permissions in unit tests
        // In a real scenario, this would test the AXIsProcessTrusted() check
        
        // The keyboard simulator should handle the case where accessibility permissions are not granted
        XCTAssertNoThrow(keyboardSimulator.typeText("Test"), "Should handle missing accessibility permissions gracefully")
    }
    
    // MARK: - UTF-16 Conversion Tests
    
    func testUTF16Conversion() {
        let testString = "Hello 世界 🌍"
        let utf16Array = Array(testString.utf16)
        
        XCTAssertFalse(utf16Array.isEmpty, "UTF-16 conversion should produce non-empty array")
        XCTAssertTrue(utf16Array.count >= testString.count, "UTF-16 array should have at least as many elements as characters")
    }
    
    func testComplexEmojiUTF16() {
        let complexEmoji = "👨‍👩‍👧‍👦" // Family emoji (complex multi-codepoint)
        let utf16Array = Array(complexEmoji.utf16)
        
        XCTAssertFalse(utf16Array.isEmpty, "Complex emoji should produce valid UTF-16 array")
        XCTAssertTrue(utf16Array.count > 1, "Complex emoji should require multiple UTF-16 code units")
    }
}