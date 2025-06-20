//
//  AppDelegate.swift
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
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenu: NSMenu!
    private var mainMenuItem: NSMenuItem!
    private var clipboardStatusMenuItem: NSMenuItem!
    private var delayValueLabel: NSTextField!
    private var preferencesManager: PreferencesManager!
    private var clipboardManager: ClipboardManager!
    private var keyboardSimulator: KeyboardSimulator!
    private var shortcutManager: GlobalShortcutManager!
    private var loginItemManager: LoginItemManager!
    private let defaults = UserDefaults.standard
    
    // Flag to track if a warning dialog is currently shown
    private var isWarningDialogShown = false
    // Flag to track if countdown is in progress
    private var isCountdownInProgress = false
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupManagers()
        setupStatusItem()
        setupMenu()
        registerShortcut()
        requestAccessibilityPermission()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up observers
        if #available(macOS 10.14, *) {
            NSApp.removeObserver(self, forKeyPath: "effectiveAppearance")
        }
        
        // Clean up managers
        shortcutManager?.unregisterShortcut()
    }
    
    deinit {
        // Additional cleanup in case applicationWillTerminate isn't called
        if #available(macOS 10.14, *) {
            NSApp.removeObserver(self, forKeyPath: "effectiveAppearance")
        }
    }
    
    private func setupManagers() {
        preferencesManager = PreferencesManager()
        clipboardManager = ClipboardManager()
        keyboardSimulator = KeyboardSimulator()
        shortcutManager = GlobalShortcutManager()
        loginItemManager = LoginItemManager()
        
        // Setup clipboard monitoring to update character count
        clipboardManager.onClipboardChange = { [weak self] count in
            self?.updateCharacterCount(count)
        }
        
        // Start clipboard monitoring
        clipboardManager.startMonitoring()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Enhanced SF Symbols integration with better visual states
            setupStatusBarIcon()
            button.target = self
            
            // Right click activates typing, left click shows menu
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(statusItemClicked(_:))
            
            // Enhanced accessibility
            button.toolTip = "ClipTyper - Right-click to type clipboard, left-click for settings"
        }
        
        // Setup automatic dark mode observation
        setupDarkModeObserver()
        updateCharacterCount(clipboardManager.getClipboardCharacterCount())
    }
    
    private func setupStatusBarIcon() {
        guard let button = statusItem.button else { return }
        
        // Use enhanced SF Symbol with better configuration
        let iconImage: NSImage?
        if #available(macOS 11.0, *) {
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium, scale: .medium)
            iconImage = NSImage(systemSymbolName: "doc.on.clipboard.fill", accessibilityDescription: "ClipTyper")?.withSymbolConfiguration(config)
        } else {
            iconImage = NSImage(systemSymbolName: "doc.on.clipboard.fill", accessibilityDescription: "ClipTyper")
        }
        
        button.image = iconImage
        
        // Enhanced visual feedback
        button.imagePosition = .imageLeading
        button.imageHugsTitle = true
        
        // Better template rendering for dark mode
        iconImage?.isTemplate = true
    }
    
    private func setupDarkModeObserver() {
        // Use a safer approach with KVO instead of distributed notifications
        if #available(macOS 10.14, *) {
            // Listen for effective appearance changes
            NSApp.addObserver(self, forKeyPath: "effectiveAppearance", options: [.new, .initial], context: nil)
        }
        
        // Initial appearance setup
        updateAppearance()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "effectiveAppearance" {
            DispatchQueue.main.async {
                self.updateAppearance()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func updateAppearance() {
        // Update status item for current appearance
        setupStatusBarIcon()
        
        // Update any open panels/dialogs
        for window in NSApp.windows {
            if let panel = window as? ModernPanel {
                panel.updateForCurrentAppearance()
            }
        }
    }
    
    private func setupMenu() {
        statusMenu = NSMenu()
        
        // === PRIMARY ACTIONS ===
        mainMenuItem = NSMenuItem(title: "Type Clipboard (\(shortcutManager.getCurrentShortcutString()))", action: #selector(startTypingProcess), keyEquivalent: "")
        statusMenu.addItem(mainMenuItem)
        
        // Clipboard status (informational)
        let clipboardLength = clipboardManager.getClipboardCharacterCount()
        clipboardStatusMenuItem = NSMenuItem(title: "Clipboard: \(clipboardLength) characters", action: nil, keyEquivalent: "")
        clipboardStatusMenuItem.isEnabled = false
        statusMenu.addItem(clipboardStatusMenuItem)
        
        statusMenu.addItem(NSMenuItem.separator())
        
        // === TYPING SETTINGS ===
        // Delay slider
        let delayItem = NSMenuItem(title: "Typing Delay:", action: nil, keyEquivalent: "")
        let delayView = createDelaySliderView()
        delayItem.view = delayView
        statusMenu.addItem(delayItem)
        
        // Character warning threshold
        let thresholdItem = NSMenuItem(title: "Character Warning Threshold: \(preferencesManager.getCharacterWarningThreshold())", action: #selector(changeWarningThreshold), keyEquivalent: "")
        statusMenu.addItem(thresholdItem)
        
        // Auto-clear clipboard option
        let autoClearItem = NSMenuItem(title: "Auto-clear Clipboard After Typing", action: #selector(toggleAutoClear), keyEquivalent: "")
        autoClearItem.state = preferencesManager.getAutoClearClipboard() ? .on : .off
        statusMenu.addItem(autoClearItem)
        
        statusMenu.addItem(NSMenuItem.separator())
        
        // === DISPLAY SETTINGS ===
        // Countdown display options (as submenu)
        let countdownMenuItem = NSMenuItem(title: "Countdown Display", action: nil, keyEquivalent: "")
        let countdownSubmenu = NSMenu()
        
        let dialogItem = NSMenuItem(title: "Show in Dialog", action: #selector(selectDialogCountdown), keyEquivalent: "")
        dialogItem.state = !preferencesManager.getShowCountdownInMenuBar() ? .on : .off
        countdownSubmenu.addItem(dialogItem)
        
        let menuBarItem = NSMenuItem(title: "Show in Menu Bar", action: #selector(selectMenuBarCountdown), keyEquivalent: "")
        menuBarItem.state = preferencesManager.getShowCountdownInMenuBar() ? .on : .off
        countdownSubmenu.addItem(menuBarItem)
        
        countdownMenuItem.submenu = countdownSubmenu
        statusMenu.addItem(countdownMenuItem)
        
        // Show character count option
        let showCountItem = NSMenuItem(title: "Show Character Count in Menu Bar", action: #selector(toggleShowCharacterCount), keyEquivalent: "")
        showCountItem.state = preferencesManager.getShowCharacterCount() ? .on : .off
        statusMenu.addItem(showCountItem)
        
        statusMenu.addItem(NSMenuItem.separator())
        
        // === SYSTEM SETTINGS ===
        // Change keyboard shortcut
        statusMenu.addItem(NSMenuItem(title: "Change Keyboard Shortcut…", action: #selector(changeKeyboardShortcut), keyEquivalent: ""))
        
        // Autostart option
        let autostartItem = NSMenuItem(title: "Start ClipTyper at Login", action: #selector(toggleAutostart), keyEquivalent: "")
        autostartItem.state = preferencesManager.getAutostart() ? .on : .off
        statusMenu.addItem(autostartItem)
        
        statusMenu.addItem(NSMenuItem.separator())
        
        // === ABOUT & QUIT ===
        statusMenu.addItem(NSMenuItem(title: "About ClipTyper", action: #selector(showAbout), keyEquivalent: ""))
        statusMenu.addItem(NSMenuItem(title: "Quit ClipTyper", action: #selector(quitApp), keyEquivalent: "q"))
    }
    
    private func createDelaySliderView() -> NSView {
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 60))
        containerView.wantsLayer = true
        
        // Modern spacing
        let margin: CGFloat = 16
        let sliderWidth: CGFloat = 180
        
        // Modern slider with proper styling
        let slider = NSSlider(frame: NSRect(x: margin + 35, y: 25, width: sliderWidth, height: 20))
        slider.minValue = 0.5
        slider.maxValue = 10.0
        slider.doubleValue = preferencesManager.getTypingDelay()
        slider.target = self
        slider.action = #selector(delaySliderChanged(_:))
        slider.isContinuous = true
        
        // Modern slider appearance
        if #available(macOS 11.0, *) {
            slider.trackFillColor = NSColor.controlAccentColor
        }
        
        // Current value label with modern typography
        let currentDelay = preferencesManager.getTypingDelay()
        delayValueLabel = ModernLabel.createCaptionLabel(
            text: String(format: "%.1fs", currentDelay),
            frame: NSRect(x: margin + 35 + (sliderWidth / 2) - 20, y: 5, width: 40, height: 15)
        )
        delayValueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        
        // Min/max labels with modern styling
        let minLabel = ModernLabel.createCaptionLabel(
            text: "0.5s",
            frame: NSRect(x: 8, y: 25, width: 30, height: 20)
        )
        minLabel.alignment = .right
        
        let maxLabel = ModernLabel.createCaptionLabel(
            text: "10s",
            frame: NSRect(x: margin + 35 + sliderWidth + 5, y: 25, width: 30, height: 20)
        )
        maxLabel.alignment = .left
        
        containerView.addSubview(slider)
        containerView.addSubview(delayValueLabel)
        containerView.addSubview(minLabel)
        containerView.addSubview(maxLabel)
        
        return containerView
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        if event.type == .leftMouseUp {
            // Left click - show the menu
            statusItem.menu = statusMenu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else if event.type == .rightMouseUp {
            // Right click - start typing process
            startTypingProcess()
        }
    }
    
    @objc private func startTypingProcess() {
        // Check if we're already in the process
        if isCountdownInProgress {
            return
        }
        
        // If warning dialog is shown, take this as confirmation to proceed
        if isWarningDialogShown {
            dismissWarningAndStartCountdown()
            return
        }
        
        let clipboardContent = clipboardManager.getClipboardText()
        let characterCount = clipboardContent.count
        
        // Check if the clipboard has text content
        if characterCount == 0 {
            showAlert(title: "Empty Clipboard", message: "There is no text in the clipboard to type.")
            return
        }
        
        // Check if we need to show a warning dialog
        let threshold = preferencesManager.getCharacterWarningThreshold()
        if characterCount > threshold {
            showWarningDialog(characterCount: characterCount)
        } else {
            startCountdown()
        }
    }
    
    private func showWarningDialog(characterCount: Int) {
        // Capture the currently active application to restore focus later
        let currentApp = NSWorkspace.shared.frontmostApplication
        
        isWarningDialogShown = true
        
        // Create a modern warning panel
        let panelWidth: CGFloat = 360
        let panelHeight: CGFloat = 160
        let panel = ModernPanel(contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
                               styleMask: [.titled],
                               backing: .buffered,
                               defer: false)
        panel.title = "ClipTyper"
        
        // Modern content view with proper spacing
        let contentView = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
        contentView.wantsLayer = true
        panel.contentView = contentView
        
        // Modern spacing using 8pt grid system
        let margin: CGFloat = 24
        let buttonSpacing: CGFloat = 16
        
        // Main message label using modern typography
        let messageLabel = ModernLabel.createHeadlineLabel(
            text: "The clipboard contains \(characterCount) characters.\nDo you want to proceed with typing?",
            frame: NSRect(x: margin, y: 100, width: panelWidth - (margin * 2), height: 40)
        )
        contentView.addSubview(messageLabel)
        
        // Tip label with proper hierarchy
        let tipLabel = ModernLabel.createCaptionLabel(
            text: "Tip: Press \(shortcutManager.getCurrentShortcutString()) again to proceed",
            frame: NSRect(x: margin, y: 60, width: panelWidth - (margin * 2), height: 30)
        )
        contentView.addSubview(tipLabel)
        
        // Modern button layout with proper spacing for large control size
        let buttonWidth: CGFloat = 100
        let buttonHeight: CGFloat = 32
        let totalButtonWidth = (buttonWidth * 2) + buttonSpacing
        let buttonStartX = (panelWidth - totalButtonWidth) / 2
        
        // Primary action button (Proceed)
        let proceedButton = ModernButton.createPrimaryButton(
            title: "Proceed",
            frame: NSRect(x: buttonStartX + buttonWidth + buttonSpacing, y: 20, width: buttonWidth, height: buttonHeight)
        )
        proceedButton.target = self
        proceedButton.action = #selector(warningProceedClicked(_:))
        proceedButton.keyEquivalent = "\r"  // Enter key
        contentView.addSubview(proceedButton)
        
        // Secondary action button (Cancel)
        let cancelButton = ModernButton.createSecondaryButton(
            title: "Cancel",
            frame: NSRect(x: buttonStartX, y: 20, width: buttonWidth, height: buttonHeight)
        )
        cancelButton.target = self
        cancelButton.action = #selector(warningCancelClicked(_:))
        cancelButton.keyEquivalent = "\u{1B}"  // Escape key
        contentView.addSubview(cancelButton)
        
        // Store references for button actions
        objc_setAssociatedObject(proceedButton, "panel", panel, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(proceedButton, "currentApp", currentApp, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(cancelButton, "panel", panel, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(cancelButton, "currentApp", currentApp, .OBJC_ASSOCIATION_RETAIN)
        
        // Position and show window below menu bar icon
        positionWindowBelowStatusItem(panel)
        panel.orderFront(nil)
    }
    
    @objc private func warningProceedClicked(_ sender: NSButton) {
        if let panel = objc_getAssociatedObject(sender, "panel") as? NSPanel,
           let currentApp = objc_getAssociatedObject(sender, "currentApp") as? NSRunningApplication {
            panel.close()
            isWarningDialogShown = false
            
            // Restore focus to original app before starting countdown
            currentApp.activate(options: [])
            
            // Small delay to ensure focus is restored
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.startCountdown()
            }
        }
    }
    
    @objc private func warningCancelClicked(_ sender: NSButton) {
        if let panel = objc_getAssociatedObject(sender, "panel") as? NSPanel {
            panel.close()
            isWarningDialogShown = false
        }
    }
    
    @objc private func cancelCountdown(_ sender: NSButton) {
        if let panel = objc_getAssociatedObject(sender, "panel") as? NSPanel {
            panel.close()
            isCountdownInProgress = false
        }
    }
    
    private func dismissWarningAndStartCountdown() {
        // Close any open warning panels
        for window in NSApp.windows {
            if window is ModernPanel && window.title == "ClipTyper" {
                window.close()
                break
            }
        }
        
        isWarningDialogShown = false
        
        // Try to restore focus to the previously active app if possible
        if let currentApp = NSWorkspace.shared.frontmostApplication {
            currentApp.activate(options: [])
        }
        
        // Small delay to ensure focus is restored before starting countdown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startCountdown()
        }
    }
    
    private func startCountdown() {
        isCountdownInProgress = true
        let delay = preferencesManager.getTypingDelay()
        
        if preferencesManager.getShowCountdownInMenuBar() {
            // Show countdown in menu bar
            showMenuBarCountdown(seconds: Int(delay))
        } else {
            // Show countdown in dialog
            showCountdownDialog(seconds: Int(delay))
        }
    }
    
    private func showMenuBarCountdown(seconds: Int) {
        var secondsRemaining = seconds
        
        // Save the original title and update visual state
        let originalTitle = statusItem.button?.title ?? ""
        updateStatusBarForCountdown(true)
        
        // Update the menu bar with countdown
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if secondsRemaining > 0 {
                self.statusItem.button?.title = "\(secondsRemaining)s"
                secondsRemaining -= 1
            } else {
                timer.invalidate()
                self.statusItem.button?.title = originalTitle
                self.updateStatusBarForCountdown(false) // Reset to normal state
                self.performTyping()
            }
        }
    }
    
    private func updateStatusBarForCountdown(_ isCountdown: Bool) {
        guard let button = statusItem.button else { return }
        
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium, scale: .medium)
        
        if isCountdown {
            // Use timer symbol during countdown
            let timerImage: NSImage?
            if #available(macOS 11.0, *) {
                timerImage = NSImage(systemSymbolName: "timer", accessibilityDescription: "ClipTyper - Countdown Active")?.withSymbolConfiguration(config)
            } else {
                timerImage = NSImage(systemSymbolName: "timer", accessibilityDescription: "ClipTyper - Countdown Active")
            }
            button.image = timerImage
            button.toolTip = "ClipTyper - Countdown in progress"
        } else {
            // Return to normal state - this will be updated by updateCharacterCount
            setupStatusBarIcon()
        }
        
        // Ensure template rendering for proper dark mode support
        button.image?.isTemplate = true
    }
    
    private func showCountdownDialog(seconds: Int) {
        // Capture the currently active application to restore focus later
        let currentApp = NSWorkspace.shared.frontmostApplication
        var secondsRemaining = seconds
        
        // Create a modern countdown panel
        let panelWidth: CGFloat = 280
        let panelHeight: CGFloat = 120
        let panel = ModernPanel(contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
                               styleMask: [.titled],
                               backing: .buffered,
                               defer: false)
        panel.title = "ClipTyper"
        
        // Modern content view
        let contentView = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
        contentView.wantsLayer = true
        panel.contentView = contentView
        
        // Modern spacing
        let margin: CGFloat = 24
        
        // Countdown Label with modern typography
        let countdownLabel = ModernLabel.createHeadlineLabel(
            text: "Typing in \(secondsRemaining)...",
            frame: NSRect(x: margin, y: 55, width: panelWidth - (margin * 2), height: 30)
        )
        contentView.addSubview(countdownLabel)
        
        // Cancel Button with modern styling
        let buttonWidth: CGFloat = 120
        let cancelButton = ModernButton.createSecondaryButton(
            title: "Cancel Typing",
            frame: NSRect(x: (panelWidth - buttonWidth) / 2, y: 20, width: buttonWidth, height: 30)
        )
        cancelButton.target = self
        cancelButton.action = #selector(cancelCountdown(_:))
        cancelButton.keyEquivalent = "\u{1B}"  // Escape key
        contentView.addSubview(cancelButton)
        
        // Store panel reference for cancel action
        objc_setAssociatedObject(cancelButton, "panel", panel, .OBJC_ASSOCIATION_RETAIN)
        
        // Position window below status item
        positionWindowBelowStatusItem(panel)
        
        // Show the panel without stealing focus
        panel.orderFront(nil)
        
        // Create a timer to update the countdown and dismiss when done
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self, weak panel, weak countdownLabel, currentApp] timer in
            guard let self = self, let panel = panel, panel.isVisible else {
                timer.invalidate()
                return
            }
            
            secondsRemaining -= 1
            
            if secondsRemaining > 0 {
                countdownLabel?.stringValue = "Typing in \(secondsRemaining)..."
            } else {
                timer.invalidate()
                panel.close()
                
                // Restore focus to the original application before typing
                if let app = currentApp {
                    app.activate(options: [])
                }
                
                // Small delay to ensure focus is restored
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.isCountdownInProgress = false
                    self.performTyping()
                }
            }
        }
        
        // Store timer reference for potential cleanup
        objc_setAssociatedObject(panel, "timer", timer, .OBJC_ASSOCIATION_RETAIN)
    }
    
    private func positionWindowBelowStatusItem(_ window: NSWindow) {
        guard let statusItemButton = statusItem.button,
              let statusItemWindow = statusItemButton.window else {
            return
        }
        
        // Get the frame of the status item in screen coordinates
        let statusItemFrame = statusItemButton.convert(statusItemButton.bounds, to: nil)
        let statusItemScreenFrame = statusItemWindow.convertToScreen(statusItemFrame)
        
        // Calculate new position - centered below the status item
        let windowFrame = window.frame
        let xPos = statusItemScreenFrame.midX - (windowFrame.width / 2)
        let yPos = statusItemScreenFrame.minY - windowFrame.height - 5 // 5 pixel gap
        
        // Set new position
        window.setFrameOrigin(NSPoint(x: xPos, y: yPos))
    }
    
    private func performTyping() {
        isCountdownInProgress = false
        
        let clipboardText = clipboardManager.getClipboardText()
        keyboardSimulator.typeText(clipboardText)
        
        if preferencesManager.getAutoClearClipboard() {
            clipboardManager.clearClipboard()
        }
    }
    
    private func updateCharacterCount(_ count: Int) {
        guard let button = statusItem?.button else { return }
        
        if preferencesManager.getShowCharacterCount() && !isCountdownInProgress {
            // Show character count with better formatting and accessibility
            let formattedText = formatCharacterCount(count)
            button.title = formattedText
            
            // Enhanced accessibility
            button.toolTip = "ClipTyper - \(count) characters in clipboard. Right-click to type, left-click for settings"
        } else if !isCountdownInProgress {
            // Hide character count
            button.title = ""
            button.toolTip = "ClipTyper - Right-click to type clipboard, left-click for settings"
        }
        
        // Update clipboard status in menu (only if menu is set up)
        if clipboardStatusMenuItem != nil {
            clipboardStatusMenuItem.title = "Clipboard: \(formatCharacterCount(count))"
        }
        
        // Update visual state based on clipboard content
        if !isCountdownInProgress {
            updateStatusBarForClipboardState(count)
        }
    }
    
    private func formatCharacterCount(_ count: Int) -> String {
        if count == 0 {
            return "" // Don't show anything for empty clipboard
        } else if count > 999 {
            return "\(count / 1000)k+"
        } else {
            return "\(count)"
        }
    }
    
    private func updateStatusBarForClipboardState(_ count: Int) {
        guard let button = statusItem.button else { return }
        
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium, scale: .medium)
        let iconName: String
        let accessibilityDescription: String
        
        if count == 0 {
            iconName = "doc.on.clipboard"
            accessibilityDescription = "ClipTyper - No clipboard content"
        } else if count > (preferencesManager?.getCharacterWarningThreshold() ?? 100) {
            iconName = "doc.on.clipboard.fill"
            accessibilityDescription = "ClipTyper - Large clipboard content (\(count) characters)"
        } else {
            iconName = "doc.on.clipboard.fill"
            accessibilityDescription = "ClipTyper - \(count) characters ready to type"
        }
        
        let iconImage: NSImage?
        if #available(macOS 11.0, *) {
            iconImage = NSImage(systemSymbolName: iconName, accessibilityDescription: accessibilityDescription)?.withSymbolConfiguration(config)
        } else {
            iconImage = NSImage(systemSymbolName: iconName, accessibilityDescription: accessibilityDescription)
        }
        button.image = iconImage
        button.image?.isTemplate = true
    }
    
    private func registerShortcut() {
        // Load keyboard shortcut from preferences
        let keyCode = preferencesManager.getKeyboardShortcutKeyCode()
        let modifiers = preferencesManager.getKeyboardShortcutModifiers()
        
        let success = shortcutManager.registerShortcut(callback: { [weak self] in
            // When shortcut is pressed, activate typing process
            DispatchQueue.main.async {
                self?.startTypingProcess()
            }
        }, keyCode: keyCode, modifiers: modifiers)
        
        if !success {
            // Retry after a short delay - accessibility permissions might be granted after app launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                print("Retrying shortcut registration...")
                _ = self?.shortcutManager.registerShortcut(callback: { [weak self] in
                    DispatchQueue.main.async {
                        self?.startTypingProcess()
                    }
                }, keyCode: keyCode, modifiers: modifiers)
            }
        }
    }
    
    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            showAlert(title: "Accessibility Permission Required", 
                      message: "ClipTyper needs accessibility permissions to simulate keyboard typing. Please grant permission in System Preferences > Security & Privacy > Privacy > Accessibility.")
            
            // Start monitoring for accessibility permission changes
            startAccessibilityPermissionMonitoring()
        }
    }
    
    private func startAccessibilityPermissionMonitoring() {
        // Check periodically if accessibility permissions have been granted
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            let accessEnabled = AXIsProcessTrusted()
            
            if accessEnabled {
                print("Accessibility permissions granted - re-registering shortcut")
                timer.invalidate()
                
                // Re-register the shortcut now that we have permissions
                DispatchQueue.main.async {
                    self?.registerShortcut()
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // MARK: - Menu Actions
    
    @objc private func delaySliderChanged(_ sender: NSSlider) {
        let value = sender.doubleValue
        preferencesManager.setTypingDelay(value)
        
        // Update the live value display (only if UI is set up)
        if delayValueLabel != nil {
            delayValueLabel.stringValue = String(format: "%.1fs", value)
        }
    }
    
    @objc private func toggleAutoClear(_ sender: NSMenuItem) {
        let newValue = !preferencesManager.getAutoClearClipboard()
        preferencesManager.setAutoClearClipboard(newValue)
        sender.state = newValue ? .on : .off
    }
    
    @objc private func toggleShowCharacterCount(_ sender: NSMenuItem) {
        let newValue = !preferencesManager.getShowCharacterCount()
        preferencesManager.setShowCharacterCount(newValue)
        sender.state = newValue ? .on : .off
        
        // Update the display
        if newValue {
            updateCharacterCount(clipboardManager.getClipboardCharacterCount())
        } else {
            statusItem.button?.title = ""
        }
    }
    
    @objc private func toggleAutostart(_ sender: NSMenuItem) {
        let newValue = !preferencesManager.getAutostart()
        
        // Update the login item setting
        let success = loginItemManager.setLoginItemEnabled(newValue)
        
        // Always update the preference to track user intent
        preferencesManager.setAutostart(newValue)
        sender.state = newValue ? .on : .off
        
        if success {
            // Automatic setup succeeded
            let message = newValue ? "ClipTyper will now start automatically when you log in." : "ClipTyper will no longer start automatically at login."
            showAlert(title: "Autostart Updated", message: message)
        } else {
            // Show manual setup instructions
            if newValue {
                // For enabling, show detailed instructions
                let instructions = loginItemManager.getManualSetupInstructions(newValue)
                let appPath = loginItemManager.getAppPath() ?? "ClipTyper.app"
                
                showManualSetupAlert(title: "Manual Setup Required", 
                                   message: "ClipTyper needs to be added to your login items manually.\n\nApp location: \(appPath)\n\n\(instructions)")
            } else {
                // For disabling, show simpler message
                let instructions = loginItemManager.getManualSetupInstructions(newValue)
                showAlert(title: "Manual Removal Required", message: instructions)
            }
        }
    }
    
    private func showManualSetupAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open System Settings")
        
        let response = alert.runModal()
        
        if response == .alertSecondButtonReturn {
            // Open System Settings/Preferences to Login Items
            openLoginItemsSettings()
        }
    }
    
    private func openLoginItemsSettings() {
        // Try to open the Login Items section in System Settings/Preferences
        if #available(macOS 13.0, *) {
            // macOS 13+ uses System Settings
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!)
        } else {
            // Older macOS uses System Preferences
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.users")!)
        }
    }
    
    @objc private func selectDialogCountdown(_ sender: NSMenuItem) {
        preferencesManager.setShowCountdownInMenuBar(false)
        
        // Update menu item states
        let menuItems = statusMenu.items
        for item in menuItems {
            if item.title == "    Show in dialog" {
                item.state = .on
            } else if item.title == "    Show in menu bar" {
                item.state = .off
            }
        }
    }
    
    @objc private func selectMenuBarCountdown(_ sender: NSMenuItem) {
        preferencesManager.setShowCountdownInMenuBar(true)
        
        // Update menu item states
        let menuItems = statusMenu.items
        for item in menuItems {
            if item.title == "    Show in dialog" {
                item.state = .off
            } else if item.title == "    Show in menu bar" {
                item.state = .on
            }
        }
    }
    
    @objc private func changeWarningThreshold(_ sender: NSMenuItem) {
        let alert = NSAlert()
        alert.messageText = "Set Character Warning Threshold"
        alert.informativeText = "Enter the number of characters at which to show a warning:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = "\(preferencesManager.getCharacterWarningThreshold())"
        alert.accessoryView = textField
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            if let value = Int(textField.stringValue), value > 0 {
                preferencesManager.setCharacterWarningThreshold(value)
                // Update the menu item title
                sender.title = "Character warning threshold: \(value)"
            }
        }
    }
    
    @objc private func changeKeyboardShortcut() {
        // Temporarily disable the global shortcut while configuring
        shortcutManager.unregisterShortcut()
        
        let alert = NSAlert()
        alert.messageText = "Change Keyboard Shortcut"
        alert.informativeText = "Click in the field below and press the keys you want to use for the shortcut.\n\nCurrent shortcut: \(shortcutManager.getCurrentShortcutString())"
        alert.alertStyle = .informational
        
        // Add text field for shortcut input
        let inputField = ShortcutTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputField.placeholderString = "Click here, then press keys..."
        alert.accessoryView = inputField
        
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Reset to Default")
        
        // Position below status item
        if let statusButton = statusItem.button,
           let statusWindow = statusButton.window {
            let buttonFrame = statusButton.convert(statusButton.bounds, to: nil)
            let screenFrame = statusWindow.convertToScreen(buttonFrame)
            
            DispatchQueue.main.async {
                let alertWindow = alert.window
                let alertFrame = alertWindow.frame
                let newOrigin = NSPoint(
                    x: screenFrame.midX - alertFrame.width / 2,
                    y: screenFrame.minY - alertFrame.height - 5
                )
                alertWindow.setFrameOrigin(newOrigin)
            }
        }
        
        // Make the input field the first responder after the alert appears
        DispatchQueue.main.async {
            alert.window.makeFirstResponder(inputField)
        }
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn: // OK
            if let newShortcut = inputField.recordedShortcut {
                preferencesManager.setKeyboardShortcut(keyCode: newShortcut.keyCode, modifiers: newShortcut.modifiers)
                _ = shortcutManager.updateShortcut(keyCode: newShortcut.keyCode, modifiers: newShortcut.modifiers)
                updateMenuItemShortcut()
                
                showConfirmation("Shortcut changed to: \(shortcutManager.getCurrentShortcutString())")
            } else {
                // Re-register the existing shortcut if no new one was set
                registerShortcut()
            }
        case .alertThirdButtonReturn: // Reset to Default
            let defaultKeyCode: UInt16 = 9 // V key
            let defaultModifiers: UInt32 = UInt32(optionKey) | UInt32(cmdKey) // ⌥⌘
            
            preferencesManager.setKeyboardShortcut(keyCode: defaultKeyCode, modifiers: defaultModifiers)
            _ = shortcutManager.updateShortcut(keyCode: defaultKeyCode, modifiers: defaultModifiers)
            updateMenuItemShortcut()
            
            showConfirmation("Shortcut reset to default: ⌥⌘V")
        default: // Cancel
            // Re-register the existing shortcut
            registerShortcut()
        }
    }
    
    private func updateMenuItemShortcut() {
        mainMenuItem.title = "Type Clipboard (\(shortcutManager.getCurrentShortcutString()))"
    }
    
    private func showConfirmation(_ message: String) {
        let confirmAlert = NSAlert()
        confirmAlert.messageText = "Shortcut Updated"
        confirmAlert.informativeText = message
        confirmAlert.alertStyle = .informational
        confirmAlert.addButton(withTitle: "OK")
        
        // Position below status item
        if let statusButton = statusItem.button,
           let statusWindow = statusButton.window {
            let buttonFrame = statusButton.convert(statusButton.bounds, to: nil)
            let screenFrame = statusWindow.convertToScreen(buttonFrame)
            
            DispatchQueue.main.async {
                let alertWindow = confirmAlert.window
                let alertFrame = alertWindow.frame
                let newOrigin = NSPoint(
                    x: screenFrame.midX - alertFrame.width / 2,
                    y: screenFrame.minY - alertFrame.height - 5
                )
                alertWindow.setFrameOrigin(newOrigin)
            }
        }
        
        confirmAlert.runModal()
    }
    
    @objc private func showAbout() {
        let aboutPanel = NSAlert()
        aboutPanel.messageText = "ClipTyper"
        
        // Get version from bundle or use default
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        aboutPanel.informativeText = """
Version \(version) (Build \(build))

A macOS utility that simulates keyboard typing of clipboard contents, designed for environments with restricted copy-paste functionality.

© 2025 Ralf Sturhan. All rights reserved.

ClipTyper requires Accessibility permissions to simulate keyboard input.
"""
        
        aboutPanel.alertStyle = .informational
        aboutPanel.addButton(withTitle: "OK")
        
        // Add icon if available
        if let appIcon = NSImage(named: "AppIcon") {
            aboutPanel.icon = appIcon
        }
        
        aboutPanel.runModal()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// Simple text field for recording shortcuts
class ShortcutTextField: NSTextField {
    struct RecordedShortcut {
        let keyCode: UInt16
        let modifiers: UInt32
    }
    
    var recordedShortcut: RecordedShortcut?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupField()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupField()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupField()
    }
    
    private func setupField() {
        isEditable = false  // Changed back to false to prevent text editing
        isSelectable = true
        isBordered = true
        drawsBackground = true
        // Use semantic color for automatic dark mode support
        if #available(macOS 10.14, *) {
            backgroundColor = NSColor.controlBackgroundColor
        } else {
            backgroundColor = NSColor.textBackgroundColor
        }
        alignment = .center
        // Enhanced typography
        if #available(macOS 11.0, *) {
            font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        } else {
            font = NSFont.systemFont(ofSize: 13)
        }
        stringValue = ""
        focusRingType = .default
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            stringValue = "Press shortcut keys..."
        }
        return result
    }
    
    override func keyDown(with event: NSEvent) {
        let keyCode = UInt16(event.keyCode)
        var modifiers: UInt32 = 0
        
        // Convert NSEvent modifier flags to Carbon modifier flags
        if event.modifierFlags.contains(.command) {
            modifiers |= UInt32(cmdKey)
        }
        if event.modifierFlags.contains(.option) {
            modifiers |= UInt32(optionKey)
        }
        if event.modifierFlags.contains(.control) {
            modifiers |= UInt32(controlKey)
        }
        if event.modifierFlags.contains(.shift) {
            modifiers |= UInt32(shiftKey)
        }
        
        // Only record if we have modifiers (prevent recording of just letters)
        if modifiers != 0 {
            recordedShortcut = RecordedShortcut(keyCode: keyCode, modifiers: modifiers)
            stringValue = formatShortcut(keyCode: keyCode, modifiers: modifiers)
        }
        
        // Don't call super.keyDown to prevent normal text processing
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Intercept key equivalents and treat them as shortcuts
        keyDown(with: event)
        return true
    }
    
    override func insertText(_ insertString: Any) {
        // Prevent any text insertion
    }
    
    override func doCommand(by selector: Selector) {
        // Prevent any command processing (like character insertion)
    }
    
    override func mouseDown(with event: NSEvent) {
        // Make the field first responder when clicked
        window?.makeFirstResponder(self)
        stringValue = "Press shortcut keys..."
    }
    
    private func formatShortcut(keyCode: UInt16, modifiers: UInt32) -> String {
        var result = ""
        
        // Add modifiers in the standard macOS order
        if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        
        // Add the key character
        result += keyCodeToChar(keyCode)
        
        return result
    }
    
    private func keyCodeToChar(_ keyCode: UInt16) -> String {
        // Map to base character (unshifted version)
        let keyCodes: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
            24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O",
            32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J", 39: "'",
            40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
            48: "Tab", 49: "Space", 50: "`", 51: "Delete", 53: "Escape",
            // Function keys
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"
        ]
        
        return keyCodes[keyCode] ?? "Key"
    }
}

// Modern non-activating panel with proper styling
class ModernPanel: NSPanel {
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    override var acceptsFirstResponder: Bool {
        return false
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Don't consume any key events, let them pass through for global shortcuts
        return false
    }
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupModernStyling()
    }
    
    private func setupModernStyling() {
        // Modern window appearance with automatic dark mode support
        titlebarAppearsTransparent = false
        isMovableByWindowBackground = true
        
        // Add subtle shadow and proper materials
        hasShadow = true
        
        // Enhanced background material with automatic dark mode
        if #available(macOS 10.14, *) {
            contentView?.wantsLayer = true
            contentView?.layer?.cornerRadius = 12
            
            // Use system material for automatic dark mode
            if #available(macOS 10.14, *) {
                contentView?.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            }
            
            // Automatic appearance - follows system setting
            appearance = nil // nil means follow system appearance
        }
        
        // Ensure proper level and behavior
        level = .floating
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
    
    func updateForCurrentAppearance() {
        // Update colors and materials for current appearance
        if #available(macOS 10.14, *) {
            contentView?.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        }
        
        // Force redraw of content
        contentView?.needsDisplay = true
    }
}

// Modern button factory with improved styling
class ModernButton {
    static func createPrimaryButton(title: String, frame: NSRect) -> NSButton {
        let button = NSButton(frame: frame)
        button.title = title
        button.controlSize = .large
        button.bezelStyle = .rounded
        
        // Enhanced typography with proper system fonts
        if #available(macOS 11.0, *) {
            button.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        } else {
            button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        }
        
        // Modern primary button styling with proper semantic colors
        if #available(macOS 11.0, *) {
            button.bezelColor = NSColor.controlAccentColor
            button.contentTintColor = NSColor.white
        } else {
            button.bezelColor = NSColor.systemBlue
        }
        
        // Enhanced accessibility
        if #available(macOS 10.9, *) {
            button.setAccessibilityRole(.button)
            button.setAccessibilityLabel(title)
        }
        
        return button
    }
    
    static func createSecondaryButton(title: String, frame: NSRect) -> NSButton {
        let button = NSButton(frame: frame)
        button.title = title
        button.controlSize = .large
        button.bezelStyle = .rounded
        
        // Enhanced typography
        if #available(macOS 11.0, *) {
            button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        } else {
            button.font = NSFont.systemFont(ofSize: 13)
        }
        
        // Modern secondary button styling with semantic colors
        if #available(macOS 14.0, *) {
            // Use quaternary fill for modern secondary button look
            button.bezelColor = NSColor.quaternarySystemFill
            button.contentTintColor = NSColor.labelColor
        } else if #available(macOS 11.0, *) {
            button.bezelColor = NSColor.controlColor
            button.contentTintColor = NSColor.controlTextColor
        } else {
            button.bezelColor = NSColor.controlColor
        }
        
        // Enhanced accessibility
        if #available(macOS 10.9, *) {
            button.setAccessibilityRole(.button)
            button.setAccessibilityLabel(title)
        }
        
        return button
    }
}

// Modern text label factory
class ModernLabel {
    static func createHeadlineLabel(text: String, frame: NSRect) -> NSTextField {
        let label = NSTextField(frame: frame)
        label.stringValue = text
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        label.alignment = .center
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        // Enhanced typography hierarchy with proper system fonts
        if #available(macOS 11.0, *) {
            label.font = NSFont.systemFont(ofSize: 17, weight: .semibold) // Headline style
        } else {
            label.font = NSFont.systemFont(ofSize: 15, weight: .medium)
        }
        
        // Semantic colors for automatic dark mode support
        if #available(macOS 10.14, *) {
            label.textColor = NSColor.labelColor
        } else {
            label.textColor = NSColor.controlTextColor
        }
        
        return label
    }
    
    static func createBodyLabel(text: String, frame: NSRect) -> NSTextField {
        let label = NSTextField(frame: frame)
        label.stringValue = text
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        label.alignment = .center
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        // Enhanced body typography
        if #available(macOS 11.0, *) {
            label.font = NSFont.systemFont(ofSize: 13, weight: .regular) // Body style
        } else {
            label.font = NSFont.systemFont(ofSize: 13)
        }
        
        // Semantic colors for automatic dark mode support
        if #available(macOS 10.14, *) {
            label.textColor = NSColor.labelColor
        } else {
            label.textColor = NSColor.controlTextColor
        }
        
        return label
    }
    
    static func createCaptionLabel(text: String, frame: NSRect) -> NSTextField {
        let label = NSTextField(frame: frame)
        label.stringValue = text
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        label.alignment = .center
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        // Enhanced caption typography
        if #available(macOS 11.0, *) {
            label.font = NSFont.systemFont(ofSize: 11, weight: .regular) // Caption style
        } else {
            label.font = NSFont.systemFont(ofSize: 11)
        }
        
        // Semantic colors for automatic dark mode support
        if #available(macOS 10.14, *) {
            label.textColor = NSColor.secondaryLabelColor
        } else {
            label.textColor = NSColor.disabledControlTextColor
        }
        
        return label
    }
} 