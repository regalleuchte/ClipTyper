//
//  AppIcon.swift
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

class AppIcon {
    static func generateIconImage() -> NSImage {
        let size = NSSize(width: 128, height: 128)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Draw background
        NSColor.systemBlue.setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: size.width, height: size.height), 
                     xRadius: 20, yRadius: 20).fill()
        
        // Draw clipboard icon
        NSColor.white.setFill()
        let clipboardPath = NSBezierPath()
        clipboardPath.move(to: NSPoint(x: 40, y: 90))
        clipboardPath.line(to: NSPoint(x: 88, y: 90))
        clipboardPath.line(to: NSPoint(x: 88, y: 30))
        clipboardPath.line(to: NSPoint(x: 40, y: 30))
        clipboardPath.close()
        clipboardPath.fill()
        
        // Draw clipboard top
        NSColor.lightGray.setFill()
        let clipboardTop = NSBezierPath()
        clipboardTop.move(to: NSPoint(x: 50, y: 102))
        clipboardTop.line(to: NSPoint(x: 78, y: 102))
        clipboardTop.line(to: NSPoint(x: 78, y: 90))
        clipboardTop.line(to: NSPoint(x: 50, y: 90))
        clipboardTop.close()
        clipboardTop.fill()
        
        // Draw typing cursor
        NSColor.systemBlue.setFill()
        NSBezierPath(rect: NSRect(x: 50, y: 70, width: 28, height: 4)).fill()
        NSBezierPath(rect: NSRect(x: 50, y: 60, width: 28, height: 4)).fill()
        NSBezierPath(rect: NSRect(x: 50, y: 50, width: 28, height: 4)).fill()
        NSBezierPath(rect: NSRect(x: 50, y: 40, width: 15, height: 4)).fill()
        
        // Draw cursor
        NSColor.black.setFill()
        NSBezierPath(rect: NSRect(x: 66, y: 36, width: 2, height: 12)).fill()
        
        image.unlockFocus()
        
        return image
    }
    
    static func saveIconToResources() {
        let image = generateIconImage()
        
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            
            let fileManager = FileManager.default
            let resourcesPath = Bundle.main.resourcePath ?? ""
            let iconPath = resourcesPath + "/AppIcon.png"
            
            fileManager.createFile(atPath: iconPath, contents: pngData)
        }
    }
} 