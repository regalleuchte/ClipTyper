//
//  ClipboardManagerTests.swift
//  ClipTyperTests
//
//  Copyright © 2025 Ralf Sturhan. All rights reserved.
//

import XCTest
import AppKit
@testable import ClipTyper

/// Unit tests for ClipboardManager
final class ClipboardManagerTests: XCTestCase {
    
    private var clipboardManager: ClipboardManager!
    private var mockPasteboard: MockPasteboard!
    
    override func setUp() {
        super.setUp()
        mockPasteboard = MockPasteboard()
        clipboardManager = ClipboardManager(pasteboard: mockPasteboard)
    }
    
    override func tearDown() {
        clipboardManager.stopMonitoring()
        clipboardManager = nil
        mockPasteboard = nil
        super.tearDown()
    }
    
    // MARK: - Clipboard Content Tests
    
    func testGetClipboardText() {
        let testText = "Hello, World!"
        mockPasteboard.setString(testText, forType: .string)
        
        let clipboardText = clipboardManager.getClipboardText()
        XCTAssertEqual(clipboardText, testText, "Should retrieve correct text from clipboard")
    }
    
    func testGetClipboardTextEmpty() {
        mockPasteboard.clearContents()
        
        let clipboardText = clipboardManager.getClipboardText()
        XCTAssertEqual(clipboardText, "", "Should return empty string when clipboard is empty")
    }
    
    func testGetClipboardTextNil() {
        mockPasteboard.setString(nil, forType: .string)
        
        let clipboardText = clipboardManager.getClipboardText()
        XCTAssertEqual(clipboardText, "", "Should return empty string when clipboard text is nil")
    }
    
    // MARK: - Character Count Tests
    
    func testGetClipboardCharacterCount() {
        let testText = "Hello, World!"
        mockPasteboard.setString(testText, forType: .string)
        
        let count = clipboardManager.getClipboardCharacterCount()
        XCTAssertEqual(count, testText.count, "Should return correct character count")
    }
    
    func testGetClipboardCharacterCountEmpty() {
        mockPasteboard.clearContents()
        
        let count = clipboardManager.getClipboardCharacterCount()
        XCTAssertEqual(count, 0, "Should return 0 for empty clipboard")
    }
    
    func testGetClipboardCharacterCountUnicode() {
        let unicodeText = "Hello 世界 🌍"
        mockPasteboard.setString(unicodeText, forType: .string)
        
        let count = clipboardManager.getClipboardCharacterCount()
        XCTAssertEqual(count, unicodeText.count, "Should correctly count Unicode characters")
    }
    
    // MARK: - Clear Clipboard Tests
    
    func testClearClipboard() {
        let testText = "Test content"
        mockPasteboard.setString(testText, forType: .string)
        
        // Verify content exists
        XCTAssertEqual(clipboardManager.getClipboardText(), testText)
        
        // Clear clipboard
        clipboardManager.clearClipboard()
        
        // Verify clipboard is cleared
        XCTAssertEqual(clipboardManager.getClipboardText(), "", "Clipboard should be empty after clearing")
    }
    
    // MARK: - Monitoring Tests
    
    func testStartMonitoring() {
        var callbackCount = 0
        var lastCount = 0
        
        clipboardManager.onClipboardChange = { count in
            callbackCount += 1
            lastCount = count
        }
        
        clipboardManager.startMonitoring()
        
        // Simulate clipboard change
        mockPasteboard.setString("New content", forType: .string)
        mockPasteboard.simulateChangeCountIncrement()
        
        // Allow some time for monitoring to detect change
        let expectation = expectation(description: "Clipboard change detected")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertGreaterThan(callbackCount, 0, "Callback should have been called")
            XCTAssertEqual(lastCount, 11, "Should report correct character count") // "New content" = 11 chars
        }
    }
    
    func testStopMonitoring() {
        var callbackCount = 0
        
        clipboardManager.onClipboardChange = { _ in
            callbackCount += 1
        }
        
        clipboardManager.startMonitoring()
        clipboardManager.stopMonitoring()
        
        // Simulate clipboard change after stopping
        mockPasteboard.setString("Should not trigger", forType: .string)
        mockPasteboard.simulateChangeCountIncrement()
        
        // Wait and verify no callback
        let expectation = expectation(description: "No callback after stopping")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(callbackCount, 0, "Callback should not be called after stopping monitoring")
        }
    }
    
    // MARK: - Edge Cases
    
    func testLargeClipboardContent() {
        let largeText = String(repeating: "A", count: 100000)
        mockPasteboard.setString(largeText, forType: .string)
        
        let retrievedText = clipboardManager.getClipboardText()
        let count = clipboardManager.getClipboardCharacterCount()
        
        XCTAssertEqual(retrievedText, largeText, "Should handle large clipboard content")
        XCTAssertEqual(count, 100000, "Should correctly count large content")
    }
    
    func testSpecialCharacters() {
        let specialText = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        mockPasteboard.setString(specialText, forType: .string)
        
        let retrievedText = clipboardManager.getClipboardText()
        XCTAssertEqual(retrievedText, specialText, "Should handle special characters correctly")
    }
}

// MARK: - Mock Pasteboard

/// Mock pasteboard for testing clipboard functionality without affecting system clipboard
class MockPasteboard: NSPasteboard {
    private var mockString: String?
    private var mockChangeCount: Int = 0
    
    override var changeCount: Int {
        return mockChangeCount
    }
    
    override func string(forType dataType: NSPasteboard.PasteboardType) -> String? {
        if dataType == .string {
            return mockString
        }
        return nil
    }
    
    override func setString(_ string: String, forType dataType: NSPasteboard.PasteboardType) -> Bool {
        if dataType == .string {
            mockString = string
            mockChangeCount += 1
            return true
        }
        return false
    }
    
    func setString(_ string: String?, forType dataType: NSPasteboard.PasteboardType) {
        if dataType == .string {
            mockString = string
            mockChangeCount += 1
        }
    }
    
    override func clearContents() -> Int {
        mockString = nil
        mockChangeCount += 1
        return mockChangeCount
    }
    
    func simulateChangeCountIncrement() {
        mockChangeCount += 1
    }
}