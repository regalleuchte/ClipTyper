//
//  ClipboardManager.swift
//  ClipTyper
//
//  Copyright © 2025 Ralf Sturhan. All rights reserved.
//

import Cocoa

/// Manages clipboard monitoring and operations
/// 
/// This class provides functionality to monitor clipboard changes,
/// retrieve clipboard content, and manage clipboard operations.
class ClipboardManager {
    /// Callback triggered when clipboard content changes
    /// - Parameter count: The character count of the new clipboard content
    var onClipboardChange: ((Int) -> Void)?
    
    // Timer for clipboard monitoring
    private var clipboardTimer: Timer?
    private var lastChangeCount: Int
    private let pasteboard: NSPasteboard
    
    /// Monitoring interval in seconds
    private static let monitoringInterval = Constants.clipboardMonitoringInterval
    
    /// Initialize with optional pasteboard (useful for testing)
    /// - Parameter pasteboard: NSPasteboard to monitor (defaults to .general)
    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
        self.lastChangeCount = pasteboard.changeCount
    }
    
    /// Start monitoring clipboard changes
    func startMonitoring() {
        startMonitoringClipboard()
    }
    
    /// Stop monitoring clipboard changes
    func stopMonitoring() {
        stopMonitoringClipboard()
    }
    
    deinit {
        stopMonitoringClipboard()
    }
    
    private func startMonitoringClipboard() {
        // Check clipboard at regular intervals
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: Self.monitoringInterval, repeats: true) { [weak self] _ in
            self?.checkClipboardChanges()
        }
    }
    
    private func stopMonitoringClipboard() {
        clipboardTimer?.invalidate()
        clipboardTimer = nil
    }
    
    private func checkClipboardChanges() {
        let currentChangeCount = pasteboard.changeCount
        
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            // Notify about clipboard change with character count
            let count = getClipboardCharacterCount()
            onClipboardChange?(count)
        }
    }
    
    /// Retrieve current clipboard text content
    /// - Returns: The clipboard text, or empty string if no text available
    func getClipboardText() -> String {
        return pasteboard.string(forType: .string) ?? ""
    }
    
    /// Get the character count of current clipboard content
    /// - Returns: Number of characters in clipboard text
    func getClipboardCharacterCount() -> Int {
        return getClipboardText().count
    }
    
    /// Clear the clipboard contents
    func clearClipboard() {
        pasteboard.clearContents()
    }
} 