#!/bin/bash

# ClipTyper Notarization Setup Script
# Helps you configure notarization credentials for the first time

echo "🔧 ClipTyper Notarization Setup"
echo "==============================="
echo ""
echo "This script will help you set up notarization credentials for ClipTyper."
echo ""

# Check if already configured
NOTARY_PROFILE="notarytool-profile"
if security find-generic-password -s "AC_PASSWORD" -a "${NOTARY_PROFILE}" >/dev/null 2>&1; then
    echo "✅ Notarization credentials already configured!"
    echo ""
    echo "Profile name: ${NOTARY_PROFILE}"
    echo ""
    echo "You can now run: ./build-notarized.sh"
    exit 0
fi

echo "📋 Prerequisites Checklist:"
echo ""
echo "✅ Apple Developer Program membership (\$99/year)"
echo "✅ Developer ID Application certificate (you have this)"
echo "❓ App-specific password (we'll help you create this)"
echo ""

read -p "Do you have an Apple Developer account? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "❌ You need an Apple Developer Program membership first."
    echo "   Visit: https://developer.apple.com/programs/"
    exit 1
fi

echo ""
echo "🔑 App-Specific Password Setup"
echo "------------------------------"
echo ""
echo "You need to create an app-specific password for notarization:"
echo ""
echo "1. Go to: https://appleid.apple.com"
echo "2. Sign in with your Apple ID"
echo "3. Go to 'Security' section"
echo "4. Click 'App-Specific Passwords'"
echo "5. Click 'Generate Password'"
echo "6. Label it 'ClipTyper Notarization'"
echo "7. Copy the generated password"
echo ""

read -p "Have you created an app-specific password? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Please create the app-specific password first, then run this script again."
    exit 1
fi

echo ""
echo "📝 Enter Your Credentials"
echo "------------------------"
echo ""

# Get Apple ID
read -p "Enter your Apple ID (email): " APPLE_ID
if [[ -z "$APPLE_ID" ]]; then
    echo "❌ Apple ID is required"
    exit 1
fi

# Get Team ID
echo ""
echo "Your Team ID is: 5S5J7MMS7A"
echo "(This should match your Developer ID certificate)"
read -p "Is this correct? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter your Team ID: " TEAM_ID
else
    TEAM_ID="5S5J7MMS7A"
fi

# Get app-specific password
echo ""
read -s -p "Enter your app-specific password: " APP_PASSWORD
echo
if [[ -z "$APP_PASSWORD" ]]; then
    echo "❌ App-specific password is required"
    exit 1
fi

echo ""
echo "💾 Storing credentials in keychain..."

# Store credentials using notarytool
xcrun notarytool store-credentials "${NOTARY_PROFILE}" \
    --apple-id "${APPLE_ID}" \
    --team-id "${TEAM_ID}" \
    --password "${APP_PASSWORD}"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Notarization credentials stored successfully!"
    echo ""
    echo "Profile name: ${NOTARY_PROFILE}"
    echo "Apple ID: ${APPLE_ID}"
    echo "Team ID: ${TEAM_ID}"
    echo ""
    echo "🎯 Next Steps:"
    echo "  1. Run: ./build-notarized.sh"
    echo "  2. Wait for notarization to complete"
    echo "  3. Distribute the notarized DMG"
    echo ""
    echo "💡 The credentials are stored securely in your macOS keychain"
    echo "   and will be reused for future notarization builds."
else
    echo ""
    echo "❌ Failed to store credentials"
    echo ""
    echo "🔧 Common issues:"
    echo "  • Incorrect Apple ID or password"
    echo "  • Wrong Team ID"
    echo "  • Network connectivity issues"
    echo ""
    echo "Please verify your credentials and try again."
    exit 1
fi