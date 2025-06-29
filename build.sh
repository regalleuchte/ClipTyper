#!/bin/bash

# ClipTyper Development Build Script
# Creates a basic app bundle for development testing

set -e  # Exit on error

PROJECT_DIR="$(dirname "$0")"
cd "$PROJECT_DIR"

APP_NAME="ClipTyper"
APP_BUNDLE="${APP_NAME}.app"

echo "🔨 Building ${APP_NAME} for development..."

# Clean previous build
rm -rf "${APP_BUNDLE}"

# Build the project
echo "⚡ Compiling Swift project..."
swift build -c release

echo "✅ Build successful!"

# Create app bundle structure
echo "📦 Creating app bundle..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy executable
cp "./.build/release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Copy and process Info.plist to replace placeholder values
cp "./Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
sed -i '' 's/$(EXECUTABLE_NAME)/ClipTyper/g' "${APP_BUNDLE}/Contents/Info.plist"
sed -i '' 's/$(PRODUCT_NAME)/ClipTyper/g' "${APP_BUNDLE}/Contents/Info.plist"
sed -i '' 's/$(MACOSX_DEPLOYMENT_TARGET)/12.0/g' "${APP_BUNDLE}/Contents/Info.plist"

# Copy icon file
if [ -f "./Sources/Resources/ClipTyper.icns" ]; then
    cp "./Sources/Resources/ClipTyper.icns" "${APP_BUNDLE}/Contents/Resources/"
    echo "✅ Icon copied successfully!"
else
    echo "⚠️  Warning: ClipTyper.icns not found"
fi

# Make executable
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Clean extended attributes (apply lessons learned)
echo "🧹 Cleaning extended attributes..."
xattr -cr "${APP_BUNDLE}" 2>/dev/null || true

echo "✅ App bundle created successfully!"

# Optional code signing with improved approach
SIGNING_IDENTITY="Developer ID Application: RALF STURHAN (5S5J7MMS7A)"
if security find-identity -v -p codesigning | grep -q "${SIGNING_IDENTITY}" 2>/dev/null; then
    echo "🔐 Developer ID certificate detected. Signing app..."
    
    if codesign --force \
               --deep \
               --entitlements "./ClipTyper.entitlements" \
               --sign "${SIGNING_IDENTITY}" \
               --timestamp \
               --options runtime \
               "${APP_BUNDLE}" 2>/dev/null; then
        echo "✅ App signed successfully!"
        
        # Verify signature (non-fatal)
        if codesign --verify --deep --strict "${APP_BUNDLE}" 2>/dev/null; then
            echo "✅ Signature verified!"
        else
            echo "⚠️  Signature verification had issues (likely extended attributes) but signing succeeded"
        fi
        
        SIGNED_STATUS="✅ Signed"
    else
        echo "⚠️  Code signing failed, but app is functional"
        SIGNED_STATUS="⚠️  Unsigned"
    fi
else
    echo "ℹ️  No Developer ID certificate found - creating unsigned build"
    SIGNED_STATUS="ℹ️  Unsigned (no certificate)"
fi

echo ""
echo "📋 Development Build Summary:"
echo "  • App Bundle: ${APP_BUNDLE}"
echo "  • Status: ${SIGNED_STATUS}"
echo "  • Location: $(pwd)/${APP_BUNDLE}"
echo ""
echo "🚀 To run the app:"
echo "  • Double-click: ${APP_BUNDLE}"
echo "  • Command line: ./${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
echo "  • Debugging: Run from Xcode or add debug flags"
echo ""
echo "💡 For distribution builds, use:"
echo "  • ./build-dmg.sh (signed DMG)"
echo "  • ./build-notarized.sh (maximum security)" 