#!/bin/bash
#
# test.sh - Comprehensive test runner for ClipTyper
#
# Usage:
#   ./test.sh              # Run all tests
#   ./test.sh unit         # Run only unit tests
#   ./test.sh integration  # Run only integration tests
#   ./test.sh smoke        # Run quick smoke tests
#   ./test.sh coverage     # Run with coverage report
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test categories
TEST_TYPE=${1:-all}

echo -e "${BLUE}🧪 ClipTyper Test Suite${NC}"
echo "================================"
echo

# Function to run tests with nice output
run_test_category() {
    local category=$1
    local filter=$2
    local description=$3
    
    echo -e "${YELLOW}Running $description...${NC}"
    
    if swift test --filter "$filter" 2>&1 | tee test_output.log; then
        echo -e "${GREEN}✅ $description passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ $description failed!${NC}"
        return 1
    fi
}

# Function to check if tests can run
check_test_environment() {
    echo -e "${BLUE}Checking test environment...${NC}"
    
    # Check if we're in the right directory
    if [ ! -f "Package.swift" ]; then
        echo -e "${RED}Error: Package.swift not found. Run this script from the project root.${NC}"
        exit 1
    fi
    
    # Check if Tests directory exists
    if [ ! -d "Tests" ]; then
        echo -e "${RED}Error: Tests directory not found.${NC}"
        exit 1
    fi
    
    # Check Swift version
    SWIFT_VERSION=$(swift --version | head -n 1)
    echo "Swift version: $SWIFT_VERSION"
    
    echo -e "${GREEN}✅ Test environment OK${NC}"
    echo
}

# Function to run smoke tests (quick validation)
run_smoke_tests() {
    echo -e "${BLUE}🚀 Running Smoke Tests${NC}"
    echo "======================"
    
    # Quick build test
    echo -n "Building project... "
    if swift build --quiet 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        exit 1
    fi
    
    # Check critical files exist
    echo -n "Checking critical files... "
    critical_files=(
        "Sources/AppDelegate.swift"
        "Sources/ClipboardManager.swift"
        "Sources/KeyboardSimulator.swift"
        "Sources/GlobalShortcutManager.swift"
    )
    
    all_exist=true
    for file in "${critical_files[@]}"; do
        if [ ! -f "$file" ]; then
            all_exist=false
            break
        fi
    done
    
    if $all_exist; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Smoke tests passed!${NC}"
}

# Function to generate coverage report
generate_coverage_report() {
    echo -e "${BLUE}📊 Generating Coverage Report${NC}"
    echo "=============================="
    
    # Run tests with coverage
    swift test --enable-code-coverage
    
    # Find the xctest bundle
    XCTEST_PATH=$(find .build -name "*.xctest" -type d | head -n 1)
    
    if [ -z "$XCTEST_PATH" ]; then
        echo -e "${RED}Could not find test bundle for coverage${NC}"
        return 1
    fi
    
    # Generate coverage report
    xcrun llvm-cov report \
        "$XCTEST_PATH/Contents/MacOS/ClipTyperPackageTests" \
        -instr-profile=.build/debug/codecov/default.profdata \
        -ignore-filename-regex=".build|Tests" \
        -use-color
    
    # Generate detailed HTML report
    echo
    echo "Generating HTML coverage report..."
    xcrun llvm-cov show \
        "$XCTEST_PATH/Contents/MacOS/ClipTyperPackageTests" \
        -instr-profile=.build/debug/codecov/default.profdata \
        -ignore-filename-regex=".build|Tests" \
        -format=html \
        -output-dir=coverage_report
    
    echo -e "${GREEN}✅ Coverage report generated in coverage_report/index.html${NC}"
}

# Main test execution
check_test_environment

case $TEST_TYPE in
    "unit")
        run_test_category "unit" "ClipTyperTests" "Unit Tests"
        ;;
    
    "integration")
        echo -e "${YELLOW}Integration tests not yet implemented${NC}"
        ;;
    
    "smoke")
        run_smoke_tests
        ;;
    
    "coverage")
        generate_coverage_report
        ;;
    
    "all")
        # Run all test categories
        FAILED=0
        
        run_smoke_tests || FAILED=1
        echo
        
        run_test_category "unit" "ClipTyperTests" "Unit Tests" || FAILED=1
        echo
        
        if [ $FAILED -eq 0 ]; then
            echo -e "${GREEN}🎉 All tests passed!${NC}"
        else
            echo -e "${RED}❌ Some tests failed${NC}"
            exit 1
        fi
        ;;
    
    *)
        echo "Usage: $0 [all|unit|integration|smoke|coverage]"
        exit 1
        ;;
esac

# Cleanup
rm -f test_output.log

echo
echo -e "${BLUE}Test run completed$(date '+%Y-%m-%d %H:%M:%S')${NC}" 