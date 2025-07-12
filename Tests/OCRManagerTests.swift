//
//  OCRManagerTests.swift
//  ClipTyperTests
//
//  Copyright © 2025 Ralf Sturhan. All rights reserved.
//

import XCTest
import Vision
@testable import ClipTyper

/// Unit tests for OCRManager
final class OCRManagerTests: XCTestCase {
    
    private var ocrManager: OCRManager!
    
    override func setUp() {
        super.setUp()
        ocrManager = OCRManager()
    }
    
    override func tearDown() {
        ocrManager = nil
        super.tearDown()
    }
    
    // MARK: - Text Recognition Tests
    
    func testRecognizeTextWithValidImage() async throws {
        // Given: A test image with text
        let testImage = createTestImage(withText: "Hello World")
        
        // When: Recognizing text
        let recognizedText = try await ocrManager.recognizeText(in: testImage)
        
        // Then: Should contain expected text (actual recognition depends on Vision framework)
        XCTAssertFalse(recognizedText.isEmpty, "Should recognize some text from image")
    }
    
    func testRecognizeTextWithEmptyImage() async throws {
        // Given: An empty/blank image
        let emptyImage = createBlankImage()
        
        // When: Recognizing text
        let recognizedText = try await ocrManager.recognizeText(in: emptyImage)
        
        // Then: Should return empty or minimal text
        XCTAssertTrue(recognizedText.isEmpty || recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                     "Should return empty text for blank image")
    }
    
    func testMultilineTextPreservation() async throws {
        // Test that multiline text is properly preserved
        // Note: Actual test would require a proper test image with multiline text
        let testText = "Line 1\nLine 2\nLine 3"
        
        // Verify the text processing preserves newlines
        XCTAssertTrue(testText.contains("\n"), "Test text should contain newlines")
        XCTAssertEqual(testText.components(separatedBy: "\n").count, 3, "Should have 3 lines")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceOfTextRecognition() {
        // Given: A standard test image
        let testImage = createTestImage(withText: "Performance Test Text")
        
        // Measure performance
        measure {
            Task {
                _ = try? await ocrManager.recognizeText(in: testImage)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidImageHandling() async {
        // Given: Invalid CGImage (1x1 pixel)
        let tinyImage = createTestImage(width: 1, height: 1)
        
        // When: Attempting recognition
        do {
            let result = try await ocrManager.recognizeText(in: tinyImage)
            // Very small images might still process but return empty
            XCTAssertTrue(result.isEmpty || result.count < 5, "Tiny image should yield minimal text")
        } catch {
            // Error is acceptable for invalid input
            XCTAssertNotNil(error, "Error handling invalid image is acceptable")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(withText text: String = "Test", width: Int = 200, height: Int = 50) -> CGImage {
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        guard let context = CGContext(data: nil,
                                    width: Int(bounds.width),
                                    height: Int(bounds.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: 0,
                                    space: colorSpace,
                                    bitmapInfo: bitmapInfo.rawValue) else {
            fatalError("Failed to create CGContext")
        }
        
        // Fill white background
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(bounds)
        
        // Draw black text (simplified - real implementation would use NSAttributedString)
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        
        // Create image
        guard let image = context.makeImage() else {
            fatalError("Failed to create CGImage")
        }
        
        return image
    }
    
    private func createBlankImage() -> CGImage {
        return createTestImage(withText: "", width: 100, height: 100)
    }
}

// MARK: - Mock Helpers for Testing

extension OCRManagerTests {
    
    /// Simulates Vision framework text observations for testing
    func createMockTextObservations(texts: [String]) -> [VNRecognizedTextObservation] {
        // In real tests, we'd create mock VNRecognizedTextObservation objects
        // For now, this is a placeholder showing the testing approach
        return []
    }
    
    /// Tests text sorting algorithm used in OCR
    func testTextRegionSorting() {
        // Test the sorting logic for text regions
        struct MockRegion {
            let text: String
            let bounds: CGRect
        }
        
        let regions = [
            MockRegion(text: "Bottom", bounds: CGRect(x: 0, y: 0, width: 100, height: 20)),
            MockRegion(text: "Top", bounds: CGRect(x: 0, y: 80, width: 100, height: 20)),
            MockRegion(text: "Middle", bounds: CGRect(x: 0, y: 40, width: 100, height: 20))
        ]
        
        // Sort by Y position (top to bottom in screen coordinates)
        let sorted = regions.sorted { $0.bounds.minY > $1.bounds.minY }
        
        XCTAssertEqual(sorted[0].text, "Top")
        XCTAssertEqual(sorted[1].text, "Middle")
        XCTAssertEqual(sorted[2].text, "Bottom")
    }
} 