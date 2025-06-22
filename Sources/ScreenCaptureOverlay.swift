//
//  ScreenCaptureOverlay.swift
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
import Foundation

/// Manages screen text capture selection using transparent window
/// Clean interface with crosshair cursor and reliable mouse tracking
class ScreenCaptureOverlay {
    
    /// Completion handler for selection results
    typealias SelectionCompletion = (CGRect?) -> Void
    
    private var completion: SelectionCompletion?
    private var captureWindow: NSWindow?
    private var escKeyMonitor: Any?
    private var localEscKeyMonitor: Any?
    
    /// Shows the screen capture selection with transparent window
    /// - Parameter completion: Called with selected region or nil if cancelled
    func showSelection(completion: @escaping SelectionCompletion) {
        print("ScreenCaptureOverlay: Starting screen selection")
        self.completion = completion
        
        // Get main screen bounds
        guard let mainScreen = NSScreen.main else {
            completion(nil)
            return
        }
        
        // Create transparent full-screen window for mouse tracking
        let screenFrame = mainScreen.frame
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Ensure window is retained
        window.isReleasedWhenClosed = false
        captureWindow = window
        
        guard let window = captureWindow else {
            completion(nil)
            return
        }
        
        // Configure window to be invisible but capture mouse events
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.level = .floating  // Lower priority than .screenSaver to allow menu interactions
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Create selection view with direct callback instead of delegate
        let selectionView = SelectionTrackingView(frame: screenFrame)
        selectionView.completionCallback = { [weak self] region in
            if let region = region {
                self?.finishSelection(with: region)
            } else {
                self?.cancelSelection()
            }
        }
        window.contentView = selectionView
        
        // Set up both global and local ESC key monitoring for reliable cancellation
        escKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                print("ScreenCaptureOverlay: Global ESC pressed")
                self?.cancelSelection()
            }
        }
        
        // Also add local monitor to catch ESC when our app has focus
        localEscKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                print("ScreenCaptureOverlay: Local ESC pressed")
                self?.cancelSelection()
                return nil // Consume the event
            }
            return event
        }
        
        // Show window and immediately set cursor
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Force immediate cursor update - must be after window is key
        DispatchQueue.main.async {
            // Force a cursor update cycle to clear any AppKit caching
            if let selectionView = window.contentView as? SelectionTrackingView {
                window.invalidateCursorRects(for: selectionView)
                window.resetCursorRects()
            }
            
            NSCursor.crosshair.set()
            
            // Force AppKit to immediately recognize the cursor change
            window.makeKey()
            print("ScreenCaptureOverlay: Immediate cursor setup after window shown")
        }
        
        print("ScreenCaptureOverlay: Window shown, crosshair cursor setup initiated")
    }
    
    /// Finishes selection with the given region
    private func finishSelection(with region: CGRect) {
        print("ScreenCaptureOverlay: Finishing selection with region: \(region)")
        
        // Handle cursor restoration for successful completion
        if let window = captureWindow,
           let selectionView = window.contentView as? SelectionTrackingView {
            if selectionView.cursorPushed {
                NSCursor.pop()
                selectionView.cursorPushed = false
                print("ScreenCaptureOverlay: Popped cursor after successful selection")
            } else {
                NSCursor.arrow.set()
                print("ScreenCaptureOverlay: Set arrow cursor after successful selection")
            }
        }
        
        // Store completion before cleanup to prevent retain cycles
        let savedCompletion = completion
        completion = nil
        
        // Perform cleanup first to release resources
        cleanup()
        
        // Call completion handler synchronously to avoid async retain cycle issues
        print("ScreenCaptureOverlay: Calling completion with region: \(region)")
        savedCompletion?(region)
    }
    
    /// Cancels the current selection
    func cancelSelection() {
        print("ScreenCaptureOverlay: Cancelling selection")
        
        // Handle cursor restoration for ESC cancellation
        if let window = captureWindow,
           let selectionView = window.contentView as? SelectionTrackingView {
            if selectionView.cursorPushed {
                NSCursor.pop()
                selectionView.cursorPushed = false
                print("ScreenCaptureOverlay: Popped cursor during ESC cancellation")
            } else {
                NSCursor.arrow.set()
                print("ScreenCaptureOverlay: Set arrow cursor during ESC cancellation")
            }
        }
        
        // Store completion before cleanup to prevent retain cycles
        let savedCompletion = completion
        completion = nil
        
        // Perform cleanup first to release resources
        cleanup()
        
        // Call completion handler synchronously to avoid async retain cycle issues
        print("ScreenCaptureOverlay: Calling completion with nil (cancelled)")
        savedCompletion?(nil)
        print("ScreenCaptureOverlay: Cancellation completion called successfully")
    }
    
    /// Cleans up window and restores cursor
    private func cleanup() {
        print("ScreenCaptureOverlay: Starting cleanup")
        
        autoreleasepool {
            // Cursor restoration is handled by finishSelection/cancelSelection
            print("ScreenCaptureOverlay: Cleaning up resources")
            
            // Remove ESC key monitors safely
            if let monitor = escKeyMonitor {
                NSEvent.removeMonitor(monitor)
                escKeyMonitor = nil
                print("ScreenCaptureOverlay: Global ESC monitor removed")
            }
            
            if let localMonitor = localEscKeyMonitor {
                NSEvent.removeMonitor(localMonitor)
                localEscKeyMonitor = nil
                print("ScreenCaptureOverlay: Local ESC monitor removed")
            }
            
            // Close and cleanup window with explicit autorelease pool
            if let window = captureWindow {
                // Clear callback first to break retain cycles
                if let selectionView = window.contentView as? SelectionTrackingView {
                    selectionView.completionCallback = nil
                    print("ScreenCaptureOverlay: Callback reference cleared")
                }
                
                // Order out first to remove from screen
                window.orderOut(nil)
                print("ScreenCaptureOverlay: Window ordered out")
                
                // Clear content view
                window.contentView = nil
                print("ScreenCaptureOverlay: Content view cleared")
                
                // Close window
                window.close()
                print("ScreenCaptureOverlay: Window closed")
            }
            captureWindow = nil
        }
        
        print("ScreenCaptureOverlay: Cleanup complete")
    }
}

// MARK: - Selection Tracking View

/// Transparent view that handles mouse tracking for selection
private class SelectionTrackingView: NSView {
    var completionCallback: ((CGRect?) -> Void)?
    
    private var isDragging = false
    private var startPoint: NSPoint = .zero
    private var currentPoint: NSPoint = .zero
    fileprivate var cursorPushed = false
    
    /// Reset cursor state (for debugging)
    func resetCursorState() {
        if cursorPushed {
            NSCursor.pop()
            cursorPushed = false
            print("SelectionTrackingView: Reset - popped cursor")
        }
        NSCursor.arrow.set()
        print("SelectionTrackingView: Reset - set arrow cursor")
    }
    
    override func mouseDown(with event: NSEvent) {
        print("SelectionTrackingView: Mouse down - pushing crosshair cursor")
        NSCursor.crosshair.push()
        cursorPushed = true
        isDragging = true
        startPoint = convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        setNeedsDisplay(bounds)
    }
    
    override func mouseMoved(with event: NSEvent) {
        // Ensure crosshair cursor is maintained during mouse movement
        NSCursor.crosshair.set()
        print("SelectionTrackingView: mouseMoved - setting crosshair")
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        currentPoint = convert(event.locationInWindow, from: nil)
        setNeedsDisplay(bounds)
        
        // ensure it stays a crosshair
        NSCursor.crosshair.set()
    }
    
    override func mouseUp(with event: NSEvent) {
        guard isDragging else { return }
        print("SelectionTrackingView: Mouse up - popping cursor")
        isDragging = false
        if cursorPushed {
            NSCursor.pop()
            cursorPushed = false
        }
        
        let endPoint = convert(event.locationInWindow, from: nil)
        
        // Calculate selection rectangle
        let selectionRect = NSRect(
            x: min(startPoint.x, endPoint.x),
            y: min(startPoint.y, endPoint.y),
            width: abs(endPoint.x - startPoint.x),
            height: abs(endPoint.y - startPoint.y)
        )
        
        print("SelectionTrackingView: Selection rect: \(selectionRect)")
        
        // Convert to screen coordinates (flip Y)
        let screenRect = CGRect(
            x: selectionRect.origin.x,
            y: NSScreen.main!.frame.height - selectionRect.origin.y - selectionRect.height,
            width: selectionRect.width,
            height: selectionRect.height
        )
        
        // Store callback before clearing to prevent retain cycles
        let callback = completionCallback
        completionCallback = nil
        
        // Only proceed if selection has meaningful size (reduced threshold)
        if screenRect.width > 5 && screenRect.height > 5 {
            print("SelectionTrackingView: Calling completion callback")
            callback?(screenRect)
        } else {
            print("SelectionTrackingView: Selection too small (\(screenRect.width)x\(screenRect.height)), cancelling")
            callback?(nil)
        }
    }
    
    override func keyDown(with event: NSEvent) {
        // Let the global ESC monitors handle ESC key
        // This prevents conflicts between multiple ESC handlers
        super.keyDown(with: event)
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
        
        // Set up tracking area for cursor management
        updateTrackingAreas()
        
        print("SelectionTrackingView: viewDidMoveToWindow - setup complete")
    }
    
    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .crosshair)
        print("SelectionTrackingView: resetCursorRects called - crosshair cursor rect added")
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        let options: NSTrackingArea.Options = [
            .mouseMoved, .activeAlways, .cursorUpdate
        ]
        let area = NSTrackingArea(rect: bounds,
                                  options: options,
                                  owner: self,
                                  userInfo: nil)
        addTrackingArea(area)
        window?.invalidateCursorRects(for: self)
    }
    
    override func cursorUpdate(with event: NSEvent) {
        NSCursor.crosshair.set()
        print("SelectionTrackingView: cursorUpdate called - crosshair set")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Only draw selection rectangle if we're dragging
        if isDragging {
            let selectionRect = NSRect(
                x: min(startPoint.x, currentPoint.x),
                y: min(startPoint.y, currentPoint.y),
                width: abs(currentPoint.x - startPoint.x),
                height: abs(currentPoint.y - startPoint.y)
            )
            
            // Draw selection border with dynamic colors for better visibility in all modes
            NSColor.systemBlue.setStroke()
            let borderPath = NSBezierPath(rect: selectionRect)
            borderPath.lineWidth = 3
            borderPath.stroke()
            
            // Add a contrasting inner border - white in dark mode, black in light mode
            let appearance = NSApp.effectiveAppearance
            let isDarkMode = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let innerColor = isDarkMode ? NSColor.white : NSColor.black
            
            innerColor.setStroke()
            let innerPath = NSBezierPath(rect: selectionRect.insetBy(dx: 1.5, dy: 1.5))
            innerPath.lineWidth = 1
            innerPath.stroke()
            
            // Note: Dimensions display removed to avoid interference with OCR capture
        }
    }
}