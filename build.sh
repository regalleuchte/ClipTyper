#!/bin/bash

# Navigate to the project directory
cd "$(dirname "$0")"

# Build the project
echo "Building ClipTyper..."
swift build -c release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "Build successful!"
    
    # Create a directory for the app
    mkdir -p ./ClipTyper.app/Contents/MacOS
    mkdir -p ./ClipTyper.app/Contents/Resources
    
    # Copy the executable
    cp ./.build/release/ClipTyper ./ClipTyper.app/Contents/MacOS/
    
    # Copy the Info.plist and entitlements
    cp ./Info.plist ./ClipTyper.app/Contents/
    cp ./ClipTyper.entitlements ./ClipTyper.app/Contents/
    
    echo "ClipTyper.app created successfully!"
    echo "To run the app, execute: ./ClipTyper.app/Contents/MacOS/ClipTyper"
    
    # Optionally, you can sign the app with a developer certificate
    # if you have one installed
    if [ -n "$(which codesign)" ]; then
        echo "Would you like to sign the app? (y/n)"
        read answer
        if [ "$answer" = "y" ]; then
            echo "Signing app with developer identity..."
            codesign --force --deep --entitlements ./ClipTyper.entitlements --sign "Developer ID Application" ./ClipTyper.app
            echo "App signed successfully!"
        fi
    fi
else
    echo "Build failed."
fi 