//
//  main.swift
//  ClipTyper
//
//  Copyright © 2025 Ralf Sturhan. All rights reserved.
//

import Cocoa

// This prevents the app from launching with a dock icon
NSApplication.shared.setActivationPolicy(.accessory)

// Create an instance of our application delegate
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate

// Start the application
NSApplication.shared.run() 