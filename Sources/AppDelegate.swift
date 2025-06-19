import Cocoa
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenu: NSMenu!
    private var preferencesManager: PreferencesManager!
    private var clipboardManager: ClipboardManager!
    private var keyboardSimulator: KeyboardSimulator!
    private var shortcutManager: GlobalShortcutManager!
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
    
    private func setupManagers() {
        preferencesManager = PreferencesManager()
        clipboardManager = ClipboardManager()
        keyboardSimulator = KeyboardSimulator()
        shortcutManager = GlobalShortcutManager()
        
        // Setup clipboard monitoring to update character count
        clipboardManager.onClipboardChange = { [weak self] count in
            self?.updateCharacterCount(count)
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Create custom icon for status bar
            let iconImage = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipTyper")
            iconImage?.size = NSSize(width: 18, height: 18) // Resize for status bar
            button.image = iconImage
            button.target = self
            
            // Left click activates typing, right click shows menu
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(statusItemClicked(_:))
        }
        
        updateCharacterCount(clipboardManager.getClipboardCharacterCount())
    }
    
    private func setupMenu() {
        statusMenu = NSMenu()
        
        // Main action
        statusMenu.addItem(NSMenuItem(title: "Type Clipboard (⌥⌘V)", action: #selector(startTypingProcess), keyEquivalent: ""))
        statusMenu.addItem(NSMenuItem.separator())
        
        // Delay slider
        let delayItem = NSMenuItem(title: "Delay before typing:", action: nil, keyEquivalent: "")
        let delayView = createDelaySliderView()
        delayItem.view = delayView
        statusMenu.addItem(delayItem)
        
        // Auto-clear clipboard option
        let autoClearItem = NSMenuItem(title: "Auto-clear clipboard after typing", action: #selector(toggleAutoClear), keyEquivalent: "")
        autoClearItem.state = preferencesManager.getAutoClearClipboard() ? .on : .off
        statusMenu.addItem(autoClearItem)
        
        // Show character count option
        let showCountItem = NSMenuItem(title: "Show character count in menu bar", action: #selector(toggleShowCharacterCount), keyEquivalent: "")
        showCountItem.state = preferencesManager.getShowCharacterCount() ? .on : .off
        statusMenu.addItem(showCountItem)
        
        // Countdown display options
        let countdownItem = NSMenuItem(title: "Countdown display:", action: nil, keyEquivalent: "")
        statusMenu.addItem(countdownItem)
        
        let dialogItem = NSMenuItem(title: "    Show in dialog", action: #selector(selectDialogCountdown), keyEquivalent: "")
        dialogItem.state = !preferencesManager.getShowCountdownInMenuBar() ? .on : .off
        statusMenu.addItem(dialogItem)
        
        let menuBarItem = NSMenuItem(title: "    Show in menu bar", action: #selector(selectMenuBarCountdown), keyEquivalent: "")
        menuBarItem.state = preferencesManager.getShowCountdownInMenuBar() ? .on : .off
        statusMenu.addItem(menuBarItem)
        
        statusMenu.addItem(NSMenuItem.separator())
        
        // Change keyboard shortcut
        statusMenu.addItem(NSMenuItem(title: "Change Keyboard Shortcut", action: #selector(changeKeyboardShortcut), keyEquivalent: ""))
        
        // Character warning threshold
        let thresholdItem = NSMenuItem(title: "Character warning threshold: \(preferencesManager.getCharacterWarningThreshold())", action: #selector(changeWarningThreshold), keyEquivalent: "")
        statusMenu.addItem(thresholdItem)
        
        statusMenu.addItem(NSMenuItem.separator())
        
        // Quit option
        statusMenu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    }
    
    private func createDelaySliderView() -> NSView {
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 40))
        
        let slider = NSSlider(frame: NSRect(x: 40, y: 10, width: 160, height: 20))
        slider.minValue = 0.5
        slider.maxValue = 10.0
        slider.doubleValue = preferencesManager.getTypingDelay()
        slider.target = self
        slider.action = #selector(delaySliderChanged(_:))
        slider.isContinuous = true
        
        let minLabel = NSTextField(frame: NSRect(x: 5, y: 10, width: 35, height: 20))
        minLabel.stringValue = "0.5s"
        minLabel.isEditable = false
        minLabel.isBordered = false
        minLabel.drawsBackground = false
        
        let maxLabel = NSTextField(frame: NSRect(x: 200, y: 10, width: 35, height: 20))
        maxLabel.stringValue = "10s"
        maxLabel.isEditable = false
        maxLabel.isBordered = false
        maxLabel.drawsBackground = false
        
        containerView.addSubview(slider)
        containerView.addSubview(minLabel)
        containerView.addSubview(maxLabel)
        
        return containerView
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        if event.type == .rightMouseUp {
            // Right click - show the menu
            statusItem.menu = statusMenu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else if event.type == .leftMouseUp {
            // Left click - start typing process
            startTypingProcess()
        }
    }
    
    @objc private func startTypingProcess() {
        // Check if we're already in the process
        if isCountdownInProgress {
            // If warning dialog is shown, take this as confirmation to proceed
            if isWarningDialogShown {
                dismissWarningAndStartCountdown()
            }
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
        isWarningDialogShown = true
        
        let alert = NSAlert()
        alert.messageText = "ClipTyper"
        alert.informativeText = "The clipboard contains \(characterCount) characters.\nDo you want to proceed with typing?\n\nTip: Press ⌥⌘V again to proceed"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Proceed")
        alert.addButton(withTitle: "Cancel")
        
        // Position and show window below menu bar icon
        let window = alert.window
        window.level = .floating // Stay on top
        positionWindowBelowStatusItem(window)
        
        let response = alert.runModal()
        isWarningDialogShown = false
        
        if response == .alertFirstButtonReturn {
            startCountdown()
        }
    }
    
    private func dismissWarningAndStartCountdown() {
        isWarningDialogShown = false
        startCountdown()
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
        
        // Save the original title
        let originalTitle = statusItem.button?.title ?? ""
        
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
                self.performTyping()
            }
        }
    }
    
    private func showCountdownDialog(seconds: Int) {
        var secondsRemaining = seconds
        
        // Create a custom panel
        let panelWidth: CGFloat = 200
        let panelHeight: CGFloat = 80
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
                            styleMask: [.borderless],
                            backing: .buffered,
                            defer: false)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Content View
        let contentView = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
        panel.contentView = contentView
        
        // Remove background color
        contentView.wantsLayer = false
        
        // Countdown Label
        let countdownLabel = NSTextField(frame: NSRect(x: 20, y: 35, width: panelWidth - 40, height: 25))
        countdownLabel.stringValue = "Typing in \(secondsRemaining)..."
        countdownLabel.isEditable = false
        countdownLabel.isBordered = false
        countdownLabel.drawsBackground = false
        countdownLabel.alignment = .center
        countdownLabel.font = NSFont.systemFont(ofSize: 14)
        contentView.addSubview(countdownLabel)
        
        // Cancel Button
        let cancelButton = NSButton(frame: NSRect(x: (panelWidth - 100) / 2, y: 5, width: 100, height: 25))
        cancelButton.title = "Cancel Typing"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        var associatedTimer: Timer? = nil
        let cancelAction = { [weak self, weak panel, weak associatedTimer] in
            associatedTimer?.invalidate()
            panel?.close()
            self?.isCountdownInProgress = false
        }
        class ActionWrapper: NSObject {
            let action: () -> Void
            init(action: @escaping () -> Void) {
                self.action = action
            }
            @objc func performAction() {
                action()
            }
        }
        let actionWrapper = ActionWrapper(action: cancelAction)
        objc_setAssociatedObject(cancelButton, "actionWrapper", actionWrapper, .OBJC_ASSOCIATION_RETAIN)
        cancelButton.target = actionWrapper
        cancelButton.action = #selector(ActionWrapper.performAction)
        contentView.addSubview(cancelButton)
        
        // Position window below status item
        positionWindowBelowStatusItem(panel)
        
        // Activate app before showing panel
        NSApp.activate(ignoringOtherApps: true)
        
        // Show the panel asynchronously
        DispatchQueue.main.async {
            panel.makeKeyAndOrderFront(nil)
        }
        
        // Create a timer to update the countdown and dismiss when done
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self, weak panel, weak countdownLabel] timer in
            guard let self = self, let panel = panel, panel.isVisible else {
                timer.invalidate()
                return
            }
            
            secondsRemaining -= 1
            
            if secondsRemaining >= 0 {
                countdownLabel?.stringValue = "Typing in \(secondsRemaining)..."
            } else {
                timer.invalidate()
                panel.close()
                self.performTyping()
            }
        }
        associatedTimer = timer
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
        if preferencesManager.getShowCharacterCount() && !isCountdownInProgress {
            statusItem.button?.title = "\(count)"
        } else if !isCountdownInProgress {
            statusItem.button?.title = ""
        }
    }
    
    private func registerShortcut() {
        // Load keyboard shortcut from preferences
        let keyCode = preferencesManager.getKeyboardShortcutKeyCode()
        let modifiers = preferencesManager.getKeyboardShortcutModifiers()
        
        shortcutManager.registerShortcut(callback: { [weak self] in
            // When shortcut is pressed, activate typing process
            DispatchQueue.main.async {
                self?.startTypingProcess()
            }
        }, keyCode: keyCode, modifiers: modifiers)
    }
    
    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            showAlert(title: "Accessibility Permission Required", 
                      message: "ClipTyper needs accessibility permissions to simulate keyboard typing. Please grant permission in System Preferences > Security & Privacy > Privacy > Accessibility.")
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
        // Create a custom window for shortcut recording
        let window = ShortcutRecorderWindow()
        
        // Set up the window
        window.title = "Record New Shortcut"
        window.styleMask = [.titled, .closable]
        window.level = .floating
        window.center()
        
        // Center below status item
        positionWindowBelowStatusItem(window)
        
        // Set the completion handler
        window.shortcutRecorded = { [weak self] keyCode, modifiers in
            guard let self = self else { return }
            
            // Save the new shortcut in preferences
            self.preferencesManager.setKeyboardShortcut(keyCode: keyCode, modifiers: modifiers)
            
            // Update the shortcut manager
            self.shortcutManager.updateShortcut(keyCode: keyCode, modifiers: modifiers)
            
            // Show confirmation
            let alert = NSAlert()
            alert.messageText = "Shortcut Changed"
            alert.informativeText = "New shortcut set to: \(self.shortcutManager.modifiersToString())"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            
            positionWindowBelowStatusItem(alert.window)
            alert.runModal()
        }
        
        // Show the window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// Custom window class for recording shortcuts
class ShortcutRecorderWindow: NSWindow {
    private var monitorGlobal: Any?
    private var monitorLocal: Any?
    private var currentModifiers: UInt32 = 0
    private var recordingView: ShortcutDisplayView!
    
    // Callback for when a shortcut is recorded
    var shortcutRecorded: ((UInt16, UInt32) -> Void)?
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        
        // Create a content view for the window
        let contentRect = NSRect(x: 0, y: 0, width: 300, height: 150)
        
        super.init(contentRect: contentRect, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        
        // Create the content
        let contentView = NSView(frame: contentRect)
        self.contentView = contentView
        
        // Title label
        let titleLabel = NSTextField(frame: NSRect(x: 20, y: 110, width: 260, height: 20))
        titleLabel.stringValue = "Press a new keyboard shortcut"
        titleLabel.isEditable = false
        titleLabel.isBordered = false
        titleLabel.drawsBackground = false
        titleLabel.alignment = .center
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        contentView.addSubview(titleLabel)
        
        // Instruction label
        let instructionLabel = NSTextField(frame: NSRect(x: 20, y: 30, width: 260, height: 30))
        instructionLabel.stringValue = "Press Escape to cancel or Return to confirm"
        instructionLabel.isEditable = false
        instructionLabel.isBordered = false
        instructionLabel.drawsBackground = false
        instructionLabel.alignment = .center
        instructionLabel.font = NSFont.systemFont(ofSize: 12)
        instructionLabel.textColor = NSColor.secondaryLabelColor
        contentView.addSubview(instructionLabel)
        
        // Shortcut display view
        recordingView = ShortcutDisplayView(frame: NSRect(x: 50, y: 60, width: 200, height: 40))
        contentView.addSubview(recordingView)
        
        // Start monitoring keyboard events
        startMonitoring()
    }
    
    override func close() {
        stopMonitoring()
        super.close()
    }
    
    private func startMonitoring() {
        // Monitor for key down events
        monitorGlobal = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        
        monitorLocal = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil // consume the event
        }
        
        // Monitor for flag changes (modifier keys)
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagEvent(event)
            return event
        }
    }
    
    private func stopMonitoring() {
        if let monitor = monitorGlobal {
            NSEvent.removeMonitor(monitor)
        }
        
        if let monitor = monitorLocal {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        let keyCode = UInt16(event.keyCode)
        
        // Escape cancels
        if keyCode == 53 {
            close()
            return
        }
        
        // Return confirms
        if keyCode == 36 {
            // Only confirm if we have a valid shortcut
            if recordingView.currentKeyCode != nil && recordingView.currentModifiers != 0 {
                shortcutRecorded?(recordingView.currentKeyCode!, recordingView.currentModifiers)
                close()
            }
            return
        }
        
        // Record the shortcut
        recordingView.currentKeyCode = keyCode
        recordingView.currentModifiers = currentModifiers
        
        // Force redraw to show current shortcut
        recordingView.needsDisplay = true
    }
    
    private func handleFlagEvent(_ event: NSEvent) {
        currentModifiers = 0
        
        if event.modifierFlags.contains(.command) {
            currentModifiers |= UInt32(cmdKey)
        }
        
        if event.modifierFlags.contains(.option) {
            currentModifiers |= UInt32(optionKey)
        }
        
        if event.modifierFlags.contains(.control) {
            currentModifiers |= UInt32(controlKey)
        }
        
        if event.modifierFlags.contains(.shift) {
            currentModifiers |= UInt32(shiftKey)
        }
        
        // Update the view
        recordingView.currentModifiers = currentModifiers
        recordingView.needsDisplay = true
    }
}

// View to display the current shortcut
class ShortcutDisplayView: NSView {
    var currentModifiers: UInt32 = 0
    var currentKeyCode: UInt16?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw background
        NSColor.controlBackgroundColor.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 5, yRadius: 5).fill()
        
        // Draw border
        NSColor.separatorColor.setStroke()
        let borderPath = NSBezierPath(roundedRect: NSInsetRect(bounds, 0.5, 0.5), xRadius: 5, yRadius: 5)
        borderPath.lineWidth = 1
        borderPath.stroke()
        
        // Draw text
        let text = shortcutDisplayString()
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]
        
        let stringSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: bounds.midX - stringSize.width / 2,
            y: bounds.midY - stringSize.height / 2,
            width: stringSize.width,
            height: stringSize.height
        )
        
        text.draw(in: textRect, withAttributes: attributes)
    }
    
    private func shortcutDisplayString() -> String {
        var result = ""
        
        // Add modifiers
        if currentModifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if currentModifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if currentModifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if currentModifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        
        // Add key if present
        if let keyCode = currentKeyCode {
            result += keyCodeToChar(keyCode)
        }
        
        return result.isEmpty ? "Press Keys..." : result
    }
    
    private func keyCodeToChar(_ keyCode: UInt16) -> String {
        // This is a simplified version - in a real app you'd want a more complete mapping
        let keyCodes: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 10: "§", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
            24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O",
            32: "U", 33: "[", 34: "I", 35: "P", 36: "Return", 37: "L", 38: "J", 39: "'",
            40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
            48: "Tab", 49: "Space", 50: "`", 51: "Delete", 52: "⌘⏎", 53: "Escape"
            // Function keys and other special keys would continue...
        ]
        
        return keyCodes[keyCode] ?? "?"
    }
} 