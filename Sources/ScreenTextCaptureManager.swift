//
//  ScreenTextCaptureManager.swift
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
import Cocoa

/// Manages the complete Screen Text Capture workflow
/// Coordinates between screen selection, OCR processing, and clipboard integration
class ScreenTextCaptureManager {
    
    /// Completion handler for the capture process
    typealias CaptureCompletion = (Result<String, CaptureError>) -> Void
    
    /// Screen text capture specific errors
    enum CaptureError: LocalizedError {
        case featureDisabled
        case permissionDenied
        case selectionCancelled
        case ocrFailed(OCRManager.OCRError)
        case unknownError(String)
        
        var errorDescription: String? {
            switch self {
            case .featureDisabled:
                return "Screen Text Capture is not enabled"
            case .permissionDenied:
                return "Screen Recording permission is required for Screen Text Capture"
            case .selectionCancelled:
                return "Screen selection was cancelled"
            case .ocrFailed(let ocrError):
                return ocrError.errorDescription
            case .unknownError(let message):
                return "An unknown error occurred: \(message)"
            }
        }
    }
    
    private let preferencesManager: PreferencesManager
    private let ocrManager: OCRManager
    private let screenCaptureOverlay: ScreenCaptureOverlay
    
    /// Current capture process completion handler
    private var currentCompletion: CaptureCompletion?
    
    /// Initializes the Screen Text Capture Manager
    /// - Parameter preferencesManager: The preferences manager to use for settings
    init(preferencesManager: PreferencesManager) {
        self.preferencesManager = preferencesManager
        self.ocrManager = OCRManager()
        self.screenCaptureOverlay = ScreenCaptureOverlay()
    }
    
    /// Starts the screen text capture process
    /// - Parameter completion: Called when the process completes or fails
    func startCapture(completion: @escaping CaptureCompletion) {
        // Check if feature is enabled
        guard preferencesManager.ocrEnabled else {
            completion(.failure(.featureDisabled))
            return
        }
        
        // Check if OCR is supported
        guard OCRManager.isOCRSupported() else {
            completion(.failure(.unknownError("OCR is not supported on this device")))
            return
        }
        
        // Check screen recording permission with better user experience
        guard OCRManager.hasScreenRecordingPermission() else {
            print("ScreenTextCaptureManager: Screen recording permission not available")
            
            // Show user-friendly dialog explaining the permission requirement
            DispatchQueue.main.async {
                let userWantsToGrantPermission = OCRManager.showPermissionDialog()
                if !userWantsToGrantPermission {
                    completion(.failure(.permissionDenied))
                }
                // If user opened System Settings, they need to restart the app
                // The permission check will happen again next time they try to use OCR
            }
            
            completion(.failure(.permissionDenied))
            return
        }
        
        // Store completion handler
        self.currentCompletion = completion
        
        // Start screen selection with safer overlay
        print("ScreenTextCaptureManager: Starting screen selection")
        screenCaptureOverlay.showSelection { [weak self] selectedRegion in
            print("ScreenTextCaptureManager: Screen selection callback called with region: \(String(describing: selectedRegion))")
            
            // Add defensive programming to prevent crashes
            guard let strongSelf = self else {
                print("ScreenTextCaptureManager: Self was deallocated, ignoring callback")
                return
            }
            
            strongSelf.handleScreenSelection(region: selectedRegion)
        }
    }
    
    /// Handles the result of screen selection
    /// - Parameter region: The selected screen region, or nil if cancelled
    private func handleScreenSelection(region: CGRect?) {
        print("ScreenTextCaptureManager: handleScreenSelection called with region: \(String(describing: region))")
        
        guard let completion = currentCompletion else { 
            print("ScreenTextCaptureManager: No completion handler available")
            return 
        }
        
        // Clear the completion handler immediately to prevent retain cycles
        currentCompletion = nil
        
        // Check if selection was cancelled
        guard let region = region else {
            print("ScreenTextCaptureManager: Selection was cancelled")
            DispatchQueue.main.async {
                completion(.failure(.selectionCancelled))
            }
            return
        }
        
        print("ScreenTextCaptureManager: Starting OCR on region: \(region)")
        
        // Add a delay to ensure our overlay is completely gone before capture
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            // Perform OCR on the selected region with explicit weak reference
            self?.ocrManager.performOCR(on: region) { [weak self] result in
                print("ScreenTextCaptureManager: OCR completed with result: \(result)")
                
                // Ensure we're on main queue and handle result safely
                DispatchQueue.main.async {
                    self?.handleOCRResultSafely(result: result, completion: completion)
                }
            }
        }
    }
    
    /// Safely handles the result of OCR processing with defensive memory management
    /// - Parameters:
    ///   - result: The OCR result
    ///   - completion: The original completion handler
    private func handleOCRResultSafely(result: Result<OCRManager.OCRResult, OCRManager.OCRError>, completion: @escaping CaptureCompletion) {
        print("ScreenTextCaptureManager: handleOCRResultSafely called")
        
        // Ensure we're on main thread
        assert(Thread.isMainThread, "handleOCRResultSafely must be called on main thread")
        
        switch result {
        case .success(let ocrResult):
            let hasText = !ocrResult.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            print("ScreenTextCaptureManager: OCR completed with \(hasText ? "\(ocrResult.text.count) characters" : "no text found")")
            
            // Always show preview dialog if enabled, or if no text was found (to allow manual entry)
            if preferencesManager.ocrShowPreview || !hasText {
                let dialogTitle = hasText ? "Preview the recognized text:" : "No text found - you can enter text manually:"
                print("ScreenTextCaptureManager: Showing preview dialog (\(hasText ? "with text" : "for manual entry"))")
                showPreviewDialog(text: ocrResult.text, image: ocrResult.capturedImage, title: dialogTitle, completion: completion)
            } else {
                print("ScreenTextCaptureManager: Adding text directly to clipboard")
                addToClipboard(text: ocrResult.text)
                completion(.success(ocrResult.text))
            }
            
        case .failure(let ocrError):
            print("ScreenTextCaptureManager: OCR failed with error: \(ocrError)")
            completion(.failure(.ocrFailed(ocrError)))
        }
    }
    
    /// Legacy method kept for compatibility - now calls safer version
    /// - Parameters:
    ///   - result: The OCR result
    ///   - completion: The original completion handler
    private func handleOCRResult(result: Result<OCRManager.OCRResult, OCRManager.OCRError>, completion: @escaping CaptureCompletion) {
        DispatchQueue.main.async {
            self.handleOCRResultSafely(result: result, completion: completion)
        }
    }
    
    /// Shows a preview dialog for the recognized text with the captured image
    /// - Parameters:
    ///   - text: The recognized text to preview
    ///   - image: The captured image to display
    ///   - title: Custom title for the dialog
    ///   - completion: The completion handler to call with final result
    private func showPreviewDialog(text: String, image: CGImage, title: String, completion: @escaping CaptureCompletion) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Screen Text Capture"
            alert.informativeText = title
            alert.alertStyle = .informational
            
            // Create main container
            let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 350))
            
            // Create image view to display captured image
            let imageView = NSImageView(frame: NSRect(x: 0, y: 200, width: 500, height: 150))
            let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
            imageView.image = nsImage
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.wantsLayer = true
            imageView.layer?.borderWidth = 1.0
            imageView.layer?.borderColor = NSColor.controlAccentColor.cgColor
            imageView.layer?.cornerRadius = 4.0
            
            // Add label for the image
            let imageLabel = NSTextField(labelWithString: "Captured Image:")
            imageLabel.frame = NSRect(x: 0, y: 175, width: 500, height: 20)
            imageLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            
            // Create text view for editing
            let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let textLabelText = hasText ? "Recognized Text (editable):" : "Enter Text Manually:"
            let textLabel = NSTextField(labelWithString: textLabelText)
            textLabel.frame = NSRect(x: 0, y: 150, width: 500, height: 20)
            textLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            
            let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 500, height: 145))
            let textView = NSTextView(frame: scrollView.bounds)
            textView.string = text
            textView.isEditable = true
            textView.isSelectable = true
            textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            
            scrollView.documentView = textView
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = true
            scrollView.autohidesScrollers = false
            
            // Add all views to container
            containerView.addSubview(imageView)
            containerView.addSubview(imageLabel)
            containerView.addSubview(textLabel)
            containerView.addSubview(scrollView)
            
            alert.accessoryView = containerView
            
            alert.addButton(withTitle: "Add to Clipboard")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                // User confirmed - use the (possibly edited) text
                let finalText = textView.string
                self.addToClipboard(text: finalText)
                completion(.success(finalText))
            } else {
                // User cancelled
                completion(.failure(.selectionCancelled))
            }
        }
    }
    
    /// Adds text to the system clipboard
    /// - Parameter text: The text to add to clipboard
    private func addToClipboard(text: String) {
        print("ScreenTextCaptureManager: addToClipboard called with text: '\(text)'")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)
        print("ScreenTextCaptureManager: Clipboard set result: \(success)")
    }
    
    /// Cancels any ongoing capture process
    func cancelCapture() {
        screenCaptureOverlay.cancelSelection()
        
        if let completion = currentCompletion {
            currentCompletion = nil
            completion(.failure(.selectionCancelled))
        }
    }
    
    /// Checks if Screen Text Capture is available and properly configured
    /// - Returns: True if available, false otherwise
    func isAvailable() -> Bool {
        return preferencesManager.ocrEnabled && 
               OCRManager.isOCRSupported() && 
               OCRManager.hasScreenRecordingPermission()
    }
    
    /// Requests necessary permissions for Screen Text Capture
    /// This may show system permission dialogs
    func requestPermissions() {
        OCRManager.requestScreenRecordingPermission()
    }
    
    /// Checks if all required permissions are granted
    /// - Returns: True if all permissions are available
    func hasRequiredPermissions() -> Bool {
        return OCRManager.hasScreenRecordingPermission()
    }
}