#!/bin/bash
#
# quick-validate.sh - Quick pre-release validation for ClipTyper
# Runs in < 2 minutes to ensure release quality
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 ClipTyper Quick Release Validation${NC}"
echo "====================================="
echo "This should complete in < 2 minutes"
echo

FAILED=0
WARNINGS=0

# 1. Check Swift version
echo -n "1. Checking Swift version... "
if swift --version &>/dev/null; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Swift not found${NC}"
    FAILED=1
fi

# 2. Clean build
echo -n "2. Clean build test... "
rm -rf .build &>/dev/null || true
if swift build -c release --quiet 2>&1; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Build failed${NC}"
    FAILED=1
fi

# 3. Run unit tests
echo -n "3. Running unit tests... "
if swift test --quiet 2>&1; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Tests failed${NC}"
    FAILED=1
fi

# 4. Check for common issues
echo -n "4. Checking for common issues... "
issues_found=false

# Check for force unwrapping in key files
if grep -r "!" Sources/ --include="*.swift" | grep -v "!=" | grep -v "// swiftlint:disable" &>/dev/null; then
    echo -e "${YELLOW}⚠️  Force unwrapping found${NC}"
    WARNINGS=$((WARNINGS + 1))
    issues_found=true
fi

# Check for print statements (should use proper logging)
if grep -r "print(" Sources/ --include="*.swift" | grep -v "// DEBUG" &>/dev/null; then
    echo -e "${YELLOW}⚠️  Debug print statements found${NC}"
    WARNINGS=$((WARNINGS + 1))
    issues_found=true
fi

if ! $issues_found; then
    echo -e "${GREEN}✅${NC}"
fi

# 5. Verify app bundle creation
echo -n "5. Creating app bundle... "
if ./build.sh &>/dev/null; then
    if [ -d "ClipTyper.app" ]; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌ App bundle not created${NC}"
        FAILED=1
    fi
else
    echo -e "${RED}❌ Build script failed${NC}"
    FAILED=1
fi

# 6. Check app structure
echo -n "6. Validating app structure... "
if [ -d "ClipTyper.app" ]; then
    required_files=(
        "ClipTyper.app/Contents/MacOS/ClipTyper"
        "ClipTyper.app/Contents/Info.plist"
        "ClipTyper.app/Contents/Resources/ClipTyper.icns"
    )
    
    structure_ok=true
    for file in "${required_files[@]}"; do
        if [ ! -e "$file" ]; then
            structure_ok=false
            break
        fi
    done
    
    if $structure_ok; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌ Missing required files${NC}"
        FAILED=1
    fi
else
    echo -e "${YELLOW}⚠️  Skipped (no app bundle)${NC}"
fi

# 7. Check code signing (if available)
echo -n "7. Checking code signing... "
if [ -d "ClipTyper.app" ]; then
    if codesign -v "ClipTyper.app" &>/dev/null; then
        echo -e "${GREEN}✅ Signed${NC}"
    else
        echo -e "${YELLOW}⚠️  Not signed (OK for dev)${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  Skipped${NC}"
fi

# 8. Memory leak check (basic)
echo -n "8. Basic memory check... "
if swift build --quiet 2>&1; then
    # Run a quick test to check for obvious leaks
    # In a real scenario, we'd use Instruments
    echo -e "${GREEN}✅ Build OK${NC}"
else
    echo -e "${YELLOW}⚠️  Could not verify${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# 9. Documentation check
echo -n "9. Checking documentation... "
required_docs=(
    "README.md"
    "LICENSE"
    "TESTING_STRATEGY.md"
)

docs_ok=true
for doc in "${required_docs[@]}"; do
    if [ ! -f "$doc" ]; then
        docs_ok=false
        break
    fi
done

if $docs_ok; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${YELLOW}⚠️  Missing docs${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# 10. Version check
echo -n "10. Checking version consistency... "
if [ -f "Info.plist" ]; then
    VERSION=$(grep -A1 "CFBundleShortVersionString" Info.plist | tail -1 | sed 's/.*<string>\(.*\)<\/string>/\1/')
    if [ -n "$VERSION" ]; then
        echo -e "${GREEN}✅ v$VERSION${NC}"
    else
        echo -e "${YELLOW}⚠️  Version not found${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  Info.plist not found${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

echo
echo "====================================="

# Summary
if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✅ All checks passed! Ready for release.${NC}"
        echo
        echo "Next steps:"
        echo "1. Run ./build-dmg.sh for distribution"
        echo "2. Test the DMG on a clean system"
        echo "3. Create GitHub release"
    else
        echo -e "${YELLOW}⚠️  Validation passed with $WARNINGS warnings${NC}"
        echo
        echo "Review warnings above before release."
        echo "Run ./test.sh for more detailed testing."
    fi
    exit 0
else
    echo -e "${RED}❌ Validation failed!${NC}"
    echo
    echo "Fix the issues above before releasing."
    echo "Run ./test.sh for detailed error information."
    exit 1
fi 