#!/bin/bash

# ClipTyper DMG Build Script
# Creates a distributable DMG for testing

set -e  # Exit on error

PROJECT_DIR="$(dirname "$0")"
cd "$PROJECT_DIR"

APP_NAME="ClipTyper"
VERSION="1.0"
DMG_NAME="${APP_NAME}-${VERSION}"
BUILD_DIR="./build"
DMG_DIR="./dmg-build"

echo "🔨 Building ${APP_NAME}..."

# Clean previous builds
rm -rf "${BUILD_DIR}" "${DMG_DIR}" "${APP_NAME}.app" "${DMG_NAME}.dmg"

# Build the project
swift build -c release

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# Create app bundle structure
echo "📦 Creating app bundle..."
mkdir -p "${BUILD_DIR}/${APP_NAME}.app/Contents/MacOS"
mkdir -p "${BUILD_DIR}/${APP_NAME}.app/Contents/Resources"

# Copy executable
cp "./.build/release/${APP_NAME}" "${BUILD_DIR}/${APP_NAME}.app/Contents/MacOS/"

# Copy Info.plist
cp "./Info.plist" "${BUILD_DIR}/${APP_NAME}.app/Contents/"

# Make executable
chmod +x "${BUILD_DIR}/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"

echo "✅ App bundle created!"

# Create DMG
echo "💿 Creating DMG..."

# Create temporary DMG directory
mkdir -p "${DMG_DIR}"
cp -R "${BUILD_DIR}/${APP_NAME}.app" "${DMG_DIR}/"

# Create Applications symlink for easy installation
ln -s /Applications "${DMG_DIR}/Applications"

# Create DMG
hdiutil create -srcfolder "${DMG_DIR}" \
               -volname "${APP_NAME}" \
               -format UDZO \
               -o "${DMG_NAME}.dmg"

# Clean up temporary directories
rm -rf "${BUILD_DIR}" "${DMG_DIR}"

echo "✅ DMG created: ${DMG_NAME}.dmg"
echo ""
echo "📋 Distribution Summary:"
echo "  • File: ${DMG_NAME}.dmg"
echo "  • Size: $(du -h "${DMG_NAME}.dmg" | cut -f1)"
echo "  • Status: Unsigned (will show security warning)"
echo ""
echo "🚀 Next Steps:"
echo "  1. Test the DMG by mounting and installing"
echo "  2. For signed distribution, join Apple Developer Program"
echo "  3. Share DMG with testers via email/cloud storage"
echo ""
echo "⚠️  Testers will need to:"
echo "  1. Right-click DMG → Open (first time only)"
echo "  2. Drag ClipTyper to Applications folder"
echo "  3. Right-click app → Open (first launch only)"
echo "  4. Grant Accessibility permissions in System Settings"