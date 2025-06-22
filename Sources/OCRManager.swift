//
//  OCRManager.swift
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

import Foundation
import Vision
import CoreGraphics
import Cocoa
import UniformTypeIdentifiers
import ScreenCaptureKit

/// Manages OCR processing using Apple's Vision framework
class OCRManager {
    
    /// OCR result with both text and image
    struct OCRResult {
        let text: String
        let capturedImage: CGImage
    }
    
    /// Completion handler for OCR results
    typealias OCRCompletion = (Result<OCRResult, OCRError>) -> Void
    
    /// OCR-specific errors
    enum OCRError: LocalizedError {
        case screenCaptureFailure
        case noTextFound
        case processingFailed(String)
        case invalidRegion
        
        var errorDescription: String? {
            switch self {
            case .screenCaptureFailure:
                return "Failed to capture screen content"
            case .noTextFound:
                return "No text was found in the selected area"
            case .processingFailed(let message):
                return "OCR processing failed: \(message)"
            case .invalidRegion:
                return "Invalid selection region"
            }
        }
    }
    
    /// Performs OCR on a specific region of the screen
    /// - Parameters:
    ///   - region: The screen region to capture and process
    ///   - completion: Completion handler called with the OCR result
    func performOCR(on region: CGRect, completion: @escaping OCRCompletion) {
        print("OCRManager: Starting OCR on region: \(region)")
        
        // Validate region
        guard region.width > 0 && region.height > 0 else {
            print("OCRManager: Invalid region dimensions")
            DispatchQueue.main.async {
                completion(.failure(.invalidRegion))
            }
            return
        }
        
        // Capture screen region
        print("OCRManager: Attempting to capture screen region")
        guard let screenImage = captureScreen(region: region) else {
            print("OCRManager: Failed to capture screen region")
            DispatchQueue.main.async {
                completion(.failure(.screenCaptureFailure))
            }
            return
        }
        
        print("OCRManager: Successfully captured screen image: \(screenImage.width)x\(screenImage.height)")
        
        // Save debug image to desktop for troubleshooting (only in debug builds)
        #if DEBUG
        if let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            let imageURL = desktopURL.appendingPathComponent("ocr_debug_capture.png")
            if let destination = CGImageDestinationCreateWithURL(imageURL as CFURL, UTType.png.identifier as CFString, 1, nil) {
                CGImageDestinationAddImage(destination, screenImage, nil)
                CGImageDestinationFinalize(destination)
                print("OCRManager: Debug image saved to \(imageURL.path)")
            }
        }
        #endif
        
        // Process image with Vision framework
        print("OCRManager: Starting Vision framework processing")
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            print("OCRManager: Vision request completed")
            DispatchQueue.main.async {
                self?.handleVisionResults(request: request, error: error, capturedImage: screenImage, completion: completion)
            }
        }
        
        // Configure for better text detection
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Add more recognition languages for better detection
        if #available(macOS 13.0, *) {
            request.recognitionLanguages = ["en-US", "en-GB"]
        }
        
        // Enable automatic detection of text regions (macOS 13+)
        if #available(macOS 13.0, *) {
            request.automaticallyDetectsLanguage = true
        }
        
        // Create handler and perform request
        let handler = VNImageRequestHandler(cgImage: screenImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                print("OCRManager: Performing Vision request")
                try handler.perform([request])
            } catch {
                print("OCRManager: Vision request failed: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.processingFailed(error.localizedDescription)))
                }
            }
        }
    }
    
    /// Captures a specific region of the screen including all visible windows
    /// - Parameter region: The region to capture in screen coordinates  
    /// - Returns: CGImage of the captured region, or nil if capture fails
    private func captureScreen(region: CGRect) -> CGImage? {
        print("OCRManager: Starting comprehensive screen capture analysis")
        
        // DIAGNOSTIC: Let's first understand what's available
        debugAvailableCaptureMethods()
        
        // Method 1: Try the most direct approach - screenshot-style capture
        print("OCRManager: Method 1 - Direct screenshot-style capture")
        if let image = captureViaScreenshot(region: region) {
            print("OCRManager: SUCCESS - Screenshot method worked")
            return image
        }
        
        // Method 2: Try window enumeration and manual capture
        print("OCRManager: Method 2 - Window enumeration approach")
        if let image = captureViaWindowEnumeration(region: region) {
            print("OCRManager: SUCCESS - Window enumeration worked") 
            return image
        }
        
        // Method 3: Last resort - tell user to use built-in screenshot
        print("OCRManager: Method 3 - All methods failed")
        return nil
    }
    
    /// Debug what capture methods are available
    private func debugAvailableCaptureMethods() {
        print("=== CAPTURE METHOD DIAGNOSIS ===")
        
        // Check if we can capture display at all
        let displayID = CGMainDisplayID()
        if let _ = CGDisplayCreateImage(displayID) {
            print("✅ CGDisplayCreateImage: Available")
        } else {
            print("❌ CGDisplayCreateImage: Failed")
        }
        
        // Check window list
        if let _ = CGWindowListCreateImage(CGRect.infinite, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) {
            print("✅ CGWindowListCreateImage: Available")
        } else {
            print("❌ CGWindowListCreateImage: Failed")
        }
        
        // Check ScreenCaptureKit availability
        if #available(macOS 12.3, *) {
            print("✅ ScreenCaptureKit: Framework available")
        } else {
            print("❌ ScreenCaptureKit: Not available on this macOS version")
        }
        
        print("=== END DIAGNOSIS ===")
    }
    
    /// Method 1: Screenshot-style capture using native APIs with proper Retina handling
    private func captureViaScreenshot(region: CGRect) -> CGImage? {
        // Use CGDisplayCreateImageForRect to handle Retina coordinates properly
        let displayID = CGMainDisplayID()
        
        // Force a brief pause to ensure all rendering is complete
        usleep(100000) // 0.1 second
        
        print("OCRManager: Attempting to capture region: \(region)")
        
        // Use CGDisplayCreateImage with rect parameter to avoid coordinate system issues on Retina
        guard let regionImage = CGDisplayCreateImage(displayID, rect: region) else {
            print("OCRManager: Failed to capture region directly")
            
            // Fallback: capture full display and crop (old method)
            guard let fullImage = CGDisplayCreateImage(displayID) else {
                print("OCRManager: Failed to capture full display as fallback")
                return nil
            }
            
            print("OCRManager: Fallback - captured full display (\(fullImage.width)x\(fullImage.height))")
            
            // Crop to region
            guard let croppedImage = fullImage.cropping(to: region) else {
                print("OCRManager: Failed to crop to region")
                return nil
            }
            
            print("OCRManager: Fallback - cropped to region (\(croppedImage.width)x\(croppedImage.height))")
            return croppedImage
        }
        
        print("OCRManager: Successfully captured region directly (\(regionImage.width)x\(regionImage.height))")
        return regionImage
    }
    
    /// Method 2: Try to enumerate and capture specific windows
    private func captureViaWindowEnumeration(region: CGRect) -> CGImage? {
        print("OCRManager: Enumerating windows in region...")
        
        // Get window list
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            print("OCRManager: Failed to get window list")
            return nil
        }
        
        print("OCRManager: Found \(windowList.count) windows")
        
        // Find windows that intersect with our region
        var intersectingWindows: [CGWindowID] = []
        
        for windowInfo in windowList {
            if let bounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
               let x = bounds["X"] as? CGFloat,
               let y = bounds["Y"] as? CGFloat,
               let width = bounds["Width"] as? CGFloat,
               let height = bounds["Height"] as? CGFloat {
                
                let windowRect = CGRect(x: x, y: y, width: width, height: height)
                
                if windowRect.intersects(region) {
                    if let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID {
                        intersectingWindows.append(windowID)
                        print("OCRManager: Window \(windowID) intersects region")
                    }
                }
            }
        }
        
        if intersectingWindows.isEmpty {
            print("OCRManager: No windows found in region")
            return nil
        }
        
        // Try to capture the region with these windows
        let options: CGWindowListOption = [.optionOnScreenOnly, .optionIncludingWindow]
        
        for windowID in intersectingWindows {
            if let image = CGWindowListCreateImage(region, options, windowID, .bestResolution) {
                print("OCRManager: Successfully captured with window \(windowID)")
                return image
            }
        }
        
        print("OCRManager: Failed to capture any intersecting windows")
        return nil
    }
    
    /// Captures screen using ScreenCaptureKit (macOS 12.3+)
    @available(macOS 12.3, *)
    private func captureWithScreenCaptureKit(region: CGRect) -> CGImage? {
        // For now, let's skip the complex ScreenCaptureKit implementation
        // and focus on fixing the basic window capture issue first
        print("OCRManager: ScreenCaptureKit implementation temporarily disabled")
        return nil
    }
    
    /// Handles the results from Vision framework
    /// - Parameters:
    ///   - request: The completed Vision request
    ///   - error: Any error that occurred during processing
    ///   - capturedImage: The original captured image
    ///   - completion: The completion handler to call with results
    private func handleVisionResults(request: VNRequest, error: Error?, capturedImage: CGImage, completion: @escaping OCRCompletion) {
        print("OCRManager: handleVisionResults called")
        
        // Check for processing errors
        if let error = error {
            print("OCRManager: Vision processing error: \(error)")
            completion(.failure(.processingFailed(error.localizedDescription)))
            return
        }
        
        // Extract text observations
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            print("OCRManager: No valid observations found")
            completion(.failure(.noTextFound))
            return
        }
        
        print("OCRManager: Found \(observations.count) text observations")
        
        // Sort observations by vertical position (top to bottom) for proper line order
        let sortedObservations = observations.sorted { obs1, obs2 in
            // VNRecognizedTextObservation coordinates are normalized (0.0 to 1.0)
            // Y coordinate 0 is bottom, 1 is top, so we want descending Y order for top-to-bottom reading
            return obs1.boundingBox.midY > obs2.boundingBox.midY
        }
        
        print("OCRManager: Sorted \(sortedObservations.count) observations by vertical position")
        
        // Combine all recognized text with intelligent line break detection
        var recognizedText = ""
        var previousBoundingBox: CGRect?
        
        for (index, observation) in sortedObservations.enumerated() {
            guard let candidate = observation.topCandidates(1).first else { 
                print("OCRManager: No candidate found for observation \(index)")
                continue 
            }
            
            let currentBounds = observation.boundingBox
            print("OCRManager: Observation \(index): '\(candidate.string)' at Y: \(currentBounds.midY)")
            
            // Determine if we need a line break
            var needsLineBreak = false
            
            if let prevBounds = previousBoundingBox {
                // Calculate vertical distance between text regions
                let verticalDistance = abs(prevBounds.midY - currentBounds.midY)
                
                // If there's significant vertical separation, it's likely a new line
                // Threshold of 0.02 works well for typical text (about 2% of image height)
                if verticalDistance > 0.02 {
                    needsLineBreak = true
                    print("OCRManager: Line break detected (vertical distance: \(verticalDistance))")
                }
            }
            
            // Add the text with appropriate spacing
            if !recognizedText.isEmpty {
                if needsLineBreak {
                    recognizedText += "\n"
                } else {
                    // Same line, add space if not already present
                    if !recognizedText.hasSuffix(" ") && !candidate.string.hasPrefix(" ") {
                        recognizedText += " "
                    }
                }
            }
            
            recognizedText += candidate.string
            previousBoundingBox = currentBounds
        }
        
        print("OCRManager: Final recognized text: '\(recognizedText)'")
        
        // Always return the result with the captured image, even if no text was found
        print("OCRManager: Recognized text: '\(recognizedText)' (\(recognizedText.count) characters)")
        let result = OCRResult(text: recognizedText, capturedImage: capturedImage)
        completion(.success(result))
    }
    
    /// Checks if the device supports OCR functionality
    /// - Returns: True if OCR is supported, false otherwise
    static func isOCRSupported() -> Bool {
        // OCR is available on macOS 10.15+ with Vision framework
        if #available(macOS 10.15, *) {
            return true
        } else {
            return false
        }
    }
    
    /// Requests screen recording permission if not already granted
    /// - Returns: True if permission is already granted, false if permission dialog was shown
    @discardableResult
    static func requestScreenRecordingPermission() -> Bool {
        print("OCRManager: Checking screen recording permission...")
        
        // Check if we already have permission by attempting a small screen capture
        let testRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let displayID = CGMainDisplayID()
        
        if let _ = CGDisplayCreateImage(displayID, rect: testRect) {
            // We have permission
            print("OCRManager: Screen recording permission already granted")
            return true
        } else {
            // We don't have permission - the system will show permission dialog
            // when we attempt screen capture
            print("OCRManager: Screen recording permission not granted - dialog should appear")
            return false
        }
    }
    
    /// Checks if screen recording permission is granted
    /// - Returns: True if permission is granted
    static func hasScreenRecordingPermission() -> Bool {
        // Attempt a minimal screen capture to test permission
        let testRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let displayID = CGMainDisplayID()
        
        let hasPermission = CGDisplayCreateImage(displayID, rect: testRect) != nil
        print("OCRManager: Screen recording permission check result: \(hasPermission)")
        return hasPermission
    }
    
    /// Shows a user-friendly dialog explaining why Screen Recording permission is needed
    /// - Returns: True if user clicked OK to go to settings, false if cancelled
    @discardableResult
    static func showPermissionDialog() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "ClipTyper needs Screen Recording permission to capture text from your screen.\n\nPlease:\n1. Click 'Open System Settings'\n2. Enable ClipTyper in Screen Recording\n3. Restart ClipTyper"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Open System Preferences to Privacy settings
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
            return true
        }
        
        return false
    }
}