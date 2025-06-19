//
//  ClipboardManager.swift
//  ClipTyper
//
//  Copyright © 2025 Ralf Sturhan. All rights reserved.
//

import Cocoa

class ClipboardManager {
    // Callback for when clipboard changes
    var onClipboardChange: ((Int) -> Void)?
    
    // Timer for clipboard monitoring
    private var clipboardTimer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    
    init() {
        startMonitoringClipboard()
    }
    
    deinit {
        stopMonitoringClipboard()
    }
    
    private func startMonitoringClipboard() {
        // Check clipboard every 0.5 seconds
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboardChanges()
        }
    }
    
    private func stopMonitoringClipboard() {
        clipboardTimer?.invalidate()
        clipboardTimer = nil
    }
    
    private func checkClipboardChanges() {
        let currentChangeCount = NSPasteboard.general.changeCount
        
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            // Notify about clipboard change with character count
            let count = getClipboardCharacterCount()
            onClipboardChange?(count)
        }
    }
    
    func getClipboardText() -> String {
        if let clipboardString = NSPasteboard.general.string(forType: .string) {
            return clipboardString
        }
        return ""
    }
    
    func getClipboardCharacterCount() -> Int {
        return getClipboardText().count
    }
    
    func clearClipboard() {
        NSPasteboard.general.clearContents()
    }
} 