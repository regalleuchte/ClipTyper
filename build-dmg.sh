#!/bin/bash

# ClipTyper DMG Build Script
# Creates a distributable DMG for testing

set -e  # Exit on error

PROJECT_DIR="$(dirname "$0")"
cd "$PROJECT_DIR"

APP_NAME="ClipTyper"
VERSION="2.0"
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

# Copy and process Info.plist to replace placeholder values
cp "./Info.plist" "${BUILD_DIR}/${APP_NAME}.app/Contents/"
sed -i '' 's/$(EXECUTABLE_NAME)/ClipTyper/g' "${BUILD_DIR}/${APP_NAME}.app/Contents/Info.plist"
sed -i '' 's/$(PRODUCT_NAME)/ClipTyper/g' "${BUILD_DIR}/${APP_NAME}.app/Contents/Info.plist"
sed -i '' 's/$(MACOSX_DEPLOYMENT_TARGET)/12.0/g' "${BUILD_DIR}/${APP_NAME}.app/Contents/Info.plist"

# Copy icon file
if [ -f "./Sources/Resources/ClipTyper.icns" ]; then
    cp "./Sources/Resources/ClipTyper.icns" "${BUILD_DIR}/${APP_NAME}.app/Contents/Resources/"
    echo "✅ Icon copied successfully!"
else
    echo "⚠️  Warning: ClipTyper.icns not found"
fi

# Make executable
chmod +x "${BUILD_DIR}/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"

echo "✅ App bundle created!"

# Optional code signing (if Developer ID certificate is available)
SIGNING_IDENTITY="Developer ID Application: RALF STURHAN (5S5J7MMS7A)"
if security find-identity -v -p codesigning | grep -q "${SIGNING_IDENTITY}"; then
    echo "🔐 Code signing app..."
    
    # Clean extended attributes that can cause signing issues
    xattr -cr "${BUILD_DIR}/${APP_NAME}.app" 2>/dev/null || true
    
    codesign --force \
             --deep \
             --entitlements "./ClipTyper.entitlements" \
             --sign "${SIGNING_IDENTITY}" \
             --timestamp \
             --options runtime \
             "${BUILD_DIR}/${APP_NAME}.app"
    
    if [ $? -eq 0 ]; then
        echo "✅ App signed successfully!"
        SIGNED_STATUS="Code signed with Developer ID Application certificate"
    else
        echo "⚠️  Code signing failed, continuing with unsigned build"
        SIGNED_STATUS="Unsigned (will show security warning)"
    fi
else
    echo "ℹ️  No Developer ID certificate found, creating unsigned build"
    SIGNED_STATUS="Unsigned (will show security warning)"
fi

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

# Sign the DMG (if we have a certificate)
if security find-identity -v -p codesigning | grep -q "${SIGNING_IDENTITY}"; then
    echo "🔐 Signing DMG..."
    if codesign --force \
               --sign "${SIGNING_IDENTITY}" \
               --timestamp \
               "${DMG_NAME}.dmg" 2>/dev/null; then
        echo "✅ DMG signed successfully!"
        DMG_SIGNED_STATUS="DMG is code signed"
    else
        echo "⚠️  DMG signing failed, but app inside is signed"
        DMG_SIGNED_STATUS="DMG unsigned, but app inside is signed"
    fi
else
    echo "ℹ️  No certificate found, DMG will be unsigned"
    DMG_SIGNED_STATUS="DMG unsigned (no certificate)"
fi

# Clean up temporary directories
rm -rf "${BUILD_DIR}" "${DMG_DIR}"

echo "✅ DMG created: ${DMG_NAME}.dmg"
echo ""
echo "📋 Distribution Summary:"
echo "  • File: ${DMG_NAME}.dmg"
echo "  • Size: $(du -h "${DMG_NAME}.dmg" | cut -f1)"
echo "  • App Status: ${SIGNED_STATUS}"
echo "  • DMG Status: ${DMG_SIGNED_STATUS}"
echo ""
echo "🚀 Next Steps:"
echo "  1. Test the DMG by mounting and installing"
echo "  2. For signed distribution, join Apple Developer Program"
echo "  3. Share DMG with testers via email/cloud storage"
echo ""
# Provide different instructions based on signing status
if [[ "${SIGNED_STATUS}" == *"Code signed"* && "${DMG_SIGNED_STATUS}" == *"code signed"* ]]; then
    echo "✅ Users can install normally:"
    echo "  1. Double-click DMG to mount"
    echo "  2. Drag ClipTyper to Applications folder"
    echo "  3. Double-click app to launch"
    echo "  4. Grant Accessibility permissions in System Settings"
else
    echo "⚠️  Users will need to (due to unsigned components):"
    echo "  1. Right-click DMG → Open (if DMG unsigned)"
    echo "  2. Drag ClipTyper to Applications folder"
    echo "  3. Right-click app → Open (if app unsigned)"
    echo "  4. Grant Accessibility permissions in System Settings"
fi