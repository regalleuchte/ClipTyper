//
//  LoginItemManager.swift
//  ClipTyper
//
//  Copyright © 2025 Ralf Sturhan. All rights reserved.
//

import Cocoa
import ServiceManagement

class LoginItemManager {
    private var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "de.sturhan.ClipTyper"
    }
    
    // Check if the app is currently set to launch at login
    func isLoginItemEnabled() -> Bool {
        // For macOS 13.0+, use the modern API
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // For older versions, check our saved state
            return UserDefaults.standard.bool(forKey: "autostart")
        }
    }
    
    // Enable or disable launch at login
    func setLoginItemEnabled(_ enabled: Bool) -> Bool {
        print("Attempting to \(enabled ? "enable" : "disable") autostart for bundle: \(bundleIdentifier)")
        
        // For macOS 13.0+, use the modern API
        if #available(macOS 13.0, *) {
            return setLoginItemModern(enabled)
        } else {
            return setLoginItemLegacy(enabled)
        }
    }
    
    // Modern API for macOS 13.0+
    @available(macOS 13.0, *)
    private func setLoginItemModern(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                print("Successfully registered app for login using modern API")
                UserDefaults.standard.set(true, forKey: "autostart")
            } else {
                try SMAppService.mainApp.unregister()
                print("Successfully unregistered app from login using modern API")
                UserDefaults.standard.set(false, forKey: "autostart")
            }
            return true
        } catch {
            print("Failed to \(enabled ? "register" : "unregister") login item: \(error)")
            // Save the preference anyway for manual setup
            UserDefaults.standard.set(enabled, forKey: "autostart")
            return false
        }
    }
    
    // Legacy approach for older macOS versions and fallback
    private func setLoginItemLegacy(_ enabled: Bool) -> Bool {
        print("Using legacy approach with bundle identifier: \(bundleIdentifier)")
        
        // First try the SMLoginItemSetEnabled API
        let success = SMLoginItemSetEnabled(bundleIdentifier as CFString, enabled)
        
        if success {
            print("Successfully \(enabled ? "enabled" : "disabled") login item using SMLoginItemSetEnabled")
            UserDefaults.standard.set(enabled, forKey: "autostart")
            return true
        } else {
            print("SMLoginItemSetEnabled failed, this is common for unsigned apps")
            // Save the preference for manual setup
            UserDefaults.standard.set(enabled, forKey: "autostart")
            return false // Return false to trigger manual setup instructions
        }
    }
    
    // Get a user-friendly instruction message for manual setup
    func getManualSetupInstructions(_ enabled: Bool) -> String {
        if enabled {
            return "To enable autostart:\n\n1. Open System Settings (or System Preferences)\n2. Go to General → Login Items\n3. Click the '+' button\n4. Navigate to and select ClipTyper.app\n5. Click 'Add'\n\nAlternatively, you can drag ClipTyper.app to the Login Items list."
        } else {
            return "To disable autostart:\n\n1. Open System Settings (or System Preferences)\n2. Go to General → Login Items\n3. Find ClipTyper in the list\n4. Click the '-' button to remove it\n\nOr simply uncheck ClipTyper in the Login Items list."
        }
    }
    
    // Get the path to the app for manual setup
    func getAppPath() -> String? {
        return Bundle.main.bundlePath
    }
    
    // Check if manual setup might be needed
    func requiresManualSetup() -> Bool {
        // Unsigned apps typically require manual setup on macOS
        return !isAppSigned()
    }
    
    // Simple check if the app is signed (not foolproof, but helps)
    private func isAppSigned() -> Bool {
        let path = Bundle.main.bundlePath
        
        // Check if the app has a code signature
        let task = Process()
        task.launchPath = "/usr/bin/codesign"
        task.arguments = ["--verify", "--verbose", path]
        
        let pipe = Pipe()
        task.standardError = pipe
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            print("Could not check code signature: \(error)")
            return false
        }
    }
}