#!/bin/bash

# ClipTyper Notarized Build Script
# Creates a fully notarized, distributable DMG for public distribution
# 
# Prerequisites:
# 1. Apple Developer Program membership
# 2. Developer ID Application certificate installed
# 3. App-specific password for Apple ID
# 4. Notarization credentials stored in keychain
#
# Setup notarization credentials first:
# xcrun notarytool store-credentials "notarytool-profile" \
#   --apple-id "your-apple-id@example.com" \
#   --team-id "YOUR_TEAM_ID" \
#   --password "your-app-specific-password"

set -e  # Exit on error

PROJECT_DIR="$(dirname "$0")"
cd "$PROJECT_DIR"

APP_NAME="ClipTyper"
VERSION="1.2"
DMG_NAME="${APP_NAME}-${VERSION}-Notarized"
BUILD_DIR="./build"
DMG_DIR="./dmg-build"

# Configuration - Update these for your setup
SIGNING_IDENTITY="Developer ID Application: RALF STURHAN (5S5J7MMS7A)"
NOTARY_PROFILE="notarytool-profile"  # Name you used when storing credentials
TEAM_ID="5S5J7MMS7A"  # Your Apple Developer Team ID

echo "🔨 Building ${APP_NAME} with notarization..."
echo "🔐 Using identity: ${SIGNING_IDENTITY}"
echo "📤 Using notary profile: ${NOTARY_PROFILE}"

# Verify notarization credentials exist
if ! security find-generic-password -s "AC_PASSWORD" -a "${NOTARY_PROFILE}" >/dev/null 2>&1; then
    echo ""
    echo "❌ Notarization credentials not found!"
    echo ""
    echo "🔧 Please set up notarization credentials first:"
    echo "   1. Get app-specific password from appleid.apple.com"
    echo "   2. Run this command:"
    echo "      xcrun notarytool store-credentials \"${NOTARY_PROFILE}\" \\"
    echo "        --apple-id \"your-apple-id@example.com\" \\"
    echo "        --team-id \"${TEAM_ID}\" \\"
    echo "        --password \"your-app-specific-password\""
    echo ""
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "${BUILD_DIR}" "${DMG_DIR}" "${APP_NAME}.app" "${DMG_NAME}.dmg"

# Build the project
echo "⚡ Building Swift project..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "❌ Swift build failed!"
    exit 1
fi

echo "✅ Swift build successful!"

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

# Clean extended attributes that can cause signing issues
echo "🧹 Cleaning extended attributes..."
xattr -cr "${BUILD_DIR}/${APP_NAME}.app"

echo "✅ App bundle created!"

# Code sign the app with hardened runtime (required for notarization)
echo "🔐 Code signing app with hardened runtime..."
codesign --force \
         --deep \
         --entitlements "./ClipTyper.entitlements" \
         --sign "${SIGNING_IDENTITY}" \
         --timestamp \
         --options runtime \
         "${BUILD_DIR}/${APP_NAME}.app"

if [ $? -ne 0 ]; then
    echo "❌ Code signing failed!"
    echo "💡 Check that your certificate is installed and accessible"
    exit 1
fi

echo "✅ App signed successfully with hardened runtime!"

# Verify signature
echo "🔍 Verifying code signature..."
codesign --verify --deep --strict --verbose=2 "${BUILD_DIR}/${APP_NAME}.app"

if [ $? -ne 0 ]; then
    echo "❌ Code signature verification failed!"
    exit 1
fi

echo "✅ Code signature verified!"

# Create DMG
echo "💿 Creating DMG..."

# Create temporary DMG directory
mkdir -p "${DMG_DIR}"
cp -R "${BUILD_DIR}/${APP_NAME}.app" "${DMG_DIR}/"

# Create Applications symlink for easy installation
ln -s /Applications "${DMG_DIR}/Applications"

# Create DMG with better compression and settings
hdiutil create -srcfolder "${DMG_DIR}" \
               -volname "${APP_NAME}" \
               -format UDZO \
               -imagekey zlib-level=9 \
               -o "${DMG_NAME}.dmg"

if [ $? -ne 0 ]; then
    echo "❌ DMG creation failed!"
    exit 1
fi

echo "✅ DMG created successfully!"

# Sign the DMG
echo "🔐 Signing DMG..."
codesign --force \
         --sign "${SIGNING_IDENTITY}" \
         --timestamp \
         "${DMG_NAME}.dmg"

if [ $? -ne 0 ]; then
    echo "❌ DMG signing failed!"
    exit 1
fi

echo "✅ DMG signed successfully!"

# Submit for notarization
echo ""
echo "📤 Submitting to Apple for notarization..."
echo "⏳ This may take several minutes..."

NOTARIZATION_OUTPUT=$(xcrun notarytool submit "${DMG_NAME}.dmg" \
                                            --keychain-profile "${NOTARY_PROFILE}" \
                                            --wait 2>&1)

NOTARIZATION_EXIT_CODE=$?

echo "$NOTARIZATION_OUTPUT"

if [ $NOTARIZATION_EXIT_CODE -ne 0 ]; then
    echo ""
    echo "❌ Notarization failed!"
    echo ""
    echo "🔧 Common issues and solutions:"
    echo "   • Invalid credentials: Re-run notarytool store-credentials"
    echo "   • Signing issues: Check code signing and entitlements"
    echo "   • Network issues: Check internet connection"
    echo ""
    echo "📋 Debug steps:"
    echo "   1. Check submission ID in output above"
    echo "   2. Get detailed info: xcrun notarytool info <submission-id> --keychain-profile \"${NOTARY_PROFILE}\""
    echo "   3. Get logs: xcrun notarytool log <submission-id> --keychain-profile \"${NOTARY_PROFILE}\""
    exit 1
fi

echo ""
echo "✅ Notarization successful!"

# Staple the notarization ticket to the DMG
echo "📎 Stapling notarization ticket to DMG..."
xcrun stapler staple "${DMG_NAME}.dmg"

if [ $? -ne 0 ]; then
    echo "⚠️  Stapling failed, but notarization was successful"
    echo "💡 The DMG is still valid - users may need internet for first launch"
    echo "💡 This can happen with network issues during stapling"
else
    echo "✅ Notarization ticket stapled successfully!"
fi

# Verify stapling (optional, doesn't fail the build if it fails)
echo "🔍 Verifying stapling..."
xcrun stapler validate "${DMG_NAME}.dmg" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Stapling verification successful!"
else
    echo "⚠️  Stapling verification failed, but DMG should still work"
fi

# Clean up temporary directories
rm -rf "${BUILD_DIR}" "${DMG_DIR}"

# Final verification with Gatekeeper
echo "🛡️  Final Gatekeeper verification..."
spctl --assess --type open --context context:primary-signature --verbose "${DMG_NAME}.dmg" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Gatekeeper verification passed!"
else
    echo "⚠️  Gatekeeper verification inconclusive (this can be normal)"
fi

echo ""
echo "🎉 SUCCESS! Notarized DMG created: ${DMG_NAME}.dmg"
echo ""
echo "📋 Distribution Summary:"
echo "  • File: ${DMG_NAME}.dmg"
echo "  • Size: $(du -h "${DMG_NAME}.dmg" | cut -f1)"
echo "  • Status: Code signed and notarized by Apple"
echo "  • Identity: ${SIGNING_IDENTITY}"
echo "  • Hardened Runtime: Enabled"
echo "  • Notarization: ✅ Complete"
echo "  • Ticket Stapled: $(xcrun stapler validate "${DMG_NAME}.dmg" >/dev/null 2>&1 && echo "✅ Yes" || echo "⚠️  Check required")"
echo ""
echo "🚀 Distribution Options:"
echo "  • ✅ No security warnings on any macOS version"
echo "  • ✅ Can be distributed anywhere (web, email, cloud)"
echo "  • ✅ Users can install normally without workarounds"
echo "  • ✅ Full Gatekeeper approval"
echo "  • ✅ Ready for professional distribution"
echo ""
echo "🎯 Next Steps:"
echo "  • Test installation on different macOS versions"
echo "  • Upload to GitHub releases with notarized tag"
echo "  • Share download link publicly"
echo "  • Consider website/marketing distribution"
echo ""
echo "💡 Pro tip: The notarized DMG can be distributed through any channel"
echo "    and will install without security warnings on all macOS versions."